import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/auth/providers/auth_provider.dart';
import 'package:cinex_application/features/projects/providers/project_provider.dart';
import 'package:cinex_application/shared/widgets/empty_state_widget.dart';
import '../widgets/project_card.dart';
import 'project_form_screen.dart';
import 'package:cinex_application/features/notifications/providers/notification_provider.dart';
import 'package:cinex_application/features/notifications/data/models/notification_model.dart';

import 'project_detail_screen.dart';

import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/shared/widgets/pagination_bar.dart';

class ProjectLauncherScreen extends StatefulWidget {
  const ProjectLauncherScreen({super.key});

  @override
  State<ProjectLauncherScreen> createState() => _ProjectLauncherScreenState();
}

class _ProjectLauncherScreenState extends State<ProjectLauncherScreen> {
  int _currentPage = 1;
  static const int _itemsPerPage = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isWritable = auth.isScreenwriter;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CineX Launcher'),
            Text(
              'Xin chào, ${auth.fullName} (${auth.role == 'SCREENWRITER' ? 'Biên kịch' : 'Nhà sản xuất'})',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.projects.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.movie_creation_outlined,
              message: isWritable
                  ? 'Chưa có dự án nào.\nBấm nút + để tạo dự án đầu tiên.'
                  : 'Không có dự án phim nào trong hệ thống.',
              actionLabel: isWritable ? 'Tạo dự án' : null,
              onAction: isWritable ? () => _openForm(context) : null,
            );
          }

          // Sắp xếp theo ngày tạo mới nhất lên đầu
          final sortedProjects = List<Project>.from(provider.projects)
            ..sort((a, b) {
              final aTime = DateTime.tryParse(a.createdAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bTime = DateTime.tryParse(b.createdAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bTime.compareTo(aTime);
            });

          // Phân trang
          final totalItems = sortedProjects.length;
          final totalPages = (totalItems / _itemsPerPage).ceil();
          
          // Giới hạn trang hiện tại trong khoảng hợp lệ (phòng trường hợp xoá phần tử)
          if (_currentPage > totalPages && totalPages > 0) {
            _currentPage = totalPages;
          }
          
          final startIndex = (_currentPage - 1) * _itemsPerPage;
          final endIndex = startIndex + _itemsPerPage > totalItems ? totalItems : startIndex + _itemsPerPage;
          final paginatedProjects = sortedProjects.sublist(startIndex, endIndex);

          final screenWidth = MediaQuery.of(context).size.width;
          final double availableWidth = screenWidth - 32;
          int crossAxisCount = (availableWidth / 260).floor();
          if (crossAxisCount < 1) crossAxisCount = 1;
          if (crossAxisCount > paginatedProjects.length && paginatedProjects.isNotEmpty) {
            double widthPerCard = (availableWidth - (paginatedProjects.length - 1) * 16) / paginatedProjects.length;
            if (widthPerCard <= 360) {
              crossAxisCount = paginatedProjects.length;
            } else {
              int limitCols = (availableWidth / 360).floor();
              crossAxisCount = limitCols < paginatedProjects.length ? paginatedProjects.length : limitCols;
            }
          }

          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: paginatedProjects.length,
                  itemBuilder: (context, i) {
                    final project = paginatedProjects[i];
                    return ProjectCard(
                      project: project,
                      isWritable: isWritable,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailScreen(project: project),
                        ),
                      ),
                      onEdit: () => _openForm(context, project: project),
                      onDelete: () async {
                        final ok = await provider.removeProject(project.id!);
                        if (ok && context.mounted) {
                          context.read<NotificationProvider>().addNotification(
                                projectId: project.id,
                                projectTitle: project.title,
                                title: 'Xóa dự án: ${project.title}',
                                body: 'Dự án "${project.title}" và toàn bộ tài nguyên đi kèm đã bị xóa khỏi hệ thống.',
                                actionType: NotificationActionType.delete,
                              );
                        }
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
              onPressed: () => _openForm(context),
              child: const Icon(Icons.add),
            )
          : null,
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
