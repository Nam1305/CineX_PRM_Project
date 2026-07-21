import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/features/acts/data/models/act.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/features/acts/providers/act_provider.dart';
import 'package:cinex_application/features/scenes/providers/scene_provider.dart';
import 'package:cinex_application/shared/widgets/app_snackbar.dart';
import 'package:cinex_application/shared/widgets/empty_state_widget.dart';

class TrashBinScreen extends StatefulWidget {
  final int projectId;
  const TrashBinScreen({super.key, required this.projectId});

  @override
  State<TrashBinScreen> createState() => _TrashBinScreenState();
}

class _TrashBinScreenState extends State<TrashBinScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabController;
  
  List<Act> _deletedActs = [];
  List<Scene> _deletedScenes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrashData();
  }

  Future<void> _loadTrashData() async {
    setState(() => _isLoading = true);
    try {
      final acts = await _api.getDeletedActs(widget.projectId);
      final scenes = await _api.getDeletedScenes(widget.projectId);
      if (mounted) {
        setState(() {
          _deletedActs = acts;
          _deletedScenes = scenes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('TrashBinScreen._loadTrashData error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restoreAct(Act act) async {
    final actProvider = context.read<ActProvider>();
    final sceneProvider = context.read<SceneProvider>();
    
    final ok = await actProvider.restoreAct(act.id!, widget.projectId);
    if (ok) {
      if (mounted) {
        AppSnackbar.success(context, 'Đã khôi phục Hồi "${act.title}" cùng các cảnh quay');
      }
      // Khởi động lại dữ liệu cảnh trong provider cho Hồi này
      await sceneProvider.loadScenesForAct(act.id!);
      _loadTrashData();
    } else {
      if (mounted) {
        AppSnackbar.error(context, 'Khôi phục Hồi thất bại');
      }
    }
  }

  Future<void> _restoreScene(Scene scene) async {
    final sceneProvider = context.read<SceneProvider>();
    final ok = await sceneProvider.restoreScene(scene.id!, scene.actId);
    if (ok) {
      if (mounted) {
        AppSnackbar.success(context, 'Đã khôi phục Cảnh ${scene.sceneNumber}');
      }
      _loadTrashData();
    } else {
      if (mounted) {
        AppSnackbar.error(context, 'Khôi phục Cảnh thất bại');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thùng rác'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF571A),
          tabs: const [
            Tab(text: 'Hồi đã xoá'),
            Tab(text: 'Phân cảnh đã xoá'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActsList(),
                _buildScenesList(),
              ],
            ),
    );
  }

  Widget _buildActsList() {
    if (_deletedActs.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.layers_clear,
        message: 'Thùng rác trống',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _deletedActs.length,
      itemBuilder: (context, i) {
        final act = _deletedActs[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(act.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(act.summary ?? 'Không có tóm tắt'),
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _restoreAct(act),
              icon: const Icon(Icons.restore, size: 16),
              label: const Text('Khôi phục'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScenesList() {
    if (_deletedScenes.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.movie_outlined,
        message: 'Thùng rác trống',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _deletedScenes.length,
      itemBuilder: (context, i) {
        final scene = _deletedScenes[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              child: Text('${scene.sceneNumber}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: Text(scene.title.isNotEmpty ? scene.title : 'Cảnh không tiêu đề',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Thuộc Hồi: ${scene.location?.sceneLabel ?? "Không rõ bối cảnh"}'),
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _restoreScene(scene),
              icon: const Icon(Icons.restore, size: 16),
              label: const Text('Khôi phục'),
            ),
          ),
        );
      },
    );
  }
}
