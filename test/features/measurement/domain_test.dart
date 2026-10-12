import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stillbeat/core/errors/app_error.dart';
import 'package:stillbeat/core/logging/app_logger.dart';
import 'package:stillbeat/features/measurement/domain/measurement_phase.dart';
import 'package:stillbeat/features/measurement/domain/measurement_result.dart';
import 'package:stillbeat/features/measurement/domain/positioning.dart';
import 'package:stillbeat/features/measurement/domain/result_aggregator.dart';
import 'package:stillbeat/features/measurement/domain/session_config.dart';
import 'package:stillbeat/features/signal_quality/domain/quality_assessor.dart';
import 'package:stillbeat/features/signal_quality/domain/quality_config.dart';
import 'package:stillbeat/features/signal_quality/domain/signal_quality.dart';
import 'package:stillbeat/services/camera/camera_frame.dart';
import 'package:stillbeat/services/face_detection/face_locator.dart';
import 'package:stillbeat/services/rppg/rppg_engine.dart';
import 'package:stillbeat/services/rppg/rppg_sample.dart';
import 'package:stillbeat/services/rppg/window_analyzer.dart';

WindowAnalysis window(double? bpm, SignalQuality q,
        {Set<QualityIssue>? issues}) =>
    WindowAnalysis(
      windowEndMicros: 0,
      bpm: bpm,
      assessment: QualityAssessment(
        quality: q,
        issues: issues ?? const {},
        metrics:
            const QualityMetrics(snrDb: 4, peakProminence: 3, stabilityBpm: 1),
      ),
      waveform: Float64List.fromList([0, 1, 0, -1]),
      waveformRateHz: 30,
    );

MeasurementOutcome aggregate(List<WindowAnalysis> w) => aggregateMeasurement(
      windows: w,
      config: const AggregationConfig(),
      algorithm: AlgorithmInfo.pos,
      startedAtUtc: DateTime.utc(2026),
      durationMilliseconds: 30000,
    );

void main() {
  group('MeasurementStateMachine', () {
    test('happy path transitions are allowed', () {
      final sm = MeasurementStateMachine();
      for (final p in [
        MeasurementPhase.requestingPermission,
        MeasurementPhase.initializing,
        MeasurementPhase.positioning,
        MeasurementPhase.warmingUp,
        MeasurementPhase.measuring,
        MeasurementPhase.validating,
        MeasurementPhase.completed,
      ]) {
        sm.transition(p);
      }
      expect(sm.phase, MeasurementPhase.completed);
    });

    test('invalid transitions throw and leave state unchanged', () {
      final sm = MeasurementStateMachine();
      expect(
        () => sm.transition(MeasurementPhase.measuring),
        throwsA(isA<InvalidTransitionError>()),
      );
      expect(sm.phase, MeasurementPhase.idle);
      sm
        ..transition(MeasurementPhase.requestingPermission)
        ..transition(MeasurementPhase.initializing)
        ..transition(MeasurementPhase.positioning);
      expect(sm.canTransition(MeasurementPhase.completed), isFalse);
      expect(sm.canTransition(MeasurementPhase.validating), isFalse);
    });

    test('terminal phases can only restart', () {
      final sm = MeasurementStateMachine(MeasurementPhase.cancelled);
      expect(sm.canTransition(MeasurementPhase.measuring), isFalse);
      expect(sm.canTransition(MeasurementPhase.requestingPermission), isTrue);
      expect(sm.canTransition(MeasurementPhase.idle), isTrue);
    });

    test('every active phase can be cancelled or interrupted', () {
      for (final p in MeasurementPhase.values.where((p) => p.isActive)) {
        final sm = MeasurementStateMachine(p);
        expect(sm.canTransition(MeasurementPhase.cancelled), isTrue,
            reason: p.name);
        expect(sm.canTransition(MeasurementPhase.interrupted), isTrue,
            reason: p.name);
      }
    });

    test('phase helpers', () {
      expect(MeasurementPhase.measuring.needsCamera, isTrue);
      expect(MeasurementPhase.validating.needsCamera, isFalse);
      expect(MeasurementPhase.completed.isTerminal, isTrue);
      expect(MeasurementPhase.idle.isTerminal, isFalse);
    });
  });

  group('aggregateMeasurement', () {
    test('median of usable windows; quality good when most are good', () {
      final outcome = aggregate([
        for (var i = 0; i < 10; i++) window(70.0 + i % 3, SignalQuality.good),
        window(150, SignalQuality.poor),
      ]);
      expect(outcome, isA<MeasurementSucceeded>());
      final r = (outcome as MeasurementSucceeded).result;
      expect(r.heartRateBpm, 71);
      expect(r.validWindowCount, 10);
      expect(r.totalWindowCount, 11);
      expect(r.quality, SignalQuality.good);
    });

    test('rejects when too few usable windows', () {
      final outcome = aggregate([
        for (var i = 0; i < 5; i++) window(70, SignalQuality.good),
        for (var i = 0; i < 10; i++)
          window(70, SignalQuality.poor,
              issues: {QualityIssue.excessiveMotion}),
      ]);
      expect(outcome, isA<MeasurementRejected>());
      expect(
        (outcome as MeasurementRejected).reason,
        MeasurementFailureReason.excessiveMotion,
      );
    });

    test('rejects when usable windows disagree', () {
      final outcome = aggregate([
        for (var i = 0; i < 12; i++)
          window(i.isEven ? 60 : 110, SignalQuality.acceptable),
      ]);
      expect(outcome, isA<MeasurementRejected>());
      expect(
        (outcome as MeasurementRejected).reason,
        MeasurementFailureReason.unstableEstimates,
      );
    });

    test('empty input is rejected, never fabricated', () {
      expect(aggregate(const []), isA<MeasurementRejected>());
    });

    test('aggregation config validation', () {
      expect(const AggregationConfig().validate(), isEmpty);
      expect(
          const AggregationConfig(minValidFraction: 2).validate(), isNotEmpty);
      expect(const SessionConfig().validate(), isEmpty);
      expect(const SessionConfig(measuringSeconds: 3).validate(), isNotEmpty);
    });
  });

  group('positioning', () {
    const c = PositioningConfig();
    test('ready when one centred, sized, frontal face', () {
      final s = evaluatePositioning(
        const [DetectedFace(box: NormRect(0.3, 0.2, 0.7, 0.75), yawDegrees: 5)],
        c,
      );
      expect(s.isReady, isTrue);
    });

    test('flags yaw, size, centring and multiplicity', () {
      expect(
        evaluatePositioning(
          const [
            DetectedFace(box: NormRect(0.3, 0.2, 0.7, 0.75), yawDegrees: 40)
          ],
          c,
        ).issues,
        contains(QualityIssue.notFacingCamera),
      );
      expect(
        evaluatePositioning(
                const [DetectedFace(box: NormRect(0.0, 0.0, 0.95, 0.95))], c)
            .issues,
        contains(QualityIssue.faceTooLarge),
      );
      expect(evaluatePositioning(const [], c).issues, {QualityIssue.noFace});
      final multi = evaluatePositioning(
        const [
          DetectedFace(box: NormRect(0.3, 0.2, 0.7, 0.75)),
          DetectedFace(box: NormRect(0.3, 0.2, 0.7, 0.75)),
        ],
        c,
      );
      expect(multi.issues, {QualityIssue.multipleFaces});
      expect(multi.face, isNull);
    });

    test('lighting issues', () {
      expect(lightingIssues(meanLuma: 10, skinFraction: 0.9, c: c),
          {QualityIssue.lowLight});
      expect(lightingIssues(meanLuma: 250, skinFraction: 0.9, c: c),
          {QualityIssue.overexposed});
      expect(lightingIssues(meanLuma: double.nan, skinFraction: 0, c: c),
          {QualityIssue.lowLight});
      expect(lightingIssues(meanLuma: 120, skinFraction: 0.9, c: c), isEmpty);
    });
  });

  group('quality assessor', () {
    WindowObservations obs(
            {double snr = 5, double prom = 3, double? stab = 1}) =>
        WindowObservations(
          windowCoverage: 1,
          faceDetectedRatio: 1,
          meanLuma: 120,
          lumaCoefficientOfVariation: 0.01,
          motionFaceWidthsPerSecond: 0,
          effectiveFrameRateHz: 30,
          maxGapSeconds: 0.05,
          snrDb: snr,
          peakProminence: prom,
          stabilityBpm: stab,
          hasStabilityHistory: stab != null,
        );
    const c = QualityConfig();

    test('tiers', () {
      expect(assessWindowQuality(obs(), c).quality, SignalQuality.good);
      expect(assessWindowQuality(obs(snr: 1), c).quality,
          SignalQuality.acceptable);
      expect(assessWindowQuality(obs(snr: -3), c).quality, SignalQuality.poor);
      expect(assessWindowQuality(obs(prom: 1.1), c).issues,
          contains(QualityIssue.ambiguousSpectrum));
      // Without history, best possible tier is acceptable.
      expect(assessWindowQuality(obs(stab: null), c).quality,
          SignalQuality.acceptable);
    });

    test('irregular sampling and low frame rate are hard failures', () {
      const o = WindowObservations(
        windowCoverage: 1,
        faceDetectedRatio: 1,
        meanLuma: 120,
        lumaCoefficientOfVariation: 0.01,
        motionFaceWidthsPerSecond: 0,
        effectiveFrameRateHz: 5,
        maxGapSeconds: 2,
        snrDb: 10,
        peakProminence: 10,
        stabilityBpm: 0,
        hasStabilityHistory: true,
      );
      final a = assessWindowQuality(o, c);
      expect(a.quality, SignalQuality.poor);
      expect(
          a.issues,
          containsAll(
              [QualityIssue.lowFrameRate, QualityIssue.irregularSampling]));
    });

    test('signal quality enum helpers', () {
      expect(SignalQuality.fromName('good'), SignalQuality.good);
      expect(SignalQuality.fromName('bogus'), SignalQuality.unavailable);
      expect(SignalQuality.good.rank, greaterThan(SignalQuality.poor.rank));
    });
  });

  group('signal buffer', () {
    test('is bounded and drops non-advancing timestamps', () {
      final b = SignalBuffer(capacity: 3);
      for (var i = 0; i < 5; i++) {
        b.add(RgbSample.invalid(i));
      }
      expect(b.length, 3);
      expect(b.add(const RgbSample.invalid(2)), isFalse);
      expect(b.snapshotSince(3).length, 2);
    });
  });

  group('engines', () {
    test('neural engine is explicitly unavailable', () async {
      const e = UnavailableNeuralRppgEngine();
      final caps = await e.getCapabilities();
      expect(caps.available, isFalse);
      expect(e.info.kind, AlgorithmKind.neuralNetwork);
      expect(e.initialize, throwsA(isA<ModelUnavailableError>()));
      expect(e.analyzerMethod, isNull);
    });

    test('signal-processing engine reports itself as non-neural', () async {
      final e = SignalProcessingRppgEngine(PulseMethod.pos);
      expect(e.info.kind, AlgorithmKind.unsupervisedSignalProcessing);
      expect((await e.getCapabilities()).supportsRespiratoryRate, isFalse);
      final out = await e.process(
        RppgInput(
          red: Float64List.fromList(List.filled(90, 100)),
          green: Float64List.fromList(List.filled(90, 100)),
          blue: Float64List.fromList(List.filled(90, 100)),
          sampleRateHz: 30,
        ),
      );
      expect(out.pulse, hasLength(90));
    });
  });

  group('logger', () {
    test('redacts sensitive keys and non-scalar values', () {
      final r = AppLogger.redact({
        'bpm': 72,
        'heartRate': 70,
        'frameCount': 3,
        'ms': 12,
        'phase': 'measuring',
        'deviceId': 'abc',
        'payload': [1, 2, 3],
      });
      expect(r['bpm'], '<redacted>');
      expect(r['heartRate'], '<redacted>');
      expect(r['frameCount'], '<redacted>');
      expect(r['deviceId'], '<redacted>');
      expect(r['ms'], 12);
      expect(r['phase'], 'measuring');
      expect(r['payload'], isNot(isA<List<dynamic>>()));
    });

    test('emits through the sink override', () {
      final lines = <String>[];
      AppLogger.sinkOverride = lines.add;
      addTearDown(() => AppLogger.sinkOverride = null);
      AppLogger('t').warn('hello', {'bpm': 99});
      expect(lines.single, contains('hello'));
      expect(lines.single, isNot(contains('99')));
    });
  });
}
