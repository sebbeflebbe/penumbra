import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<void> downloadJsonFile({
  required String filename,
  required String contents,
}) async {
  final blob = web.Blob(
    [contents.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
