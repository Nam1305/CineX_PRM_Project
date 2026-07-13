import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/core/widgets/app_header.dart';
import 'package:cinex_application/core/widgets/status_badge.dart';
import 'package:cinex_application/core/widgets/progress_widget.dart';
import 'package:cinex_application/core/widgets/image_card.dart';
import 'package:cinex_application/features/projects/providers/project_provider.dart';
import 'package:cinex_application/features/projects/presentation/screens/project_form_screen.dart';
import 'package:cinex_application/features/projects/presentation/screens/project_detail_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  bool _isSearching = false;
  String _searchQuery = '';

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
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allProjects = provider.projects;
          final projects = allProjects
              .where((p) => p.title.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();

          final activeProjects =
              allProjects.where((p) => p.status == 'SHOOTING').toList();
          final completedProjects =
              allProjects.where((p) => p.status == 'POST_PRODUCTION').toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _isSearching
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                autofocus: true,
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value.trim();
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Tìm kiếm dự án...',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _isSearching = false;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : AppHeader(
                        title: 'Dự án của tôi',
                        onSearch: () {
                          setState(() {
                            _isSearching = true;
                          });
                        },
                        onNotification: () {},
                      ),
              ),
              if (projects.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _FeaturedProjectCard(
                      project: projects.first,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProjectDetailScreen(
                              project: projects.first,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Đang thực hiện',
                          count: activeProjects.length,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Đã hoàn tất',
                          count: completedProjects.length,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProjectCard(
                        project: project,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProjectDetailScreen(project: project),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'project_list_add_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProjectFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FeaturedProjectCard extends StatelessWidget {
  final dynamic project;
  final VoidCallback onTap;

  const _FeaturedProjectCard({
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ImageCard(
                  imageUrl: project.posterUrl,
                  onTap: onTap,
                  height: 200,
                  heroTag: 'featured_project_${project.id}',
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: StatusBadge(
                    status: project.status == 'SHOOTING'
                        ? StatusType.active
                        : StatusType.completed,
                    label: project.status == 'SHOOTING'
                        ? 'ĐANG QUAY'
                        : 'HOÀN TẤT',
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        project.startDate ?? 'TBD',
                        style: theme.textTheme.labelSmall,
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.people_outline,
                          size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${project.crewCount} người',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ProgressWidget(
                    percentage: project.progress,
                    label: 'Tiến độ',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;

  const _StatCard({
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final dynamic project;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                height: 120,
                child: ImageCard(
                  imageUrl: project.posterUrl,
                  onTap: onTap,
                  heroTag: 'thumb_project_${project.id}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: project.progress,
                        minHeight: 4,
                        backgroundColor: theme.colorScheme.surface,
                        valueColor: AlwaysStoppedAnimation(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(project.progress * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        StatusBadge(
                          status: project.status == 'SHOOTING'
                              ? StatusType.active
                              : StatusType.completed,
                          label: project.status == 'SHOOTING'
                              ? 'QUAY'
                              : 'HOÀN',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
