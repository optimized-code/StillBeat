import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/brand.dart';
import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/labels.dart';
import '../../history/domain/measurement_record.dart';
import '../../history/presentation/history_providers.dart';
import '../../settings/presentation/settings_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final platform = ref.watch(platformServicesProvider);
    final seconds = ref.watch(
      settingsControllerProvider.select((s) => s.measurementSeconds),
    );
    final history = ref.watch(allHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppBrand.name),
        actions: [
          IconButton(
            tooltip: l.homeSettings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
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
                  _Hero(
                    seconds: seconds,
                    supported: platform.supportsLiveMeasurement,
                    unsupportedReason: platform.unsupportedReason,
                  ),
                  const SizedBox(height: Space.lg),
                  history.when(
                    loading: () => const SectionCard(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => SectionCard(
                      child: Text(l.historyError),
                    ),
                    data: (page) => _LatestResult(records: page.records),
                  ),
                  const SizedBox(height: Space.lg),
                  const _Links(),
                  const SizedBox(height: Space.lg),
                  const DisclaimerNote(short: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.seconds,
    required this.supported,
    this.unsupportedReason,
  });

  final int seconds;
  final bool supported;
  final String? unsupportedReason;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Card(
      color: context.colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.monitor_heart_outlined,
              size: 40,
              color: context.colors.onPrimaryContainer,
            ),
            const SizedBox(height: Space.md),
            Text(
              l.appTagline,
              style: context.text.headlineSmall?.copyWith(
                color: context.colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: Space.sm),
            Text(
              l.homeIntro(seconds),
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: Space.xl),
            if (supported)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push(Routes.measure),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l.homeStartMeasurement),
                ),
              )
            else
              Text(
                l.homeUnsupported(unsupportedReason ?? ''),
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.onPrimaryContainer,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LatestResult extends StatelessWidget {
  const _LatestResult({required this.records});
  final List<MeasurementRecord> records;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (records.isEmpty) {
      return SectionCard(
        title: l.homeLatestResult,
        child: Text(l.homeNoResults, style: context.text.bodyMedium),
      );
    }
    final r = records.first;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return SectionCard(
      title: l.homeLatestResult,
      trailing: QualityBadge(r.signalQuality),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: '${r.heartRateBpm.round()} ${l.commonBpm}',
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  r.heartRateBpm.round().toString(),
                  style: context.text.displayMedium,
                ),
                const SizedBox(width: Space.sm),
                Text(l.commonBpm, style: context.text.titleMedium),
              ],
            ),
          ),
          Text(
            DateFormat.yMMMd(locale).add_jm().format(r.timestampUtc.toLocal()),
            style: context.text.bodySmall,
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.homeHistorySummary(records.length),
                  style: context.text.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: () => context.push(Routes.history),
                child: Text(l.homeViewHistory),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Links extends StatelessWidget {
  const _Links();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.science_outlined),
            title: Text(l.homeMethodology),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.about),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(l.homeViewHistory),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.history),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l.homePrivacy),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.privacy),
          ),
        ],
      ),
    );
  }
}
