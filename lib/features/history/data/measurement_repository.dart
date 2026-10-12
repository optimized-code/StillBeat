import 'package:sembast/sembast.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/storage/app_database.dart';
import '../domain/measurement_record.dart';

class HistoryPage {
  const HistoryPage({required this.records, required this.skippedCorrupted});

  /// Newest first.
  final List<MeasurementRecord> records;

  /// Stored entries that could not be parsed and were ignored.
  final int skippedCorrupted;
}

abstract interface class MeasurementRepository {
  Future<HistoryPage> list({DateTime? fromUtc, DateTime? toUtc});
  Future<MeasurementRecord?> get(String id);
  Future<void> save(MeasurementRecord record);
  Future<void> delete(String id);
  Future<void> deleteAll();
  Stream<void> get changes;
}

class SembastMeasurementRepository implements MeasurementRepository {
  SembastMeasurementRepository(this._db);

  final Database _db;
  final _store = stringMapStoreFactory.store(Stores.measurements);
  final _log = AppLogger('history.repo');

  @override
  Stream<void> get changes => _store.query().onSnapshots(_db).map((_) {});

  @override
  Future<HistoryPage> list({DateTime? fromUtc, DateTime? toUtc}) async {
    try {
      final filters = <Filter>[
        if (fromUtc != null)
          Filter.greaterThanOrEquals(
            'timestampUtc',
            fromUtc.toUtc().toIso8601String(),
          ),
        if (toUtc != null)
          Filter.lessThan('timestampUtc', toUtc.toUtc().toIso8601String()),
      ];
      final snaps = await _store.find(
        _db,
        finder: Finder(
          filter: filters.isEmpty ? null : Filter.and(filters),
          sortOrders: [SortOrder('timestampUtc', false)],
        ),
      );
      var skipped = 0;
      final records = <MeasurementRecord>[];
      for (final s in snaps) {
        final r = MeasurementRecord.tryFromJson(s.value);
        if (r == null) {
          skipped++;
        } else {
          records.add(r);
        }
      }
      if (skipped > 0) {
        _log.warn('skipped corrupted records', {'count': skipped});
      }
      return HistoryPage(records: records, skippedCorrupted: skipped);
    } catch (e) {
      throw StorageError('list: ${e.runtimeType}');
    }
  }

  @override
  Future<MeasurementRecord?> get(String id) async {
    try {
      final v = await _store.record(id).get(_db);
      return v == null ? null : MeasurementRecord.tryFromJson(v);
    } catch (e) {
      throw StorageError('get: ${e.runtimeType}');
    }
  }

  @override
  Future<void> save(MeasurementRecord record) async {
    try {
      await _store.record(record.id).put(_db, record.toJson());
    } catch (e) {
      throw StorageError('save: ${e.runtimeType}');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _store.record(id).delete(_db);
    } catch (e) {
      throw StorageError('delete: ${e.runtimeType}');
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _store.delete(_db);
    } catch (e) {
      throw StorageError('deleteAll: ${e.runtimeType}');
    }
  }
}
