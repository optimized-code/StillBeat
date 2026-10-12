import 'dart:async';
import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/errors/app_error.dart';
import '../../core/logging/app_logger.dart';
import 'camera_frame.dart';
import 'camera_source.dart';

/// Android (CameraX) / iOS (AVFoundation) camera via the `camera` plugin.
class MobileCameraSource implements CameraSource {
  MobileCameraSource({AppLogger? logger})
      : _log = logger ?? AppLogger('camera.mobile');

  final AppLogger _log;
  final Stopwatch _clock = Stopwatch();
  CameraController? _controller;
  // Closed in close(); the lint cannot see across methods.
  // ignore: close_sinks
  StreamController<CameraFrame>? _frames;
  int _rotation = 0;

  @override
  Stream<CameraFrame> get frames =>
      _frames?.stream ?? const Stream<CameraFrame>.empty();

  @override
  double? get previewAspectRatio {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return null;
    // Plugin aspect ratio is landscape (sensor) width/height; the app is
    // portrait-locked during measurement.
    return 1 / c.value.aspectRatio;
  }

  @override
  bool get isMirrored => true;

  @override
  Future<List<CameraDeviceInfo>> listCameras() async {
    final cams = await availableCameras();
    return [
      for (final c in cams)
        CameraDeviceInfo(id: c.name, label: c.lensDirection.name),
    ];
  }

  @override
  Future<void> open({String? deviceId}) async {
    await close();
    await _ensurePermission();

    final List<CameraDescription> cams;
    try {
      cams = await availableCameras();
    } on CameraException catch (e) {
      throw CameraFailureError(e.code);
    }
    if (cams.isEmpty) throw const CameraUnavailableError('no cameras');
    final desc = cams.firstWhere(
      (c) => deviceId != null
          ? c.name == deviceId
          : c.lensDirection == CameraLensDirection.front,
      orElse: () => cams.first,
    );

    // Android front camera: ML Kit and our ROI mapping need the rotation
    // that makes the sensor image upright for a portrait-held device.
    _rotation = Platform.isAndroid ? desc.sensorOrientation : 0;

    final controller = CameraController(
      desc,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );
    _controller = controller;
    try {
      await controller.initialize();
    } on CameraException catch (e) {
      await close();
      throw _mapCameraException(e);
    }

    _frames = StreamController<CameraFrame>.broadcast();
    _clock
      ..reset()
      ..start();
    try {
      await controller.startImageStream(_onImage);
    } on CameraException catch (e) {
      await close();
      throw CameraFailureError('startImageStream: ${e.code}');
    }
    _log.info('camera opened', {
      'format': controller.imageFormatGroup?.name,
      'rotation': _rotation,
    });
  }

  void _onImage(CameraImage image) {
    final sink = _frames;
    if (sink == null || sink.isClosed) return;
    final format = switch (image.format.group) {
      ImageFormatGroup.yuv420 => FramePixelFormat.yuv420,
      ImageFormatGroup.nv21 => FramePixelFormat.nv21,
      ImageFormatGroup.bgra8888 => FramePixelFormat.bgra8888,
      _ => null,
    };
    if (format == null) {
      sink.addError(CameraFailureError('unsupported ${image.format.group}'));
      return;
    }
    // The plugin does not expose sensor capture timestamps on all
    // platforms, so frame arrival time on a monotonic clock is used.
    // Resampling tolerates the resulting jitter (docs/technical_decisions.md).
    sink.add(
      CameraFrame(
        timestampMicros: _clock.elapsedMicroseconds,
        width: image.width,
        height: image.height,
        format: format,
        rotationDegrees: _rotation,
        planes: [
          for (final p in image.planes)
            FramePlane(
              bytes: p.bytes,
              bytesPerRow: p.bytesPerRow,
              bytesPerPixel: p.bytesPerPixel ?? 1,
            ),
        ],
      ),
    );
  }

  Future<void> _ensurePermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted || status.isLimited) return;
    throw PermissionDeniedError(
      permanent: status.isPermanentlyDenied || status.isRestricted,
      detail: status.name,
    );
  }

  AppError _mapCameraException(CameraException e) {
    switch (e.code) {
      case 'CameraAccessDenied':
      case 'cameraPermission':
        return const PermissionDeniedError(detail: 'camera');
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        return const PermissionDeniedError(permanent: true, detail: 'camera');
      default:
        return CameraFailureError(e.code);
    }
  }

  @override
  Widget buildPreview(BuildContext context) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return const SizedBox.shrink();
    return CameraPreview(c);
  }

  @override
  Future<void> close() async {
    final c = _controller;
    _controller = null;
    _clock.stop();
    final frames = _frames;
    _frames = null;
    if (c != null) {
      try {
        if (c.value.isStreamingImages) await c.stopImageStream();
      } catch (e) {
        _log.warn('stopImageStream failed', {'error': e.runtimeType});
      }
      await c.dispose();
      _log.info('camera closed');
    }
    await frames?.close();
  }
}
