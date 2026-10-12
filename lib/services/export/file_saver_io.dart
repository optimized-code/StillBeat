import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Writes the export to the app's temporary directory and opens the system
/// share sheet. The temporary file is deleted after the sheet closes.
Future<void> saveTextFile({
  required String fileName,
  required String content,
  required String mimeType,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(content, flush: true);
  try {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: mimeType)]),
    );
  } finally {
    if (await file.exists()) await file.delete();
  }
}
