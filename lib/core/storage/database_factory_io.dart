import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

import 'app_database.dart';

DatabaseFactory platformDatabaseFactory() => databaseFactoryIo;

Future<String> platformDatabasePath() async {
  // Application Support is excluded from user-visible document folders and
  // is removed when the app is uninstalled.
  final dir = await getApplicationSupportDirectory();
  return '${dir.path}/stillbeat.db';
}

StorageBackendInfo platformStorageBackendInfo() => const StorageBackendInfo(
      name: 'sembast file (app sandbox)',
      encrypted: false,
    );
