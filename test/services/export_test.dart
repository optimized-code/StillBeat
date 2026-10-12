import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stillbeat/services/export/export_service.dart';

import '../helpers/records.dart';

void main() {
  const builder = ExportBuilder(appName: 'TestApp', appVersion: '1.2.3+4');

  test('JSON export is versioned, includes disclaimer and records only', () {
    final json = builder.buildJson(
      [sampleRecord(id: 'a'), sampleRecord(id: 'b', bpm: 80)],
      nowUtc: DateTime.utc(2026, 1, 2),
    );
    final doc = jsonDecode(json) as Map<String, dynamic>;
    expect(doc['format'], 'stillbeat-rppg-export');
    expect(doc['exportSchemaVersion'], 1);
    expect(doc['exportedAtUtc'], '2026-01-02T00:00:00.000Z');
    expect(doc['disclaimer'], contains('Not a medical diagnosis'));
    expect((doc['measurements'] as List).length, 2);
    expect(doc['app'], {'name': 'TestApp', 'version': '1.2.3+4'});
    // No device/OS/locale identifiers.
    for (final k in ['device', 'os', 'platform', 'locale', 'user']) {
      expect(doc.containsKey(k), isFalse, reason: k);
    }
  });

  test('CSV export has a header row and one row per record', () {
    final csv = builder.buildCsv([sampleRecord(id: 'a', bpm: 71.26)]);
    final lines = const LineSplitter().convert(csv);
    expect(lines.first, ExportBuilder.csvColumns.join(','));
    expect(lines, hasLength(2));
    final cells = lines[1].split(',');
    expect(cells[0], 'a');
    expect(cells[3], '71.3');
    expect(cells[4], '');
    expect(cells[5], 'good');
  });

  test('CSV escapes quotes/commas and neutralises formula injection', () {
    final r = sampleRecord(id: '=HYPERLINK("x")');
    final csv = builder.buildCsv([r]);
    final row = const LineSplitter().convert(csv)[1];
    expect(row.startsWith('"\'=HYPERLINK(""x"")"'), isTrue, reason: row);
  });

  test('empty export still produces a valid document', () {
    final doc = jsonDecode(builder.buildJson(const [])) as Map<String, dynamic>;
    expect(doc['measurements'], isEmpty);
    expect(
        const LineSplitter().convert(builder.buildCsv(const [])), hasLength(1));
  });
}
