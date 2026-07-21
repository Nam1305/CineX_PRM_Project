import 'package:flutter/material.dart';
import 'adaptive_image.dart';

class ImageCard extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onTap;
  final double? height;
  final double aspectRatio;
  final String heroTag;

  const ImageCard({
    super.key,
    this.imageUrl,
    required this.onTap,
    this.height,
    this.aspectRatio = 1.0,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: heroTag,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surface,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl != null
                ? AdaptiveImage(
                    source: imageUrl!,
                    fit: BoxFit.cover,
                    placeholderBuilder: (_) => Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  )
                : _buildPlaceholder(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
