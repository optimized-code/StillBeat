import 'dart:math' as math;
import 'dart:typed_data';

/// Second-order IIR section (direct form I), normalised so a0 == 1.
class Biquad {
  const Biquad(this.b0, this.b1, this.b2, this.a1, this.a2);

  /// 2nd-order Butterworth low-pass (RBJ cookbook, Q = 1/sqrt(2)).
  factory Biquad.butterworthLowPass(double cutoffHz, double sampleRateHz) {
    _checkCutoff(cutoffHz, sampleRateHz);
    final w0 = 2 * math.pi * cutoffHz / sampleRateHz;
    final cosW = math.cos(w0);
    final alpha = math.sin(w0) / (2 * _butterworthQ);
    final a0 = 1 + alpha;
    return Biquad(
      (1 - cosW) / 2 / a0,
      (1 - cosW) / a0,
      (1 - cosW) / 2 / a0,
      -2 * cosW / a0,
      (1 - alpha) / a0,
    );
  }

  /// 2nd-order Butterworth high-pass (RBJ cookbook, Q = 1/sqrt(2)).
  factory Biquad.butterworthHighPass(double cutoffHz, double sampleRateHz) {
    _checkCutoff(cutoffHz, sampleRateHz);
    final w0 = 2 * math.pi * cutoffHz / sampleRateHz;
    final cosW = math.cos(w0);
    final alpha = math.sin(w0) / (2 * _butterworthQ);
    final a0 = 1 + alpha;
    return Biquad(
      (1 + cosW) / 2 / a0,
      -(1 + cosW) / a0,
      (1 + cosW) / 2 / a0,
      -2 * cosW / a0,
      (1 - alpha) / a0,
    );
  }

  static const double _butterworthQ = 0.7071067811865476;

  static void _checkCutoff(double cutoffHz, double sampleRateHz) {
    if (cutoffHz <= 0 || cutoffHz >= sampleRateHz / 2) {
      throw ArgumentError(
        'Cutoff $cutoffHz Hz must lie in (0, Nyquist=${sampleRateHz / 2})',
      );
    }
  }

  final double b0, b1, b2, a1, a2;

  Float64List apply(List<double> x) {
    final y = Float64List(x.length);
    var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0;
    for (var i = 0; i < x.length; i++) {
      final xi = x[i];
      final yi = b0 * xi + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
      y[i] = yi;
      x2 = x1;
      x1 = xi;
      y2 = y1;
      y1 = yi;
    }
    return y;
  }
}

/// Zero-phase band-pass filter built from cascaded Butterworth biquads
/// applied forward and backward (equivalent in spirit to SciPy's `filtfilt`).
///
/// Zero phase matters because the filtered signal is also rendered as the
/// pulse waveform; a causal filter would shift it in time.
class ZeroPhaseBandPass {
  ZeroPhaseBandPass({
    required this.lowHz,
    required this.highHz,
    required this.sampleRateHz,
    this.sectionsPerEdge = 1,
  }) : _sections = [
          for (var i = 0; i < sectionsPerEdge; i++)
            Biquad.butterworthHighPass(lowHz, sampleRateHz),
          for (var i = 0; i < sectionsPerEdge; i++)
            Biquad.butterworthLowPass(highHz, sampleRateHz),
        ] {
    if (lowHz >= highHz) {
      throw ArgumentError('lowHz must be below highHz');
    }
  }

  final double lowHz;
  final double highHz;
  final double sampleRateHz;
  final int sectionsPerEdge;
  final List<Biquad> _sections;

  /// Filters [x]. The signal is reflection-padded at both ends to reduce
  /// start-up transients, then the padding is removed.
  Float64List apply(List<double> x) {
    if (x.isEmpty) return Float64List(0);
    final pad = math.min(x.length - 1, (sampleRateHz / lowHz).ceil());
    final padded = _reflectPad(x, pad);

    var y = Float64List.fromList(padded);
    for (final s in _sections) {
      y = s.apply(y);
    }
    y = _reverse(y);
    for (final s in _sections) {
      y = s.apply(y);
    }
    y = _reverse(y);
    return Float64List.sublistView(y, pad, pad + x.length);
  }

  static List<double> _reflectPad(List<double> x, int pad) {
    if (pad <= 0) return List<double>.of(x);
    final n = x.length;
    final out = List<double>.filled(n + 2 * pad, 0);
    // Odd reflection (as used by filtfilt) keeps the signal continuous in
    // both value and slope at the boundaries.
    for (var i = 0; i < pad; i++) {
      out[pad - 1 - i] = 2 * x[0] - x[i + 1];
      out[pad + n + i] = 2 * x[n - 1] - x[n - 2 - i];
    }
    for (var i = 0; i < n; i++) {
      out[pad + i] = x[i];
    }
    return out;
  }

  static Float64List _reverse(Float64List x) {
    final n = x.length;
    final out = Float64List(n);
    for (var i = 0; i < n; i++) {
      out[i] = x[n - 1 - i];
    }
    return out;
  }
}

/// Centred moving average with edge shrinkage. Used for local-mean
/// normalisation in CHROM.
Float64List movingAverage(List<double> x, int window) {
  final n = x.length;
  final out = Float64List(n);
  if (n == 0) return out;
  final half = math.max(0, window ~/ 2);
  final prefix = Float64List(n + 1);
  for (var i = 0; i < n; i++) {
    prefix[i + 1] = prefix[i] + x[i];
  }
  for (var i = 0; i < n; i++) {
    final lo = math.max(0, i - half);
    final hi = math.min(n - 1, i + half);
    out[i] = (prefix[hi + 1] - prefix[lo]) / (hi - lo + 1);
  }
  return out;
}
