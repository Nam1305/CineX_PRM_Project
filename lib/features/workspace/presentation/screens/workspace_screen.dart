import 'package:flutter/material.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/features/scenes/presentation/screens/storyboard_tab.dart';
import 'package:cinex_application/features/characters/presentation/screens/characters_tab.dart';
import 'package:cinex_application/features/locations/presentation/screens/locations_tab.dart';
import 'package:cinex_application/features/production/presentation/screens/production_tab.dart';

class WorkspaceScreen extends StatefulWidget {
  final Project project;
  const WorkspaceScreen({super.key, required this.project});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    final id = widget.project.id!;
    _tabs = [
      StoryboardTab(projectId: id),
      const CharactersTab(),
      const LocationsTab(),
      ProductionTab(projectId: id),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.project.title)),
      body: IndexedStack(index: _selectedIndex, children: _tabs),
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
