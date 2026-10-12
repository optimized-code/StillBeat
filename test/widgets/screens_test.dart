import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stillbeat/app/providers.dart';
import 'package:stillbeat/app/router.dart';
import 'package:stillbeat/core/errors/app_error.dart';
import 'package:stillbeat/features/history/presentation/history_providers.dart';
import 'package:stillbeat/features/measurement/domain/measurement_result.dart';
import 'package:stillbeat/features/measurement/domain/result_aggregator.dart';
import 'package:stillbeat/features/settings/presentation/settings_controller.dart';
import 'package:stillbeat/services/rppg/rppg_engine.dart';
import 'package:stillbeat/services/rppg/window_analyzer.dart';

import '../helpers/app_harness.dart';
import '../helpers/records.dart';
import '../helpers/synthetic_signals.dart';
import 'package:stillbeat/features/signal_quality/domain/quality_config.dart';
import 'package:stillbeat/services/rppg/rppg_config.dart';
import 'package:stillbeat/services/rppg/rppg_sample.dart';

void go(AppHarness h, String location) =>
    h.container.read(routerProvider).go(location);

MeasurementResult syntheticResult() {
  // Built through the real pipeline from synthetic traces, so the screen
  // shows exactly what the aggregator would produce.
  final windows = <WindowAnalysis>[];
  final samples =
      syntheticSamples(const SyntheticTraceSpec(durationSeconds: 40));
  final buf = SignalBuffer(capacity: 5000);
  samples.forEach(buf.add);
  final recent = <double>[];
  for (var end = 10.0; end <= 39; end += 1) {
    final a = analyzeWindow(
      AnalysisRequest(
        samples: buf.snapshotSince(0),
        windowEndMicros: (end * 1e6).round(),
        method: PulseMethod.pos,
        rppgConfig: const RppgConfig(),
        qualityConfig: const QualityConfig(),
        recentBpms: List.of(recent),
      ),
    );
    if (a.bpm != null) recent.add(a.bpm!);
    windows.add(a);
  }
  final outcome = aggregateMeasurement(
    windows: windows,
    config: const AggregationConfig(),
    algorithm: AlgorithmInfo.pos,
    startedAtUtc: DateTime.utc(2026, 5, 1, 9),
    durationMilliseconds: 30000,
  );
  return (outcome as MeasurementSucceeded).result;
}

void main() {
  group('onboarding', () {
    testWidgets('requires acknowledgement before reaching home', (t) async {
      final h = await AppHarness.pump(t, acknowledged: false);
      expect(find.text('How it works'), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        await t.tap(find.text('Continue'));
        await t.pumpAndSettle();
      }
      final getStarted = find.widgetWithText(FilledButton, 'Get started');
      expect(t.widget<FilledButton>(getStarted).onPressed, isNull);
      expect(find.textContaining('not a medical diagnosis'), findsOneWidget);

      await t.tap(find.byType(Checkbox));
      await t.pump();
      expect(t.widget<FilledButton>(getStarted).onPressed, isNotNull);
      await t.tap(getStarted);
      await h.settle(t);
      expect(find.text('Start measurement'), findsOneWidget);
      expect(
        h.container.read(settingsControllerProvider).hasAcknowledgedDisclaimer,
        isTrue,
      );
    });

    testWidgets('privacy notice is reachable before acknowledging', (t) async {
      final h = await AppHarness.pump(t, acknowledged: false);
      go(h, Routes.privacy);
      await h.settle(t);
      expect(find.text('Privacy'), findsWidgets);
      expect(find.textContaining('No video or images are recorded'),
          findsOneWidget);
    });
  });

  group('home', () {
    testWidgets('empty state shows no fabricated health data', (t) async {
      await AppHarness.pump(t);
      expect(find.text('No saved measurements yet.'), findsOneWidget);
      expect(find.textContaining('BPM'), findsNothing);
      expect(find.text('Start measurement'), findsOneWidget);
    });

    testWidgets('shows latest saved result and summary', (t) async {
      await AppHarness.pump(
        t,
        records: [
          sampleRecord(id: 'a', bpm: 64, at: DateTime.utc(2026, 1, 1)),
          sampleRecord(id: 'b', bpm: 77, at: DateTime.utc(2026, 2, 1)),
        ],
      );
      expect(find.text('77'), findsOneWidget);
      expect(find.text('2 measurements saved'), findsOneWidget);
    });

    testWidgets('unsupported platform explains instead of offering start',
        (t) async {
      await AppHarness.pump(t, supported: false);
      expect(find.text('Start measurement'), findsNothing);
      expect(find.textContaining('test-unsupported'), findsOneWidget);
    });
  });

  group('measurement screen', () {
    testWidgets('shows purpose first and requests camera only on tap',
        (t) async {
      final h = await AppHarness.pump(t);
      await t.tap(find.text('Start measurement'));
      await h.settle(t);
      expect(find.textContaining('Nothing is recorded or uploaded'),
          findsOneWidget);
      expect(h.camera.openCount, 0);

      await t.tap(find.text('Start camera'));
      await h.settle(t);
      expect(h.camera.openCount, 1);
      expect(find.text('Position your face'), findsOneWidget);
      expect(find.byTooltip('Cancel measurement'), findsOneWidget);
      // End the session so no camera watchdog outlives the test.
      await t.tap(find.byTooltip('Cancel measurement'));
      await h.settle(t);
      expect(h.camera.isOpen, isFalse);
    });

    testWidgets('permission denial shows recovery actions', (t) async {
      final h = await AppHarness.pump(t);
      h.camera.openError = const PermissionDeniedError();
      go(h, Routes.measure);
      await h.settle(t);
      await t.tap(find.text('Start camera'));
      await h.settle(t);
      expect(find.text('Camera access needed'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('cancel closes the camera and leaves the screen', (t) async {
      final h = await AppHarness.pump(t);
      await t.tap(find.text('Start measurement'));
      await h.settle(t);
      await t.tap(find.text('Start camera'));
      await h.settle(t);
      expect(h.camera.isOpen, isTrue);
      await t.tap(find.text('Cancel measurement').last);
      await h.settle(t);
      expect(h.camera.isOpen, isFalse);
      expect(find.text('Start measurement'), findsOneWidget);
    });
  });

  group('results', () {
    testWidgets('shows validated result with disclaimer and saves it',
        (t) async {
      final h = await AppHarness.pump(t);
      final result = syntheticResult();
      h.container.read(pendingResultProvider.notifier).state = result;
      go(h, Routes.results);
      await h.settle(t);

      expect(find.text(result.heartRateBpm.round().toString()), findsOneWidget);
      expect(find.textContaining('not a medical diagnosis'), findsOneWidget);
      expect(find.textContaining('POS (Plane-Orthogonal-to-Skin)'),
          findsOneWidget);
      expect(find.textContaining('no neural network'), findsOneWidget);
      expect(find.text('Pulse waveform'), findsOneWidget);

      await t.ensureVisible(find.text('Save'));
      await t.pumpAndSettle();
      await t.tap(find.text('Save'));
      await h.settle(t);
      final page = (await t.runAsync(() => h.repo.list()))!;
      expect(page.records, hasLength(1));
      expect(
          page.records.single.heartRateBpm, closeTo(result.heartRateBpm, 0.05));
      expect(find.text('View history'), findsOneWidget);
    });

    testWidgets('with no pending result shows an empty state', (t) async {
      final h = await AppHarness.pump(t);
      go(h, Routes.results);
      await h.settle(t);
      expect(find.text('No result to show.'), findsOneWidget);
    });
  });

  group('history', () {
    testWidgets('lists records, shows trend, and deletes all', (t) async {
      final h = await AppHarness.pump(
        t,
        records: [
          sampleRecord(id: 'a', bpm: 61, at: DateTime.now().toUtc()),
          sampleRecord(
            id: 'b',
            bpm: 68,
            at: DateTime.now().toUtc().subtract(const Duration(days: 2)),
          ),
        ],
      );
      go(h, Routes.history);
      await h.settle(t);
      expect(find.text('61 BPM'), findsOneWidget);
      expect(find.text('68 BPM'), findsOneWidget);
      expect(find.textContaining('not a diagnosis'), findsOneWidget);

      await t.tap(find.byIcon(Icons.more_vert));
      await t.pumpAndSettle();
      await t.tap(find.text('Delete all measurements'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(FilledButton, 'Delete'));
      await h.settle(t);
      expect(
          find.text('No saved measurements for this period.'), findsOneWidget);
    });

    testWidgets('detail view and single delete', (t) async {
      final h =
          await AppHarness.pump(t, records: [sampleRecord(id: 'x', bpm: 70)]);
      go(h, Routes.history);
      await h.settle(t);
      await t.tap(find.text('70 BPM'));
      await h.settle(t);
      expect(find.text('Measurement details'), findsOneWidget);
      await t.tap(find.byTooltip('Delete'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(FilledButton, 'Delete'));
      await h.settle(t);
      expect((await t.runAsync(() => h.repo.list()))!.records, isEmpty);
    });

    testWidgets('date filter chips change the query', (t) async {
      final h = await AppHarness.pump(
        t,
        records: [
          sampleRecord(id: 'old', bpm: 59, at: DateTime.utc(2020, 1, 1))
        ],
      );
      go(h, Routes.history);
      await h.settle(t);
      expect(find.text('59 BPM'), findsOneWidget);
      await t.tap(find.text('7 days'));
      await h.settle(t);
      expect(find.text('59 BPM'), findsNothing);
      expect(h.container.read(historyFilterProvider).range,
          HistoryRange.last7Days);
    });
  });

  group('settings', () {
    testWidgets('changes persist and neural option is disabled', (t) async {
      final h = await AppHarness.pump(t);
      go(h, Routes.settings);
      await h.settle(t);
      await t.tap(find.text('60 seconds'));
      await t.pump();
      await h.settle(t);
      expect(
          h.container.read(settingsControllerProvider).measurementSeconds, 60);
      final neural = find.textContaining('Neural model');
      await t.scrollUntilVisible(neural, 200);
      expect(neural, findsOneWidget);
      await t.tap(find.text('CHROM (chrominance-based)'));
      await h.settle(t);
      expect(h.container.read(settingsControllerProvider).method,
          PulseMethod.chrom);
    });

    testWidgets('delete all data resets acknowledgement', (t) async {
      final h = await AppHarness.pump(t, records: [sampleRecord()]);
      go(h, Routes.settings);
      await h.settle(t);
      final del = find.text('Delete all data');
      await t.scrollUntilVisible(del, 200);
      await t.ensureVisible(del);
      await t.pumpAndSettle();
      await t.tap(del);
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(FilledButton, 'Delete'));
      await h.settle(t);
      expect((await t.runAsync(() => h.repo.list()))!.records, isEmpty);
      expect(
        h.container.read(settingsControllerProvider).hasAcknowledgedDisclaimer,
        isFalse,
      );
      expect(find.text('How it works'), findsOneWidget);
    });
  });

  group('about', () {
    testWidgets('identifies algorithms honestly', (t) async {
      final h = await AppHarness.pump(t);
      go(h, Routes.about);
      await h.settle(t);
      expect(find.textContaining('Wang, den Brinker'), findsOneWidget);
      expect(
          find.text('Neural model (not installed) · v0.0.0'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });
  });

  group('accessibility and layout', () {
    for (final size in const [
      Size(320, 640),
      Size(800, 1200),
      Size(1440, 900)
    ]) {
      testWidgets('home lays out without overflow at $size', (t) async {
        await AppHarness.pump(t, size: size, records: [sampleRecord()]);
        expect(t.takeException(), isNull);
        expect(find.text('Start measurement'), findsOneWidget);
      });
    }

    testWidgets('home survives 2x text scale', (t) async {
      await AppHarness.pump(t, textScale: 2.0, size: const Size(390, 844));
      expect(t.takeException(), isNull);
    });

    testWidgets('home meets tap-target, label and contrast guidelines',
        (t) async {
      final handle = t.ensureSemantics();
      await AppHarness.pump(t, records: [sampleRecord()]);
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(t, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('results meets label and contrast guidelines in dark mode',
        (t) async {
      final handle = t.ensureSemantics();
      final h = await AppHarness.pump(t);
      await t.runAsync(
        () => h.container
            .read(settingsControllerProvider.notifier)
            .setThemeMode(ThemeMode.dark),
      );
      h.container.read(pendingResultProvider.notifier).state =
          syntheticResult();
      go(h, Routes.results);
      await h.settle(t);
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(t, meetsGuideline(textContrastGuideline));
      expect(
        find.bySemanticsLabel(RegExp(r'Estimated heart rate: \d+ BPM')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
