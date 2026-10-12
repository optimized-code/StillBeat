import 'dart:math' as math;
import 'dart:typed_data';

import '../../features/signal_quality/domain/quality_assessor.dart';
import '../../features/signal_quality/domain/quality_config.dart';
import '../../features/signal_quality/domain/signal_quality.dart';
import 'algorithms/chrom.dart';
import 'algorithms/pos.dart';
import 'dsp/filters.dart';
import 'dsp/resampler.dart';
import 'dsp/stats.dart';
import 'rppg_config.dart';
import 'rppg_sample.dart';
import 'spectral_estimator.dart';

/// Unsupervised pulse-extraction methods implemented in this app.
enum PulseMethod { pos, chrom }

class AnalysisRequest {
  const AnalysisRequest({
    required this.samples,
    required this.windowEndMicros,
    required this.method,
    required this.rppgConfig,
    required this.qualityConfig,
    this.recentBpms = const [],
  });

  final SampleSnapshot samples;
  final int windowEndMicros;
  final PulseMethod method;
  final RppgConfig rppgConfig;
  final QualityConfig qualityConfig;

  /// Heart-rate estimates of the immediately preceding windows, oldest
  /// first, used for the stability check.
  final List<double> recentBpms;
}

/// Result of analysing one sliding window.
class WindowAnalysis {
  const WindowAnalysis({
    required this.windowEndMicros,
    required this.bpm,
    required this.assessment,
    required this.waveform,
    required this.waveformRateHz,
  });

  final int windowEndMicros;

  /// Spectral peak in BPM, or null if no estimate could be formed. A
  /// non-null value may still be unusable; always check [assessment].
  final double? bpm;

  final QualityAssessment assessment;

  /// Band-pass-filtered pulse signal, z-score normalised, most recent
  /// [RppgConfig.waveformSeconds]. Derived from camera data only.
  final Float64List waveform;
  final double waveformRateHz;

  SignalQuality get quality => assessment.quality;
}

/// Full per-window pipeline:
/// samples → validity filtering → resampling → POS/CHROM → detrend →
/// zero-phase band-pass → spectral peak → quality assessment.
///
/// Top-level and side-effect free so it can run via `compute`/isolates.
WindowAnalysis analyzeWindow(AnalysisRequest req) {
  final cfg = req.rppgConfig;
  final s = req.samples;
  final windowStart =
      req.windowEndMicros - (cfg.analysisWindowSeconds * 1e6).round();

  final validT = <int>[];
  final r = <double>[];
  final g = <double>[];
  final b = <double>[];
  final luma = <double>[];
  var total = 0;
  var motionSum = 0.0;
  for (var i = 0; i < s.length; i++) {
    final t = s.timestampsMicros[i];
    if (t < windowStart || t > req.windowEndMicros) continue;
    total++;
    final ok = s.faceValid[i] == 1 &&
        s.red[i].isFinite &&
        s.green[i].isFinite &&
        s.blue[i].isFinite;
    if (!ok) continue;
    if (validT.isNotEmpty && t <= validT.last) continue;
    validT.add(t);
    r.add(s.red[i]);
    g.add(s.green[i]);
    b.add(s.blue[i]);
    luma.add(s.luma[i]);
    motionSum += s.motion[i];
  }

  final sampling = SamplingStats.fromTimestamps(validT);
  final coverage = sampling.spanSeconds / cfg.analysisWindowSeconds;
  final faceRatio = total == 0 ? 0.0 : validT.length / total;
  final meanLuma = luma.isEmpty ? 0.0 : mean(luma);
  final lumaCv =
      luma.isEmpty || meanLuma == 0 ? 0.0 : standardDeviation(luma) / meanLuma;
  final motionRate =
      sampling.spanSeconds > 0 ? motionSum / sampling.spanSeconds : 0.0;

  // The algorithms need at least two inner windows of data after resampling.
  const minValidSamples = 8;
  if (validT.length < minValidSamples ||
      sampling.spanSeconds < 2 * cfg.algorithmWindowSeconds) {
    return WindowAnalysis(
      windowEndMicros: req.windowEndMicros,
      bpm: null,
      assessment: assessWindowQuality(
        WindowObservations(
          windowCoverage: coverage,
          faceDetectedRatio: faceRatio,
          meanLuma: meanLuma,
          lumaCoefficientOfVariation: lumaCv,
          motionFaceWidthsPerSecond: motionRate,
          effectiveFrameRateHz: sampling.effectiveRateHz,
          maxGapSeconds: sampling.maxGapSeconds,
        ),
        req.qualityConfig,
      ),
      waveform: Float64List(0),
      waveformRateHz: cfg.targetSampleRateHz,
    );
  }

  final uniform = resampleLinear(
    timestampsMicros: validT,
    channels: [r, g, b],
    targetRateHz: cfg.targetSampleRateHz,
  );
  final fs = uniform.sampleRateHz;
  final raw = switch (req.method) {
    PulseMethod.pos => posPulse(
        red: uniform.channels[0],
        green: uniform.channels[1],
        blue: uniform.channels[2],
        sampleRateHz: fs,
        windowSeconds: cfg.algorithmWindowSeconds,
      ),
    PulseMethod.chrom => chromPulse(
        red: uniform.channels[0],
        green: uniform.channels[1],
        blue: uniform.channels[2],
        sampleRateHz: fs,
        bandLowHz: cfg.bandPassLowHz,
        bandHighHz: cfg.bandPassHighHz,
        windowSeconds: cfg.algorithmWindowSeconds,
      ),
  };

  final filtered = ZeroPhaseBandPass(
    lowHz: cfg.bandPassLowHz,
    highHz: cfg.bandPassHighHz,
    sampleRateHz: fs,
  ).apply(detrendLinear(raw));

  final est = estimateHeartRate(
    pulse: filtered,
    sampleRateHz: fs,
    minHz: cfg.minPlausibleHz,
    maxHz: cfg.maxPlausibleHz,
    bandLowHz: cfg.bandPassLowHz,
    bandHighHz: cfg.bandPassHighHz,
    minFftSize: cfg.minFftSize,
    harmonicHalfWidthBpm: cfg.snrHarmonicHalfWidthBpm,
    prominenceExclusionBpm: cfg.prominenceExclusionBpm,
  );

  double? stability;
  final needed = req.qualityConfig.stabilityHistory - 1;
  final hasHistory = est != null && req.recentBpms.length >= needed;
  if (hasHistory) {
    final recent = [
      ...req.recentBpms.sublist(req.recentBpms.length - needed),
      est.bpm,
    ];
    stability = recent.reduce(math.max) - recent.reduce(math.min);
  }

  const edgeToleranceBpm = 1.0;
  final atEdge = est != null &&
      (est.bpm - cfg.minPlausibleBpm < edgeToleranceBpm ||
          cfg.maxPlausibleBpm - est.bpm < edgeToleranceBpm);

  final assessment = assessWindowQuality(
    WindowObservations(
      windowCoverage: coverage,
      faceDetectedRatio: faceRatio,
      meanLuma: meanLuma,
      lumaCoefficientOfVariation: lumaCv,
      motionFaceWidthsPerSecond: motionRate,
      effectiveFrameRateHz: sampling.effectiveRateHz,
      maxGapSeconds: sampling.maxGapSeconds,
      snrDb: est?.snrDb,
      peakProminence: est?.peakProminence,
      peakAtBandEdge: atEdge,
      stabilityBpm: stability,
      hasStabilityHistory: hasHistory,
    ),
    req.qualityConfig,
  );

  final waveLen = math.min(
    filtered.length,
    (cfg.waveformSeconds * fs).round(),
  );
  final waveform = zScore(
    Float64List.sublistView(filtered, filtered.length - waveLen),
  );

  return WindowAnalysis(
    windowEndMicros: req.windowEndMicros,
    bpm: est?.bpm,
    assessment: assessment,
    waveform: waveform,
    waveformRateHz: fs,
  );
}
