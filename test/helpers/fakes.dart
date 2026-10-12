import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:stillbeat/core/errors/app_error.dart';
import 'package:stillbeat/core/platform/platform_services.dart';
import 'package:stillbeat/services/camera/camera_frame.dart';
import 'package:stillbeat/services/camera/camera_source.dart';
import 'package:stillbeat/services/face_detection/face_locator.dart';

/// Describes the synthetic scene rendered by [FakeCameraSource].
class FakeScene {
  FakeScene({
    this.heartRateBpm = 72,
    this.pulseAmplitude = 0.01,
    this.pixelNoise = 3,
    this.skinRgb = const [175, 125, 105],
    this.backgroundRgb = const [40, 60, 90],
    this.faceBox = const NormRect(0.3, 0.2, 0.7, 0.75),
    this.seed = 1,
  });

  double heartRateBpm;
  double pulseAmplitude;
  double pixelNoise;
  List<int> skinRgb;
  List<int> backgroundRgb;
  NormRect faceBox;
  final int seed;
}

/// Deterministic camera that renders RGBA frames of a skin-coloured patch
/// whose colour is modulated by a synthetic pulse. Frames are pushed
/// manually by the test with explicit timestamps, so a 40 s session runs in
/// milliseconds.
class FakeCameraSource implements CameraSource {
  FakeCameraSource({
    FakeScene? scene,
    this.width = 64,
    this.height = 48,
    this.openError,
  })  : scene = scene ?? FakeScene(),
        _rng = math.Random(1);

  final FakeScene scene;
  final int width;
  final int height;
  AppError? openError;
  final math.Random _rng;

  StreamController<CameraFrame>? _frames;
  int openCount = 0;
  int closeCount = 0;
  bool get isOpen => _frames != null;

  @override
  Stream<CameraFrame> get frames =>
      _frames?.stream ?? const Stream<CameraFrame>.empty();

  @override
  double? get previewAspectRatio => width / height;

  @override
  bool get isMirrored => true;

  @override
  Widget buildPreview(BuildContext context) =>
      const ColoredBox(color: Color(0xFF223344));

  @override
  Future<List<CameraDeviceInfo>> listCameras() async =>
      const [CameraDeviceInfo(id: 'fake', label: 'Fake camera')];

  @override
  Future<void> open({String? deviceId}) async {
    openCount++;
    final e = openError;
    if (e != null) throw e;
    _frames = StreamController<CameraFrame>.broadcast(sync: true);
  }

  @override
  Future<void> close() async {
    closeCount++;
    final f = _frames;
    _frames = null;
    await f?.close();
  }

  void emitError(AppError e) => _frames?.addError(e);

  /// Renders and emits one frame at [timeSeconds].
  void emitFrame(double timeSeconds) {
    final sink = _frames;
    if (sink == null) return;
    sink.add(render(timeSeconds));
  }

  CameraFrame render(double t) {
    final bytes = Uint8List(width * height * 4);
    final pulse = math.sin(2 * math.pi * scene.heartRateBpm / 60 * t);
    // Pulse signature: green strongest (see test/helpers/synthetic_signals).
    const sig = [0.33, 1.0, 0.55];
    final box = scene.faceBox;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final nx = (x + 0.5) / width;
        final ny = (y + 0.5) / height;
        final inFace = nx >= box.left &&
            nx < box.right &&
            ny >= box.top &&
            ny < box.bottom;
        final o = (y * width + x) * 4;
        for (var c = 0; c < 3; c++) {
          final base = inFace ? scene.skinRgb[c] : scene.backgroundRgb[c];
          final mod = inFace ? 1 + scene.pulseAmplitude * sig[c] * pulse : 1;
          final noise = (_rng.nextDouble() - 0.5) * 2 * scene.pixelNoise;
          bytes[o + c] = (base * mod + noise).round().clamp(0, 255);
        }
        bytes[o + 3] = 255;
      }
    }
    return CameraFrame(
      timestampMicros: (t * 1e6).round(),
      width: width,
      height: height,
      format: FramePixelFormat.rgba8888,
      planes: [
        FramePlane(bytes: bytes, bytesPerRow: width * 4, bytesPerPixel: 4),
      ],
    );
  }
}

/// Returns a configurable list of faces.
class FakeFaceLocator implements FaceLocator {
  FakeFaceLocator(this.facesFor);

  List<DetectedFace> Function() facesFor;
  bool throwOnDetect = false;
  int calls = 0;
  bool disposed = false;

  @override
  FaceLocatorInfo get info => const FaceLocatorInfo(
        id: 'fake-locator',
        isLearnedDetector: true,
        canDetectMultipleFaces: true,
      );

  @override
  Future<FaceDetectionResult> detect(CameraFrame frame) async {
    calls++;
    if (throwOnDetect) throw StateError('detector failure');
    return FaceDetectionResult(facesFor());
  }

  @override
  Future<void> dispose() async => disposed = true;
}

PlatformServices fakePlatform({
  required FakeCameraSource camera,
  required FakeFaceLocator locator,
  bool supported = true,
}) =>
    PlatformServices(
      platformId: 'test',
      supportsLiveMeasurement: supported,
      unsupportedReason: supported ? null : 'test-unsupported',
      createCamera: () => camera,
      createFaceLocator: (_) => locator,
      supportsCameraSelection: true,
    );
