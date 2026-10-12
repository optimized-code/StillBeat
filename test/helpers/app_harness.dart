import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stillbeat/app/app.dart';
import 'package:stillbeat/app/providers.dart';
import 'package:stillbeat/core/storage/app_database.dart';
import 'package:stillbeat/features/history/data/measurement_repository.dart';
import 'package:stillbeat/features/history/domain/measurement_record.dart';
import 'package:stillbeat/features/settings/domain/app_settings.dart';
import 'package:stillbeat/features/settings/presentation/settings_controller.dart';
import 'package:stillbeat/services/rppg/window_analyzer.dart';
import 'package:sembast/sembast_memory.dart';

import 'fakes.dart';

int _dbCounter = 0;

class AppHarness {
  AppHarness._(this.db, this.container, this.camera, this.locator);

  final Database db;
  final ProviderContainer container;
  final FakeCameraSource camera;
  final FakeFaceLocator locator;

  MeasurementRepository get repo =>
      container.read(measurementRepositoryProvider);

  static Future<AppHarness> pump(
    WidgetTester tester, {
    bool acknowledged = true,
    bool supported = true,
    List<MeasurementRecord> records = const [],
    Size size = const Size(400, 860),
    double textScale = 1.0,
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    final db = (await tester.runAsync(
      () => openAppDatabase(
        factory: databaseFactoryMemory,
        path: 'widget-${_dbCounter++}',
      ),
    ))!;
    final camera = FakeCameraSource();
    final locator = FakeFaceLocator(() => const []);
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        platformServicesProvider.overrideWithValue(
          fakePlatform(camera: camera, locator: locator, supported: supported),
        ),
        analysisRunnerProvider.overrideWithValue((r) async => analyzeWindow(r)),
        initialSettingsProvider.overrideWithValue(
          AppSettings(
            acknowledgedDisclaimerVersion:
                acknowledged ? AppSettings.currentDisclaimerVersion : 0,
          ),
        ),
        ...overrides,
      ],
    );
    final h = AppHarness._(db, container, camera, locator);
    for (final r in records) {
      await tester.runAsync(() => h.repo.save(r));
    }
    addTearDown(() async {
      container.dispose();
      await tester.runAsync(db.close);
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const RppgApp()),
    );
    await h.settle(tester);
    return h;
  }

  /// Lets real async work (database queries) complete, then settles frames.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }
}
