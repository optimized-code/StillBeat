import 'quality_config.dart';
import 'signal_quality.dart';

/// Inputs describing one analysis window, gathered before classification.
class WindowObservations {
  const WindowObservations({
    required this.windowCoverage,
    required this.faceDetectedRatio,
    required this.meanLuma,
    required this.lumaCoefficientOfVariation,
    required this.motionFaceWidthsPerSecond,
    required this.effectiveFrameRateHz,
    required this.maxGapSeconds,
    this.snrDb,
    this.peakProminence,
    this.peakAtBandEdge = false,
    this.stabilityBpm,
    this.hasStabilityHistory = false,
  });

  final double windowCoverage;
  final double faceDetectedRatio;
  final double meanLuma;
  final double lumaCoefficientOfVariation;
  final double motionFaceWidthsPerSecond;
  final double effectiveFrameRateHz;
  final double maxGapSeconds;
  final double? snrDb;
  final double? peakProminence;
  final bool peakAtBandEdge;
  final double? stabilityBpm;
  final bool hasStabilityHistory;
}

/// Rule-based classifier. Pure and deterministic so it can be unit tested
/// and executed inside a background isolate.
QualityAssessment assessWindowQuality(
  WindowObservations o,
  QualityConfig c,
) {
  final metrics = QualityMetrics(
    snrDb: o.snrDb,
    peakProminence: o.peakProminence,
    faceDetectedRatio: o.faceDetectedRatio,
    motionFaceWidthsPerSecond: o.motionFaceWidthsPerSecond,
    meanLuma: o.meanLuma,
    lumaCoefficientOfVariation: o.lumaCoefficientOfVariation,
    effectiveFrameRateHz: o.effectiveFrameRateHz,
    maxGapSeconds: o.maxGapSeconds,
    stabilityBpm: o.stabilityBpm,
  );

  if (o.windowCoverage < c.minWindowCoverage) {
    return QualityAssessment(
      quality: SignalQuality.insufficientData,
      issues: {QualityIssue.insufficientSamples},
      metrics: metrics,
    );
  }

  // Acquisition problems: any one of these makes the window unusable no
  // matter how clean the spectrum looks, because a periodic artefact (e.g.
  // rhythmic motion or flicker) can produce a convincing peak.
  final hard = <QualityIssue>{};
  if (o.faceDetectedRatio < c.minFaceDetectedRatio) {
    hard.add(QualityIssue.noFace);
  }
  if (o.meanLuma < c.minMeanLuma) hard.add(QualityIssue.lowLight);
  if (o.meanLuma > c.maxMeanLuma) hard.add(QualityIssue.overexposed);
  if (o.lumaCoefficientOfVariation > c.maxLumaCoefficientOfVariation) {
    hard.add(QualityIssue.unevenLighting);
  }
  if (o.motionFaceWidthsPerSecond > c.maxMotionFaceWidthsPerSecond) {
    hard.add(QualityIssue.excessiveMotion);
  }
  if (o.effectiveFrameRateHz < c.minEffectiveFrameRateHz) {
    hard.add(QualityIssue.lowFrameRate);
  }
  if (o.maxGapSeconds > c.maxGapSeconds) {
    hard.add(QualityIssue.irregularSampling);
  }

  final snr = o.snrDb;
  final prominence = o.peakProminence;
  if (snr == null || prominence == null) {
    return QualityAssessment(
      quality: SignalQuality.poor,
      issues: {...hard, QualityIssue.weakSignal},
      metrics: metrics,
    );
  }

  final soft = <QualityIssue>{};
  if (o.peakAtBandEdge) soft.add(QualityIssue.ambiguousSpectrum);

  final stability = o.stabilityBpm;
  final stableGood = o.hasStabilityHistory &&
      stability != null &&
      stability <= c.goodStabilityBpm;
  final stableAcceptable = !o.hasStabilityHistory ||
      (stability != null && stability <= c.acceptableStabilityBpm);

  final SignalQuality signalTier;
  if (snr >= c.goodSnrDb &&
      prominence >= c.goodPeakProminence &&
      stableGood &&
      !o.peakAtBandEdge) {
    signalTier = SignalQuality.good;
  } else if (snr >= c.acceptableSnrDb &&
      prominence >= c.acceptablePeakProminence &&
      stableAcceptable &&
      !o.peakAtBandEdge) {
    signalTier = SignalQuality.acceptable;
  } else {
    signalTier = SignalQuality.poor;
    if (snr < c.acceptableSnrDb) soft.add(QualityIssue.weakSignal);
    if (prominence < c.acceptablePeakProminence) {
      soft.add(QualityIssue.ambiguousSpectrum);
    }
    if (!stableAcceptable) soft.add(QualityIssue.unstableEstimate);
  }

  return QualityAssessment(
    quality: hard.isEmpty ? signalTier : SignalQuality.poor,
    issues: {...hard, ...soft},
    metrics: metrics,
  );
}
