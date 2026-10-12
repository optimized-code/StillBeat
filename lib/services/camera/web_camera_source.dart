import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import '../../core/errors/app_error.dart';
import '../../core/logging/app_logger.dart';
import 'camera_frame.dart';
import 'camera_source.dart';

extension type _FrameMetadata._(JSObject _) implements JSObject {
  external JSNumber? get captureTime;
}

/// Browser camera via `getUserMedia`, rendered in a `<video>` platform view
/// and sampled through a small canvas.
///
/// Flutter's `camera` plugin on web does not offer an image stream, so this
/// adapter is used instead.
class WebCameraSource implements CameraSource {
  WebCameraSource({AppLogger? logger, this.sampleWidth = 160})
      : _log = logger ?? AppLogger('camera.web');

  /// Width of the canvas frames are scaled to before reading pixels. The
  /// browser's scaler averages neighbouring pixels, which also reduces
  /// sensor noise in the colour means.
  final int sampleWidth;

  final AppLogger _log;
  static int _viewCounter = 0;

  web.MediaStream? _stream;
  web.HTMLVideoElement? _video;
  web.HTMLCanvasElement? _canvas;
  web.CanvasRenderingContext2D? _ctx;
  // Closed in close(); the lint cannot see across methods.
  // ignore: close_sinks
  StreamController<CameraFrame>? _frames;
  String? _viewType;
  Timer? _fallbackTimer;
  double _lastMediaTime = -1;
  bool _running = false;
  int _width = 0;
  int _height = 0;
  final List<JSFunction> _trackEndedHandlers = [];

  @override
  Stream<CameraFrame> get frames =>
      _frames?.stream ?? const Stream<CameraFrame>.empty();

  @override
  double? get previewAspectRatio =>
      _width > 0 && _height > 0 ? _width / _height : null;

  @override
  bool get isMirrored => true;

  @override
  Future<List<CameraDeviceInfo>> listCameras() async {
    final md = web.window.navigator.mediaDevices;
    final devices = (await md.enumerateDevices().toDart).toDart;
    var i = 0;
    return [
      for (final d in devices)
        if (d.kind == 'videoinput')
          CameraDeviceInfo(
            id: d.deviceId,
            label: d.label.isNotEmpty ? d.label : 'Camera ${++i}',
          ),
    ];
  }

  @override
  Future<void> open({String? deviceId}) async {
    await close();
    if (!web.window.isSecureContext) {
      throw const UnsupportedPlatformError('insecure-context');
    }
    final nav = web.window.navigator as JSObject;
    if (!nav.has('mediaDevices')) {
      throw const UnsupportedPlatformError('no-mediaDevices');
    }

    final video = <String, Object?>{
      'width': {'ideal': 640},
      'height': {'ideal': 480},
      'frameRate': {'ideal': 30},
      if (deviceId != null)
        'deviceId': {'exact': deviceId}
      else
        'facingMode': 'user',
    };
    final web.MediaStream stream;
    try {
      stream = await web.window.navigator.mediaDevices
          .getUserMedia(
            web.MediaStreamConstraints(
              video: video.jsify()!,
              audio: false.toJS,
            ),
          )
          .toDart;
    } catch (e) {
      throw _mapError(e);
    }
    _stream = stream;

    final el = web.HTMLVideoElement()
      ..autoplay = true
      ..muted = true
      ..playsInline = true
      ..srcObject = stream;
    el.style
      ..width = '100%'
      ..height = '100%'
      ..objectFit = 'cover'
      ..transform = 'scaleX(-1)'
      ..pointerEvents = 'none';
    _video = el;

    try {
      await el.play().toDart;
    } catch (e) {
      await close();
      throw CameraFailureError('play: ${e.runtimeType}');
    }
    await _waitForDimensions(el);
    _width = el.videoWidth;
    _height = el.videoHeight;
    if (_width == 0 || _height == 0) {
      await close();
      throw const CameraFailureError('no video dimensions');
    }

    final viewType = 'rppg-camera-${_viewCounter++}';
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) => el);
    _viewType = viewType;

    final h = (sampleWidth * _height / _width).round();
    final canvas = web.HTMLCanvasElement()
      ..width = sampleWidth
      ..height = h;
    _canvas = canvas;
    _ctx = canvas.getContext(
      '2d',
      {'willReadFrequently': true}.jsify(),
    ) as web.CanvasRenderingContext2D?;

    for (final track in stream.getVideoTracks().toDart) {
      final handler = ((web.Event _) {
        _frames?.addError(const CameraFailureError('track-ended'));
      }).toJS;
      track.addEventListener('ended', handler);
      _trackEndedHandlers.add(handler);
    }

    _frames = StreamController<CameraFrame>.broadcast();
    _running = true;
    _scheduleNext();
    _log.info('web camera opened', {'w': _width, 'h': _height});
  }

  Future<void> _waitForDimensions(web.HTMLVideoElement el) async {
    for (var i = 0; i < 50 && el.videoWidth == 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  void _scheduleNext() {
    final v = _video;
    if (!_running || v == null) return;
    if ((v as JSObject).has('requestVideoFrameCallback')) {
      v.requestVideoFrameCallback(
        ((JSNumber now, _FrameMetadata meta) {
          final capture = meta.captureTime?.toDartDouble;
          _grab(capture ?? now.toDartDouble);
          _scheduleNext();
        }).toJS,
      );
    } else {
      // Firefox (at time of writing) lacks requestVideoFrameCallback. Poll
      // and skip frames whose media time has not advanced, so duplicates
      // never enter the signal.
      _fallbackTimer ??= Timer.periodic(
        const Duration(milliseconds: 16),
        (_) {
          final t = v.currentTime;
          if (t == _lastMediaTime) return;
          _lastMediaTime = t;
          _grab(web.window.performance.now());
        },
      );
    }
  }

  void _grab(double timestampMs) {
    final ctx = _ctx;
    final canvas = _canvas;
    final video = _video;
    final sink = _frames;
    if (!_running || ctx == null || canvas == null || video == null) return;
    if (sink == null || sink.isClosed) return;
    if (web.document.hidden) return;
    final w = canvas.width;
    final h = canvas.height;
    ctx.drawImage(video, 0, 0, w.toDouble(), h.toDouble());
    final data = ctx.getImageData(0, 0, w, h).data.toDart;
    sink.add(
      CameraFrame(
        timestampMicros: (timestampMs * 1000).round(),
        width: w,
        height: h,
        format: FramePixelFormat.rgba8888,
        planes: [
          FramePlane(
            bytes: Uint8List.view(data.buffer, data.offsetInBytes, data.length),
            bytesPerRow: w * 4,
            bytesPerPixel: 4,
          ),
        ],
      ),
    );
  }

  /// Maps a getUserMedia rejection to a typed error. DOMException names are
  /// matched in the error's string form, which is stable across dart2js and
  /// dart2wasm (type checks against JS interop types are not).
  AppError _mapError(Object e) {
    final s = e.toString();
    bool has(String name) => s.contains(name);
    if (has('NotAllowedError') || has('SecurityError')) {
      return const PermissionDeniedError(detail: 'browser');
    }
    if (has('NotFoundError') || has('OverconstrainedError')) {
      return const CameraUnavailableError('not-found');
    }
    if (has('NotReadableError') || has('AbortError')) {
      return const CameraFailureError('not-readable');
    }
    return const CameraFailureError('getUserMedia');
  }

  @override
  Widget buildPreview(BuildContext context) {
    final vt = _viewType;
    if (vt == null) return const SizedBox.shrink();
    return HtmlElementView(viewType: vt);
  }

  @override
  Future<void> close() async {
    _running = false;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    _lastMediaTime = -1;
    final stream = _stream;
    _stream = null;
    if (stream != null) {
      final tracks = stream.getTracks().toDart;
      for (var i = 0; i < tracks.length; i++) {
        if (i < _trackEndedHandlers.length) {
          tracks[i].removeEventListener('ended', _trackEndedHandlers[i]);
        }
        tracks[i].stop();
      }
      _log.info('web camera closed');
    }
    _trackEndedHandlers.clear();
    final v = _video;
    if (v != null) {
      v.pause();
      v.srcObject = null;
    }
    _video = null;
    _canvas = null;
    _ctx = null;
    _viewType = null;
    _width = 0;
    _height = 0;
    final f = _frames;
    _frames = null;
    await f?.close();
  }
}
