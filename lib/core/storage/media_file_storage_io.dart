import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String?> readOrWritePlatformMediaFile({
  required String cacheKey,
  required List<int> bytes,
  required String extension,
}) async {
  final directory = await getApplicationDocumentsDirectory();
  final mediaDirectory = Directory(p.join(directory.path, 'cinex_media'));
  await mediaDirectory.create(recursive: true);
  final file = File(p.join(mediaDirectory.path, '$cacheKey$extension'));
  if (!await file.exists()) {
    await file.writeAsBytes(bytes, flush: true);
  }
  return file.path;
}
