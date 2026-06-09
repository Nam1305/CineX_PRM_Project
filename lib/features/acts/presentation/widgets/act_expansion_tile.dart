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

  const ActExpansionTile({
    super.key,
    required this.act,
    required this.scenes,
    required this.onAddScene,
    required this.onEditScene,
    required this.onDeleteScene,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        title: Text(act.title,
            style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text('${scenes.length} cảnh'),
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
