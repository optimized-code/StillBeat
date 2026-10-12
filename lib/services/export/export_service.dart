import 'dart:convert';

import '../../core/errors/app_error.dart';
import '../../features/history/domain/measurement_record.dart';
import 'file_saver_stub.dart'
    if (dart.library.io) 'file_saver_io.dart'
    if (dart.library.js_interop) 'file_saver_web.dart';

enum ExportFormat { json, csv }

/// Builds export documents. Only measurement summaries are included: no
/// device model, OS version, advertising IDs, locale or account data.
class ExportBuilder {
  const ExportBuilder({required this.appName, required this.appVersion});

  final String appName;
  final String appVersion;

  static const int exportSchemaVersion = 1;
  static const String disclaimer =
      'Experimental camera-based estimates for informational and research '
      'purposes only. Not a medical diagnosis; do not use for medical '
      'decisions.';

  String buildJson(List<MeasurementRecord> records, {DateTime? nowUtc}) {
    final doc = {
      'format': 'stillbeat-rppg-export',
      'exportSchemaVersion': exportSchemaVersion,
      'exportedAtUtc': (nowUtc ?? DateTime.now().toUtc()).toIso8601String(),
      'app': {'name': appName, 'version': appVersion},
      'disclaimer': disclaimer,
      'measurements': [for (final r in records) r.toJson()],
    };
    return const JsonEncoder.withIndent('  ').convert(doc);
  }

  static const csvColumns = [
    'id',
    'timestamp_utc',
    'duration_ms',
    'heart_rate_bpm',
    'respiratory_rate_bpm',
    'signal_quality',
    'snr_db',
    'peak_prominence',
    'window_iqr_bpm',
    'algorithm_id',
    'algorithm_version',
    'model_version',
  ];

  String buildCsv(List<MeasurementRecord> records) {
    final b = StringBuffer()..writeln(csvColumns.join(','));
    for (final r in records) {
      final m = r.qualityMetrics;
      final row = [
        r.id,
        r.timestampUtc.toUtc().toIso8601String(),
        '${r.durationMilliseconds}',
        r.heartRateBpm.toStringAsFixed(1),
        r.respiratoryRateBpm?.toStringAsFixed(1) ?? '',
        r.signalQuality.name,
        m.snrDb?.toStringAsFixed(2) ?? '',
        m.peakProminence?.toStringAsFixed(2) ?? '',
        m.stabilityBpm?.toStringAsFixed(2) ?? '',
        r.algorithmId,
        r.algorithmVersion,
        r.modelVersion ?? '',
      ];
      b.writeln(row.map(_csvEscape).join(','));
    }
    return b.toString();
  }

  static String _csvEscape(String v) {
    // Neutralise spreadsheet formula injection as well as quoting.
    var s = v;
    if (s.isNotEmpty && '=+-@'.contains(s[0]) && double.tryParse(s) == null) {
      s = "'$s";
    }
    if (s.contains(RegExp(r'[",\n\r]'))) {
      s = '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}

/// Hands an export to the platform (share sheet on mobile, download on web).
class ExportService {
  const ExportService(this.builder);

  final ExportBuilder builder;

  Future<void> export(
      List<MeasurementRecord> records, ExportFormat format) async {
    final now = DateTime.now().toUtc();
    final stamp = now.toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final (content, ext, mime) = switch (format) {
      ExportFormat.json => (
          builder.buildJson(records, nowUtc: now),
          'json',
          'application/json'
        ),
      ExportFormat.csv => (builder.buildCsv(records), 'csv', 'text/csv'),
    };
    try {
      await saveTextFile(
        fileName: 'stillbeat-measurements-$stamp.$ext',
        content: content,
        mimeType: mime,
      );
    } on AppError {
      rethrow;
    } catch (e) {
      throw ExportError(e.runtimeType.toString());
    }
  }
}
