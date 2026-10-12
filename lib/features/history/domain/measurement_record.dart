import '../../signal_quality/domain/signal_quality.dart';

/// Persisted summary of a completed measurement.
///
/// Deliberately excludes images, video, raw colour traces and device
/// identifiers. The waveform is not persisted either: it is a display aid
/// and storing it would retain more physiological data than needed.
class MeasurementRecord {
  const MeasurementRecord({
    required this.id,
    required this.timestampUtc,
    required this.durationMilliseconds,
    required this.heartRateBpm,
    required this.signalQuality,
    required this.qualityMetrics,
    required this.algorithmId,
    required this.algorithmVersion,
    required this.processingMetadata,
    required this.createdAtUtc,
    this.respiratoryRateBpm,
    this.modelVersion,
  });

  static const int schemaVersion = 1;

  final String id;

  /// Session start time.
  final DateTime timestampUtc;
  final int durationMilliseconds;
  final double heartRateBpm;

  /// Always null in this build: respiratory rate is not estimated.
  final double? respiratoryRateBpm;
  final SignalQuality signalQuality;
  final QualityMetrics qualityMetrics;
  final String algorithmId;
  final String algorithmVersion;
  final String? modelVersion;

  /// Non-identifying processing details (window counts, IQR, locator type).
  final Map<String, Object?> processingMetadata;
  final DateTime createdAtUtc;

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'timestampUtc': timestampUtc.toUtc().toIso8601String(),
        'durationMilliseconds': durationMilliseconds,
        'heartRateBpm': heartRateBpm,
        'respiratoryRateBpm': respiratoryRateBpm,
        'signalQuality': signalQuality.name,
        'qualityMetrics': qualityMetrics.toJson(),
        'algorithmId': algorithmId,
        'algorithmVersion': algorithmVersion,
        'modelVersion': modelVersion,
        'processingMetadata': processingMetadata,
        'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
      };

  /// Parses a stored record. Returns null for corrupted or incompatible
  /// data rather than throwing, so one bad row cannot break history.
  static MeasurementRecord? tryFromJson(Map<String, Object?> json) {
    try {
      final version = json['schemaVersion'];
      if (version is! int || version > schemaVersion) return null;
      final hr = json['heartRateBpm'];
      if (hr is! num || !hr.isFinite) return null;
      final metrics = json['qualityMetrics'];
      final meta = json['processingMetadata'];
      return MeasurementRecord(
        id: json['id']! as String,
        timestampUtc: DateTime.parse(json['timestampUtc']! as String).toUtc(),
        durationMilliseconds: (json['durationMilliseconds']! as num).toInt(),
        heartRateBpm: hr.toDouble(),
        respiratoryRateBpm: (json['respiratoryRateBpm'] as num?)?.toDouble(),
        signalQuality: SignalQuality.fromName(json['signalQuality']! as String),
        qualityMetrics: metrics is Map
            ? QualityMetrics.fromJson(metrics.cast<String, Object?>())
            : const QualityMetrics(),
        algorithmId: json['algorithmId']! as String,
        algorithmVersion: json['algorithmVersion']! as String,
        modelVersion: json['modelVersion'] as String?,
        processingMetadata:
            meta is Map ? meta.cast<String, Object?>() : const {},
        createdAtUtc: DateTime.parse(json['createdAtUtc']! as String).toUtc(),
      );
    } catch (_) {
      return null;
    }
  }
}
