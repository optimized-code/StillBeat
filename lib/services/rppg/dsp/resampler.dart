import 'dart:typed_data';

/// Result of resampling irregular timestamped samples onto a uniform grid.
class UniformSeries {
  const UniformSeries({
    required this.sampleRateHz,
    required this.startMicros,
    required this.channels,
  });

  final double sampleRateHz;
  final int startMicros;

  /// One list per channel, all of equal length.
  final List<Float64List> channels;

  int get length => channels.isEmpty ? 0 : channels.first.length;
}

/// Linearly interpolates irregular samples onto a uniform time grid.
///
/// Camera frame timestamps are never assumed to be evenly spaced: requested
/// FPS rarely equals delivered FPS, and frames are dropped under load. Every
/// downstream algorithm (POS window length, filters, FFT bin spacing) depends
/// on a known sampling rate, so resampling happens before any of them.
///
/// [timestampsMicros] must be strictly increasing.
UniformSeries resampleLinear({
  required List<int> timestampsMicros,
  required List<List<double>> channels,
  required double targetRateHz,
}) {
  final n = timestampsMicros.length;
  if (n < 2) {
    throw ArgumentError('Need at least two samples to resample');
  }
  for (final c in channels) {
    if (c.length != n) {
      throw ArgumentError('Channel length does not match timestamps');
    }
  }
  for (var i = 1; i < n; i++) {
    if (timestampsMicros[i] <= timestampsMicros[i - 1]) {
      throw ArgumentError('Timestamps must be strictly increasing');
    }
  }

  final start = timestampsMicros.first;
  final spanSeconds = (timestampsMicros.last - start) / 1e6;
  final outLen = (spanSeconds * targetRateHz).floor() + 1;
  final stepMicros = 1e6 / targetRateHz;
  final out = [for (var _ in channels) Float64List(outLen)];

  var j = 0;
  for (var k = 0; k < outLen; k++) {
    final t = start + k * stepMicros;
    while (j < n - 2 && timestampsMicros[j + 1] < t) {
      j++;
    }
    final t0 = timestampsMicros[j].toDouble();
    final t1 = timestampsMicros[j + 1].toDouble();
    final frac = ((t - t0) / (t1 - t0)).clamp(0.0, 1.0);
    for (var c = 0; c < channels.length; c++) {
      final v0 = channels[c][j];
      final v1 = channels[c][j + 1];
      out[c][k] = v0 + (v1 - v0) * frac;
    }
  }
  return UniformSeries(
    sampleRateHz: targetRateHz,
    startMicros: start,
    channels: out,
  );
}

/// Sampling statistics computed from raw timestamps.
class SamplingStats {
  const SamplingStats({
    required this.effectiveRateHz,
    required this.maxGapSeconds,
    required this.spanSeconds,
    required this.count,
  });

  final double effectiveRateHz;
  final double maxGapSeconds;
  final double spanSeconds;
  final int count;

  static SamplingStats fromTimestamps(List<int> timestampsMicros) {
    final n = timestampsMicros.length;
    if (n < 2) {
      return SamplingStats(
        effectiveRateHz: 0,
        maxGapSeconds: double.infinity,
        spanSeconds: 0,
        count: n,
      );
    }
    var maxGap = 0;
    for (var i = 1; i < n; i++) {
      final gap = timestampsMicros[i] - timestampsMicros[i - 1];
      if (gap > maxGap) maxGap = gap;
    }
    final span = (timestampsMicros.last - timestampsMicros.first) / 1e6;
    return SamplingStats(
      effectiveRateHz: span > 0 ? (n - 1) / span : 0,
      maxGapSeconds: maxGap / 1e6,
      spanSeconds: span,
      count: n,
    );
  }
}
