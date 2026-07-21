import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/acts/providers/act_provider.dart';
import 'package:cinex_application/features/scenes/providers/scene_provider.dart';
import 'package:cinex_application/shared/widgets/empty_state_widget.dart';
import 'package:cinex_application/shared/widgets/confirm_dialog.dart';
import 'package:cinex_application/features/acts/presentation/widgets/act_expansion_tile.dart';
import 'package:cinex_application/features/acts/presentation/screens/act_form_screen.dart';
import 'package:cinex_application/features/auth/providers/auth_provider.dart';
import 'package:cinex_application/shared/widgets/pagination_bar.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/notifications/providers/notification_provider.dart';
import 'package:cinex_application/features/notifications/data/models/notification_model.dart';
import 'scene_form_screen.dart';

class StoryboardTab extends StatefulWidget {
  final int projectId;
  const StoryboardTab({super.key, required this.projectId});

  @override
  State<StoryboardTab> createState() => _StoryboardTabState();
}

class _StoryboardTabState extends State<StoryboardTab> {
  bool _initialized = false;
  int _currentPage = 1;
  static const int _itemsPerPage = 4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final actProvider = context.read<ActProvider>();
      final sceneProvider = context.read<SceneProvider>();
      actProvider.loadActs(widget.projectId).then((_) {
        for (final act in actProvider.acts) {
          sceneProvider.loadScenesForAct(act.id!);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isWritable = auth.isScreenwriter;

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

          // Phân trang
          final totalItems = actProvider.acts.length;
          final totalPages = (totalItems / _itemsPerPage).ceil();

          if (_currentPage > totalPages && totalPages > 0) {
            _currentPage = totalPages;
          }

          final startIndex = (_currentPage - 1) * _itemsPerPage;
          final endIndex = startIndex + _itemsPerPage > totalItems ? totalItems : startIndex + _itemsPerPage;
          final paginatedActs = actProvider.acts.sublist(startIndex, endIndex);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: paginatedActs.length,
                  itemBuilder: (context, i) {
                    final act = paginatedActs[i];
                    final scenes = sceneProvider.scenesForAct(act.id!);
                    return ActExpansionTile(
                      key: ValueKey('act_${act.id}'),
                      act: act,
                      scenes: scenes,
                      isWritable: isWritable,
                      initiallyExpanded: false,
                      onAddScene: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SceneFormScreen(
                            projectId: widget.projectId,
                            actId: act.id!,
                          ),
                        ),
                      ),
                      onSceneStatusChanged: (scene, newStatus) async {
                        final ok = await context.read<SceneProvider>().updateSceneStatus(scene, newStatus);
                        if (ok && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã cập nhật trạng thái cảnh sang ${newStatus.label}'),
                              backgroundColor: Colors.green.shade700,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      onEditScene: (scene) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SceneFormScreen(
                            projectId: widget.projectId,
                            actId: act.id!,
                            scene: scene,
                          ),
                        ),
                      ),
                      onDeleteScene: (scene) async {
                        final sceneProvider = context.read<SceneProvider>();
                        final messenger = ScaffoldMessenger.of(context);
                        final confirmed = await ConfirmDialog.show(
                          context,
                          title: 'Xoá cảnh',
                          content: 'Xoá Cảnh ${scene.sceneNumber}?',
                        );
                        if (!confirmed) return;
                        await sceneProvider.removeScene(scene.id!, act.id!);
                        if (context.mounted) {
                          context.read<NotificationProvider>().addNotification(
                                projectId: widget.projectId,
                                projectTitle: 'Dự án CineX #${widget.projectId}',
                                actId: act.id,
                                sceneId: scene.id,
                                title: 'Xóa Cảnh ${scene.sceneNumber}',
                                body: 'Cảnh ${scene.sceneNumber}: ${scene.title} đã bị xóa khỏi ${act.title}.',
                                actionType: NotificationActionType.delete,
                              );
                        }
                        messenger.showSnackBar(
                          SnackBar(
                            content: const Text('Đã xoá cảnh'),
                            backgroundColor: Colors.green.shade700,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      onEditAct: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActFormScreen(
                            projectId: widget.projectId,
                            act: act,
                          ),
                        ),
                      ),
                      onDeleteAct: () async {
                        final actProvider = context.read<ActProvider>();
                        final messenger = ScaffoldMessenger.of(context);
                        final confirmed = await ConfirmDialog.show(
                          context,
                          title: 'Xoá hồi',
                          content: 'Xoá "${act.title}" và toàn bộ cảnh bên trong?',
                        );
                        if (!confirmed) return;
                        await actProvider.removeAct(act.id!);
                        if (context.mounted) {
                          context.read<NotificationProvider>().addNotification(
                                projectId: widget.projectId,
                                projectTitle: 'Dự án CineX #${widget.projectId}',
                                actId: act.id,
                                title: 'Xóa Hồi: ${act.title}',
                                body: 'Hồi "${act.title}" đã bị xóa khỏi dự án.',
                                actionType: NotificationActionType.delete,
                              );
                        }
                        messenger.showSnackBar(
                          SnackBar(
                            content: const Text('Đã xoá hồi'),
                            backgroundColor: Colors.green.shade700,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              PaginationBar(
                currentPage: _currentPage,
                totalPages: totalPages,
                totalItems: totalItems,
                itemsPerPage: _itemsPerPage,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: isWritable
          ? FloatingActionButton(
              heroTag: 'add_act_fab',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActFormScreen(projectId: widget.projectId),
                ),
              ),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
