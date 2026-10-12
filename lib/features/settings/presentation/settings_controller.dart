import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../services/rppg/window_analyzer.dart';
import '../domain/app_settings.dart';

/// Settings loaded before the first frame (bootstrap override) so routing
/// can decide whether onboarding is needed without a loading flash.
final initialSettingsProvider =
    Provider<AppSettings>((ref) => const AppSettings());

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(initialSettingsProvider);

  Future<void> _update(AppSettings next) async {
    final previous = state;
    state = next;
    try {
      await ref.read(settingsRepositoryProvider).save(next);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _update(state.copyWith(themeMode: mode));

  Future<void> setLocale(String? code) =>
      _update(state.copyWith(localeCode: () => code));

  Future<void> setMeasurementSeconds(int seconds) {
    if (!AppSettings.allowedMeasurementSeconds.contains(seconds)) {
      throw ArgumentError.value(seconds, 'seconds');
    }
    return _update(state.copyWith(measurementSeconds: seconds));
  }

  Future<void> setMethod(PulseMethod method) =>
      _update(state.copyWith(method: method));

  Future<void> acknowledgeDisclaimer() => _update(
        state.copyWith(
          acknowledgedDisclaimerVersion: AppSettings.currentDisclaimerVersion,
        ),
      );

  /// Resets to defaults after "delete all data".
  Future<void> resetAfterDataDeletion() async {
    await ref.read(settingsRepositoryProvider).clear();
    state = const AppSettings();
  }
}
