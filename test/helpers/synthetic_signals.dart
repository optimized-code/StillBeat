import 'dart:math' as math;

import 'package:stillbeat/services/rppg/rppg_sample.dart';

/// Deterministic synthetic skin-colour traces for testing the DSP chain.
///
/// These signals verify that the implementation behaves as designed. They
/// are NOT evidence of physiological accuracy on real video.
class SyntheticTraceSpec {
  const SyntheticTraceSpec({
    this.heartRateBpm = 72,
    this.durationSeconds = 20,
    this.frameRateHz = 30,
    this.timestampJitterFraction = 0.15,
    this.pulseAmplitude = 0.004,
    this.noiseAmplitude = 0.0015,
    this.illuminationDriftAmplitude = 0.03,
    this.illuminationDriftHz = 0.05,
    this.motion = 0.0,
    this.droppedFrameEvery = 0,
    this.seed = 42,
    this.baseRgb = const [175.0, 125.0, 105.0],
    this.faceValid = true,
  });

  final double heartRateBpm;
  final double durationSeconds;
  final double frameRateHz;
  final double timestampJitterFraction;
  final double pulseAmplitude;
  final double noiseAmplitude;
  final double illuminationDriftAmplitude;
  final double illuminationDriftHz;
  final double motion;
  final int droppedFrameEvery;
  final int seed;
  final List<double> baseRgb;
  final bool faceValid;
}

/// Approximate blood-volume-pulse colour signature on skin (relative
/// modulation strength per channel, normalised to green). Green carries the
/// strongest pulsatile component; the exact numbers are illustrative.
const _pulseSignature = [0.33, 1.0, 0.55];

List<RgbSample> syntheticSamples(SyntheticTraceSpec spec,
    {int startMicros = 0}) {
  final rng = math.Random(spec.seed);
  final out = <RgbSample>[];
  final dt = 1 / spec.frameRateHz;
  final f = spec.heartRateBpm / 60;
  final n = (spec.durationSeconds * spec.frameRateHz).round();
  for (var i = 0; i < n; i++) {
    if (spec.droppedFrameEvery > 0 &&
        i % spec.droppedFrameEvery == 0 &&
        i > 0) {
      continue;
    }
    final jitter = (rng.nextDouble() - 0.5) * spec.timestampJitterFraction * dt;
    final t = i * dt + jitter;
    final pulse = math.sin(2 * math.pi * f * t) +
        0.3 * math.sin(4 * math.pi * f * t + 0.6);
    final illum = 1 +
        spec.illuminationDriftAmplitude *
            math.sin(2 * math.pi * spec.illuminationDriftHz * t);
    final rgb = <double>[];
    for (var c = 0; c < 3; c++) {
      final noise = (rng.nextDouble() - 0.5) * 2 * spec.noiseAmplitude;
      final v = spec.baseRgb[c] *
          illum *
          (1 + spec.pulseAmplitude * _pulseSignature[c] * pulse + noise);
      rgb.add(v);
    }
    final luma = 0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2];
    out.add(
      spec.faceValid
          ? RgbSample(
              timestampMicros: startMicros + (t * 1e6).round(),
              red: rgb[0],
              green: rgb[1],
              blue: rgb[2],
              luma: luma,
              faceValid: true,
              motion: spec.motion * dt,
            )
          : RgbSample.invalid(startMicros + (t * 1e6).round()),
    );
  }
  return out;
}

/// Pure noise with no periodic component.
List<RgbSample> noiseSamples({
  double durationSeconds = 20,
  double frameRateHz = 30,
  int seed = 7,
  double amplitude = 0.01,
}) {
  final rng = math.Random(seed);
  final out = <RgbSample>[];
  final n = (durationSeconds * frameRateHz).round();
  for (var i = 0; i < n; i++) {
    final t = i / frameRateHz;
    final rgb = [
      for (final base in const [175.0, 125.0, 105.0])
        base * (1 + (rng.nextDouble() - 0.5) * 2 * amplitude),
    ];
    out.add(
      RgbSample(
        timestampMicros: (t * 1e6).round(),
        red: rgb[0],
        green: rgb[1],
        blue: rgb[2],
        luma: 0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2],
        faceValid: true,
        motion: 0,
      ),
    );
  }
  return out;
}
