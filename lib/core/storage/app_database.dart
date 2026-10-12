import 'package:sembast/sembast.dart';

import '../logging/app_logger.dart';
import 'database_factory_stub.dart'
    if (dart.library.io) 'database_factory_io.dart'
    if (dart.library.js_interop) 'database_factory_web.dart';
import 'migrations.dart';

/// Store names. Kept here so deletion can enumerate every store.
abstract final class Stores {
  static const measurements = 'measurements';
  static const settings = 'settings';
  static const all = [measurements, settings];
}

class StorageBackendInfo {
  const StorageBackendInfo({required this.name, required this.encrypted});
  final String name;

  /// No backend is encrypted by the app in this build; see docs/privacy.md.
  final bool encrypted;
}

/// Opens the application database with migrations.
///
/// Native: a sembast JSON file in the app-support directory (sandboxed by
/// the OS, not encrypted by the app). Web: IndexedDB via sembast_web
/// (origin-scoped, not encrypted).
Future<Database> openAppDatabase({
  DatabaseFactory? factory,
  String? path,
  Map<int, MigrationStep>? migrations,
  int version = currentDatabaseVersion,
}) async {
  final log = AppLogger('storage');
  final f = factory ?? platformDatabaseFactory();
  final p = path ?? await platformDatabasePath();
  return f.openDatabase(
    p,
    version: version,
    onVersionChanged: (db, oldVersion, newVersion) => runMigrations(
      db,
      oldVersion,
      newVersion,
      steps: migrations,
      logger: log,
    ),
  );
}

StorageBackendInfo get storageBackendInfo => platformStorageBackendInfo();
