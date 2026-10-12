import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/brand.dart';
import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/storage/app_database.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/export/export_service.dart';
import '../../../services/rppg/rppg_engine.dart';
import '../../../services/rppg/window_analyzer.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/labels.dart';
import '../../history/presentation/history_providers.dart';
import '../../history/presentation/history_screen.dart';
import '../domain/app_settings.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _guard(
      BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorStorageFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(settingsControllerProvider);
    final c = ref.read(settingsControllerProvider.notifier);
    final version = ref.watch(appVersionProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    title: l.settingsAppearance,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.settingsTheme, style: context.text.labelLarge),
                        const SizedBox(height: Space.sm),
                        SegmentedButton<ThemeMode>(
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text(l.settingsThemeSystem),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text(l.settingsThemeLight),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text(l.settingsThemeDark),
                            ),
                          ],
                          selected: {s.themeMode},
                          onSelectionChanged: (v) =>
                              _guard(context, () => c.setThemeMode(v.first)),
                        ),
                        const SizedBox(height: Space.lg),
                        DropdownButtonFormField<String?>(
                          value: s.localeCode,
                          decoration:
                              InputDecoration(labelText: l.settingsLanguage),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(l.settingsLanguageSystem),
                            ),
                            for (final loc in AppLocalizations.supportedLocales)
                              DropdownMenuItem(
                                value: loc.languageCode,
                                child: Text(_languageName(loc.languageCode)),
                              ),
                          ],
                          onChanged: (v) =>
                              _guard(context, () => c.setLocale(v)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  SectionCard(
                    title: l.settingsMeasurement,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.settingsDuration,
                            style: context.text.labelLarge),
                        const SizedBox(height: Space.sm),
                        SegmentedButton<int>(
                          segments: [
                            for (final sec
                                in AppSettings.allowedMeasurementSeconds)
                              ButtonSegment(
                                value: sec,
                                label: Text(l.settingsDurationValue(sec)),
                              ),
                          ],
                          selected: {s.measurementSeconds},
                          onSelectionChanged: (v) => _guard(
                            context,
                            () => c.setMeasurementSeconds(v.first),
                          ),
                        ),
                        const SizedBox(height: Space.lg),
                        Text(l.settingsAlgorithm,
                            style: context.text.labelLarge),
                        for (final m in PulseMethod.values)
                          RadioListTile<PulseMethod>(
                            value: m,
                            groupValue: s.method,
                            contentPadding: EdgeInsets.zero,
                            title: Text(AlgorithmInfo.forMethod(m).displayName),
                            subtitle: Text(l.resultsAlgorithmKindSignal),
                            onChanged: (v) {
                              if (v != null) {
                                _guard(context, () => c.setMethod(v));
                              }
                            },
                          ),
                        RadioListTile<PulseMethod?>(
                          value: null,
                          groupValue: s.method,
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.settingsNeuralUnavailable),
                          subtitle:
                              const Text(UnavailableNeuralRppgEngine.reason),
                          onChanged: null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  const _DataSection(),
                  const SizedBox(height: Space.md),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.science_outlined),
                          title: Text(l.settingsMethodology),
                          onTap: () => context.push(Routes.about),
                        ),
                        ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: Text(l.settingsPrivacy),
                          onTap: () => context.push(Routes.privacy),
                        ),
                        ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: Text(l.settingsLicenses),
                          onTap: () => showLicensePage(
                            context: context,
                            applicationName: AppBrand.name,
                            applicationVersion: version.display,
                          ),
                        ),
                        if (AppBrand.privacyPolicyUrl.isNotEmpty)
                          ListTile(
                            leading: const Icon(Icons.policy_outlined),
                            title: Text(l.settingsPrivacyPolicy),
                            subtitle:
                                const SelectableText(AppBrand.privacyPolicyUrl),
                          ),
                        if (AppBrand.supportUrl.isNotEmpty)
                          ListTile(
                            leading: const Icon(Icons.help_outline),
                            title: Text(l.settingsSupport),
                            subtitle: const SelectableText(AppBrand.supportUrl),
                          ),
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: Text(l.settingsVersion),
                          subtitle: Text('${AppBrand.name} ${version.display}'),
                        ),
                      ],
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

  static String _languageName(String code) => switch (code) {
        'en' => 'English',
        _ => code,
      };
}

class _DataSection extends ConsumerWidget {
  const _DataSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final degraded = ref.watch(storageDegradedProvider);
    return SectionCard(
      title: l.settingsData,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.settingsStorage(
              degraded ? 'in-memory (not persisted)' : storageBackendInfo.name,
            ),
            style: context.text.bodySmall,
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () => runExport(context, ref, ExportFormat.json),
                icon: const Icon(Icons.download_outlined),
                label: Text(l.historyExportJson),
              ),
              OutlinedButton.icon(
                onPressed: () => runExport(context, ref, ExportFormat.csv),
                icon: const Icon(Icons.table_chart_outlined),
                label: Text(l.historyExportCsv),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Text(l.settingsDeleteAllBody, style: context.text.bodySmall),
          const SizedBox(height: Space.sm),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.error,
            ),
            onPressed: () async {
              final ok = await confirmDialog(
                context,
                message: l.settingsDeleteAllBody,
                confirmLabel: l.commonDelete,
                title: l.settingsDeleteAll,
              );
              if (!ok || !context.mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(historyActionsProvider).deleteAll();
                await ref
                    .read(settingsControllerProvider.notifier)
                    .resetAfterDataDeletion();
                messenger.showSnackBar(
                  SnackBar(content: Text(l.settingsDeletedAll)),
                );
              } catch (_) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l.errorStorageFailed)),
                );
              }
            },
            icon: const Icon(Icons.delete_forever_outlined),
            label: Text(l.settingsDeleteAll),
          ),
        ],
      ),
    );
  }
}
