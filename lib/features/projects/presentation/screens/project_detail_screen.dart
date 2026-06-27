import 'package:flutter/material.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/features/acts/data/models/act.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/widgets/status_badge.dart';
import 'package:cinex_application/core/widgets/progress_widget.dart';
import 'package:cinex_application/core/widgets/image_card.dart';
import 'package:cinex_application/core/widgets/section_card.dart';
import 'package:cinex_application/features/production/presentation/screens/project_production_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _api = ApiService();
  List<Act> _acts = [];
  bool _actsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActs();
  }

  /// Load danh sách Hồi từ API
  Future<void> _loadActs() async {
    if (widget.project.id == null) return;
    final acts = await _api.getActsForProject(widget.project.id!);
    if (mounted) {
      setState(() {
        _acts = acts;
        _actsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final project = widget.project;

    // Xác định StatusType dựa trên status thực từ server
    StatusType statusType;
    String statusLabel;
    switch (project.status) {
      case 'SHOOTING':
        statusType = StatusType.active;
        statusLabel = 'ĐANG QUAY';
        break;
      case 'POST_PRODUCTION':
        statusType = StatusType.completed;
        statusLabel = 'HẬU KỲ';
        break;
      case 'COMPLETED':
        statusType = StatusType.completed;
        statusLabel = 'HOÀN TẤT';
        break;
      default:
        statusType = StatusType.pending;
        statusLabel = 'LẬP KẾ HOẠCH';
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  ImageCard(
                    imageUrl: project.posterUrl,
                    onTap: () {},
                    heroTag: 'project_${project.id}',
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusBadge(status: statusType, label: statusLabel),
                          const SizedBox(height: 8),
                          Text(
                            project.title,
                            style: theme.textTheme.headlineLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Metadata Grid
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _MetadataCard(
                      label: 'Ngày bắt đầu',
                      value: _formatDate(project.startDate),
                      icon: Icons.calendar_today_outlined,
                    ),
                    _MetadataCard(
                      label: 'Ngày kết thúc',
                      value: _formatDate(project.endDate),
                      icon: Icons.event_outlined,
                    ),
                    _MetadataCard(
                      label: 'Đạo diễn',
                      value: project.director ?? 'TBD',
                      icon: Icons.person_outline,
                    ),
                    _MetadataCard(
                      label: 'Đoàn phim',
                      value: project.crewCount > 0
                          ? '${project.crewCount} người'
                          : 'TBD',
                      icon: Icons.people_outline,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Progress
                SectionCard(
                  title: 'Tiến độ',
                  child: ProgressWidget(
                    percentage: project.progress,
                    label: 'Hoàn thành',
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _ActionButton(
                      label: 'Lịch Quay',
                      icon: Icons.calendar_month_outlined,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectProductionScreen(
                            projectId: project.id!,
                            projectTitle: project.title,
                            initialTab: 0,
                          ),
                        ),
                      ),
                    ),
                    _ActionButton(
                      label: 'Phân Tích',
                      icon: Icons.analytics_outlined,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectProductionScreen(
                            projectId: project.id!,
                            projectTitle: project.title,
                            initialTab: 1,
                          ),
                        ),
                      ),
                    ),
                    _ActionButton(
                      label: 'Báo Cáo',
                      icon: Icons.description_outlined,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectProductionScreen(
                            projectId: project.id!,
                            projectTitle: project.title,
                            initialTab: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Act Progress
                SectionCard(
                  title: 'Tiến độ các Hồi',
                  child: _actsLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _acts.isEmpty
                          ? Text(
                              'Chưa có hồi nào được tạo',
                              style: theme.textTheme.bodySmall,
                            )
                          : Column(
                              children: _acts.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final act = entry.value;
                                return Column(
                                  children: [
                                    if (idx > 0) const SizedBox(height: 12),
                                    _ActProgressItem(
                                      act: act.title,
                                      status: act.status,
                                      theme: theme,
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Format date từ ISO string sang dạng dd/MM/yyyy
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'TBD';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _MetadataCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetadataCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActProgressItem extends StatelessWidget {
  final String act;
  final String status;
  final ThemeData theme;

  const _ActProgressItem({
    required this.act,
    required this.status,
    required this.theme,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'DONE':
        return const Color(0xFF51CF66);
      case 'IN_PROGRESS':
        return const Color(0xFFFFD43B);
      case 'WAITING':
        return const Color(0xFF9E9E9E);
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (status) {
      case 'DONE':
        return 'Hoàn tất';
      case 'IN_PROGRESS':
        return 'Đang làm';
      case 'WAITING':
        return 'Chờ';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            act,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor().withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStatusLabel(),
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
