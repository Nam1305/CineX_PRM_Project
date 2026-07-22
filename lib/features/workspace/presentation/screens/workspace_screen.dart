import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/features/scenes/presentation/screens/storyboard_tab.dart';
import 'package:cinex_application/features/characters/presentation/screens/characters_tab.dart';
import 'package:cinex_application/features/locations/presentation/screens/locations_tab.dart';
import 'package:cinex_application/features/production/presentation/screens/production_tab.dart';
import 'package:cinex_application/features/production/providers/production_provider.dart';
import 'package:cinex_application/features/auth/providers/auth_provider.dart';
import 'package:cinex_application/features/notifications/providers/notification_provider.dart';
import 'package:cinex_application/features/notifications/presentation/screens/notification_screen.dart';

class WorkspaceScreen extends StatefulWidget {
  final Project project;
  final int initialTab;
  const WorkspaceScreen({
    super.key,
    required this.project,
    this.initialTab = 0,
  });

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
      ProductionTab(
        projectId: id,
        projectStartDate: widget.project.startDate,
        projectEndDate: widget.project.endDate,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.title),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF571A),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
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
        onDestinationSelected: (i) {
          setState(() => _selectedIndex = i);
          if (i == 3) {
            context.read<ProductionProvider>().loadForProject(
              widget.project.id!,
              canMigrateLegacy: context.read<AuthProvider>().isProducer,
            );
          }
        },
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
