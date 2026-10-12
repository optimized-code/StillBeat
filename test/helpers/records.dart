import 'package:stillbeat/features/history/domain/measurement_record.dart';
import 'package:stillbeat/features/signal_quality/domain/signal_quality.dart';

MeasurementRecord sampleRecord({
  String id = 'r1',
  double bpm = 72,
  DateTime? at,
  SignalQuality quality = SignalQuality.good,
}) {
  final t = at ?? DateTime.utc(2026, 5, 4, 10, 30);
  return MeasurementRecord(
    id: id,
    timestampUtc: t,
    durationMilliseconds: 30000,
    heartRateBpm: bpm,
    signalQuality: quality,
    qualityMetrics: const QualityMetrics(
      snrDb: 4.2,
      peakProminence: 3.1,
      effectiveFrameRateHz: 29.8,
      stabilityBpm: 1.5,
    ),
    algorithmId: 'pos',
    algorithmVersion: '1.0.0',
    processingMetadata: const {
      'validWindows': 20,
      'totalWindows': 26,
      'interquartileRangeBpm': 1.5,
      'faceLocator': 'test',
    },
    createdAtUtc: t.add(const Duration(minutes: 1)),
  );
}
