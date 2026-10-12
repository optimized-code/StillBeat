import 'dart:math' as math;
import 'dart:typed_data';

import '../dsp/stats.dart';

/// Plane-Orthogonal-to-Skin (POS) pulse extraction.
///
/// Reference: W. Wang, A. C. den Brinker, S. Stuijk, G. de Haan,
/// "Algorithmic Principles of Remote PPG", IEEE Transactions on Biomedical
/// Engineering 64(7):1479–1491, 2017. doi:10.1109/TBME.2016.2609282.
///
/// This is an original implementation of Algorithm 1 in the paper:
///  1. For every sliding window of length l (1.6 s in the paper, chosen to
///     span roughly one cardiac cycle at typical resting rates), temporally
///     normalise each colour channel by its window mean.
///  2. Project onto the plane orthogonal to the skin tone using
///     P = [[0, 1, -1], [-2, 1, 1]].
///  3. Alpha-tune: h = S1 + (σ(S1)/σ(S2))·S2.
///  4. Overlap-add the zero-mean h into the output.
///
/// Input channels must be uniformly sampled at [sampleRateHz].
Float64List posPulse({
  required List<double> red,
  required List<double> green,
  required List<double> blue,
  required double sampleRateHz,
  double windowSeconds = 1.6,
}) {
  final n = red.length;
  if (green.length != n || blue.length != n) {
    throw ArgumentError('Channel lengths differ');
  }
  final l = math.max(2, (windowSeconds * sampleRateHz).ceil());
  final h = Float64List(n);
  if (n < l) return h;

  final s1 = Float64List(l);
  final s2 = Float64List(l);
  for (var end = l - 1; end < n; end++) {
    final start = end - l + 1;
    var mr = 0.0, mg = 0.0, mb = 0.0;
    for (var i = start; i <= end; i++) {
      mr += red[i];
      mg += green[i];
      mb += blue[i];
    }
    mr /= l;
    mg /= l;
    mb /= l;
    if (mr <= 0 || mg <= 0 || mb <= 0) continue;

    for (var i = 0; i < l; i++) {
      final rn = red[start + i] / mr;
      final gn = green[start + i] / mg;
      final bn = blue[start + i] / mb;
      s1[i] = gn - bn;
      s2[i] = -2 * rn + gn + bn;
    }
    final sd2 = standardDeviation(s2);
    final alpha = sd2 > 0 ? standardDeviation(s1) / sd2 : 0.0;

    var hMean = 0.0;
    for (var i = 0; i < l; i++) {
      hMean += s1[i] + alpha * s2[i];
    }
    hMean /= l;
    for (var i = 0; i < l; i++) {
      h[start + i] += s1[i] + alpha * s2[i] - hMean;
    }
  }
  return h;
}
