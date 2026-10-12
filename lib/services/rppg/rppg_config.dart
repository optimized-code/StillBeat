/// Tunable parameters for the rPPG signal pipeline.
///
/// Every number here is an engineering default chosen from the cited
/// algorithm papers and physiological plausibility, not from a calibration
/// study. See docs/technical_decisions.md and docs/validation_protocol.md.
class RppgConfig {
  const RppgConfig({
    this.targetSampleRateHz = 30,
    this.minPlausibleBpm = 40,
    this.maxPlausibleBpm = 180,
    this.bandPassLowHz = 0.6,
    this.bandPassHighHz = 4.0,
    this.analysisWindowSeconds = 10,
    this.algorithmWindowSeconds = 1.6,
    this.minFftSize = 4096,
    this.snrHarmonicHalfWidthBpm = 6,
    this.prominenceExclusionBpm = 12,
    this.waveformSeconds = 8,
  });

  /// Uniform rate that irregular camera samples are resampled to.
  final double targetSampleRateHz;

  /// Plausibility bounds for the spectral peak search. These are a sanity
  /// filter, not evidence that values inside the range are correct.
  final double minPlausibleBpm;
  final double maxPlausibleBpm;

  /// Band-pass edges. Slightly wider than the plausible range so the
  /// filter roll-off does not attenuate peaks at the range boundaries.
  final double bandPassLowHz;
  final double bandPassHighHz;

  /// Sliding window used for each heart-rate estimate. 10 s gives a
  /// spectral resolution of ~6 BPM before zero-padding and contains several
  /// cardiac cycles even at 40 BPM.
  final double analysisWindowSeconds;

  /// POS/CHROM inner window (1.6 s per Wang et al. 2017).
  final double algorithmWindowSeconds;

  /// Minimum zero-padded FFT size (interpolates the spectrum; it does not
  /// add information).
  final int minFftSize;

  /// Half-width around the fundamental and first harmonic counted as
  /// "signal" when computing SNR (after de Haan & Jeanne 2013).
  final double snrHarmonicHalfWidthBpm;

  /// Region around the dominant peak excluded when searching for the
  /// runner-up peak for the prominence ratio.
  final double prominenceExclusionBpm;

  /// Duration of the most recent filtered signal exposed for display.
  final double waveformSeconds;

  double get minPlausibleHz => minPlausibleBpm / 60;
  double get maxPlausibleHz => maxPlausibleBpm / 60;

  /// Returns a list of human-readable configuration problems (empty if OK).
  List<String> validate() {
    final problems = <String>[];
    final nyquist = targetSampleRateHz / 2;
    if (targetSampleRateHz <= 0) problems.add('targetSampleRateHz must be > 0');
    if (minPlausibleBpm <= 0 || minPlausibleBpm >= maxPlausibleBpm) {
      problems.add('minPlausibleBpm must be > 0 and < maxPlausibleBpm');
    }
    if (bandPassLowHz <= 0 || bandPassLowHz >= bandPassHighHz) {
      problems.add('bandPassLowHz must be > 0 and < bandPassHighHz');
    }
    if (bandPassHighHz >= nyquist) {
      problems.add('bandPassHighHz must be below Nyquist ($nyquist Hz)');
    }
    if (bandPassLowHz > minPlausibleHz || bandPassHighHz < maxPlausibleHz) {
      problems.add('band-pass must cover the plausible heart-rate range');
    }
    if (analysisWindowSeconds * minPlausibleHz < 2) {
      problems.add(
        'analysisWindowSeconds must hold at least two cycles at the minimum rate',
      );
    }
    if (algorithmWindowSeconds <= 0 ||
        algorithmWindowSeconds >= analysisWindowSeconds) {
      problems.add('algorithmWindowSeconds must be in (0, analysisWindow)');
    }
    if (minFftSize < 64 || (minFftSize & (minFftSize - 1)) != 0) {
      problems.add('minFftSize must be a power of two >= 64');
    }
    if (waveformSeconds <= 0 || waveformSeconds > analysisWindowSeconds) {
      problems.add('waveformSeconds must be in (0, analysisWindowSeconds]');
    }
    return problems;
  }
}
