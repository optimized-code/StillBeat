import 'dart:math' as math;
import 'dart:typed_data';

double mean(List<double> x) {
  if (x.isEmpty) return double.nan;
  var s = 0.0;
  for (final v in x) {
    s += v;
  }
  return s / x.length;
}

/// Population standard deviation.
double standardDeviation(List<double> x) {
  if (x.isEmpty) return double.nan;
  final m = mean(x);
  var s = 0.0;
  for (final v in x) {
    final d = v - m;
    s += d * d;
  }
  return math.sqrt(s / x.length);
}

double median(List<double> x) {
  if (x.isEmpty) return double.nan;
  final sorted = List<double>.of(x)..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}

/// Median absolute deviation from the median (unscaled).
double medianAbsoluteDeviation(List<double> x) {
  if (x.isEmpty) return double.nan;
  final m = median(x);
  return median([for (final v in x) (v - m).abs()]);
}

/// Removes the least-squares linear trend from [x].
Float64List detrendLinear(List<double> x) {
  final n = x.length;
  final out = Float64List(n);
  if (n < 2) {
    if (n == 1) out[0] = 0;
    return out;
  }
  final tMean = (n - 1) / 2;
  final xMean = mean(x);
  var num = 0.0;
  var den = 0.0;
  for (var i = 0; i < n; i++) {
    final dt = i - tMean;
    num += dt * (x[i] - xMean);
    den += dt * dt;
  }
  final slope = den == 0 ? 0.0 : num / den;
  for (var i = 0; i < n; i++) {
    out[i] = x[i] - (xMean + slope * (i - tMean));
  }
  return out;
}

/// Z-score normalisation. Returns zeros when the signal is flat.
Float64List zScore(List<double> x) {
  final out = Float64List(x.length);
  if (x.isEmpty) return out;
  final m = mean(x);
  final sd = standardDeviation(x);
  if (sd == 0 || sd.isNaN) return out;
  for (var i = 0; i < x.length; i++) {
    out[i] = (x[i] - m) / sd;
  }
  return out;
}
