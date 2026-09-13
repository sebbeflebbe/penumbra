import 'download_stub.dart'
    if (dart.library.js_interop) 'download_web.dart';

export 'download_stub.dart' show ExportDownloader;

Future<void> downloadExportJson({
  required String filename,
  required String contents,
}) => downloadJsonFile(filename: filename, contents: contents);
