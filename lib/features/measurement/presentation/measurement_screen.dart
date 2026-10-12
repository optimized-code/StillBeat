import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/charts.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/labels.dart';
import '../domain/measurement_phase.dart';
import '../domain/measurement_result.dart';
import 'measurement_controller.dart';
import 'widgets/camera_stage.dart';

class MeasurementScreen extends ConsumerStatefulWidget {
  const MeasurementScreen({super.key});

  @override
  ConsumerState<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends ConsumerState<MeasurementScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    // `hidden` (not `inactive`) so the iOS permission prompt, which makes
    // the app briefly inactive, does not cancel the session.
    _lifecycle = AppLifecycleListener(
      onHide: () =>
          ref.read(measurementControllerProvider.notifier).onAppPaused(),
      onShow: () =>
          ref.read(measurementControllerProvider.notifier).onAppResumed(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    if (!kIsWeb) SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(measurementControllerProvider);
    final controller = ref.read(measurementControllerProvider.notifier);

    ref.listen(measurementControllerProvider.select((s) => s.phase), (_, next) {
      if (next == MeasurementPhase.completed) {
        final outcome = ref.read(measurementControllerProvider).outcome;
        if (outcome is MeasurementSucceeded) {
          ref.read(pendingResultProvider.notifier).state = outcome.result;
          ref.read(pendingLocatorIdProvider.notifier).state =
              ref.read(measurementControllerProvider).faceLocator?.id ??
                  'unknown';
          context.pushReplacement(Routes.results);
        }
      }
    });

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) controller.cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.measureTitle),
          leading: IconButton(
            tooltip: l.measureCancel,
            icon: const Icon(Icons.close),
            onPressed: () async {
              await controller.cancel();
              if (context.mounted) context.pop();
            },
          ),
        ),
        body: SafeArea(
          child: ContentWidth(
            child: switch (state.phase) {
              MeasurementPhase.idle => _IntroView(onStart: controller.start),
              _ when state.phase.isActive =>
                _ActiveView(state: state, controller: controller),
              _ => _TerminalView(state: state, controller: controller),
            },
          ),
        ),
      ),
    );
  }
}

/// Purpose statement shown before any camera access is requested.
class _IntroView extends StatelessWidget {
  const _IntroView({required this.onStart});
  final Future<void> Function({String? cameraId}) onStart;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(Space.xl),
      children: [
        Icon(Icons.videocam_outlined, size: 56, color: context.colors.primary),
        const SizedBox(height: Space.lg),
        Text(l.measurePurpose, style: context.text.bodyLarge),
        const SizedBox(height: Space.lg),
        Text(l.onboardingBody2, style: context.text.bodyMedium),
        const SizedBox(height: Space.xl),
        FilledButton.icon(
          autofocus: true,
          onPressed: () => onStart(),
          icon: const Icon(Icons.videocam),
          label: Text(l.measureStart),
        ),
        const SizedBox(height: Space.xl),
        const DisclaimerNote(short: true),
      ],
    );
  }
}

class _ActiveView extends StatelessWidget {
  const _ActiveView({required this.state, required this.controller});
  final MeasurementViewState state;
  final MeasurementController controller;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final issues = prioritiseIssues(state.guidance);
    final collecting = state.phase == MeasurementPhase.measuring ||
        state.phase == MeasurementPhase.warmingUp;
    final camera = controller.camera;
    final ready = state.phase != MeasurementPhase.positioning || issues.isEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewMaxHeight = constraints.maxHeight * 0.55;
        return ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: previewMaxHeight),
                child: CameraStage(
                  camera: camera,
                  guideReady: ready,
                  semanticLabel: l.measureGuideSemantics,
                ),
              ),
            ),
            const SizedBox(height: Space.lg),
            Semantics(
              liveRegion: true,
              child: Text(
                phaseLabel(l, state.phase),
                style: context.text.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: Space.sm),
            if (issues.isNotEmpty)
              Semantics(
                liveRegion: true,
                child: Text(
                  issueLabel(l, issues.first),
                  style: context.text.bodyLarge?.copyWith(
                    color: context.colors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: Space.md),
            if (state.phase == MeasurementPhase.measuring) ...[
              Semantics(
                label: l.measurePhaseMeasuring,
                value: '${(state.progress * 100).round()}%',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.pill),
                  child: LinearProgressIndicator(
                    value: state.progress,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(height: Space.xs),
              if (state.secondsRemaining != null)
                Text(
                  l.measureSecondsRemaining(state.secondsRemaining!),
                  style: context.text.labelMedium,
                  textAlign: TextAlign.center,
                ),
            ],
            if (collecting) ...[
              const SizedBox(height: Space.md),
              _LiveCard(state: state),
            ],
            if (state.faceLocator != null &&
                !state.faceLocator!.isLearnedDetector) ...[
              const SizedBox(height: Space.md),
              Text(
                l.measureHeuristicLocator,
                style: context.text.bodySmall,
              ),
            ],
            if (state.cameras.length > 1) ...[
              const SizedBox(height: Space.md),
              _CameraPicker(state: state, controller: controller),
            ],
            const SizedBox(height: Space.lg),
            OutlinedButton(
              onPressed: () async {
                await controller.cancel();
                if (context.mounted) context.pop();
              },
              child: Text(l.measureCancel),
            ),
          ],
        );
      },
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.state});
  final MeasurementViewState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bpm = state.liveBpm;
    return SectionCard(
      title: l.measureLiveEstimate,
      trailing: QualityBadge(state.liveQuality),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.waveform == null)
            Text(l.measureCollecting, style: context.text.bodyMedium)
          else if (bpm == null)
            Text(l.measureLiveUnavailable, style: context.text.bodyMedium)
          else
            Text(
              '${bpm.round()} ${l.commonBpm}',
              style: context.text.headlineMedium,
            ),
          const SizedBox(height: Space.md),
          WaveformView(
            samples: state.waveform,
            semanticLabel: l.measureWaveformLabel,
          ),
          Text(l.measureWaveformLabel, style: context.text.labelSmall),
          if (state.measuredFps != null)
            Text(
              l.measureFps(state.measuredFps!.toStringAsFixed(0)),
              style: context.text.labelSmall,
            ),
        ],
      ),
    );
  }
}

class _CameraPicker extends StatelessWidget {
  const _CameraPicker({required this.state, required this.controller});
  final MeasurementViewState state;
  final MeasurementController controller;

  @override
  Widget build(BuildContext context) {
    final ids = state.cameras.map((c) => c.id).toSet();
    return DropdownButtonFormField<String>(
      value:
          ids.contains(state.selectedCameraId) ? state.selectedCameraId : null,
      decoration: InputDecoration(labelText: context.l10n.measureCamera),
      items: [
        for (final c in state.cameras)
          DropdownMenuItem(value: c.id, child: Text(c.label)),
      ],
      onChanged: (id) {
        if (id != null) controller.selectCamera(id);
      },
    );
  }
}

class _TerminalView extends StatelessWidget {
  const _TerminalView({required this.state, required this.controller});
  final MeasurementViewState state;
  final MeasurementController controller;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final error = state.error;
    final outcome = state.outcome;
    final retry = FilledButton(
      onPressed: () => controller.start(),
      child: Text(l.commonRetry),
    );
    final back = OutlinedButton(
      onPressed: () => context.pop(),
      child: Text(l.commonBack),
    );

    final (icon, message, actions) = switch (state.phase) {
      MeasurementPhase.completed => (
          Icons.check_circle_outline,
          l.measurePhaseCompleted,
          [
            FilledButton(
              onPressed: () => context.pushReplacement(Routes.results),
              child: Text(l.measureViewResult),
            ),
          ],
        ),
      MeasurementPhase.lowSignalQuality => (
          Icons.signal_cellular_connected_no_internet_0_bar,
          [
            l.failureNoValue,
            if (outcome is MeasurementRejected) failureLabel(l, outcome.reason),
            ...prioritiseIssues(state.guidance)
                .take(2)
                .map((i) => issueLabel(l, i)),
            l.failureTips,
          ].join('\n\n'),
          [retry, back],
        ),
      MeasurementPhase.permissionDenied => (
          Icons.no_photography_outlined,
          error == null ? l.errorPermissionDenied : errorMessage(l, error),
          [
            if (error is PermissionDeniedError && error.permanent && !kIsWeb)
              FilledButton(
                onPressed: openAppSettings,
                child: Text(l.measureOpenSettings),
              )
            else
              retry,
            back,
          ],
        ),
      MeasurementPhase.unsupported => (
          Icons.block,
          error == null ? l.errorUnsupportedPlatform : errorMessage(l, error),
          [back],
        ),
      MeasurementPhase.interrupted => (
          Icons.pause_circle_outline,
          l.errorInterrupted,
          [retry, back],
        ),
      MeasurementPhase.cancelled => (
          Icons.cancel_outlined,
          l.errorSessionCancelled,
          [retry, back],
        ),
      _ => (
          Icons.error_outline,
          error == null ? l.errorCameraFailure : errorMessage(l, error),
          [retry, back],
        ),
    };

    return SingleChildScrollView(
      child: Semantics(
        liveRegion: true,
        child: MessageView(
          icon: icon,
          title: phaseLabel(l, state.phase),
          message: message,
          actions: actions,
        ),
      ),
    );
  }
}
