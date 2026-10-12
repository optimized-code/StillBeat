import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../services/export/export_service.dart';
import '../../../shared/widgets/charts.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/labels.dart';
import '../domain/measurement_record.dart';
import 'history_providers.dart';

/// Runs an export and reports the outcome in a snackbar.
Future<void> runExport(
  BuildContext context,
  WidgetRef ref,
  ExportFormat format,
) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final any = await ref.read(historyActionsProvider).exportAll(format);
    messenger.showSnackBar(
      SnackBar(
          content: Text(any ? l.historyExported : l.historyNothingToExport)),
    );
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l.errorExportFailed)));
  }
}

Future<void> runDeleteAllMeasurements(
    BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final ok = await confirmDialog(
    context,
    message: l.historyDeleteAllConfirm,
    confirmLabel: l.commonDelete,
  );
  if (!ok || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(historyActionsProvider).deleteAll();
    messenger.showSnackBar(SnackBar(content: Text(l.historyDeleted)));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l.errorStorageFailed)));
  }
}

enum _MenuAction { exportJson, exportCsv, deleteAll }

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final history = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.historyTitle),
        actions: [
          PopupMenuButton<_MenuAction>(
            onSelected: (a) => switch (a) {
              _MenuAction.exportJson =>
                runExport(context, ref, ExportFormat.json),
              _MenuAction.exportCsv =>
                runExport(context, ref, ExportFormat.csv),
              _MenuAction.deleteAll => runDeleteAllMeasurements(context, ref),
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _MenuAction.exportJson,
                child: Text(l.historyExportJson),
              ),
              PopupMenuItem(
                value: _MenuAction.exportCsv,
                child: Text(l.historyExportCsv),
              ),
              PopupMenuItem(
                value: _MenuAction.deleteAll,
                child: Text(l.historyDeleteAll),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _FilterBar(),
                  const SizedBox(height: Space.lg),
                  history.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(Space.xxl),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => MessageView(
                      icon: Icons.error_outline,
                      message: l.historyError,
                      actions: [
                        FilledButton(
                          onPressed: () => ref.invalidate(historyProvider),
                          child: Text(l.commonRetry),
                        ),
                      ],
                    ),
                    data: (page) => _HistoryBody(
                      records: page.records,
                      corrupted: page.skippedCorrupted,
                    ),
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

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final filter = ref.watch(historyFilterProvider);
    void set(HistoryFilter f) =>
        ref.read(historyFilterProvider.notifier).state = f;

    Widget chip(HistoryRange r, String label, VoidCallback onTap) => ChoiceChip(
          label: Text(label),
          selected: filter.range == r,
          onSelected: (_) => onTap(),
        );

    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      children: [
        chip(HistoryRange.last7Days, l.historyFilter7d,
            () => set(const HistoryFilter(range: HistoryRange.last7Days))),
        chip(HistoryRange.last30Days, l.historyFilter30d,
            () => set(const HistoryFilter(range: HistoryRange.last30Days))),
        chip(HistoryRange.all, l.historyFilterAll,
            () => set(const HistoryFilter())),
        chip(HistoryRange.custom, l.historyFilterCustom, () async {
          final now = DateTime.now();
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(now.year - 5),
            lastDate: now,
          );
          if (picked == null) return;
          set(
            HistoryFilter(
              range: HistoryRange.custom,
              from: picked.start,
              to: picked.end.add(const Duration(days: 1)),
            ),
          );
        }),
      ],
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({required this.records, required this.corrupted});
  final List<MeasurementRecord> records;
  final int corrupted;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (corrupted > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: Text(
              l.historyCorrupted(corrupted),
              style:
                  context.text.bodySmall?.copyWith(color: context.colors.error),
            ),
          ),
        SectionCard(
          title: l.historyTrend,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (records.length < 2)
                Text(l.historyTrendNeedsMore, style: context.text.bodyMedium)
              else
                TrendChart(
                  semanticLabel: l.historyTrend,
                  points: [
                    for (final r in records)
                      TrendPoint(r.timestampUtc, r.heartRateBpm),
                  ],
                ),
              const SizedBox(height: Space.sm),
              Text(l.historyTrendNote, style: context.text.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: Space.lg),
        if (records.isEmpty)
          MessageView(icon: Icons.inbox_outlined, message: l.historyEmpty)
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < records.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    title: Text(
                      '${records[i].heartRateBpm.round()} ${l.commonBpm}',
                      style: context.text.titleMedium,
                    ),
                    subtitle: Text(
                      DateFormat.yMMMd(locale)
                          .add_jm()
                          .format(records[i].timestampUtc.toLocal()),
                    ),
                    trailing: QualityBadge(records[i].signalQuality),
                    onTap: () =>
                        context.push(Routes.historyDetail(records[i].id)),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
