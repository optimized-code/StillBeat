import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../services/camera/camera_frame.dart';
import '../../../services/camera/camera_source.dart';
import '../../../services/face_detection/face_locator.dart';
import '../../../services/frame_processing/roi_extractor.dart';
import '../../../services/rppg/dsp/stats.dart';
import '../../../services/rppg/rppg_engine.dart';
import '../../../services/rppg/rppg_sample.dart';
import '../../../services/rppg/window_analyzer.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../signal_quality/domain/signal_quality.dart';
import '../domain/measurement_phase.dart';
import '../domain/measurement_result.dart';
import '../domain/positioning.dart';
import '../domain/result_aggregator.dart';
import '../domain/session_config.dart';

/// Immutable snapshot rendered by the measurement screen.
class MeasurementViewState {
  const MeasurementViewState({
    required this.phase,
    this.guidance = const {},
    this.progress = 0,
    this.liveBpm,
    this.liveQuality = SignalQuality.insufficientData,
    this.waveform,
    this.waveformRateHz = 30,
    this.error,
    this.outcome,
    this.cameras = const [],
    this.selectedCameraId,
    this.faceLocator,
    this.algorithm,
    this.measuredFps,
    this.secondsRemaining,
  });

  final MeasurementPhase phase;

  /// Current, user-actionable issues (positioning, lighting, signal).
  final Set<QualityIssue> guidance;

  /// Fraction of the measuring phase completed (0–1).
  final double progress;

  /// Smoothed live estimate. Null whenever the latest window is not usable,
  /// so deterioration is shown immediately rather than hidden by smoothing.
  final double? liveBpm;
  final SignalQuality liveQuality;
  final Float64List? waveform;
  final double waveformRateHz;
  final AppError? error;
  final MeasurementOutcome? outcome;
  final List<CameraDeviceInfo> cameras;
  final String? selectedCameraId;
  final FaceLocatorInfo? faceLocator;
  final AlgorithmInfo? algorithm;
  final double? measuredFps;
  final int? secondsRemaining;

  MeasurementViewState copyWith({
    MeasurementPhase? phase,
    Set<QualityIssue>? guidance,
    double? progress,
    double? Function()? liveBpm,
    SignalQuality? liveQuality,
    Float64List? Function()? waveform,
    double? waveformRateHz,
    AppError? Function()? error,
    MeasurementOutcome? Function()? outcome,
    List<CameraDeviceInfo>? cameras,
    String? Function()? selectedCameraId,
    FaceLocatorInfo? faceLocator,
    AlgorithmInfo? algorithm,
    double? Function()? measuredFps,
    int? Function()? secondsRemaining,
  }) =>
      MeasurementViewState(
        phase: phase ?? this.phase,
        guidance: guidance ?? this.guidance,
        progress: progress ?? this.progress,
        liveBpm: liveBpm != null ? liveBpm() : this.liveBpm,
        liveQuality: liveQuality ?? this.liveQuality,
        waveform: waveform != null ? waveform() : this.waveform,
        waveformRateHz: waveformRateHz ?? this.waveformRateHz,
        error: error != null ? error() : this.error,
        outcome: outcome != null ? outcome() : this.outcome,
        cameras: cameras ?? this.cameras,
        selectedCameraId: selectedCameraId != null
            ? selectedCameraId()
            : this.selectedCameraId,
        faceLocator: faceLocator ?? this.faceLocator,
        algorithm: algorithm ?? this.algorithm,
        measuredFps: measuredFps != null ? measuredFps() : this.measuredFps,
        secondsRemaining: secondsRemaining != null
            ? secondsRemaining()
            : this.secondsRemaining,
      );
}

/// Per-session mutable runtime. Replaced on every start so nothing leaks
/// between sessions.
class _Session {
  _Session({
    required this.id,
    required this.method,
    required this.algorithm,
    required this.config,
    required int bufferCapacity,
  }) : buffer = SignalBuffer(capacity: bufferCapacity);

  final int id;
  final PulseMethod method;
  final AlgorithmInfo algorithm;
  final SessionConfig config;
  final SignalBuffer buffer;

  final Stopwatch sinceLastFrame = Stopwatch();
  int? firstFrameT;
  int? positioningStartT;
  int? readySince;
  int? notReadySince;
  int? warmUpStartT;
  int? measureStartT;
  DateTime? measureStartWall;
  // Sentinels must be representable on the web (no 64-bit int shifts).
  static const int _never = -9007199254740991;
  int lastAnalysisT = _never;
  Future<void>? analysisInFlight;
  bool detectionInFlight = false;
  int lastDetectionRequestT = _never;
  int? lastDetectionT;
  List<DetectedFace> faces = const [];
  NormRect? previousBox;
  double pendingMotion = 0;
  final List<WindowAnalysis> measuringWindows = [];
  final List<double> recentBpms = [];
  final List<double> recentUsableBpms = [];
  int lastUiT = _never;
  final List<int> frameTimes = [];
  Set<QualityIssue> lastWindowIssues = const {};
}

final measurementControllerProvider =
    NotifierProvider.autoDispose<MeasurementController, MeasurementViewState>(
  MeasurementController.new,
);

class MeasurementController extends AutoDisposeNotifier<MeasurementViewState> {
  final _log = AppLogger('measurement');
  final _sm = MeasurementStateMachine();
  CameraSource? _camera;
  FaceLocator? _locator;
  StreamSubscription<CameraFrame>? _frameSub;
  Timer? _watchdog;
  _Session? _s;
  int _sessionCounter = 0;
  bool _disposed = false;

  CameraSource? get camera => _camera;

  @override
  MeasurementViewState build() {
    ref.onDispose(() {
      _disposed = true;
      _invalidateSession();
      unawaited(_releaseHardware());
    });
    final platform = ref.read(platformServicesProvider);
    if (!platform.supportsLiveMeasurement) {
      _sm.transition(MeasurementPhase.unsupported);
      return MeasurementViewState(
        phase: MeasurementPhase.unsupported,
        error: UnsupportedPlatformError(platform.unsupportedReason),
      );
    }
    return const MeasurementViewState(phase: MeasurementPhase.idle);
  }

  bool _isCurrent(_Session s) => !_disposed && identical(s, _s);

  void _invalidateSession() {
    _s = null;
    _sessionCounter++;
  }

  bool _go(MeasurementPhase to) {
    if (!_sm.canTransition(to)) {
      _log.warn('rejected transition', {'from': _sm.phase.name, 'to': to.name});
      return false;
    }
    _sm.transition(to);
    if (!_disposed) state = state.copyWith(phase: to);
    _log.info('phase', {'to': to.name});
    return true;
  }

  /// Starts (or restarts) a session. Safe to call from any idle or terminal
  /// phase; ignored while a session is active.
  Future<void> start({String? cameraId}) async {
    if (_sm.phase.isActive) return;
    final platform = ref.read(platformServicesProvider);
    if (!platform.supportsLiveMeasurement) return;

    await _releaseHardware();
    _sm.reset();
    final settings = ref.read(settingsControllerProvider);
    final engine = ref.read(rppgEngineProvider(settings.method));
    final config = ref
        .read(sessionConfigProvider)
        .copyWith(measuringSeconds: settings.measurementSeconds);
    final s = _Session(
      id: ++_sessionCounter,
      method: settings.method,
      algorithm: engine.info,
      config: config,
      bufferCapacity: config.signalBufferCapacity,
    );
    _s = s;
    final selected = cameraId ?? state.selectedCameraId;
    state = MeasurementViewState(
      phase: MeasurementPhase.idle,
      algorithm: engine.info,
      cameras: state.cameras,
      selectedCameraId: selected,
    );

    _go(MeasurementPhase.requestingPermission);
    final cam = platform.createCamera();
    _camera = cam;
    try {
      await cam.open(deviceId: selected);
    } on AppError catch (e) {
      if (!_isCurrent(s)) return;
      await _fail(e);
      return;
    } catch (e) {
      if (!_isCurrent(s)) return;
      await _fail(CameraFailureError(e.runtimeType.toString()));
      return;
    }
    if (!_isCurrent(s)) {
      await cam.close();
      return;
    }

    _go(MeasurementPhase.initializing);
    try {
      await engine.initialize();
      final caps = await engine.getCapabilities();
      if (!caps.available || engine.analyzerMethod == null) {
        throw UnsupportedModelError(caps.unavailableReason);
      }
    } on AppError catch (e) {
      if (!_isCurrent(s)) return;
      await _fail(e);
      return;
    }
    final locator =
        platform.createFaceLocator(ref.read(positioningConfigProvider));
    _locator = locator;
    List<CameraDeviceInfo> cameras = const [];
    if (platform.supportsCameraSelection) {
      try {
        cameras = await cam.listCameras();
      } catch (_) {
        // Camera listing is optional; selection is simply not offered.
      }
    }
    if (!_isCurrent(s)) return;
    state = state.copyWith(faceLocator: locator.info, cameras: cameras);

    _frameSub = cam.frames.listen(
      (f) => _onFrame(s, f),
      onError: (Object e) {
        if (!_isCurrent(s)) return;
        unawaited(
          _fail(
              e is AppError ? e : CameraFailureError(e.runtimeType.toString())),
        );
      },
    );
    s.sinceLastFrame.start();
    _watchdog =
        Timer.periodic(const Duration(seconds: 1), (_) => _checkStall(s));
    _go(MeasurementPhase.positioning);
  }

  Future<void> selectCamera(String id) async {
    state = state.copyWith(selectedCameraId: () => id);
    if (_sm.phase.isActive) {
      await cancel(restart: false);
    }
    await start(cameraId: id);
  }

  /// User cancellation. Stops the camera immediately.
  Future<void> cancel({bool restart = false}) async {
    if (!_sm.phase.isActive) return;
    _invalidateSession();
    _go(MeasurementPhase.cancelled);
    await _releaseHardware();
  }

  /// App went to background / tab hidden: stop the camera, remember to
  /// resume.
  Future<void> onAppPaused() async {
    if (!_sm.phase.isActive) return;
    _invalidateSession();
    _go(MeasurementPhase.interrupted);
    await _releaseHardware();
  }

  Future<void> onAppResumed() async {
    if (_sm.phase == MeasurementPhase.interrupted) await start();
  }

  void _checkStall(_Session s) {
    if (!_isCurrent(s)) return;
    final stall = s.sinceLastFrame.elapsedMilliseconds / 1000;
    if (_sm.phase.needsCamera && stall > s.config.frameStallSeconds) {
      unawaited(_fail(const CameraFailureError('frame stall')));
    }
  }

  Future<void> _fail(AppError e) async {
    final phase = switch (e) {
      PermissionDeniedError() => MeasurementPhase.permissionDenied,
      UnsupportedPlatformError() => MeasurementPhase.unsupported,
      UnsupportedModelError() ||
      ModelUnavailableError() ||
      InferenceFailedError() =>
        MeasurementPhase.inferenceFailure,
      MeasurementTimeoutError() => MeasurementPhase.timedOut,
      _ => MeasurementPhase.cameraFailure,
    };
    _log.warn('session failed', {'kind': e.kind.name});
    _invalidateSession();
    if (!_go(phase) && phase != MeasurementPhase.cameraFailure) {
      _go(MeasurementPhase.cameraFailure);
    }
    if (!_disposed) state = state.copyWith(error: () => e);
    await _releaseHardware();
  }

  Future<void> _releaseHardware() async {
    _watchdog?.cancel();
    _watchdog = null;
    final sub = _frameSub;
    _frameSub = null;
    final cam = _camera;
    _camera = null;
    final loc = _locator;
    _locator = null;
    await sub?.cancel();
    try {
      await cam?.close();
    } catch (e) {
      _log.warn('camera close failed', {'error': e.runtimeType});
    }
    try {
      await loc?.dispose();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------
  // Frame pipeline
  // ---------------------------------------------------------------------

  void _onFrame(_Session s, CameraFrame frame) {
    if (!_isCurrent(s) || !_sm.phase.needsCamera) return;
    try {
      _processFrame(s, frame);
    } catch (e) {
      // Never let a processing bug silently degrade into "low quality":
      // surface it as a processing failure and stop the camera.
      _log.error('frame processing failed', {'error': e.runtimeType});
      if (_isCurrent(s)) {
        unawaited(_fail(InferenceFailedError(e.runtimeType.toString())));
      }
    }
  }

  void _processFrame(_Session s, CameraFrame frame) {
    final t = frame.timestampMicros;
    s.sinceLastFrame
      ..reset()
      ..start();
    s.firstFrameT ??= t;
    s.positioningStartT ??= t;
    _trackFps(s, t);

    if ((t - s.firstFrameT!) / 1e6 > s.config.sessionTimeoutSeconds) {
      unawaited(_fail(const MeasurementTimeoutError('session')));
      return;
    }

    _maybeDetect(s, frame);

    final pc = ref.read(positioningConfigProvider);
    final faceFresh = s.lastDetectionT != null &&
        (t - s.lastDetectionT!) / 1000 <= s.config.detectionStaleMillis;
    final positioning = faceFresh
        ? evaluatePositioning(s.faces, pc)
        : const PositioningStatus(issues: {QualityIssue.noFace});

    RoiStats? stats;
    final face = positioning.face;
    if (face != null) {
      final r = pc.roiInFace;
      stats = extractRoiStats(
        frame,
        face.box.fraction(r.left, r.top, r.right, r.bottom),
      );
    }
    final lighting = stats == null
        ? const <QualityIssue>{}
        : lightingIssues(
            meanLuma: stats.meanLuma,
            skinFraction: stats.skinFraction,
            c: pc,
          );
    final faceOk = positioning.isReady &&
        stats != null &&
        stats.skinPixels >= const RoiExtractionConfig().minSkinPixels;
    final guidance = {...positioning.issues, ...lighting};

    switch (_sm.phase) {
      case MeasurementPhase.positioning:
        _handlePositioning(s, t, faceOk && lighting.isEmpty);
      case MeasurementPhase.warmingUp:
      case MeasurementPhase.measuring:
        _record(s, t, faceOk, stats);
        _handleCollecting(s, t, faceOk);
      default:
        break;
    }
    if (!_isCurrent(s)) return;

    final collecting = _sm.phase == MeasurementPhase.measuring ||
        _sm.phase == MeasurementPhase.warmingUp;
    final shownIssues = {
      ...guidance,
      if (collecting) ...s.lastWindowIssues,
    };
    _emitThrottled(s, t, shownIssues);
  }

  void _trackFps(_Session s, int t) {
    s.frameTimes.add(t);
    while (s.frameTimes.isNotEmpty && t - s.frameTimes.first > 2000000) {
      s.frameTimes.removeAt(0);
    }
  }

  void _maybeDetect(_Session s, CameraFrame frame) {
    final locator = _locator;
    final t = frame.timestampMicros;
    if (locator == null || s.detectionInFlight) return;
    if ((t - s.lastDetectionRequestT) / 1000 <
        s.config.detectionIntervalMillis) {
      return;
    }
    s.detectionInFlight = true;
    s.lastDetectionRequestT = t;
    locator.detect(frame).then((result) {
      if (!_isCurrent(s)) return;
      s.faces = result.faces;
      s.lastDetectionT = t;
      if (result.faces.length == 1) {
        final box = result.faces.single.box;
        final prev = s.previousBox;
        if (prev != null && box.width > 0) {
          final dx = box.centerX - prev.centerX;
          final dy = box.centerY - prev.centerY;
          s.pendingMotion += math.sqrt(dx * dx + dy * dy) / box.width;
        }
        s.previousBox = box;
      } else {
        s.previousBox = null;
      }
    }).catchError((Object e) {
      // A failed detection counts as "no face" for this frame; the
      // positioning timeout bounds how long this can persist.
      _log.warn('face detection failed', {'error': e.runtimeType});
      if (_isCurrent(s)) {
        s.faces = const [];
        s.lastDetectionT = t;
      }
    }).whenComplete(() => s.detectionInFlight = false);
  }

  void _handlePositioning(_Session s, int t, bool ready) {
    if (!ready) {
      s.readySince = null;
      if ((t - s.positioningStartT!) / 1e6 >
          s.config.positioningTimeoutSeconds) {
        unawaited(_fail(const MeasurementTimeoutError('positioning')));
      }
      return;
    }
    s.readySince ??= t;
    if ((t - s.readySince!) / 1e6 >= s.config.positioningStableSeconds) {
      s.buffer.clear();
      s.measuringWindows.clear();
      s.recentBpms.clear();
      s.recentUsableBpms.clear();
      s.lastWindowIssues = const {};
      s.pendingMotion = 0;
      s.warmUpStartT = t;
      s.lastAnalysisT = _Session._never;
      _go(MeasurementPhase.warmingUp);
      state = state.copyWith(
        liveBpm: () => null,
        waveform: () => null,
        progress: 0,
      );
    }
  }

  void _record(_Session s, int t, bool faceOk, RoiStats? stats) {
    if (faceOk && stats != null && stats.meanGreen.isFinite) {
      s.buffer.add(
        RgbSample(
          timestampMicros: t,
          red: stats.meanRed,
          green: stats.meanGreen,
          blue: stats.meanBlue,
          luma: stats.meanLuma,
          faceValid: true,
          motion: s.pendingMotion,
        ),
      );
      s.pendingMotion = 0;
    } else {
      s.buffer.add(RgbSample.invalid(t));
    }
  }

  void _handleCollecting(_Session s, int t, bool faceOk) {
    if (!faceOk) {
      s.notReadySince ??= t;
      if ((t - s.notReadySince!) / 1e6 > s.config.faceLossToleranceSeconds) {
        // Restart positioning; discard the partial signal rather than
        // stitching data from before and after the interruption.
        s.notReadySince = null;
        s.readySince = null;
        s.positioningStartT = t;
        _go(MeasurementPhase.positioning);
        state = state.copyWith(
          liveBpm: () => null,
          progress: 0,
          secondsRemaining: () => null,
        );
        return;
      }
    } else {
      s.notReadySince = null;
    }

    if (_sm.phase == MeasurementPhase.warmingUp &&
        (t - s.warmUpStartT!) / 1e6 >= s.config.warmUpSeconds) {
      s.measureStartT = t;
      s.measureStartWall = DateTime.now().toUtc();
      _go(MeasurementPhase.measuring);
    }

    _maybeAnalyze(s, t);

    if (_sm.phase == MeasurementPhase.measuring) {
      final elapsed = (t - s.measureStartT!) / 1e6;
      if (elapsed >= s.config.measuringSeconds) {
        unawaited(_finish(s));
      }
    }
  }

  void _maybeAnalyze(_Session s, int t) {
    if (s.analysisInFlight != null) return;
    final cfg = ref.read(rppgConfigProvider);
    if ((t - s.lastAnalysisT) / 1e6 < s.config.analysisHopSeconds) return;
    if ((t - s.warmUpStartT!) / 1e6 < cfg.analysisWindowSeconds) return;
    s.lastAnalysisT = t;
    final req = AnalysisRequest(
      samples: s.buffer.snapshotSince(
        t - (cfg.analysisWindowSeconds * 1e6).round(),
      ),
      windowEndMicros: t,
      method: s.method,
      rppgConfig: cfg,
      qualityConfig: ref.read(qualityConfigProvider),
      recentBpms: List.of(s.recentBpms),
    );
    final runner = ref.read(analysisRunnerProvider);
    final sw = Stopwatch()..start();
    s.analysisInFlight = runner(req).then((a) {
      if (!_isCurrent(s)) return;
      _log.debug('window analysed', {'ms': sw.elapsedMilliseconds});
      _onWindow(s, a);
    }).catchError((Object e) {
      _log.error('analysis failed', {'error': e.runtimeType});
      if (_isCurrent(s)) {
        unawaited(_fail(InferenceFailedError(e.runtimeType.toString())));
      }
    }).whenComplete(() => s.analysisInFlight = null);
  }

  void _onWindow(_Session s, WindowAnalysis a) {
    final bpm = a.bpm;
    if (bpm != null) {
      s.recentBpms.add(bpm);
      if (s.recentBpms.length > 10) s.recentBpms.removeAt(0);
    }
    final measureStart = s.measureStartT;
    if (measureStart != null && a.windowEndMicros >= measureStart) {
      s.measuringWindows.add(a);
    }
    final usable = a.quality.isUsable && bpm != null;
    if (usable) {
      s.recentUsableBpms.add(bpm);
      if (s.recentUsableBpms.length > s.config.liveSmoothingWindows) {
        s.recentUsableBpms.removeAt(0);
      }
    }
    s.lastWindowIssues = a.assessment.issues;
    if (_disposed) return;
    state = state.copyWith(
      liveBpm: () => usable ? median(s.recentUsableBpms) : null,
      liveQuality: a.quality,
      waveform: () => a.waveform.isEmpty ? state.waveform : a.waveform,
      waveformRateHz: a.waveformRateHz,
    );
  }

  Future<void> _finish(_Session s) async {
    if (!_go(MeasurementPhase.validating)) return;
    _watchdog?.cancel();
    // Camera is no longer needed: stop streaming before aggregation.
    await _frameSub?.cancel();
    _frameSub = null;
    await s.analysisInFlight;
    if (!_isCurrent(s)) return;
    await _releaseHardware();
    if (!_isCurrent(s)) return;

    final outcome = aggregateMeasurement(
      windows: s.measuringWindows,
      config: ref.read(aggregationConfigProvider),
      algorithm: s.algorithm,
      startedAtUtc: s.measureStartWall ?? DateTime.now().toUtc(),
      durationMilliseconds: s.config.measuringSeconds * 1000,
    );
    state = state.copyWith(outcome: () => outcome, progress: 1);
    switch (outcome) {
      case MeasurementSucceeded():
        _go(MeasurementPhase.completed);
      case MeasurementRejected(:final issues):
        state = state.copyWith(guidance: issues);
        _go(MeasurementPhase.lowSignalQuality);
    }
    _s = null;
  }

  void _emitThrottled(_Session s, int t, Set<QualityIssue> guidance) {
    if ((t - s.lastUiT) / 1000 < s.config.uiUpdateIntervalMillis) return;
    s.lastUiT = t;
    double? fps;
    if (s.frameTimes.length > 2) {
      fps = (s.frameTimes.length - 1) /
          ((s.frameTimes.last - s.frameTimes.first) / 1e6);
    }
    var progress = 0.0;
    int? remaining;
    if (_sm.phase == MeasurementPhase.measuring && s.measureStartT != null) {
      final elapsed = (t - s.measureStartT!) / 1e6;
      progress = (elapsed / s.config.measuringSeconds).clamp(0.0, 1.0);
      remaining = math.max(0, (s.config.measuringSeconds - elapsed).ceil());
    }
    state = state.copyWith(
      guidance: guidance,
      progress: progress,
      measuredFps: () => fps,
      secondsRemaining: () => remaining,
    );
  }
}
