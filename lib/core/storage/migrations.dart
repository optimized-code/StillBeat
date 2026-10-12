import 'package:sembast/sembast.dart';

import '../logging/app_logger.dart';

/// A single schema upgrade from `version - 1` to `version`.
typedef MigrationStep = Future<void> Function(DatabaseClient db);

/// Current on-disk schema version. Bump and add a step to
/// [defaultMigrations] for every incompatible change.
const int currentDatabaseVersion = 1;

/// Steps keyed by target version. Version 1 is the initial schema and needs
/// no data transformation.
final Map<int, MigrationStep> defaultMigrations = {
  1: (_) async {},
};

/// Applies each step in order from [oldVersion] + 1 to [newVersion].
///
/// sembast runs `onVersionChanged` inside a transaction, so a failing step
/// rolls back the whole upgrade instead of leaving a half-migrated store.
Future<void> runMigrations(
  DatabaseClient db,
  int oldVersion,
  int newVersion, {
  Map<int, MigrationStep>? steps,
  AppLogger? logger,
}) async {
  final all = steps ?? defaultMigrations;
  if (newVersion < oldVersion) {
    throw StateError(
      'Database version $oldVersion is newer than app version $newVersion',
    );
  }
  for (var v = oldVersion + 1; v <= newVersion; v++) {
    final step = all[v];
    if (step == null) throw StateError('Missing migration to version $v');
    await step(db);
    logger?.info('migrated', {'to': v});
  }
}
