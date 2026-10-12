import 'dart:typed_data';

import '../../../services/rppg/rppg_engine.dart';
import '../../signal_quality/domain/signal_quality.dart';

/// A validated heart-rate estimate produced by a completed session.
/// Only constructed when quality gates pass.
class MeasurementResult {
  const MeasurementResult({
    required this.heartRateBpm,
    required this.quality,
    required this.metrics,
    required this.validWindowCount,
    required this.totalWindowCount,
    required this.interquartileRangeBpm,
    required this.waveform,
    required this.waveformRateHz,
    required this.algorithm,
    required this.startedAtUtc,
    required this.durationMilliseconds,
  });

  final double heartRateBpm;
  final SignalQuality quality;
  final QualityMetrics metrics;

  /// Number of sliding windows that passed quality gates, out of all windows
  /// analysed during the measuring phase.
  final int validWindowCount;
  final int totalWindowCount;

  /// Spread of per-window estimates (IQR, BPM). Describes agreement between
  /// windows; it is not a confidence interval against a reference device.
  final double interquartileRangeBpm;

  /// Z-scored band-pass-filtered pulse signal from the last valid window.
  final Float64List waveform;
  final double waveformRateHz;

  final AlgorithmInfo algorithm;
  final DateTime startedAtUtc;
  final int durationMilliseconds;

  double get validWindowFraction =>
      totalWindowCount == 0 ? 0 : validWindowCount / totalWindowCount;
}

enum MeasurementFailureReason {
  insufficientValidWindows,
  unstableEstimates,
  noFace,
  poorLighting,
  excessiveMotion,
  lowFrameRate,
  weakSignal,
}

sealed class MeasurementOutcome {
  const MeasurementOutcome();
}

class MeasurementSucceeded extends MeasurementOutcome {
  const MeasurementSucceeded(this.result);
  final MeasurementResult result;
}

class MeasurementRejected extends MeasurementOutcome {
  const MeasurementRejected({
    required this.reason,
    required this.issues,
    required this.validWindowCount,
    required this.totalWindowCount,
  });

  final MeasurementFailureReason reason;
  final Set<QualityIssue> issues;
  final int validWindowCount;
  final int totalWindowCount;
}
