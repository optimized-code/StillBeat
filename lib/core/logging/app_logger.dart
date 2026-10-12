import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warn, error }

/// Structured logger with redaction.
///
/// Policy: logs carry technical diagnostics only. Field names that could
/// carry health values, signal samples, image data or identifiers are
/// dropped before anything is emitted, so a careless call site cannot leak
/// them. No log sink leaves the device; there is no remote logging.
class AppLogger {
  AppLogger(this.component);

  final String component;

  static LogLevel minimumLevel = kReleaseMode ? LogLevel.warn : LogLevel.debug;

  /// Test hook to capture output.
  static void Function(String line)? sinkOverride;

  static final RegExp _sensitiveKey = RegExp(
    r'(bpm|heart|pulse|resp|signal|sample|frame|pixel|image|face|rgb|'
    r'waveform|wave|path|file|user|name|email|id$|device|label)',
    caseSensitive: false,
  );

  static Map<String, Object?> redact(Map<String, Object?> fields) => {
        for (final e in fields.entries)
          e.key:
              _sensitiveKey.hasMatch(e.key) ? '<redacted>' : _scalar(e.value),
      };

  static Object? _scalar(Object? v) =>
      v == null || v is num || v is bool || v is String
          ? v
          : v.runtimeType.toString();

  void debug(String event, [Map<String, Object?> fields = const {}]) =>
      _log(LogLevel.debug, event, fields);
  void info(String event, [Map<String, Object?> fields = const {}]) =>
      _log(LogLevel.info, event, fields);
  void warn(String event, [Map<String, Object?> fields = const {}]) =>
      _log(LogLevel.warn, event, fields);
  void error(String event, [Map<String, Object?> fields = const {}]) =>
      _log(LogLevel.error, event, fields);

  void _log(LogLevel level, String event, Map<String, Object?> fields) {
    if (level.index < minimumLevel.index) return;
    final safe = redact(fields);
    final line = '[${level.name}] $component: $event'
        '${safe.isEmpty ? '' : ' $safe'}';
    final sink = sinkOverride;
    if (sink != null) {
      sink(line);
    } else {
      developer.log(line, name: 'stillbeat', level: 500 + level.index * 300);
    }
  }
}
