import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stillbeat/app/providers.dart';
import 'package:stillbeat/core/errors/app_error.dart';
import 'package:stillbeat/features/measurement/domain/measurement_phase.dart';
import 'package:stillbeat/features/measurement/domain/measurement_result.dart';
import 'package:stillbeat/features/measurement/presentation/measurement_controller.dart';
import 'package:stillbeat/features/settings/domain/app_settings.dart';
import 'package:stillbeat/features/settings/presentation/settings_controller.dart';
import 'package:stillbeat/features/signal_quality/domain/signal_quality.dart';
import 'package:stillbeat/services/camera/camera_frame.dart';
import 'package:stillbeat/services/face_detection/face_locator.dart';
import 'package:stillbeat/services/rppg/window_analyzer.dart';

import '../../helpers/fakes.dart';

const _fps = 30.0;

class Harness {
  Harness({
    FakeScene? scene,
    List<DetectedFace> Function()? faces,
    WindowAnalysisRunner? runner,
    bool supported = true,
    PulseMethod method = PulseMethod.pos,
  }) {
    camera = FakeCameraSource(scene: scene);
    locator = FakeFaceLocator(
      faces ?? () => [DetectedFace(box: camera.scene.faceBox, yawDegrees: 0)],
    );
    container = ProviderContainer(
      overrides: [
        platformServicesProvider.overrideWithValue(
          fakePlatform(camera: camera, locator: locator, supported: supported),
        ),
        analysisRunnerProvider.overrideWithValue(
          runner ?? (req) async => analyzeWindow(req),
        ),
        initialSettingsProvider.overrideWithValue(
          AppSettings(
            measurementSeconds: 30,
            method: method,
            acknowledgedDisclaimerVersion: 1,
          ),
        ),
      ],
    );
    // Keep the auto-dispose controller alive for the test.
    container.listen(measurementControllerProvider, (_, __) {});
  }

  late final FakeCameraSource camera;
  late final FakeFaceLocator locator;
  late final ProviderContainer container;
  double t = 0;

  MeasurementController get controller =>
      container.read(measurementControllerProvider.notifier);
  MeasurementViewState get state =>
      container.read(measurementControllerProvider);
  MeasurementPhase get phase => state.phase;

  /// Emits frames for [seconds], yielding to the event loop so async face
  /// detection and analysis complete as they would on a device.
  Future<void> run(double seconds, {void Function(double t)? each}) async {
    final end = t + seconds;
    while (t < end) {
      each?.call(t);
      camera.emitFrame(t);
      await Future<void>.delayed(Duration.zero);
      t += 1 / _fps;
    }
    // Drain pending async work (final analysis, aggregation, teardown).
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  void dispose() => container.dispose();
}

void main() {
  test('full session on synthetic frames yields a validated estimate',
      () async {
    final h = Harness(scene: FakeScene(heartRateBpm: 72));
    addTearDown(h.dispose);
    await h.controller.start();
    expect(h.phase, MeasurementPhase.positioning);
    expect(h.camera.isOpen, isTrue);

    await h.run(2);
    expect(h.phase, MeasurementPhase.warmingUp);
    await h.run(5);
    expect(h.phase, MeasurementPhase.measuring);
    await h.run(31);

    expect(h.phase, MeasurementPhase.completed);
    final outcome = h.state.outcome;
    expect(outcome, isA<MeasurementSucceeded>());
    final r = (outcome! as MeasurementSucceeded).result;
    expect(r.heartRateBpm, closeTo(72, 3));
    expect(r.quality.isUsable, isTrue);
    expect(r.validWindowCount, greaterThanOrEqualTo(8));
    expect(r.waveform, isNotEmpty);
    expect(r.algorithm.id, 'pos');
    // Camera must be released once measuring ends.
    expect(h.camera.isOpen, isFalse);
    expect(h.locator.disposed, isTrue);
  });

  test('CHROM also completes on the same synthetic scene', () async {
    final h =
        Harness(scene: FakeScene(heartRateBpm: 90), method: PulseMethod.chrom);
    addTearDown(h.dispose);
    await h.controller.start();
    await h.run(40);
    final outcome = h.state.outcome;
    expect(outcome, isA<MeasurementSucceeded>());
    expect(
        (outcome! as MeasurementSucceeded).result.heartRateBpm, closeTo(90, 3));
    expect((outcome as MeasurementSucceeded).result.algorithm.id, 'chrom');
  });

  test('live estimate is shown only while windows are usable', () async {
    final h = Harness();
    addTearDown(h.dispose);
    await h.controller.start();
    await h.run(18);
    expect(h.phase, MeasurementPhase.measuring);
    expect(h.state.liveBpm, isNotNull);
    expect(h.state.waveform, isNotNull);
  });

  test('a scene without a pulse is rejected and reports no value', () async {
    final h = Harness(scene: FakeScene(pulseAmplitude: 0, pixelNoise: 6));
    addTearDown(h.dispose);
    await h.controller.start();
    await h.run(40);
    expect(h.phase, MeasurementPhase.lowSignalQuality);
    expect(h.state.outcome, isA<MeasurementRejected>());
    expect(h.camera.isOpen, isFalse);
  });

  test('permission denial maps to permissionDenied and opens nothing',
      () async {
    final h = Harness();
    addTearDown(h.dispose);
    h.camera.openError = const PermissionDeniedError(permanent: true);
    await h.controller.start();
    expect(h.phase, MeasurementPhase.permissionDenied);
    expect(h.state.error, isA<PermissionDeniedError>());
    expect(h.camera.isOpen, isFalse);
  });

  test('camera unavailable maps to cameraFailure', () async {
    final h = Harness();
    addTearDown(h.dispose);
    h.camera.openError = const CameraUnavailableError();
    await h.controller.start();
    expect(h.phase, MeasurementPhase.cameraFailure);
    expect(h.state.error, isA<CameraUnavailableError>());
  });

  test('unsupported platform starts in unsupported state', () async {
    final h = Harness(supported: false);
    addTearDown(h.dispose);
    expect(h.phase, MeasurementPhase.unsupported);
    await h.controller.start();
    expect(h.camera.openCount, 0);
  });

  test('no face keeps positioning, then times out', () async {
    final h = Harness(faces: () => const []);
    addTearDown(h.dispose);
    await h.controller.start();
    await h.run(5);
    expect(h.phase, MeasurementPhase.positioning);
    expect(h.state.guidance, contains(QualityIssue.noFace));
    await h.run(57);
    expect(h.phase, MeasurementPhase.timedOut);
    expect(h.camera.isOpen, isFalse);
  });

  test('multiple faces are never measured', () async {
    final h = Harness(
      faces: () => const [
        DetectedFace(box: NormRect(0.3, 0.2, 0.7, 0.75)),
        DetectedFace(box: NormRect(0.0, 0.0, 0.3, 0.3)),
      ],
    );
    addTearDown(h.dispose);
    await h.controller.start();
    await h.run(5);
    expect(h.phase, MeasurementPhase.positioning);
    expect(h.state.guidance, contains(QualityIssue.multipleFaces));
  });

  test('face too small and off-centre produce guidance', () async {
    final h = Harness(
      faces: () => const [DetectedFace(box: NormRect(0.0, 0.0, 0.1, 0.1))],
    );
    addTearDown(h.dispose);
    await h.controller.start();
    await h.run(2);
    expect(
      h.state.guidance,
      containsAll([QualityIssue.faceTooSmall, QualityIssue.faceOffCenter]),
    );
  });

  test('dark scene is reported as low light and does not start', () async {
    final h = Harness(scene: FakeScene(skinRgb: [20, 14, 12]));
    addTearDown(h.dispose);
    await h.controller.start();
    await h.run(4);
    expect(h.phase, MeasurementPhase.positioning);
    expect(h.state.guidance, contains(QualityIssue.lowLight));
  });

  test('losing the face during measuring restarts positioning', () async {
    var faceVisible = true;
    late Harness h;
    h = Harness(
      faces: () =>
          faceVisible ? [DetectedFace(box: h.camera.scene.faceBox)] : const [],
    );
    addTearDown(h.dispose);
    await h.controller.start();
    await h.run(10);
    expect(h.phase, MeasurementPhase.measuring);
    faceVisible = false;
    await h.run(4);
    expect(h.phase, MeasurementPhase.positioning);
    expect(h.state.liveBpm, isNull);
  });

  test('cancel stops the camera and ignores late frames', () async {
    final h = Harness();
    addTearDown(h.dispose);
    await h.controller.start();
    await h.run(9);
    await h.controller.cancel();
    expect(h.phase, MeasurementPhase.cancelled);
    expect(h.camera.isOpen, isFalse);
    await h.run(1);
    expect(h.phase, MeasurementPhase.cancelled);
  });

  test('restart after cancel opens a fresh session', () async {
    final h = Harness();
    addTearDown(h.dispose);
    await h.controller.start();
    await h.run(3);
    await h.controller.cancel();
    await h.controller.start();
    expect(h.camera.openCount, 2);
    expect(h.phase, MeasurementPhase.positioning);
  });

  test('pause releases the camera and resume restarts', () async {
    final h = Harness();
    addTearDown(h.dispose);
    await h.controller.start();
    await h.run(8);
    await h.controller.onAppPaused();
    expect(h.phase, MeasurementPhase.interrupted);
    expect(h.camera.isOpen, isFalse);
    await h.controller.onAppResumed();
    expect(h.phase, MeasurementPhase.positioning);
    expect(h.camera.openCount, 2);
  });

  test('camera stream error during a session maps to cameraFailure', () async {
    final h = Harness();
    addTearDown(h.dispose);
    await h.controller.start();
    await h.run(2);
    h.camera.emitError(const CameraFailureError('track-ended'));
    await Future<void>.delayed(Duration.zero);
    expect(h.phase, MeasurementPhase.cameraFailure);
    expect(h.camera.isOpen, isFalse);
  });

  test('analysis failure maps to inferenceFailure', () async {
    final h = Harness(runner: (_) async => throw StateError('boom'));
    addTearDown(h.dispose);
    await h.controller.start();
    await h.run(12);
    expect(h.phase, MeasurementPhase.inferenceFailure);
    expect(h.camera.isOpen, isFalse);
  });

  test('face detector failures are treated as no face, not a crash', () async {
    final h = Harness();
    addTearDown(h.dispose);
    h.locator.throwOnDetect = true;
    await h.controller.start();
    await h.run(3);
    expect(h.phase, MeasurementPhase.positioning);
    expect(h.state.guidance, contains(QualityIssue.noFace));
  });

  test('face detection is rate limited', () async {
    final h = Harness();
    addTearDown(h.dispose);
    await h.controller.start();
    await h.run(3);
    // ~90 frames at 5 Hz detection => ~15 detections.
    expect(h.locator.calls, inInclusiveRange(12, 18));
  });

  test('disposing the container releases the camera', () async {
    final h = Harness();
    await h.controller.start();
    await h.run(1);
    h.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(h.camera.isOpen, isFalse);
  });
}
