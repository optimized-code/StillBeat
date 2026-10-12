import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stillbeat/services/rppg/dsp/fft.dart';
import 'package:stillbeat/services/rppg/dsp/filters.dart';
import 'package:stillbeat/services/rppg/dsp/resampler.dart';
import 'package:stillbeat/services/rppg/dsp/stats.dart';

List<double> sine(double hz, double fs, int n, {double amp = 1}) =>
    [for (var i = 0; i < n; i++) amp * math.sin(2 * math.pi * hz * i / fs)];

double rms(List<double> x) =>
    math.sqrt(x.fold<double>(0, (a, v) => a + v * v) / x.length);

void main() {
  group('FFT', () {
    test('matches naive DFT on a small random input', () {
      final rng = math.Random(1);
      const n = 16;
      final x = [for (var i = 0; i < n; i++) rng.nextDouble() - 0.5];
      final re = Float64List.fromList(x);
      final im = Float64List(n);
      fftInPlace(re, im);
      for (var k = 0; k < n; k++) {
        var sr = 0.0, si = 0.0;
        for (var t = 0; t < n; t++) {
          final a = -2 * math.pi * k * t / n;
          sr += x[t] * math.cos(a);
          si += x[t] * math.sin(a);
        }
        expect(re[k], closeTo(sr, 1e-9));
        expect(im[k], closeTo(si, 1e-9));
      }
    });

    test('rejects non power-of-two lengths', () {
      expect(
        () => fftInPlace(Float64List(12), Float64List(12)),
        throwsArgumentError,
      );
    });

    test('power spectrum peak lands on the input frequency', () {
      const fs = 30.0;
      final s = sine(1.25, fs, 300);
      final ps = hannPowerSpectrum(s, fs);
      var peak = 1;
      for (var k = 1; k < ps.power.length; k++) {
        if (ps.power[k] > ps.power[peak]) peak = k;
      }
      expect(ps.frequencyOf(peak), closeTo(1.25, ps.binHz));
    });

    test('nextPowerOfTwo', () {
      expect(nextPowerOfTwo(1), 1);
      expect(nextPowerOfTwo(5), 8);
      expect(nextPowerOfTwo(4096), 4096);
    });
  });

  group('ZeroPhaseBandPass', () {
    const fs = 30.0;
    final bp = ZeroPhaseBandPass(lowHz: 0.6, highHz: 4.0, sampleRateHz: fs);

    test('passes an in-band tone nearly unchanged', () {
      final x = sine(1.2, fs, 600);
      final y = bp.apply(x);
      // Ignore edges where reflection padding is an approximation.
      final mid = y.sublist(100, 500);
      expect(rms(mid) / rms(x.sublist(100, 500)), closeTo(1, 0.1));
    });

    test('strongly attenuates out-of-band tones', () {
      final low = bp.apply(sine(0.1, fs, 600));
      final high = bp.apply(sine(10, fs, 600));
      expect(rms(low.sublist(100, 500)), lessThan(0.1));
      expect(rms(high.sublist(100, 500)), lessThan(0.1));
    });

    test('is zero phase (no time shift of an in-band tone)', () {
      final x = sine(1.5, fs, 600);
      final y = bp.apply(x);
      var dot = 0.0;
      for (var i = 100; i < 500; i++) {
        dot += x[i] * y[i];
      }
      final corr =
          dot / (rms(x.sublist(100, 500)) * rms(y.sublist(100, 500)) * 400);
      expect(corr, greaterThan(0.98));
    });

    test('rejects invalid cutoffs', () {
      expect(
        () => ZeroPhaseBandPass(lowHz: 2, highHz: 1, sampleRateHz: fs),
        throwsArgumentError,
      );
      expect(
        () => ZeroPhaseBandPass(lowHz: 0.5, highHz: 20, sampleRateHz: fs),
        throwsArgumentError,
      );
    });

    test('handles very short inputs without throwing', () {
      expect(bp.apply(const []), isEmpty);
      expect(bp.apply(const [1.0, 2.0]).length, 2);
    });
  });

  group('resampleLinear', () {
    test('reconstructs a linear ramp exactly from irregular timestamps', () {
      final t = [0, 30000, 70000, 100000, 140000, 200000];
      final v = [for (final ti in t) ti / 1000.0];
      final out = resampleLinear(
        timestampsMicros: t,
        channels: [v],
        targetRateHz: 50,
      );
      expect(out.length, 11);
      for (var k = 0; k < out.length; k++) {
        expect(out.channels[0][k], closeTo(k * 20.0, 1e-9));
      }
    });

    test('rejects non-increasing timestamps', () {
      expect(
        () => resampleLinear(
          timestampsMicros: [0, 10, 10],
          channels: [
            [1, 2, 3],
          ],
          targetRateHz: 30,
        ),
        throwsArgumentError,
      );
    });

    test('rejects mismatched channel lengths', () {
      expect(
        () => resampleLinear(
          timestampsMicros: [0, 10, 20],
          channels: [
            [1, 2],
          ],
          targetRateHz: 30,
        ),
        throwsArgumentError,
      );
    });
  });

  group('SamplingStats', () {
    test('estimates effective rate and largest gap', () {
      final t = [for (var i = 0; i < 31; i++) i * 40000]..removeAt(10);
      final s = SamplingStats.fromTimestamps(t);
      expect(s.spanSeconds, closeTo(1.2, 1e-9));
      expect(s.maxGapSeconds, closeTo(0.08, 1e-9));
      expect(s.effectiveRateHz, closeTo(29 / 1.2, 1e-9));
    });

    test('degenerate input reports zero rate and infinite gap', () {
      final s = SamplingStats.fromTimestamps([5]);
      expect(s.effectiveRateHz, 0);
      expect(s.maxGapSeconds, double.infinity);
    });
  });

  group('stats', () {
    test('median, MAD, detrend, zScore', () {
      expect(median([3, 1, 2]), 2);
      expect(median([4, 1, 2, 3]), 2.5);
      expect(medianAbsoluteDeviation([1, 2, 3, 4, 100]), 1);
      final d = detrendLinear([for (var i = 0; i < 10; i++) 2.0 * i + 5]);
      for (final v in d) {
        expect(v, closeTo(0, 1e-9));
      }
      expect(zScore([5, 5, 5]), everyElement(0));
      final z = zScore([1, 2, 3]);
      expect(mean(z), closeTo(0, 1e-12));
      expect(standardDeviation(z), closeTo(1, 1e-12));
    });

    test('empty inputs return NaN rather than throwing', () {
      expect(mean(const []).isNaN, isTrue);
      expect(median(const []).isNaN, isTrue);
    });
  });
}
