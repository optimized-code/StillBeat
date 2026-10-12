import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sembast/sembast_memory.dart';

import 'app/app.dart';
import 'app/brand.dart';
import 'app/providers.dart';
import 'core/logging/app_logger.dart';
import 'core/storage/app_database.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/settings/presentation/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final log = AppLogger('bootstrap');

  // Errors are logged locally (redacted). No crash reporter is installed,
  // so no frames, signals or health values can leave the device this way.
  FlutterError.onError = (details) {
    log.error('flutter error', {'type': details.exception.runtimeType});
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    log.error('uncaught', {'type': error.runtimeType});
    return true;
  };

  LicenseRegistry.addLicense(() async* {
    final roboto =
        await rootBundle.loadString('assets/fonts/Roboto_LICENSE.txt');
    yield LicenseEntryWithLineBreaks(const ['Roboto font'], roboto);
  });

  // If the persistent store cannot be opened (corruption, quota, private
  // browsing), fall back to memory so the app still works, and say so.
  Database db;
  var degraded = false;
  try {
    db = await openAppDatabase();
  } catch (e) {
    log.error('database open failed', {'type': e.runtimeType});
    db =
        await openAppDatabase(factory: databaseFactoryMemory, path: 'fallback');
    degraded = true;
  }
  final settings = await SembastSettingsRepository(db).load();
  var version = const AppVersion(version: '0.0.0', buildNumber: '0');
  try {
    final info = await PackageInfo.fromPlatform();
    version = AppVersion(version: info.version, buildNumber: info.buildNumber);
  } catch (_) {
    // Version display is non-essential.
  }

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        initialSettingsProvider.overrideWithValue(settings),
        appVersionProvider.overrideWithValue(version),
        storageDegradedProvider.overrideWithValue(degraded),
      ],
      child: const RppgApp(),
    ),
  );
}
