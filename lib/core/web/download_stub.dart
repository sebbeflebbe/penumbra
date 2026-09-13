typedef ExportDownloader = Future<void> Function(String filename, String json);

Future<void> downloadJsonFile({
  required String filename,
  required String contents,
}) async {
  throw UnsupportedError('JSON download is only available in the browser.');
}
