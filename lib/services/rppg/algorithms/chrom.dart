import 'dart:math' as math;
import 'dart:typed_data';

import '../dsp/filters.dart';
import '../dsp/stats.dart';

/// Chrominance-based (CHROM) pulse extraction.
///
/// Reference: G. de Haan, V. Jeanne, "Robust Pulse Rate From
/// Chrominance-Based rPPG", IEEE Transactions on Biomedical Engineering
/// 60(10):2878–2886, 2013. doi:10.1109/TBME.2013.2266196.
///
/// Original implementation following the paper's structure:
///  1. Normalise each channel by a local (moving) mean so slow illumination
///     drift does not leak into the chrominance signals.
///  2. Xs = 3R − 2G, Ys = 1.5R + G − 1.5B.
///  3. Band-pass Xs and Ys over the whole analysis window (filtering short
///     1.6 s segments in isolation is numerically poor).
///  4. In overlapping Hann-weighted windows, S = Xf − α·Yf with
///     α = σ(Xf)/σ(Yf), then overlap-add.
Float64List chromPulse({
  required List<double> red,
  required List<double> green,
  required List<double> blue,
  required double sampleRateHz,
  required double bandLowHz,
  required double bandHighHz,
  double windowSeconds = 1.6,
}) {
  final n = red.length;
  if (green.length != n || blue.length != n) {
    throw ArgumentError('Channel lengths differ');
  }
  final l = math.max(4, (windowSeconds * sampleRateHz).ceil());
  final out = Float64List(n);
  if (n < l * 2) return out;

  final mr = movingAverage(red, l);
  final mg = movingAverage(green, l);
  final mb = movingAverage(blue, l);
  final xs = Float64List(n);
  final ys = Float64List(n);
  for (var i = 0; i < n; i++) {
    if (mr[i] <= 0 || mg[i] <= 0 || mb[i] <= 0) continue;
    final rn = red[i] / mr[i];
    final gn = green[i] / mg[i];
    final bn = blue[i] / mb[i];
    xs[i] = 3 * rn - 2 * gn;
    ys[i] = 1.5 * rn + gn - 1.5 * bn;
  }

  final bp = ZeroPhaseBandPass(
    lowHz: bandLowHz,
    highHz: bandHighHz,
    sampleRateHz: sampleRateHz,
  );
  final xf = bp.apply(xs);
  final yf = bp.apply(ys);

  final hop = l ~/ 2;
  final hann = Float64List(l);
  for (var i = 0; i < l; i++) {
    hann[i] = 0.5 - 0.5 * math.cos(2 * math.pi * i / (l - 1));
  }
  for (var start = 0; start + l <= n; start += hop) {
    final xw = Float64List.sublistView(xf, start, start + l);
    final yw = Float64List.sublistView(yf, start, start + l);
    final sdY = standardDeviation(yw);
    final alpha = sdY > 0 ? standardDeviation(xw) / sdY : 0.0;
    var sMean = 0.0;
    for (var i = 0; i < l; i++) {
      sMean += xw[i] - alpha * yw[i];
    }
    sMean /= l;
    for (var i = 0; i < l; i++) {
      out[start + i] += (xw[i] - alpha * yw[i] - sMean) * hann[i];
    }
  }
  return out;
}
