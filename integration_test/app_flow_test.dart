// End-to-end UI flow with deterministic fake camera + face locator.
//
// Run on a device/emulator/browser:
//   flutter test integration_test/app_flow_test.dart -d <device>
//
// The fake camera renders frames in real time (30 fps), so this test takes
// about a minute. It exercises the real controller, ROI extraction, POS,
// quality gates, persistence and navigation; only camera hardware and the
// face detector are replaced.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stillbeat/app/app.dart';
import 'package:stillbeat/app/providers.dart';
import 'package:stillbeat/core/errors/app_error.dart';
import 'package:stillbeat/core/storage/app_database.dart';
import 'package:stillbeat/features/settings/domain/app_settings.dart';
import 'package:stillbeat/features/settings/presentation/settings_controller.dart';
import 'package:stillbeat/services/face_detection/face_locator.dart';
import 'package:sembast/sembast_memory.dart';

import '../test/helpers/fakes.dart';

/// Emits frames on a real-time timer while open.
class RealtimeFakeCamera extends FakeCameraSource {
  RealtimeFakeCamera({super.scene});
  Timer? _timer;
  final Stopwatch _clock = Stopwatch();

  @override
  Future<void> open({String? deviceId}) async {
    await super.open(deviceId: deviceId);
    _clock
      ..reset()
      ..start();
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      emitFrame(_clock.elapsedMicroseconds / 1e6);
    });
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    _timer = null;
    await super.close();
  }
}

Future<ProviderContainer> launch(
  WidgetTester tester, {
  required FakeCameraSource camera,
  bool acknowledged = true,
}) async {
  final db = await openAppDatabase(
    factory: databaseFactoryMemory,
    path: 'it-${DateTime.now().microsecondsSinceEpoch}',
  );
  final locator = FakeFaceLocator(
    () => [DetectedFace(box: camera.scene.faceBox, yawDegrees: 0)],
  );
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      platformServicesProvider.overrideWithValue(
        fakePlatform(camera: camera, locator: locator),
      ),
      initialSettingsProvider.overrideWithValue(
        AppSettings(
          acknowledgedDisclaimerVersion:
              acknowledged ? AppSettings.currentDisclaimerVersion : 0,
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const RppgApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> pumpFor(WidgetTester tester, Duration d) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('measure → result → save → history', (tester) async {
    final camera = RealtimeFakeCamera(scene: FakeScene(heartRateBpm: 75));
    final container = await launch(tester, camera: camera);

    await tester.tap(find.text('Start measurement'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start camera'));
    await pumpFor(tester, const Duration(seconds: 42));
    await tester.pumpAndSettle();

    expect(find.text('Estimated heart rate'), findsOneWidget);
    expect(camera.isOpen, isFalse);
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final page = await container.read(measurementRepositoryProvider).list();
    expect(page.records, hasLength(1));
    expect(page.records.single.heartRateBpm, closeTo(75, 4));
  });

  testWidgets('permission denied shows recovery', (tester) async {
    final camera = RealtimeFakeCamera()
      ..openError = const PermissionDeniedError();
    await launch(tester, camera: camera);
    await tester.tap(find.text('Start measurement'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start camera'));
    await tester.pumpAndSettle();
    expect(find.text('Camera access needed'), findsOneWidget);
  });

  testWidgets('cancel mid-session stops the camera', (tester) async {
    final camera = RealtimeFakeCamera();
    await launch(tester, camera: camera);
    await tester.tap(find.text('Start measurement'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start camera'));
    await pumpFor(tester, const Duration(seconds: 3));
    expect(camera.isOpen, isTrue);
    await tester.tap(find.byTooltip('Cancel measurement'));
    await tester.pumpAndSettle();
    expect(camera.isOpen, isFalse);
  });

  testWidgets('onboarding gate', (tester) async {
    await launch(tester, camera: RealtimeFakeCamera(), acknowledged: false);
    expect(find.text('How it works'), findsOneWidget);
    expect(find.text('Start measurement'), findsNothing);
  });
}
