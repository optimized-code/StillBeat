import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../services/export/export_service.dart';
import '../../measurement/domain/measurement_result.dart';
import '../data/measurement_repository.dart';
import '../domain/measurement_record.dart';

enum HistoryRange { last7Days, last30Days, all, custom }

class HistoryFilter {
  const HistoryFilter({this.range = HistoryRange.all, this.from, this.to});
  final HistoryRange range;

  /// Local-date bounds for [HistoryRange.custom] (inclusive start, exclusive end).
  final DateTime? from;
  final DateTime? to;

  (DateTime?, DateTime?) boundsUtc(DateTime nowUtc) => switch (range) {
        HistoryRange.last7Days => (
            nowUtc.subtract(const Duration(days: 7)),
            null
          ),
        HistoryRange.last30Days => (
            nowUtc.subtract(const Duration(days: 30)),
            null
          ),
        HistoryRange.all => (null, null),
        HistoryRange.custom => (from?.toUtc(), to?.toUtc()),
      };
}

final historyFilterProvider =
    StateProvider<HistoryFilter>((ref) => const HistoryFilter());

/// Re-runs when the filter or the stored data changes.
final historyProvider = StreamProvider.autoDispose<HistoryPage>((ref) {
  final repo = ref.watch(measurementRepositoryProvider);
  final filter = ref.watch(historyFilterProvider);
  final controller = StreamController<HistoryPage>();

  Future<void> load() async {
    try {
      final (from, to) = filter.boundsUtc(DateTime.now().toUtc());
      final page = await repo.list(fromUtc: from, toUtc: to);
      if (!controller.isClosed) controller.add(page);
    } catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    }
  }

  final sub = repo.changes.listen((_) => load());
  unawaited(load());
  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });
  return controller.stream;
});

/// Unfiltered history used by the home summary.
final allHistoryProvider = StreamProvider.autoDispose<HistoryPage>((ref) {
  final repo = ref.watch(measurementRepositoryProvider);
  final controller = StreamController<HistoryPage>();
  Future<void> load() async {
    try {
      final page = await repo.list();
      if (!controller.isClosed) controller.add(page);
    } catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    }
  }

  final sub = repo.changes.listen((_) => load());
  unawaited(load());
  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });
  return controller.stream;
});

final recordProvider =
    FutureProvider.autoDispose.family<MeasurementRecord?, String>(
  (ref, id) => ref.watch(measurementRepositoryProvider).get(id),
);

/// Converts a validated session result into a storable record.
MeasurementRecord recordFromResult(
  MeasurementResult r, {
  required String faceLocatorId,
  String? id,
  DateTime? nowUtc,
}) =>
    MeasurementRecord(
      id: id ?? const Uuid().v4(),
      timestampUtc: r.startedAtUtc,
      durationMilliseconds: r.durationMilliseconds,
      heartRateBpm: double.parse(r.heartRateBpm.toStringAsFixed(1)),
      signalQuality: r.quality,
      qualityMetrics: r.metrics,
      algorithmId: r.algorithm.id,
      algorithmVersion: r.algorithm.version,
      modelVersion: r.algorithm.modelVersion,
      processingMetadata: {
        'validWindows': r.validWindowCount,
        'totalWindows': r.totalWindowCount,
        'interquartileRangeBpm':
            double.parse(r.interquartileRangeBpm.toStringAsFixed(2)),
        'faceLocator': faceLocatorId,
      },
      createdAtUtc: nowUtc ?? DateTime.now().toUtc(),
    );

final historyActionsProvider = Provider<HistoryActions>(
  (ref) => HistoryActions(
    ref.watch(measurementRepositoryProvider),
    ref.watch(exportServiceProvider),
  ),
);

class HistoryActions {
  const HistoryActions(this._repo, this._export);
  final MeasurementRepository _repo;
  final ExportService _export;

  Future<void> save(MeasurementRecord r) => _repo.save(r);
  Future<void> delete(String id) => _repo.delete(id);
  Future<void> deleteAll() => _repo.deleteAll();

  /// Returns false when there was nothing to export.
  Future<bool> exportAll(ExportFormat format) async {
    final page = await _repo.list();
    if (page.records.isEmpty) return false;
    await _export.export(page.records, format);
    return true;
  }
}
