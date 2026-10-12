import '../../core/errors/app_error.dart';

Future<void> saveTextFile({
  required String fileName,
  required String content,
  required String mimeType,
}) async =>
    throw const ExportError('unsupported platform');
