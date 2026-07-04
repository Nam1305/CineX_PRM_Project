import 'package:flutter/material.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/core/widgets/adaptive_image.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';

class SceneCard extends StatelessWidget {
  final Scene scene;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SceneCard({
    super.key,
    required this.scene,
    required this.onEdit,
    required this.onDelete,
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
        title: Text(scene.location?.sceneLabel ?? 'Chưa có bối cảnh',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
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
          ],
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Sửa')),
            const PopupMenuItem(value: 'delete', child: Text('Xoá')),
          ],
          onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
        ),
        isThreeLine: scene.characters.isNotEmpty,
      ),
    );
  }
}
