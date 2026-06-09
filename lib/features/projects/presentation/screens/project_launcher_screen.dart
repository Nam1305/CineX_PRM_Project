import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/projects/providers/project_provider.dart';
import 'package:cinex_application/features/workspace/presentation/screens/workspace_screen.dart';
import 'package:cinex_application/shared/widgets/empty_state_widget.dart';
import '../widgets/project_card.dart';
import 'project_form_screen.dart';

class ProjectLauncherScreen extends StatefulWidget {
  const ProjectLauncherScreen({super.key});

  @override
  State<ProjectLauncherScreen> createState() => _ProjectLauncherScreenState();
}

class _ProjectLauncherScreenState extends State<ProjectLauncherScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CineX')),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.projects.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.movie_creation_outlined,
              message: 'Chưa có dự án nào.\nBấm nút + để tạo dự án đầu tiên.',
              actionLabel: 'Tạo dự án',
              onAction: () => _openForm(context),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: provider.projects.length,
            itemBuilder: (context, i) {
              final project = provider.projects[i];
              return ProjectCard(
                project: project,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkspaceScreen(project: project),
                  ),
                ),
                onEdit: () => _openForm(context, project: project),
                onDelete: () async {
                  await provider.removeProject(project.id!);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openForm(BuildContext context, {project}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectFormScreen(project: project),
      ),
    );
  }
}
