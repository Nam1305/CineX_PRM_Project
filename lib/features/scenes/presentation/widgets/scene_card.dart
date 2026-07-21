import 'package:flutter/material.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/core/widgets/adaptive_image.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';

class SceneCard extends StatelessWidget {
  final Scene scene;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isWritable;
  final void Function(SceneStatus newStatus)? onStatusChanged;

  const SceneCard({
    super.key,
    required this.scene,
    required this.onEdit,
    required this.onDelete,
    this.isWritable = true,
    this.onStatusChanged,
  });

  Color _statusColor(SceneStatus s, ColorScheme cs) {
    switch (s) {
      case SceneStatus.todo:
        return cs.outline;
      case SceneStatus.inProgress:
        return cs.primary;
      case SceneStatus.done:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(scene.status, theme.colorScheme)
              .withValues(alpha: 0.15),
          child: Text('${scene.sceneNumber}',
              style: TextStyle(
                  color: _statusColor(scene.status, theme.colorScheme),
                  fontWeight: FontWeight.bold)),
        ),
        title: Text(scene.fullFormattedTitle,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFFFF571A))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (scene.summary != null && scene.summary!.isNotEmpty)
              Text(scene.summary!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall),
            if (scene.characters.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: scene.characters.take(5).map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundImage: c.imagePath != null
                          ? adaptiveImageProvider(c.imagePath!)
                          : null,
                      child: c.imagePath == null
                          ? Text(c.name[0],
                              style: const TextStyle(fontSize: 10))
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 6),
            // Inline status chip
            if (isWritable && onStatusChanged != null)
              _InlineStatusSelector(
                currentStatus: scene.status,
                onChanged: onStatusChanged!,
              )
            else
              Chip(
                label: Text(
                  scene.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: _statusColor(scene.status, theme.colorScheme),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: _statusColor(scene.status, theme.colorScheme)
                    .withValues(alpha: 0.12),
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        trailing: isWritable
            ? PopupMenuButton<String>(
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                  const PopupMenuItem(value: 'delete', child: Text('Xoá')),
                ],
                onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
              )
            : null,
        isThreeLine: true,
      ),
    );
  }
}

class _InlineStatusSelector extends StatelessWidget {
  final SceneStatus currentStatus;
  final void Function(SceneStatus) onChanged;

  const _InlineStatusSelector({
    required this.currentStatus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: SceneStatus.values.map((status) {
        final isSelected = status == currentStatus;
        Color color;
        switch (status) {
          case SceneStatus.todo:
            color = theme.colorScheme.outline;
            break;
          case SceneStatus.inProgress:
            color = theme.colorScheme.primary;
            break;
          case SceneStatus.done:
            color = Colors.green;
            break;
        }
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: isSelected ? null : () => onChanged(status),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade700,
                  width: isSelected ? 1.5 : 0.8,
                ),
              ),
              child: Text(
                status.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
