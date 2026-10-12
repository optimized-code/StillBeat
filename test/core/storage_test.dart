import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stillbeat/core/storage/app_database.dart';
import 'package:stillbeat/core/storage/migrations.dart';
import 'package:stillbeat/features/history/data/measurement_repository.dart';
import 'package:stillbeat/features/history/domain/measurement_record.dart';
import 'package:stillbeat/features/settings/data/settings_repository.dart';
import 'package:stillbeat/features/settings/domain/app_settings.dart';
import 'package:stillbeat/features/signal_quality/domain/signal_quality.dart';
import 'package:stillbeat/services/rppg/window_analyzer.dart';
import 'package:sembast/sembast_memory.dart';

import '../helpers/records.dart';

void main() {
  late Database db;
  var n = 0;

  setUp(() async {
    db = await openAppDatabase(
      factory: databaseFactoryMemory,
      path: 'test-${n++}',
    );
  });
  tearDown(() => db.close());

  group('MeasurementRecord serialization', () {
    test('round-trips through JSON', () {
      final r = sampleRecord(id: 'a', bpm: 71.3);
      final back = MeasurementRecord.tryFromJson(r.toJson())!;
      expect(back.id, 'a');
      expect(back.heartRateBpm, 71.3);
      expect(back.signalQuality, SignalQuality.good);
      expect(back.qualityMetrics.snrDb, r.qualityMetrics.snrDb);
      expect(back.respiratoryRateBpm, isNull);
      expect(back.timestampUtc, r.timestampUtc);
      expect(back.processingMetadata['validWindows'], 20);
    });

    test('rejects corrupted or future-schema records instead of throwing', () {
      final good = sampleRecord().toJson();
      expect(MeasurementRecord.tryFromJson({...good, 'heartRateBpm': 'x'}),
          isNull);
      expect(MeasurementRecord.tryFromJson({...good, 'timestampUtc': 'nope'}),
          isNull);
      expect(MeasurementRecord.tryFromJson({...good, 'schemaVersion': 99}),
          isNull);
      expect(MeasurementRecord.tryFromJson({...good}..remove('id')), isNull);
      expect(MeasurementRecord.tryFromJson(const {}), isNull);
    });

    test('non-finite metrics are not serialised', () {
      const m =
          QualityMetrics(snrDb: double.infinity, peakProminence: double.nan);
      final j = m.toJson();
      expect(j['snrDb'], isNull);
      expect(j['peakProminence'], isNull);
    });

    test('record contains no image, device or identity fields', () {
      final keys = sampleRecord().toJson().keys.toSet();
      for (final banned in [
        'image',
        'frame',
        'device',
        'deviceId',
        'user',
        'email',
        'waveform'
      ]) {
        expect(keys, isNot(contains(banned)));
      }
    });
  });

  group('SembastMeasurementRepository', () {
    test('save, list newest first, get, delete, deleteAll', () async {
      final repo = SembastMeasurementRepository(db);
      await repo.save(sampleRecord(id: 'old', at: DateTime.utc(2026, 1, 1)));
      await repo.save(sampleRecord(id: 'new', at: DateTime.utc(2026, 2, 1)));
      var page = await repo.list();
      expect(page.records.map((r) => r.id), ['new', 'old']);
      expect((await repo.get('old'))!.id, 'old');

      await repo.delete('old');
      page = await repo.list();
      expect(page.records.map((r) => r.id), ['new']);
      expect(await repo.get('old'), isNull);

      await repo.deleteAll();
      expect((await repo.list()).records, isEmpty);
    });

    test('date filtering', () async {
      final repo = SembastMeasurementRepository(db);
      for (var d = 1; d <= 10; d++) {
        await repo
            .save(sampleRecord(id: 'd$d', at: DateTime.utc(2026, 3, d, 12)));
      }
      final page = await repo.list(
        fromUtc: DateTime.utc(2026, 3, 3),
        toUtc: DateTime.utc(2026, 3, 6),
      );
      expect(page.records.map((r) => r.id), ['d5', 'd4', 'd3']);
    });

    test('corrupted rows are skipped and counted', () async {
      final repo = SembastMeasurementRepository(db);
      await repo.save(sampleRecord(id: 'ok'));
      await stringMapStoreFactory.store(Stores.measurements).record('bad').put(
          db, {'schemaVersion': 1, 'timestampUtc': '2026-01-01T00:00:00Z'});
      final page = await repo.list();
      expect(page.records.map((r) => r.id), ['ok']);
      expect(page.skippedCorrupted, 1);
    });

    test('changes stream fires on writes', () async {
      final repo = SembastMeasurementRepository(db);
      final events = <void>[];
      final sub = repo.changes.listen(events.add);
      await Future<void>.delayed(Duration.zero);
      await repo.save(sampleRecord(id: 'x'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(events, isNotEmpty);
      await sub.cancel();
    });
  });

  group('settings', () {
    test('round-trip and defaults', () async {
      final repo = SembastSettingsRepository(db);
      expect((await repo.load()).hasAcknowledgedDisclaimer, isFalse);
      const s = AppSettings(
        themeMode: ThemeMode.dark,
        localeCode: 'en',
        measurementSeconds: 60,
        method: PulseMethod.chrom,
        acknowledgedDisclaimerVersion: AppSettings.currentDisclaimerVersion,
      );
      await repo.save(s);
      final back = await repo.load();
      expect(back.themeMode, ThemeMode.dark);
      expect(back.localeCode, 'en');
      expect(back.measurementSeconds, 60);
      expect(back.method, PulseMethod.chrom);
      expect(back.hasAcknowledgedDisclaimer, isTrue);
      await repo.clear();
      expect((await repo.load()).hasAcknowledgedDisclaimer, isFalse);
    });

    test('invalid persisted values fall back to defaults', () {
      final s = AppSettings.fromJson(const {
        'themeMode': 'neon',
        'measurementSeconds': 7,
        'method': 'magic',
        'acknowledgedDisclaimerVersion': 'yes',
      });
      expect(s.themeMode, ThemeMode.system);
      expect(s.measurementSeconds, 30);
      expect(s.method, PulseMethod.pos);
      expect(s.hasAcknowledgedDisclaimer, isFalse);
    });
  });

  group('migrations', () {
    test('steps run in order from old+1 to new', () async {
      final ran = <int>[];
      await runMigrations(db, 1, 3, steps: {
        2: (_) async => ran.add(2),
        3: (_) async => ran.add(3),
      });
      expect(ran, [2, 3]);
    });

    test('missing step throws', () {
      expect(
        () => runMigrations(db, 1, 3, steps: {2: (_) async {}}),
        throwsStateError,
      );
    });

    test('downgrade is refused', () {
      expect(() => runMigrations(db, 3, 1), throwsStateError);
    });

    test('opening at a higher version transforms existing data', () async {
      const path = 'migrate-me';
      final v1 =
          await openAppDatabase(factory: databaseFactoryMemory, path: path);
      final store = stringMapStoreFactory.store(Stores.measurements);
      await store.record('r').put(v1, {'legacyBpm': 70});
      await v1.close();

      final v2 = await openAppDatabase(
        factory: databaseFactoryMemory,
        path: path,
        version: 2,
        migrations: {
          1: (_) async {},
          2: (txn) async {
            final snaps = await store.find(txn);
            for (final s in snaps) {
              await store.record(s.key).put(txn, {
                'heartRateBpm': s.value['legacyBpm'],
              });
            }
          },
        },
      );
      expect((await store.record('r').get(v2))!['heartRateBpm'], 70);
      expect(v2.version, 2);
      await v2.close();
    });

    test('current schema version has a registered step chain', () {
      for (var v = 1; v <= currentDatabaseVersion; v++) {
        expect(defaultMigrations[v], isNotNull, reason: 'version $v');
      }
    });
  });
}
