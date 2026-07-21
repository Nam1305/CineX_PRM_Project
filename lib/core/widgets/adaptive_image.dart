import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cinex_application/core/storage/media_cache_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

bool _isNetworkSource(String source) =>
    source.startsWith('http://') || source.startsWith('https://');

class AdaptiveImage extends StatefulWidget {
  final String source;
  final BoxFit fit;
  final WidgetBuilder placeholderBuilder;

  const AdaptiveImage({
    super.key,
    required this.source,
    required this.placeholderBuilder,
    this.fit = BoxFit.cover,
  });

  @override
  State<AdaptiveImage> createState() => _AdaptiveImageState();
}

class _AdaptiveImageState extends State<AdaptiveImage> {
  String? _resolvedSource;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant AdaptiveImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) _resolve();
  }

  Future<void> _resolve() async {
    final source = widget.source;
    if (!_isNetworkSource(source)) {
      if (mounted) setState(() => _resolvedSource = source);
      return;
    }
    try {
      final resolved = await MediaCacheService.instance.resolve(source);
      if (mounted && widget.source == source) {
        setState(() => _resolvedSource = resolved);
      }
    } catch (_) {
      if (mounted && widget.source == source) setState(() => _resolvedSource = source);
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = _resolvedSource;
    if (source == null) return widget.placeholderBuilder(context);

    if (source.startsWith('data:')) {
      final comma = source.indexOf(',');
      if (comma >= 0) {
        try {
          return Image.memory(
            base64Decode(source.substring(comma + 1)),
            fit: widget.fit,
            errorBuilder: (context, error, stack) =>
                widget.placeholderBuilder(context),
          );
        } catch (_) {
          return widget.placeholderBuilder(context);
        }
      }
    }

    if (kIsWeb || _isNetworkSource(source)) {
      return CachedNetworkImage(
        imageUrl: source,
        fit: widget.fit,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => widget.placeholderBuilder(context),
        errorWidget: (context, url, error) =>
            widget.placeholderBuilder(context),
      );
    }
    return Image.file(
      File(source),
      fit: widget.fit,
      errorBuilder: (context, error, stack) =>
          widget.placeholderBuilder(context),
    );
  }
}

ImageProvider adaptiveImageProvider(String source) {
  if (kIsWeb || _isNetworkSource(source)) {
    return CachedNetworkImageProvider(source);
  }
  return FileImage(File(source));
}
