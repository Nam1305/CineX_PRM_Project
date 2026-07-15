import 'dart:html' as html;
import 'dart:typed_data';

Future<String> saveAndDownloadFile({
  required Uint8List bytes,
  required String filename,
}) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = filename;
  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
  return 'Tải xuống trình duyệt';
}
