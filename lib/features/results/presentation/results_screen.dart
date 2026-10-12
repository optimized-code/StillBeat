import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../services/rppg/rppg_engine.dart';
import '../../../shared/widgets/charts.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/labels.dart';
import '../../history/presentation/history_providers.dart';
import '../../measurement/domain/measurement_result.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  bool _saved = false;
  bool _busy = false;

  Future<void> _save(MeasurementResult r) async {
    setState(() => _busy = true);
    try {
      final record = recordFromResult(
        r,
        faceLocatorId: ref.read(pendingLocatorIdProvider),
      );
      await ref.read(historyActionsProvider).save(record);
      if (!mounted) return;
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.resultsSaved)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorStorageFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _leave(String route) {
    ref.read(pendingResultProvider.notifier).state = null;
    if (route == Routes.home) {
      context.go(Routes.home);
    } else {
      context.pushReplacement(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = ref.watch(pendingResultProvider);
    if (r == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.resultsTitle)),
        body: Center(
          child: MessageView(
            icon: Icons.inbox_outlined,
            message: l.resultsNone,
            actions: [
              FilledButton(
                onPressed: () => context.go(Routes.home),
                child: Text(l.commonClose),
              ),
            ],
          ),
        ),
      );
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Scaffold(
      appBar: AppBar(
        title: Text(l.resultsTitle),
        leading: IconButton(
          tooltip: l.commonClose,
          icon: const Icon(Icons.close),
          onPressed: () => _leave(Routes.home),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    title: l.resultsHeartRate,
                    trailing: QualityBadge(r.quality),
                    child: Semantics(
                      label: '${l.resultsHeartRate}: '
                          '${r.heartRateBpm.round()} ${l.commonBpm}',
                      excludeSemantics: true,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            r.heartRateBpm.round().toString(),
                            style: context.text.displayLarge,
                          ),
                          const SizedBox(width: Space.sm),
                          Text(l.commonBpm, style: context.text.titleLarge),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  const DisclaimerNote(),
                  const SizedBox(height: Space.md),
                  SectionCard(
                    title: l.resultsWaveform,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WaveformView(
                          samples: r.waveform,
                          semanticLabel: l.measureWaveformLabel,
                        ),
                        const SizedBox(height: Space.sm),
                        Text(l.resultsWaveformHelp,
                            style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  SectionCard(
                    child: Column(
                      children: [
                        KeyValueRow(
                          label: l.resultsDate,
                          value: DateFormat.yMMMd(locale)
                              .add_jm()
                              .format(r.startedAtUtc.toLocal()),
                        ),
                        KeyValueRow(
                          label: l.resultsDuration,
                          value: l.resultsDurationValue(
                            r.durationMilliseconds ~/ 1000,
                          ),
                        ),
                        KeyValueRow(
                          label: l.resultsQuality,
                          value: qualityLabel(l, r.quality),
                        ),
                        KeyValueRow(
                          label: l.resultsConsistency,
                          value: l.resultsConsistencyValue(
                            r.validWindowCount,
                            r.totalWindowCount,
                            (r.interquartileRangeBpm / 2).toStringAsFixed(1),
                          ),
                        ),
                        KeyValueRow(
                          label: l.resultsAlgorithm,
                          value: '${r.algorithm.displayName} '
                              'v${r.algorithm.version}\n'
                              '${r.algorithm.kind == AlgorithmKind.neuralNetwork ? l.resultsAlgorithmKindNeural : l.resultsAlgorithmKindSignal}',
                        ),
                        const SizedBox(height: Space.sm),
                        Text(l.resultsConsistencyHelp,
                            style: context.text.bodySmall),
                        const SizedBox(height: Space.sm),
                        Text(l.qualityExplanation,
                            style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  SectionCard(
                    title: l.resultsLimitations,
                    child: Text(
                      l.resultsLimitationsBody,
                      style: context.text.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: Space.xl),
                  if (!_saved)
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _save(r),
                      icon: const Icon(Icons.save_outlined),
                      label: Text(l.resultsSave),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => _leave(Routes.history),
                      icon: const Icon(Icons.history),
                      label: Text(l.homeViewHistory),
                    ),
                  const SizedBox(height: Space.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _leave(Routes.measure),
                          child: Text(l.resultsRetry),
                        ),
                      ),
                      if (!_saved) ...[
                        const SizedBox(width: Space.md),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _leave(Routes.home),
                            child: Text(l.resultsDiscard),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
