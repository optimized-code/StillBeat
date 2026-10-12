/// Overall signal-quality classification for an analysis window or a
/// completed measurement.
///
/// This is a rule-based heuristic (see [QualityConfig]); it is NOT a
/// calibrated probability that the heart-rate value is correct.
enum SignalQuality {
  insufficientData,
  poor,
  acceptable,
  good,
  unavailable;

  bool get isUsable => this == acceptable || this == good;

  /// Ordering used when aggregating (higher is better).
  int get rank => switch (this) {
        unavailable => 0,
        insufficientData => 1,
        poor => 2,
        acceptable => 3,
        good => 4,
      };

  static SignalQuality fromName(String name) => SignalQuality.values
      .firstWhere((q) => q.name == name, orElse: () => unavailable);
}

/// Specific, user-actionable reasons that lowered quality.
enum QualityIssue {
  noFace,
  multipleFaces,
  faceTooSmall,
  faceTooLarge,
  faceOffCenter,
  notFacingCamera,
  lowLight,
  overexposed,
  unevenLighting,
  excessiveMotion,
  lowFrameRate,
  irregularSampling,
  insufficientSamples,
  weakSignal,
  ambiguousSpectrum,
  unstableEstimate,
}

/// Numeric descriptors behind a [SignalQuality] decision. All are aggregate
/// values; none can reconstruct an image of the user.
class QualityMetrics {
  const QualityMetrics({
    this.snrDb,
    this.peakProminence,
    this.faceDetectedRatio,
    this.motionFaceWidthsPerSecond,
    this.meanLuma,
    this.lumaCoefficientOfVariation,
    this.effectiveFrameRateHz,
    this.maxGapSeconds,
    this.stabilityBpm,
  });

  final double? snrDb;
  final double? peakProminence;
  final double? faceDetectedRatio;
  final double? motionFaceWidthsPerSecond;
  final double? meanLuma;
  final double? lumaCoefficientOfVariation;
  final double? effectiveFrameRateHz;
  final double? maxGapSeconds;

  /// Spread (max − min, BPM) of recent consecutive window estimates.
  final double? stabilityBpm;

  Map<String, Object?> toJson() => {
        'snrDb': _finite(snrDb),
        'peakProminence': _finite(peakProminence),
        'faceDetectedRatio': _finite(faceDetectedRatio),
        'motionFaceWidthsPerSecond': _finite(motionFaceWidthsPerSecond),
        'meanLuma': _finite(meanLuma),
        'lumaCoefficientOfVariation': _finite(lumaCoefficientOfVariation),
        'effectiveFrameRateHz': _finite(effectiveFrameRateHz),
        'maxGapSeconds': _finite(maxGapSeconds),
        'stabilityBpm': _finite(stabilityBpm),
      };

  factory QualityMetrics.fromJson(Map<String, Object?> json) => QualityMetrics(
        snrDb: _num(json['snrDb']),
        peakProminence: _num(json['peakProminence']),
        faceDetectedRatio: _num(json['faceDetectedRatio']),
        motionFaceWidthsPerSecond: _num(json['motionFaceWidthsPerSecond']),
        meanLuma: _num(json['meanLuma']),
        lumaCoefficientOfVariation: _num(json['lumaCoefficientOfVariation']),
        effectiveFrameRateHz: _num(json['effectiveFrameRateHz']),
        maxGapSeconds: _num(json['maxGapSeconds']),
        stabilityBpm: _num(json['stabilityBpm']),
      );

  static double? _finite(double? v) =>
      v == null || v.isNaN || v.isInfinite ? null : v;

  static double? _num(Object? v) => v is num ? v.toDouble() : null;
}

class QualityAssessment {
  const QualityAssessment({
    required this.quality,
    required this.issues,
    required this.metrics,
  });

  final SignalQuality quality;
  final Set<QualityIssue> issues;
  final QualityMetrics metrics;
}
