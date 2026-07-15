import 'dart:typed_data';

Future<String> saveAndDownloadFile({
  required Uint8List bytes,
  required String filename,
}) async {
  throw UnsupportedError('Cannot save file on this platform');
}
