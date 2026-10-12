import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Triggers a browser download of a Blob. Nothing is uploaded.
Future<void> saveTextFile({
  required String fileName,
  required String content,
  required String mimeType,
}) async {
  final blob = web.Blob(
    [content.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.append(a);
  a.click();
  a.remove();
  // Revoke after the click has been handled so the download can start.
  Future<void>.delayed(const Duration(seconds: 1), () {
    web.URL.revokeObjectURL(url);
  });
}
