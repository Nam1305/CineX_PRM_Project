import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/features/scenes/presentation/screens/storyboard_tab.dart';
import 'package:cinex_application/features/characters/presentation/screens/characters_tab.dart';
import 'package:cinex_application/features/locations/presentation/screens/locations_tab.dart';
import 'package:cinex_application/features/production/presentation/screens/production_tab.dart';
import 'package:cinex_application/features/workspace/presentation/screens/trash_bin_screen.dart';
import 'package:cinex_application/features/acts/providers/act_provider.dart';
import 'package:cinex_application/features/scenes/providers/scene_provider.dart';

class WorkspaceScreen extends StatefulWidget {
  final Project project;
  final int initialTab;
  const WorkspaceScreen({super.key, required this.project, this.initialTab = 0});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  late int _selectedIndex;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    final id = widget.project.id!;
    _tabs = [
      StoryboardTab(projectId: id),
      CharactersTab(projectId: id),
      LocationsTab(projectId: id),
      ProductionTab(projectId: id),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Thùng rác',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrashBinScreen(projectId: widget.project.id!),
                ),
              ).then((_) {
                // Tải lại dữ liệu sau khi quay lại từ thùng rác
                final id = widget.project.id!;
                context.read<ActProvider>().loadActs(id).then((_) {
                  final sceneProv = context.read<SceneProvider>();
                  for (final act in context.read<ActProvider>().acts) {
                    sceneProv.loadScenesForAct(act.id!);
                  }
                });
              });
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: IndexedStack(index: _selectedIndex, children: _tabs),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.movie_filter_outlined),
            selectedIcon: Icon(Icons.movie_filter),
            label: 'Story Board',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Nhân vật',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Bối cảnh',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Sản xuất',
          ),
        ],
      ),
    );
  }
}
