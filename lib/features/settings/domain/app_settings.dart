import 'package:flutter/material.dart';

import '../../../services/rppg/window_analyzer.dart';

/// User preferences. Contains no personal or health data.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.localeCode,
    this.measurementSeconds = 30,
    this.method = PulseMethod.pos,
    this.acknowledgedDisclaimerVersion = 0,
  });

  /// Bump when the limitations text materially changes so users
  /// re-acknowledge it.
  static const int currentDisclaimerVersion = 1;

  static const List<int> allowedMeasurementSeconds = [30, 45, 60];

  final ThemeMode themeMode;

  /// Null follows the system locale.
  final String? localeCode;
  final int measurementSeconds;
  final PulseMethod method;
  final int acknowledgedDisclaimerVersion;

  bool get hasAcknowledgedDisclaimer =>
      acknowledgedDisclaimerVersion >= currentDisclaimerVersion;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? Function()? localeCode,
    int? measurementSeconds,
    PulseMethod? method,
    int? acknowledgedDisclaimerVersion,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        localeCode: localeCode != null ? localeCode() : this.localeCode,
        measurementSeconds: measurementSeconds ?? this.measurementSeconds,
        method: method ?? this.method,
        acknowledgedDisclaimerVersion:
            acknowledgedDisclaimerVersion ?? this.acknowledgedDisclaimerVersion,
      );

  Map<String, Object?> toJson() => {
        'themeMode': themeMode.name,
        'localeCode': localeCode,
        'measurementSeconds': measurementSeconds,
        'method': method.name,
        'acknowledgedDisclaimerVersion': acknowledgedDisclaimerVersion,
      };

  /// Tolerant parser: unknown or invalid values fall back to defaults.
  factory AppSettings.fromJson(Map<String, Object?> j) {
    const d = AppSettings();
    final seconds = j['measurementSeconds'];
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == j['themeMode'],
        orElse: () => d.themeMode,
      ),
      localeCode: j['localeCode'] is String ? j['localeCode']! as String : null,
      measurementSeconds:
          seconds is int && allowedMeasurementSeconds.contains(seconds)
              ? seconds
              : d.measurementSeconds,
      method: PulseMethod.values.firstWhere(
        (m) => m.name == j['method'],
        orElse: () => d.method,
      ),
      acknowledgedDisclaimerVersion: j['acknowledgedDisclaimerVersion'] is int
          ? j['acknowledgedDisclaimerVersion']! as int
          : 0,
    );
  }
}
