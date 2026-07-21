import 'media_file_storage_stub.dart'
    if (dart.library.io) 'media_file_storage_io.dart';

Future<String?> readOrWriteMediaFile({
  required String cacheKey,
  required List<int> bytes,
  required String extension,
}) => readOrWritePlatformMediaFile(
      cacheKey: cacheKey,
      bytes: bytes,
      extension: extension,
    );
