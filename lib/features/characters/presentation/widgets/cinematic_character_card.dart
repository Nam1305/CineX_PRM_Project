import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/shared/widgets/confirm_dialog.dart';

class CinematicCharacterCard extends StatelessWidget {
  final Character character;
  final int sceneCount;
  final String status;
  final bool statusGreen;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CinematicCharacterCard({
    super.key,
    required this.character,
    required this.sceneCount,
    required this.status,
    required this.statusGreen,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: character.imagePath != null
                      ? Image.file(
                          File(character.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _fallbackImage(theme),
                        )
                      : _fallbackImage(theme),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Chip(
                    label: Text(
                      character.roleType.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    backgroundColor: theme.colorScheme.primary,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              character.name,
                              style: theme.textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              character.description ?? 'Không có mô tả',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            onTap: onEdit,
                            child: const Text('Sửa'),
                          ),
                          PopupMenuItem(
                            onTap: () async {
                              final confirmed = await ConfirmDialog.show(
                                context,
                                title: 'Xóa nhân vật',
                                content: 'Xóa "${character.name}" khỏi dự án?',
                              );
                              if (confirmed) onDelete();
                            },
                            child: const Text('Xóa'),
                          ),
                        ],
                        child: Icon(
                          Icons.more_vert,
                          size: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$sceneCount cảnh',
                        style: theme.textTheme.labelSmall,
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusGreen ? Colors.green : Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusGreen
                                  ? Colors.green
                                  : Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackImage(ThemeData theme) => Container(
    color: theme.colorScheme.surface,
    child: Icon(
      Icons.person,
      size: 64,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
    ),
  );
}
