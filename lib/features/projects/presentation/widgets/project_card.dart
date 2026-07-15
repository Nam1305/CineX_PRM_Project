import 'package:flutter/material.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/shared/widgets/confirm_dialog.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isWritable;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.isWritable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: theme.colorScheme.primaryContainer,
                child: Center(
                  child: Icon(Icons.movie_creation_outlined,
                      size: 48, color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall),
                        if (project.genre != null && project.genre!.isNotEmpty)
                          Text(project.genre!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              )),
                      ],
                    ),
                  ),
                  if (isWritable)
                    PopupMenuButton<String>(
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                        const PopupMenuItem(value: 'delete', child: Text('Xoá')),
                      ],
                      onSelected: (v) async {
                        if (v == 'edit') {
                          onEdit();
                        } else {
                          final confirmed = await ConfirmDialog.show(
                            context,
                            title: 'Xoá dự án',
                            content:
                                'Toàn bộ dữ liệu của "${project.title}" sẽ bị xoá vĩnh viễn.',
                          );
                          if (confirmed) onDelete();
                        }
                      },
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
