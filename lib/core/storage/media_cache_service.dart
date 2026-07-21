import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'local_cache_service.dart';
import 'media_file_storage.dart';

/// Caches remote media without putting native image bytes in the SQLite file.
/// Web falls back to the SQLite/IndexedDB-backed media table.
class MediaCacheService {
  MediaCacheService._();

  static final instance = MediaCacheService._();
  final _cache = LocalCacheService.instance;
  static const maxCachedImageBytes = 10 * 1024 * 1024;

  Future<String> resolve(String source) async {
    if (!_isRemote(source)) return source;
    final cacheKey = _stableKey(source);
    final existing = await _cache.getMedia(cacheKey);
    if (existing != null) {
      if (kIsWeb && existing.bytes != null) {
        return _dataUri(existing.bytes!, existing.contentType);
      }
      if (!kIsWeb && existing.localPath != null) {
        return existing.localPath!;
      }
    }

    final response = await http.get(Uri.parse(source)).timeout(
      const Duration(seconds: 20),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Media download failed: ${response.statusCode}');
    }
    if (response.contentLength != null &&
        response.contentLength! > maxCachedImageBytes) {
      throw Exception('Media exceeds local cache limit');
    }
    final bodyBytes = response.bodyBytes;
    if (bodyBytes.length > maxCachedImageBytes) {
      throw Exception('Media exceeds local cache limit');
    }
    final contentType = _contentType(response.headers['content-type'], source);
    if (kIsWeb) {
      await _cache.putMedia(
        cacheKey: cacheKey,
        contentType: contentType,
        bytes: bodyBytes,
      );
      return _dataUri(bodyBytes, contentType);
    }

    final path = await readOrWriteMediaFile(
      cacheKey: cacheKey,
      bytes: bodyBytes,
      extension: _extension(contentType),
    );
    await _cache.putMedia(
      cacheKey: cacheKey,
      contentType: contentType,
      localPath: path,
    );
    return path ?? source;
  }
  bool _isRemote(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

  String _stableKey(String value) {
    var hash = 2166136261;
    for (final unit in utf8.encode(value)) {
      hash ^= unit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return 'm$hash';
  }

  String _contentType(String? header, String source) {
    final normalized = header?.split(';').first.trim().toLowerCase();
    if (normalized != null && normalized.startsWith('image/')) return normalized;
    if (source.toLowerCase().endsWith('.png')) return 'image/png';
    if (source.toLowerCase().endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _extension(String contentType) => switch (contentType) {
    'image/png' => '.png',
    'image/webp' => '.webp',
    _ => '.jpg',
  };

  String _dataUri(List<int> bytes, String contentType) =>
      'data:$contentType;base64,${base64Encode(bytes)}';
}
