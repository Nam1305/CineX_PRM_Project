import 'package:flutter/material.dart';
import 'package:cinex_application/features/acts/data/models/act.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/features/scenes/presentation/widgets/scene_card.dart';

class ActExpansionTile extends StatelessWidget {
  final Act act;
  final List<Scene> scenes;
  final VoidCallback onAddScene;
  final void Function(Scene) onEditScene;
  final void Function(Scene) onDeleteScene;
  final VoidCallback? onEditAct;
  final VoidCallback? onDeleteAct;

  const ActExpansionTile({
    super.key,
    required this.act,
    required this.scenes,
    required this.onAddScene,
    required this.onEditScene,
    required this.onDeleteScene,
    this.onEditAct,
    this.onDeleteAct,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        title: Text(act.title,
            style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text('${scenes.length} cảnh'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEditAct?.call();
            if (value == 'delete') onDeleteAct?.call();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Sửa hồi')),
            PopupMenuItem(value: 'delete', child: Text('Xoá hồi')),
          ],
        ),
        children: [
          ...scenes.map((s) => SceneCard(
                scene: s,
                onEdit: () => onEditScene(s),
                onDelete: () => onDeleteScene(s),
              )),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Thêm cảnh'),
            onTap: onAddScene,
          ),
        ],
      ),
    );
  }
}
