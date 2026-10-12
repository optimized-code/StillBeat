import 'package:sembast/sembast.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/storage/app_database.dart';
import '../domain/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
  Future<void> clear();
}

class SembastSettingsRepository implements SettingsRepository {
  SembastSettingsRepository(this._db);

  final Database _db;
  final _record = stringMapStoreFactory.store(Stores.settings).record('app');

  @override
  Future<AppSettings> load() async {
    try {
      final v = await _record.get(_db);
      return v == null ? const AppSettings() : AppSettings.fromJson(v);
    } catch (_) {
      // Unreadable settings must never block the app; fall back to
      // defaults (which also re-shows the disclaimer).
      return const AppSettings();
    }
  }

  @override
  Future<void> save(AppSettings settings) async {
    try {
      await _record.put(_db, settings.toJson());
    } catch (e) {
      throw StorageError('settings: ${e.runtimeType}');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _record.delete(_db);
    } catch (e) {
      throw StorageError('settings clear: ${e.runtimeType}');
    }
  }
}
