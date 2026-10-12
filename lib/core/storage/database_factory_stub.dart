import 'package:sembast/sembast.dart';

import 'app_database.dart';

DatabaseFactory platformDatabaseFactory() =>
    throw UnsupportedError('No database factory for this platform');

Future<String> platformDatabasePath() async =>
    throw UnsupportedError('No database path for this platform');

StorageBackendInfo platformStorageBackendInfo() =>
    const StorageBackendInfo(name: 'unsupported', encrypted: false);
