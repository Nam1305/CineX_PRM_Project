import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<String> saveAndDownloadFile({
  required Uint8List bytes,
  required String filename,
}) async {
  String path;
  try {
    final directory = await getApplicationDocumentsDirectory();
    path = '${directory.path}/$filename';
  } catch (e) {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && Directory(userProfile).existsSync()) {
        final docsDir = Directory('$userProfile\\Documents');
        if (docsDir.existsSync()) {
          path = '${docsDir.path}\\$filename';
        } else {
          path = '$userProfile\\$filename';
        }
      } else {
        path = '.\\$filename';
      }
    } else {
      final tempDir = Directory.systemTemp;
      path = '${tempDir.path}/$filename';
    }
  }

  final file = File(path);
  await file.writeAsBytes(bytes);
  return path;
}
