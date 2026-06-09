import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/acts/providers/act_provider.dart';
import 'package:cinex_application/features/scenes/providers/scene_provider.dart';
import 'package:cinex_application/shared/widgets/empty_state_widget.dart';
import 'package:cinex_application/shared/widgets/confirm_dialog.dart';
import 'package:cinex_application/features/acts/presentation/widgets/act_expansion_tile.dart';
import 'scene_form_screen.dart';

class StoryboardTab extends StatefulWidget {
  final int projectId;
  const StoryboardTab({super.key, required this.projectId});

  @override
  State<StoryboardTab> createState() => _StoryboardTabState();
}

class _StoryboardTabState extends State<StoryboardTab> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    // didChangeDependencies is synchronous — safe to use context here
    final actProvider = context.read<ActProvider>();
    final sceneProvider = context.read<SceneProvider>();
    actProvider.loadActs(widget.projectId).then((_) {
      for (final act in actProvider.acts) {
        sceneProvider.loadScenesForAct(act.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<ActProvider, SceneProvider>(
        builder: (context, actProvider, sceneProvider, _) {
          if (actProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (actProvider.acts.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.movie_filter_outlined,
              message: 'Chưa có hồi nào. Thêm hồi để bắt đầu.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: actProvider.acts.length,
            itemBuilder: (context, i) {
              final act = actProvider.acts[i];
              final scenes = sceneProvider.scenesForAct(act.id!);
              return ActExpansionTile(
                act: act,
                scenes: scenes,
                onAddScene: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SceneFormScreen(
                      actId: act.id!,
                      projectId: widget.projectId,
                    ),
                  ),
                ),
                onEditScene: (scene) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SceneFormScreen(
                      actId: act.id!,
                      projectId: widget.projectId,
                      scene: scene,
                    ),
                  ),
                ),
                onDeleteScene: (scene) async {
                  // Capture context-dependent objects before any await
                  final sceneProvider = context.read<SceneProvider>();
                  final messenger = ScaffoldMessenger.of(context);
                  final confirmed = await ConfirmDialog.show(
                    context,
                    title: 'Xoá cảnh',
                    content: 'Xoá Cảnh ${scene.sceneNumber}?',
                  );
                  if (!confirmed) return;
                  await sceneProvider.removeScene(scene.id!, act.id!);
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('Đã xoá cảnh'),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
