import 'package:sembast_web/sembast_web.dart';

import 'app_database.dart';

DatabaseFactory platformDatabaseFactory() => databaseFactoryWeb;

Future<String> platformDatabasePath() async => 'stillbeat';

StorageBackendInfo platformStorageBackendInfo() => const StorageBackendInfo(
      name: 'IndexedDB (browser, origin-scoped)',
      encrypted: false,
    );
