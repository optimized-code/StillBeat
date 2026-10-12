import 'dart:math' as math;

import '../../../services/rppg/dsp/stats.dart';
import '../../../services/rppg/rppg_engine.dart';
import '../../../services/rppg/window_analyzer.dart';
import '../../signal_quality/domain/signal_quality.dart';
import 'measurement_result.dart';

class AggregationConfig {
  const AggregationConfig({
    this.minValidWindows = 8,
    this.minValidFraction = 0.5,
    this.maxInterquartileRangeBpm = 8,
    this.goodWindowFractionForGood = 0.6,
  });

  /// Absolute minimum number of usable windows before any value is shown.
  final int minValidWindows;

  /// Usable windows as a fraction of all measuring-phase windows.
  final double minValidFraction;

  /// Maximum IQR of usable per-window estimates.
  final double maxInterquartileRangeBpm;

  /// Fraction of usable windows rated `good` needed for an overall `good`.
  final double goodWindowFractionForGood;

  List<String> validate() => [
        if (minValidWindows < 1) 'minValidWindows must be >= 1',
        if (minValidFraction <= 0 || minValidFraction > 1)
          'minValidFraction must be in (0, 1]',
        if (maxInterquartileRangeBpm <= 0)
          'maxInterquartileRangeBpm must be > 0',
        if (goodWindowFractionForGood <= 0 || goodWindowFractionForGood > 1)
          'goodWindowFractionForGood must be in (0, 1]',
      ];
}

/// Combines the per-window analyses of the measuring phase into a single
/// outcome. Rejects rather than guesses: when quality gates fail, no heart
/// rate is produced.
MeasurementOutcome aggregateMeasurement({
  required List<WindowAnalysis> windows,
  required AggregationConfig config,
  required AlgorithmInfo algorithm,
  required DateTime startedAtUtc,
  required int durationMilliseconds,
}) {
  final usable = [
    for (final w in windows)
      if (w.quality.isUsable && w.bpm != null) w,
  ];
  final total = windows.length;

  MeasurementRejected reject(MeasurementFailureReason reason) {
    final issues = <QualityIssue>{
      for (final w in windows)
        if (!w.quality.isUsable) ...w.assessment.issues,
    };
    return MeasurementRejected(
      reason: reason,
      issues: issues,
      validWindowCount: usable.length,
      totalWindowCount: total,
    );
  }

  if (usable.length < config.minValidWindows ||
      total == 0 ||
      usable.length / total < config.minValidFraction) {
    return reject(_dominantFailure(windows));
  }

  final bpms = [for (final w in usable) w.bpm!]..sort();
  final iqr = _quantile(bpms, 0.75) - _quantile(bpms, 0.25);
  if (iqr > config.maxInterquartileRangeBpm) {
    return reject(MeasurementFailureReason.unstableEstimates);
  }

  final goodCount = usable.where((w) => w.quality == SignalQuality.good).length;
  final overall = goodCount / usable.length >= config.goodWindowFractionForGood
      ? SignalQuality.good
      : SignalQuality.acceptable;

  double? med(double? Function(QualityMetrics m) pick) {
    final v = [
      for (final w in usable)
        if (pick(w.assessment.metrics) case final x? when x.isFinite) x,
    ];
    return v.isEmpty ? null : median(v);
  }

  final metrics = QualityMetrics(
    snrDb: med((m) => m.snrDb),
    peakProminence: med((m) => m.peakProminence),
    faceDetectedRatio: med((m) => m.faceDetectedRatio),
    motionFaceWidthsPerSecond: med((m) => m.motionFaceWidthsPerSecond),
    meanLuma: med((m) => m.meanLuma),
    lumaCoefficientOfVariation: med((m) => m.lumaCoefficientOfVariation),
    effectiveFrameRateHz: med((m) => m.effectiveFrameRateHz),
    maxGapSeconds: med((m) => m.maxGapSeconds),
    stabilityBpm: iqr,
  );

  final last = usable.last;
  return MeasurementSucceeded(
    MeasurementResult(
      heartRateBpm: median(bpms),
      quality: overall,
      metrics: metrics,
      validWindowCount: usable.length,
      totalWindowCount: total,
      interquartileRangeBpm: iqr,
      waveform: last.waveform,
      waveformRateHz: last.waveformRateHz,
      algorithm: algorithm,
      startedAtUtc: startedAtUtc,
      durationMilliseconds: durationMilliseconds,
    ),
  );
}

double _quantile(List<double> sorted, double q) {
  if (sorted.length == 1) return sorted.first;
  final pos = q * (sorted.length - 1);
  final lo = pos.floor();
  final hi = math.min(lo + 1, sorted.length - 1);
  return sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo);
}

MeasurementFailureReason _dominantFailure(List<WindowAnalysis> windows) {
  final counts = <QualityIssue, int>{};
  for (final w in windows) {
    if (w.quality.isUsable) continue;
    for (final i in w.assessment.issues) {
      counts[i] = (counts[i] ?? 0) + 1;
    }
  }
  if (counts.isEmpty) return MeasurementFailureReason.insufficientValidWindows;
  final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  return switch (top) {
    QualityIssue.noFace ||
    QualityIssue.multipleFaces ||
    QualityIssue.faceOffCenter ||
    QualityIssue.faceTooSmall ||
    QualityIssue.faceTooLarge ||
    QualityIssue.notFacingCamera =>
      MeasurementFailureReason.noFace,
    QualityIssue.lowLight ||
    QualityIssue.overexposed ||
    QualityIssue.unevenLighting =>
      MeasurementFailureReason.poorLighting,
    QualityIssue.excessiveMotion => MeasurementFailureReason.excessiveMotion,
    QualityIssue.lowFrameRate ||
    QualityIssue.irregularSampling =>
      MeasurementFailureReason.lowFrameRate,
    QualityIssue.unstableEstimate => MeasurementFailureReason.unstableEstimates,
    QualityIssue.weakSignal ||
    QualityIssue.ambiguousSpectrum =>
      MeasurementFailureReason.weakSignal,
    QualityIssue.insufficientSamples =>
      MeasurementFailureReason.insufficientValidWindows,
  };
}
