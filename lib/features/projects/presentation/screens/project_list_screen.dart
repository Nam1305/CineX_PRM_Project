import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/core/widgets/app_header.dart';
import 'package:cinex_application/core/widgets/status_badge.dart';
import 'package:cinex_application/core/widgets/image_card.dart';
import 'package:cinex_application/features/projects/providers/project_provider.dart';
import 'package:cinex_application/features/projects/presentation/screens/project_form_screen.dart';
import 'package:cinex_application/features/projects/presentation/screens/project_detail_screen.dart';

import 'package:cinex_application/shared/widgets/pagination_bar.dart';
import 'package:cinex_application/features/auth/providers/auth_provider.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  String? _selectedStatusFilter;
  int _currentPage = 1;
  static const int _itemsPerPage = 5;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().loadProjects();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isWritable = auth.isScreenwriter;

    return Scaffold(
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allProjects = provider.projects;
          
          // Sắp xếp theo ngày tạo mới nhất lên đầu
          final sortedProjects = List<Project>.from(allProjects)
            ..sort((a, b) {
              final aTime = DateTime.tryParse(a.createdAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bTime = DateTime.tryParse(b.createdAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bTime.compareTo(aTime);
            });

          final projects = sortedProjects
              .where((p) => p.title.toLowerCase().contains(_searchQuery.toLowerCase()))
              .where((p) {
                if (_selectedStatusFilter == null || _selectedStatusFilter!.isEmpty) return true;
                return p.status == _selectedStatusFilter;
              })
              .toList();

          final activeProjects =
              allProjects.where((p) => p.status != 'COMPLETED').toList();
          final completedProjects =
              allProjects.where((p) => p.status == 'COMPLETED').toList();

          // Phân trang
          final totalItems = projects.length;
          final totalPages = (totalItems / _itemsPerPage).ceil();

          if (_currentPage > totalPages && totalPages > 0) {
            _currentPage = totalPages;
          }

          final startIndex = (_currentPage - 1) * _itemsPerPage;
          final endIndex = startIndex + _itemsPerPage > totalItems ? totalItems : startIndex + _itemsPerPage;
          final paginatedProjects = projects.sublist(startIndex, endIndex);

          final screenWidth = MediaQuery.of(context).size.width;
          final double availableWidth = screenWidth - 32;
          int crossAxisCount = (availableWidth / 240).floor();
          if (crossAxisCount < 1) crossAxisCount = 1;
          if (crossAxisCount > paginatedProjects.length && paginatedProjects.isNotEmpty) {
            double widthPerCard = (availableWidth - (paginatedProjects.length - 1) * 12) / paginatedProjects.length;
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
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _isSearching
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E1E1E),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFF2C2C2C)),
                                          ),
                                          child: TextField(
                                            controller: _searchController,
                                            onChanged: (val) {
                                              setState(() {
                                                _searchQuery = val.trim();
                                                _currentPage = 1;
                                              });
                                            },
                                            decoration: const InputDecoration(
                                              hintText: 'Tìm kiếm dự án...',
                                              prefixIcon: Icon(Icons.search, color: Colors.grey),
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          setState(() {
                                            _isSearching = false;
                                            _searchQuery = '';
                                            _searchController.clear();
                                            _currentPage = 1;
                                          });
                                        },
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
                                  onAdd: isWritable
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const ProjectFormScreen()),
                                          );
                                        }
                                      : null,
                                ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
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
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E1E),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF2C2C2C)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String?>(
                                      value: _selectedStatusFilter,
                                      dropdownColor: const Color(0xFF1E1E1E),
                                      hint: const Text(
                                        'Lọc theo trạng thái...',
                                        style: TextStyle(color: Colors.grey, fontSize: 14),
                                      ),
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                      icon: const Icon(Icons.filter_alt_outlined, color: Colors.grey),
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(
                                          value: null,
                                          child: Text('Tất cả trạng thái'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'PLANNING',
                                          child: Text('Lập kế hoạch'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'SHOOTING',
                                          child: Text('Đang quay (Shooting)'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'POST_PRODUCTION',
                                          child: Text('Hậu kỳ (Post-production)'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'COMPLETED',
                                          child: Text('Hoàn tất (Completed)'),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedStatusFilter = val;
                                          _currentPage = 1;
                                        });
                                      },
                                    ),
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
                          sliver: SliverGrid.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.15,
                            ),
                            itemCount: paginatedProjects.length,
                            itemBuilder: (context, index) {
                              final project = paginatedProjects[index];
                              return _ProjectCard(
                                project: project,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ProjectDetailScreen(project: project),
                                    ),
                                  );
                                  if (context.mounted) {
                                    context.read<ProjectProvider>().loadProjects();
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                      ],
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
      floatingActionButton: null,
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

class _ProjectCard extends StatefulWidget {
  final Project project;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.onTap,
  });

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  double _localProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCachedProgress();
    _loadLocalProgress();
  }

  @override
  void didUpdateWidget(_ProjectCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadLocalProgress();
  }

  Future<void> _loadCachedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getDouble('proj_${widget.project.id}_last_known_shooting_progress');
      if (cached != null && mounted) {
        setState(() {
          _localProgress = cached;
        });
      }
    } catch (e) {
        debugPrint('Error: $e');
      }
  }

  Future<void> _loadLocalProgress() async {
    if (widget.project.id == null) return;
    try {
      // Race condition safety: wait for ApiService token to load from tryAutoLogin
      int retries = 0;
      while (ApiService.token == null && retries < 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        retries++;
      }

      final api = ApiService();
      final scenes = await api.getScenesForProject(widget.project.id!);
      final prefs = await SharedPreferences.getInstance();

      final total = scenes.length;
      int done = 0;
      for (var s in scenes) {
        if (s.status == SceneStatus.done) {
          final savedStatus = prefs.getString('proj_${widget.project.id}_scene_${s.id}_shooting_status');
          final shootingStatus = savedStatus != null ? SceneStatusExt.fromDb(savedStatus) : SceneStatus.todo;
          if (shootingStatus == SceneStatus.done) {
            done++;
          }
        }
      }

      final calculatedProgress = total == 0 ? 0.0 : done / total;
      await prefs.setDouble('proj_${widget.project.id}_last_known_shooting_progress', calculatedProgress);

      if (mounted) {
        setState(() {
          _localProgress = calculatedProgress;
        });
      }
    } catch (e) {
      debugPrint('ProjectCard_Error loading progress for project ${widget.project.id}: $e');
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'TBD';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'SHOOTING':
        return 'ĐANG QUAY';
      case 'POST_PRODUCTION':
        return 'HẬU KỲ';
      case 'COMPLETED':
        return 'HOÀN THÀNH';
      default:
        return 'LẬP KẾ HOẠCH';
    }
  }

  StatusType _getStatusType(String status) {
    switch (status) {
      case 'COMPLETED':
        return StatusType.completed;
      case 'SHOOTING':
      case 'POST_PRODUCTION':
        return StatusType.active;
      default:
        return StatusType.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusType = _getStatusType(widget.project.status);
    final statusLabel = _getStatusLabel(widget.project.status);
    final progress = _localProgress;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImageCard(
                    imageUrl: widget.project.posterUrl,
                    onTap: widget.onTap,
                    heroTag: 'list_project_${widget.project.id}',
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: StatusBadge(
                      status: statusType,
                      label: statusLabel,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.project.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${_formatDate(widget.project.startDate)} - ${_formatDate(widget.project.endDate)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade400,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: theme.colorScheme.surface,
                            valueColor: AlwaysStoppedAnimation(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
