import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../services/rppg/rppg_engine.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/labels.dart';
import 'history_providers.dart';

class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final record = ref.watch(recordProvider(id));
    final locale = Localizations.localeOf(context).toLanguageTag();
    String fmt(double? v, [int digits = 1]) =>
        v == null ? l.commonNotAvailable : v.toStringAsFixed(digits);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.historyDetailTitle),
        actions: [
          IconButton(
            tooltip: l.commonDelete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await confirmDialog(
                context,
                message: l.historyDeleteOneConfirm,
                confirmLabel: l.commonDelete,
              );
              if (!ok || !context.mounted) return;
              try {
                await ref.read(historyActionsProvider).delete(id);
                if (context.mounted) context.pop();
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.errorStorageFailed)),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: record.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child:
                MessageView(icon: Icons.error_outline, message: l.historyError),
          ),
          data: (r) {
            if (r == null) {
              return Center(
                child: MessageView(
                    icon: Icons.inbox_outlined, message: l.resultsNone),
              );
            }
            final algo = AlgorithmInfo.byId(r.algorithmId);
            final m = r.qualityMetrics;
            final meta = r.processingMetadata;
            return ListView(
              padding: const EdgeInsets.all(Space.lg),
              children: [
                ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionCard(
                        title: l.resultsHeartRate,
                        trailing: QualityBadge(r.signalQuality),
                        child: Text(
                          '${r.heartRateBpm.round()} ${l.commonBpm}',
                          style: context.text.displayMedium,
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
                                  .format(r.timestampUtc.toLocal()),
                            ),
                            KeyValueRow(
                              label: l.resultsDuration,
                              value: l.resultsDurationValue(
                                r.durationMilliseconds ~/ 1000,
                              ),
                            ),
                            KeyValueRow(
                              label: l.resultsAlgorithm,
                              value: '${algo?.displayName ?? r.algorithmId} '
                                  'v${r.algorithmVersion}',
                            ),
                            if (meta['validWindows'] is int &&
                                meta['totalWindows'] is int)
                              KeyValueRow(
                                label: l.resultsConsistency,
                                value: l.resultsConsistencyValue(
                                  meta['validWindows']! as int,
                                  meta['totalWindows']! as int,
                                  fmt((m.stabilityBpm ?? 0) / 2),
                                ),
                              ),
                            KeyValueRow(
                                label: l.metricSnr, value: fmt(m.snrDb)),
                            KeyValueRow(
                              label: l.metricProminence,
                              value: fmt(m.peakProminence),
                            ),
                            KeyValueRow(
                              label: l.metricFrameRate,
                              value: fmt(m.effectiveFrameRateHz),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.md),
                      Text(l.qualityExplanation, style: context.text.bodySmall),
                      const SizedBox(height: Space.md),
                      const DisclaimerNote(short: true),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
