import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Trên Flutter Web, `dart:io File` không thể đọc được (kể cả với blob URL
/// do image_picker trả về), nên bắt buộc phải dùng [CachedNetworkImage]. Trên
/// mobile/desktop, ImageUrl từ server là http nên cũng dùng network; chỉ
/// ảnh vừa chọn từ thiết bị (đường dẫn cục bộ) mới cần [Image.file].
bool _isNetworkSource(String source) =>
    source.startsWith('http://') || source.startsWith('https://');

class AdaptiveImage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (kIsWeb || _isNetworkSource(source)) {
      return CachedNetworkImage(
        imageUrl: source,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => placeholderBuilder(context),
        errorWidget: (context, url, error) => placeholderBuilder(context),
      );
    }
    return Image.file(
      File(source),
      fit: fit,
      errorBuilder: (context, error, stack) => placeholderBuilder(context),
    );
  }
}

/// Dùng cho các chỗ cần [ImageProvider] (vd. `CircleAvatar.backgroundImage`).
ImageProvider adaptiveImageProvider(String source) {
  if (kIsWeb || _isNetworkSource(source)) {
    return CachedNetworkImageProvider(source);
  }
  return FileImage(File(source));
}
