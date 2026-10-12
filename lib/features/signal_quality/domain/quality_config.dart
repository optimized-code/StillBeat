/// Thresholds for the rule-based signal-quality assessment.
///
/// These are initial engineering heuristics. They must be re-tuned against
/// reference data collected under docs/validation_protocol.md before any
/// accuracy claim is made.
class QualityConfig {
  const QualityConfig({
    this.minWindowCoverage = 0.8,
    this.minFaceDetectedRatio = 0.85,
    this.minMeanLuma = 40,
    this.maxMeanLuma = 230,
    this.maxLumaCoefficientOfVariation = 0.08,
    this.maxMotionFaceWidthsPerSecond = 0.15,
    this.minEffectiveFrameRateHz = 10,
    this.maxGapSeconds = 0.5,
    this.goodSnrDb = 3,
    this.acceptableSnrDb = 0,
    this.goodPeakProminence = 2.0,
    this.acceptablePeakProminence = 1.3,
    this.goodStabilityBpm = 5,
    this.acceptableStabilityBpm = 10,
    this.stabilityHistory = 3,
  });

  /// Fraction of the analysis window that must be covered by valid samples.
  final double minWindowCoverage;

  final double minFaceDetectedRatio;

  /// Mean ROI luma (0–255) outside which lighting is flagged.
  final double minMeanLuma;
  final double maxMeanLuma;

  /// Relative ROI brightness variation above which illumination is
  /// considered unstable. The cardiac pulse itself modulates skin
  /// brightness by well under 1%, so 8% indicates an external change.
  final double maxLumaCoefficientOfVariation;

  /// ROI centre displacement, in face widths per second.
  final double maxMotionFaceWidthsPerSecond;

  final double minEffectiveFrameRateHz;
  final double maxGapSeconds;

  final double goodSnrDb;
  final double acceptableSnrDb;
  final double goodPeakProminence;
  final double acceptablePeakProminence;
  final double goodStabilityBpm;
  final double acceptableStabilityBpm;

  /// Number of consecutive window estimates (including the current one)
  /// used to compute stability.
  final int stabilityHistory;

  List<String> validate() {
    final p = <String>[];
    if (minWindowCoverage <= 0 || minWindowCoverage > 1) {
      p.add('minWindowCoverage must be in (0, 1]');
    }
    if (minFaceDetectedRatio < 0 || minFaceDetectedRatio > 1) {
      p.add('minFaceDetectedRatio must be in [0, 1]');
    }
    if (minMeanLuma >= maxMeanLuma) p.add('minMeanLuma must be < maxMeanLuma');
    if (goodSnrDb < acceptableSnrDb) p.add('goodSnrDb must be >= acceptable');
    if (goodPeakProminence < acceptablePeakProminence) {
      p.add('goodPeakProminence must be >= acceptable');
    }
    if (goodStabilityBpm > acceptableStabilityBpm) {
      p.add('goodStabilityBpm must be <= acceptable');
    }
    if (stabilityHistory < 2) p.add('stabilityHistory must be >= 2');
    return p;
  }
}
