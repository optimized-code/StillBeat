import 'package:flutter_test/flutter_test.dart';
import 'package:stillbeat/features/signal_quality/domain/quality_config.dart';
import 'package:stillbeat/features/signal_quality/domain/signal_quality.dart';
import 'package:stillbeat/services/rppg/rppg_config.dart';
import 'package:stillbeat/services/rppg/rppg_sample.dart';
import 'package:stillbeat/services/rppg/window_analyzer.dart';

import '../../helpers/synthetic_signals.dart';

const _cfg = RppgConfig();
const _q = QualityConfig();

WindowAnalysis analyze(
  List<RgbSample> samples, {
  PulseMethod method = PulseMethod.pos,
  List<double> recent = const [],
}) {
  final buf = SignalBuffer(capacity: 5000);
  samples.forEach(buf.add);
  return analyzeWindow(
    AnalysisRequest(
      samples: buf.snapshotSince(0),
      windowEndMicros: buf.last!.timestampMicros,
      method: method,
      rppgConfig: _cfg,
      qualityConfig: _q,
      recentBpms: recent,
    ),
  );
}

void main() {
  test('default configurations are valid', () {
    expect(_cfg.validate(), isEmpty);
    expect(_q.validate(), isEmpty);
  });

  test('config validation reports inconsistent parameters', () {
    const bad = RppgConfig(bandPassHighHz: 20, minFftSize: 1000);
    expect(bad.validate(), hasLength(greaterThanOrEqualTo(2)));
    const badQ = QualityConfig(goodSnrDb: -5, acceptableSnrDb: 0);
    expect(badQ.validate(), isNotEmpty);
  });

  for (final method in PulseMethod.values) {
    group('${method.name} on synthetic traces', () {
      for (final bpm in [48.0, 65.0, 72.0, 95.0, 130.0, 165.0]) {
        test('recovers $bpm BPM within 2 BPM', () {
          final a = analyze(
            syntheticSamples(SyntheticTraceSpec(heartRateBpm: bpm)),
            method: method,
          );
          expect(a.bpm, isNotNull);
          expect(a.bpm!, closeTo(bpm, 2));
          expect(a.quality.isUsable, isTrue, reason: '${a.assessment.issues}');
        });
      }

      test('is robust to illumination drift common to all channels', () {
        final a = analyze(
          syntheticSamples(
            const SyntheticTraceSpec(
              heartRateBpm: 80,
              illuminationDriftAmplitude: 0.05,
              illuminationDriftHz: 0.15,
            ),
          ),
          method: method,
        );
        expect(a.bpm!, closeTo(80, 2));
      });

      test('handles irregular timestamps and dropped frames', () {
        final a = analyze(
          syntheticSamples(
            const SyntheticTraceSpec(
              heartRateBpm: 75,
              frameRateHz: 24,
              timestampJitterFraction: 0.6,
              droppedFrameEvery: 7,
            ),
          ),
          method: method,
        );
        expect(a.bpm!, closeTo(75, 2));
      });
    });
  }

  test('pure noise is not classified as good', () {
    final a = analyze(noiseSamples());
    expect(a.quality, isNot(SignalQuality.good));
  });

  test('waveform is z-scored and limited to the configured duration', () {
    final a = analyze(syntheticSamples(const SyntheticTraceSpec()));
    expect(
      a.waveform.length,
      closeTo(_cfg.waveformSeconds * _cfg.targetSampleRateHz, 1),
    );
    final m = a.waveform.reduce((x, y) => x + y) / a.waveform.length;
    expect(m, closeTo(0, 1e-9));
  });

  test('too little data yields insufficientData and no estimate', () {
    final a = analyze(
      syntheticSamples(const SyntheticTraceSpec(durationSeconds: 2)),
    );
    expect(a.bpm, isNull);
    expect(a.quality, SignalQuality.insufficientData);
    expect(a.waveform, isEmpty);
  });

  test('frames without a face are excluded and flagged', () {
    final valid =
        syntheticSamples(const SyntheticTraceSpec(durationSeconds: 12));
    final invalid = syntheticSamples(
      const SyntheticTraceSpec(durationSeconds: 12, faceValid: false, seed: 3),
      startMicros: 12000000,
    );
    final a = analyze([...valid, ...invalid]);
    expect(a.quality, isNot(SignalQuality.good));
    expect(
      a.assessment.issues,
      anyOf(contains(QualityIssue.noFace),
          contains(QualityIssue.insufficientSamples)),
    );
  });

  test('excessive motion forces poor quality even with a clean signal', () {
    final a = analyze(
      syntheticSamples(const SyntheticTraceSpec(motion: 0.5)),
    );
    expect(a.quality, SignalQuality.poor);
    expect(a.assessment.issues, contains(QualityIssue.excessiveMotion));
  });

  test('dark frames are flagged as low light', () {
    final a = analyze(
      syntheticSamples(const SyntheticTraceSpec(baseRgb: [20, 15, 12])),
    );
    expect(a.assessment.issues, contains(QualityIssue.lowLight));
    expect(a.quality, SignalQuality.poor);
  });

  test('stability uses recent estimates; disagreement downgrades quality', () {
    final samples =
        syntheticSamples(const SyntheticTraceSpec(heartRateBpm: 72));
    final stable = analyze(samples, recent: [71.5, 72.5]);
    expect(stable.quality, SignalQuality.good);
    final unstable = analyze(samples, recent: [100, 130]);
    expect(unstable.quality, SignalQuality.poor);
    expect(unstable.assessment.issues, contains(QualityIssue.unstableEstimate));
  });
}
