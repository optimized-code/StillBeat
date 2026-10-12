import 'dart:math' as math;

import 'dsp/fft.dart';

/// Output of a spectral heart-rate estimate on one analysis window.
class SpectralEstimate {
  const SpectralEstimate({
    required this.bpm,
    required this.snrDb,
    required this.peakProminence,
  });

  /// Peak frequency converted to beats per minute.
  final double bpm;

  /// Ratio (dB) of power near the fundamental and its first harmonic to the
  /// remaining in-band power (after de Haan & Jeanne 2013).
  final double snrDb;

  /// Dominant peak power divided by the strongest competing local peak
  /// outside an exclusion zone. Higher means a less ambiguous spectrum.
  /// Infinite when no competing peak exists.
  final double peakProminence;
}

/// Finds the dominant in-band spectral peak of an already band-passed pulse
/// signal and reports quality descriptors.
///
/// Returns null when the band contains no power (e.g. a flat signal).
SpectralEstimate? estimateHeartRate({
  required List<double> pulse,
  required double sampleRateHz,
  required double minHz,
  required double maxHz,
  required double bandLowHz,
  required double bandHighHz,
  required int minFftSize,
  required double harmonicHalfWidthBpm,
  required double prominenceExclusionBpm,
}) {
  final spectrum =
      hannPowerSpectrum(pulse, sampleRateHz, minFftSize: minFftSize);
  final p = spectrum.power;
  final lo = math.max(1, spectrum.binOf(minHz));
  final hi = math.min(p.length - 2, spectrum.binOf(maxHz));
  if (hi <= lo) return null;

  var peakBin = lo;
  for (var k = lo + 1; k <= hi; k++) {
    if (p[k] > p[peakBin]) peakBin = k;
  }
  if (p[peakBin] <= 0) return null;

  // Parabolic interpolation on log power refines the peak between bins.
  var refinedBin = peakBin.toDouble();
  if (peakBin > 0 && peakBin < p.length - 1) {
    final a = math.log(p[peakBin - 1] + 1e-30);
    final b = math.log(p[peakBin] + 1e-30);
    final c = math.log(p[peakBin + 1] + 1e-30);
    final denom = a - 2 * b + c;
    if (denom != 0) {
      final offset = 0.5 * (a - c) / denom;
      if (offset.abs() <= 0.5) refinedBin += offset;
    }
  }
  final peakHz = refinedBin * spectrum.binHz;
  final bpm = peakHz * 60;

  // SNR: in-band power within ±halfWidth of f0 and 2·f0 vs everything else.
  final halfWidthHz = harmonicHalfWidthBpm / 60;
  final bandLo = math.max(1, spectrum.binOf(bandLowHz));
  final bandHi = math.min(p.length - 1, spectrum.binOf(bandHighHz));
  var signal = 0.0;
  var noise = 0.0;
  for (var k = bandLo; k <= bandHi; k++) {
    final f = spectrum.frequencyOf(k);
    final nearFundamental = (f - peakHz).abs() <= halfWidthHz;
    final nearHarmonic = (f - 2 * peakHz).abs() <= halfWidthHz;
    if (nearFundamental || nearHarmonic) {
      signal += p[k];
    } else {
      noise += p[k];
    }
  }
  final snrDb =
      noise > 0 ? 10 * math.log(signal / noise) / math.ln10 : double.infinity;

  // Prominence: strongest local maximum in the plausible band outside the
  // exclusion zone around the dominant peak.
  final exclusionHz = prominenceExclusionBpm / 60;
  var runnerUp = 0.0;
  for (var k = lo; k <= hi; k++) {
    if ((spectrum.frequencyOf(k) - peakHz).abs() <= exclusionHz) continue;
    final isLocalMax = p[k] >= p[k - 1] && p[k] >= p[k + 1];
    if (isLocalMax && p[k] > runnerUp) runnerUp = p[k];
  }
  final prominence = runnerUp > 0 ? p[peakBin] / runnerUp : double.infinity;

  return SpectralEstimate(
    bpm: bpm,
    snrDb: snrDb,
    peakProminence: prominence,
  );
}
