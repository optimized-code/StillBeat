import 'dart:math' as math;
import 'dart:typed_data';

/// Returns the smallest power of two that is >= [n] (minimum 1).
int nextPowerOfTwo(int n) {
  var p = 1;
  while (p < n) {
    p <<= 1;
  }
  return p;
}

/// In-place iterative radix-2 Cooley–Tukey FFT.
///
/// [re] and [im] must have the same power-of-two length.
void fftInPlace(Float64List re, Float64List im) {
  final n = re.length;
  if (n != im.length) {
    throw ArgumentError('re and im must have equal length');
  }
  if (n == 0 || (n & (n - 1)) != 0) {
    throw ArgumentError('FFT length must be a power of two, got $n');
  }

  // Bit-reversal permutation.
  for (var i = 1, j = 0; i < n; i++) {
    var bit = n >> 1;
    for (; (j & bit) != 0; bit >>= 1) {
      j ^= bit;
    }
    j ^= bit;
    if (i < j) {
      final tr = re[i];
      re[i] = re[j];
      re[j] = tr;
      final ti = im[i];
      im[i] = im[j];
      im[j] = ti;
    }
  }

  for (var len = 2; len <= n; len <<= 1) {
    final angle = -2 * math.pi / len;
    final wRe = math.cos(angle);
    final wIm = math.sin(angle);
    final half = len >> 1;
    for (var start = 0; start < n; start += len) {
      var curRe = 1.0;
      var curIm = 0.0;
      for (var k = 0; k < half; k++) {
        final a = start + k;
        final b = a + half;
        final xr = re[b] * curRe - im[b] * curIm;
        final xi = re[b] * curIm + im[b] * curRe;
        re[b] = re[a] - xr;
        im[b] = im[a] - xi;
        re[a] += xr;
        im[a] += xi;
        final nextRe = curRe * wRe - curIm * wIm;
        curIm = curRe * wIm + curIm * wRe;
        curRe = nextRe;
      }
    }
  }
}

/// One-sided power spectrum of a real signal.
class PowerSpectrum {
  const PowerSpectrum({required this.power, required this.binHz});

  /// Power for bins 0..nfft/2 (inclusive).
  final Float64List power;

  /// Frequency spacing between bins in Hz.
  final double binHz;

  double frequencyOf(int bin) => bin * binHz;

  int binOf(double hz) => (hz / binHz).round().clamp(0, power.length - 1);
}

/// Computes a Hann-windowed, zero-padded one-sided power spectrum.
///
/// The mean is removed before windowing so DC leakage does not dominate the
/// low-frequency end of the heart-rate band.
PowerSpectrum hannPowerSpectrum(
  List<double> signal,
  double sampleRateHz, {
  int minFftSize = 4096,
}) {
  final n = signal.length;
  if (n < 2) {
    throw ArgumentError('Signal must contain at least two samples');
  }
  final nfft = nextPowerOfTwo(math.max(n, minFftSize));
  final re = Float64List(nfft);
  final im = Float64List(nfft);

  var mean = 0.0;
  for (final v in signal) {
    mean += v;
  }
  mean /= n;

  for (var i = 0; i < n; i++) {
    final w = 0.5 - 0.5 * math.cos(2 * math.pi * i / (n - 1));
    re[i] = (signal[i] - mean) * w;
  }
  fftInPlace(re, im);

  final bins = nfft ~/ 2 + 1;
  final power = Float64List(bins);
  for (var k = 0; k < bins; k++) {
    power[k] = re[k] * re[k] + im[k] * im[k];
  }
  return PowerSpectrum(power: power, binHz: sampleRateHz / nfft);
}
