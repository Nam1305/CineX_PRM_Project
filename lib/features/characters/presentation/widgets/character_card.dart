import 'package:flutter/material.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/core/widgets/adaptive_image.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/shared/widgets/confirm_dialog.dart';

class CharacterCard extends StatelessWidget {
  final Character character;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const CharacterCard({
    super.key,
    required this.character,
    required this.onTap,
    required this.onDelete,
  });

  Color _chipColor(RoleType role, ColorScheme cs) {
    switch (role) {
      case RoleType.main:
        return cs.primary;
      case RoleType.support:
        return cs.secondary;
      case RoleType.crowd:
        return cs.tertiary;
    }
  }

  Widget _fallbackAvatar(ThemeData theme) => Container(
    color: theme.colorScheme.surfaceContainerHighest,
    child: Icon(
      Icons.person,
      size: 48,
      color: theme.colorScheme.onSurfaceVariant,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: () async {
          final confirmed = await ConfirmDialog.show(
            context,
            title: 'Xoá nhân vật',
            content: 'Xoá "${character.name}" khỏi dự án?',
          );
          if (confirmed) onDelete();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: character.imagePath != null
                  ? AdaptiveImage(
                      source: character.imagePath!,
                      placeholderBuilder: (_) => _fallbackAvatar(theme),
                    )
                  : _fallbackAvatar(theme),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    character.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(
                      character.roleType.label,
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: _chipColor(
                      character.roleType,
                      theme.colorScheme,
                    ).withValues(alpha: 0.2),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
