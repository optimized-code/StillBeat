/// Timing rules for a measurement session. Durations are measured on the
/// camera frame clock, so they are deterministic under test.
class SessionConfig {
  const SessionConfig({
    this.measuringSeconds = 30,
    this.positioningStableSeconds = 1.0,
    this.warmUpSeconds = 5,
    this.faceLossToleranceSeconds = 2.0,
    this.positioningTimeoutSeconds = 60,
    this.sessionTimeoutSeconds = 180,
    this.frameStallSeconds = 5,
    this.detectionIntervalMillis = 200,
    this.detectionStaleMillis = 1000,
    this.analysisHopSeconds = 1.0,
    this.uiUpdateIntervalMillis = 100,
    this.liveSmoothingWindows = 3,
    this.signalBufferCapacity = 1200,
  });

  /// Length of the measuring phase whose windows form the result.
  final int measuringSeconds;

  /// Face must be correctly positioned this long before warm-up begins.
  final double positioningStableSeconds;

  /// Samples are buffered but not reported while filters settle.
  final double warmUpSeconds;

  /// A brief loss of face is tolerated (marked as invalid samples); a
  /// longer one restarts positioning so stale data is never mixed in.
  final double faceLossToleranceSeconds;
  final double positioningTimeoutSeconds;
  final double sessionTimeoutSeconds;

  /// No frames for this long while streaming is treated as camera failure.
  final double frameStallSeconds;

  /// Face detection rate limit. Detection is far costlier than ROI
  /// sampling, so it runs at ~5 Hz and its box is reused in between.
  final int detectionIntervalMillis;

  /// A face box older than this is considered lost.
  final int detectionStaleMillis;

  /// Interval between sliding-window analyses.
  final double analysisHopSeconds;

  final int uiUpdateIntervalMillis;

  /// Live display uses the median of this many recent usable windows.
  final int liveSmoothingWindows;

  /// Bounded sample buffer (~40 s at 30 fps).
  final int signalBufferCapacity;

  SessionConfig copyWith({int? measuringSeconds}) => SessionConfig(
        measuringSeconds: measuringSeconds ?? this.measuringSeconds,
        positioningStableSeconds: positioningStableSeconds,
        warmUpSeconds: warmUpSeconds,
        faceLossToleranceSeconds: faceLossToleranceSeconds,
        positioningTimeoutSeconds: positioningTimeoutSeconds,
        sessionTimeoutSeconds: sessionTimeoutSeconds,
        frameStallSeconds: frameStallSeconds,
        detectionIntervalMillis: detectionIntervalMillis,
        detectionStaleMillis: detectionStaleMillis,
        analysisHopSeconds: analysisHopSeconds,
        uiUpdateIntervalMillis: uiUpdateIntervalMillis,
        liveSmoothingWindows: liveSmoothingWindows,
        signalBufferCapacity: signalBufferCapacity,
      );

  List<String> validate() => [
        if (measuringSeconds < 10) 'measuringSeconds must be >= 10',
        if (warmUpSeconds < 0) 'warmUpSeconds must be >= 0',
        if (detectionStaleMillis < detectionIntervalMillis)
          'detectionStaleMillis must be >= detectionIntervalMillis',
        if (analysisHopSeconds <= 0) 'analysisHopSeconds must be > 0',
        if (signalBufferCapacity < 100) 'signalBufferCapacity too small',
      ];
}
