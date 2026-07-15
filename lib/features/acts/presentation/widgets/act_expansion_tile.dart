import 'package:flutter/material.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/acts/data/models/act.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/features/scenes/presentation/widgets/scene_card.dart';

class ActExpansionTile extends StatefulWidget {
  final Act act;
  final List<Scene> scenes;
  final VoidCallback onAddScene;
  final void Function(Scene) onEditScene;
  final void Function(Scene) onDeleteScene;
  final void Function(Scene scene, SceneStatus newStatus)? onSceneStatusChanged;
  final VoidCallback? onEditAct;
  final VoidCallback? onDeleteAct;
  final bool isWritable;
  final bool initiallyExpanded;

  const ActExpansionTile({
    super.key,
    required this.act,
    required this.scenes,
    required this.onAddScene,
    required this.onEditScene,
    required this.onDeleteScene,
    this.onSceneStatusChanged,
    this.onEditAct,
    this.onDeleteAct,
    this.isWritable = true,
    this.initiallyExpanded = false,
  });

  @override
  State<ActExpansionTile> createState() => _ActExpansionTileState();
}

class _ActExpansionTileState extends State<ActExpansionTile> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant ActExpansionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initiallyExpanded != oldWidget.initiallyExpanded) {
      _isExpanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        initiallyExpanded: widget.initiallyExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        title: Text(widget.act.title,
            style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text('${widget.scenes.length} cảnh'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isWritable)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') widget.onEditAct?.call();
                  if (value == 'delete') widget.onDeleteAct?.call();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Sửa hồi')),
                  PopupMenuItem(value: 'delete', child: Text('Xoá hồi')),
                ],
              ),
            Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
          ],
        ),
        children: [
          ...widget.scenes.map((s) => SceneCard(
                scene: s,
                isWritable: widget.isWritable,
                onEdit: () => widget.onEditScene(s),
                onDelete: () => widget.onDeleteScene(s),
                onStatusChanged: widget.isWritable
                    ? (newStatus) => widget.onSceneStatusChanged?.call(s, newStatus)
                    : null,
              )),
          if (widget.isWritable)
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Thêm cảnh'),
              onTap: widget.onAddScene,
            ),
        ],
      ),
    );
  }
}
