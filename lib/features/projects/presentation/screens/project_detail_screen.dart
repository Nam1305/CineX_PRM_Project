import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/auth/providers/auth_provider.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/features/acts/data/models/act.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/storage/local_cache_service.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/core/utils/date_only.dart';
import 'package:cinex_application/core/widgets/status_badge.dart';
import 'package:cinex_application/core/widgets/image_card.dart';
import 'package:cinex_application/core/widgets/section_card.dart';
import 'package:cinex_application/features/projects/providers/project_provider.dart';
import 'package:cinex_application/features/projects/presentation/screens/project_form_screen.dart';
import 'package:cinex_application/features/production/presentation/screens/project_production_screen.dart';
import 'package:cinex_application/features/production/data/models/production_plan.dart';
import 'package:cinex_application/features/production/data/production_metrics.dart';
import 'package:cinex_application/features/workspace/presentation/screens/workspace_screen.dart';
import 'package:cinex_application/shared/widgets/confirm_dialog.dart';
import 'package:cinex_application/shared/widgets/app_snackbar.dart';
import 'package:cinex_application/features/notifications/providers/notification_provider.dart';
import 'package:cinex_application/features/notifications/data/models/notification_model.dart';
import 'package:cinex_application/core/utils/pdf_exporter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _api = ApiService();
  late Project _project;

  List<Act> _acts = [];
  List<Scene> _scenes = [];
  bool _isLoading = true;

  // Dynamic Dashboard Stats (F1.3)
  int _totalScenes = 0;
  int _doneScenes = 0;
  int _inProgressScenes = 0;
  int _todoScenes = 0;
  double _dynamicProgress = 0.0;
  int _characterCount = 0;
  int _locationCount = 0;
  int _actCount = 0;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _loadProjectData();
  }

  /// Load all project related data dynamically
  Future<void> _loadProjectData() async {
    if (_project.id == null) return;
    setState(() => _isLoading = true);

    final projectId = _project.id!;
    var acts = <Act>[];
    var scenes = <Scene>[];
    var plan = ProductionPlan.empty(projectId);
    var characterCount = 0;
    var locationCount = 0;
    try {
      acts = await LocalCacheService.instance.getActs(projectId);
      scenes = await LocalCacheService.instance.getScenesForProject(projectId);
      plan =
          await LocalCacheService.instance.getProductionPlan(projectId) ?? plan;
      characterCount = (await LocalCacheService.instance.getCharacters(
        projectId,
      )).length;
      locationCount = (await LocalCacheService.instance.getLocations(
        projectId,
      )).length;
    } catch (_) {}
    if (mounted && (acts.isNotEmpty || scenes.isNotEmpty)) {
      _applyDashboardData(
        acts,
        scenes,
        plan,
        characterCount: characterCount,
        locationCount: locationCount,
      );
    }

    try {
      acts = await _api.getActsForProject(projectId);
      scenes = await _api.getScenesForProject(projectId);
      final characters = await _api.getCharacters(projectId: projectId);
      final locations = await _api.getLocations(projectId);
      characterCount = characters.length;
      locationCount = locations.length;
      try {
        plan = await _api.getProductionPlan(projectId);
      } catch (_) {
        // Scene/act refresh remains useful even when the production endpoint is unavailable.
      }
      try {
        await LocalCacheService.instance.replaceActs(projectId, acts);
        await LocalCacheService.instance.replaceScenesForProject(
          projectId,
          scenes,
        );
        await LocalCacheService.instance.upsertProductionPlan(plan);
        await LocalCacheService.instance.replaceCharacters(
          projectId,
          characters,
        );
        await LocalCacheService.instance.replaceLocations(projectId, locations);
      } catch (_) {}
      if (mounted) {
        _applyDashboardData(
          acts,
          scenes,
          plan,
          characterCount: characterCount,
          locationCount: locationCount,
        );
      }
    } catch (e) {
      debugPrint('ProjectDetailScreen._loadProjectData error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyDashboardData(
    List<Act> acts,
    List<Scene> scenes,
    ProductionPlan plan, {
    required int characterCount,
    required int locationCount,
  }) {
    final metrics = ProductionMetrics.fromScenes(scenes, plan.sceneStatuses);
    setState(() {
      _acts = acts;
      _scenes = scenes;
      _totalScenes = metrics.total;
      _doneScenes = metrics.done;
      _inProgressScenes = metrics.inProgress;
      _todoScenes = metrics.todo;
      _dynamicProgress = metrics.progress;
      _characterCount = characterCount;
      _locationCount = locationCount;
      _actCount = acts.length;
      _isLoading = false;
    });
  }

  Future<void> _editProject() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProjectFormScreen(project: _project)),
    );
    final updated = context.read<ProjectProvider>().getProjectById(
      _project.id!,
    );
    if (updated != null && mounted) {
      setState(() {
        _project = updated;
      });
    }
    _loadProjectData();
  }

  Future<void> _deleteProject() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Xóa dự án',
      content:
          'Bạn có chắc chắn muốn xóa dự án "${_project.title}"? Thao tác này sẽ xóa sạch các hồi và cảnh liên quan.',
    );
    if (!confirmed) return;

    final ok = await context.read<ProjectProvider>().removeProject(
      _project.id!,
    );
    if (mounted) {
      if (ok) {
        context.read<NotificationProvider>().addNotification(
          projectId: _project.id,
          projectTitle: _project.title,
          title: 'Xóa dự án: ${_project.title}',
          body:
              'Dự án "${_project.title}" và toàn bộ tài nguyên đi kèm đã bị xóa khỏi hệ thống.',
          actionType: NotificationActionType.delete,
        );
        AppSnackbar.success(context, 'Xóa dự án thành công');
        Navigator.pop(context);
      } else {
        AppSnackbar.error(context, 'Xóa dự án thất bại');
      }
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1B1B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'XUẤT TÀI LIỆU PDF',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Divider(color: Color(0xFF393939), height: 1),
              ListTile(
                leading: const Icon(Icons.menu_book, color: Color(0xFFFF571A)),
                title: const Text('Xuất kịch bản phân cảnh đầy đủ'),
                subtitle: const Text(
                  'Bao gồm thông tin dự án, danh sách nhân vật & nội dung các phân cảnh theo thời gian',
                ),
                onTap: () {
                  Navigator.pop(context);
                  PdfExporter.exportScreenplay(
                    context: this.context,
                    project: _project,
                    acts: _acts,
                    allScenes: _scenes,
                  );
                },
              ),
              const Divider(color: Color(0xFF393939), height: 1),
              ListTile(
                leading: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.blue,
                ),
                title: const Text('Xuất báo cáo tiến độ sản xuất'),
                subtitle: const Text(
                  'Bao gồm tóm tắt tiến độ hoàn thành & tỷ lệ bối cảnh INT/EXT',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _exportProgressReport();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportProgressReport() async {
    try {
      final pdf = pw.Document();
      final fontRegular = await PdfGoogleFonts.notoSansRegular();
      final fontBold = await PdfGoogleFonts.notoSansBold();

      int intCount = _scenes
          .where((s) => s.location?.setting == LocationSetting.interior)
          .length;
      int extCount = _scenes
          .where((s) => s.location?.setting == LocationSetting.exterior)
          .length;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'BÁO CÁO TIẾN ĐỘ SẢN XUẤT',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 22,
                      color: PdfColor.fromHex('#FF571A'),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Dự án: ${_project.title.toUpperCase()}',
                    style: pw.TextStyle(font: fontBold, fontSize: 14),
                  ),
                  pw.SizedBox(height: 4),
                  if (_project.director != null)
                    pw.Text(
                      'Đạo diễn: ${_project.director}',
                      style: pw.TextStyle(font: fontRegular, fontSize: 11),
                    ),
                  pw.SizedBox(height: 16),
                  pw.Divider(color: PdfColors.grey400),
                  pw.SizedBox(height: 16),

                  pw.Text(
                    '1. Thống kê tiến độ:',
                    style: pw.TextStyle(font: fontBold, fontSize: 14),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Bullet(
                    text: 'Tổng số hồi: $_actCount',
                    style: pw.TextStyle(font: fontRegular),
                  ),
                  pw.Bullet(
                    text: 'Tổng số phân cảnh: $_totalScenes',
                    style: pw.TextStyle(font: fontRegular),
                  ),
                  pw.Bullet(
                    text:
                        'Phân cảnh đã hoàn thành: $_doneScenes / $_totalScenes (${(_dynamicProgress * 100).toStringAsFixed(0)}%)',
                    style: pw.TextStyle(font: fontRegular),
                  ),
                  pw.Bullet(
                    text: 'Phân cảnh đang viết/quay: $_inProgressScenes',
                    style: pw.TextStyle(font: fontRegular),
                  ),
                  pw.Bullet(
                    text: 'Phân cảnh mới tạo: $_todoScenes',
                    style: pw.TextStyle(font: fontRegular),
                  ),

                  pw.SizedBox(height: 20),
                  pw.Text(
                    '2. Thống kê bối cảnh:',
                    style: pw.TextStyle(font: fontBold, fontSize: 14),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Bullet(
                    text: 'Tổng số địa điểm sử dụng: $_locationCount',
                    style: pw.TextStyle(font: fontRegular),
                  ),
                  pw.Bullet(
                    text: 'Trong nhà (Interior): $intCount cảnh',
                    style: pw.TextStyle(font: fontRegular),
                  ),
                  pw.Bullet(
                    text: 'Ngoài trời (Exterior): $extCount cảnh',
                    style: pw.TextStyle(font: fontRegular),
                  ),

                  pw.SizedBox(height: 20),
                  pw.Text(
                    '3. Thống kê đoàn làm phim:',
                    style: pw.TextStyle(font: fontBold, fontSize: 14),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Bullet(
                    text: 'Số lượng diễn viên xuất hiện: $_characterCount',
                    style: pw.TextStyle(font: fontRegular),
                  ),
                  pw.Bullet(
                    text: 'Tổng số thành viên đoàn: ${_project.crewCount}',
                    style: pw.TextStyle(font: fontRegular),
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'BaoCaoTienDo_${_project.title.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      AppSnackbar.error(this.context, 'Không thể tạo báo cáo tiến độ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Dynamic status badge setup
    StatusType statusType;
    String statusLabel;
    switch (_project.status) {
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

    final auth = context.watch<AuthProvider>();
    final isWritable = auth.isScreenwriter;

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: CustomScrollView(
            slivers: [
              // Cinematic Flexible Header
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      ImageCard(
                        imageUrl: _project.posterUrl,
                        onTap: () {},
                        heroTag: 'project_${_project.id}',
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
                                Colors.black.withValues(alpha: 0.95),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  StatusBadge(
                                    status: statusType,
                                    label: statusLabel,
                                  ),
                                  if (isWritable)
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                          ),
                                          onPressed: _editProject,
                                          tooltip: 'Chỉnh sửa dự án',
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.black45,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: _deleteProject,
                                          tooltip: 'Xóa dự án',
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.black45,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _project.title,
                                style: theme.textTheme.headlineLarge,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
                    // Metadata Cards (Responsive Layout using Row/Column instead of GridView to avoid childAspectRatio height limits)
                    if (screenWidth > 900)
                      Row(
                        children: [
                          Expanded(
                            child: _MetadataCard(
                              label: 'Ngày bắt đầu',
                              value: _formatDate(_project.startDate),
                              icon: Icons.calendar_today_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetadataCard(
                              label: 'Ngày kết thúc',
                              value: _formatDate(_project.endDate),
                              icon: Icons.event_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetadataCard(
                              label: 'Đạo diễn',
                              value: _project.director ?? 'TBD',
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetadataCard(
                              label: 'Đoàn phim',
                              value: _project.crewCount > 0
                                  ? '${_project.crewCount} người'
                                  : 'TBD',
                              icon: Icons.people_outline,
                            ),
                          ),
                        ],
                      )
                    else if (screenWidth > 600)
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _MetadataCard(
                                  label: 'Ngày bắt đầu',
                                  value: _formatDate(_project.startDate),
                                  icon: Icons.calendar_today_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MetadataCard(
                                  label: 'Ngày kết thúc',
                                  value: _formatDate(_project.endDate),
                                  icon: Icons.event_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _MetadataCard(
                                  label: 'Đạo diễn',
                                  value: _project.director ?? 'TBD',
                                  icon: Icons.person_outline,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MetadataCard(
                                  label: 'Đoàn phim',
                                  value: _project.crewCount > 0
                                      ? '${_project.crewCount} người'
                                      : 'TBD',
                                  icon: Icons.people_outline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _MetadataCard(
                            label: 'Ngày bắt đầu',
                            value: _formatDate(_project.startDate),
                            icon: Icons.calendar_today_outlined,
                          ),
                          const SizedBox(height: 12),
                          _MetadataCard(
                            label: 'Ngày kết thúc',
                            value: _formatDate(_project.endDate),
                            icon: Icons.event_outlined,
                          ),
                          const SizedBox(height: 12),
                          _MetadataCard(
                            label: 'Đạo diễn',
                            value: _project.director ?? 'TBD',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 12),
                          _MetadataCard(
                            label: 'Đoàn phim',
                            value: _project.crewCount > 0
                                ? '${_project.crewCount} người'
                                : 'TBD',
                            icon: Icons.people_outline,
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),

                    // Description
                    if (_project.description != null &&
                        _project.description!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1B1B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2C2C2C)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MÔ TẢ CỐT TRUYỆN',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _project.description!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Bento Dashboard Grid (F1.3)
                    if (!_isLoading) ...[
                      _buildBentoDashboard(theme),
                      const SizedBox(height: 20),
                    ] else ...[
                      const Center(child: CircularProgressIndicator()),
                      const SizedBox(height: 20),
                    ],

                    // Act Progress Section
                    SectionCard(
                      title: 'Tiến độ các Hồi',
                      child: _isLoading
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
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 80,
          alignment: Alignment.center,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildActionGrid(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildBentoDashboard(ThemeData theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Production Progress Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2C2C2C)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tiến Độ Sản Xuất',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cập nhật: vừa xong',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                  Text(
                    '${(_dynamicProgress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _dynamicProgress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFF353534),
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSubCount(
                      'HOÀN THÀNH',
                      '$_doneScenes Cảnh',
                      const Color(0xFF51CF66),
                    ),
                  ),
                  Expanded(
                    child: _buildSubCount(
                      'ĐANG QUAY',
                      '$_inProgressScenes Cảnh',
                      const Color(0xFFFFD43B),
                    ),
                  ),
                  Expanded(
                    child: _buildSubCount(
                      'CÒN LẠI',
                      '$_todoScenes Cảnh',
                      const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 4 Bento Stats grid
        if (isLargeScreen)
          Row(
            children: [
              Expanded(
                child: _buildBentoStatCard(
                  'NHÂN VẬT',
                  '$_characterCount',
                  Icons.groups,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBentoStatCard(
                  'PHÂN CẢNH',
                  '$_totalScenes',
                  Icons.movie_filter,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBentoStatCard(
                  'HỒI',
                  '$_actCount',
                  Icons.layers,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBentoStatCard(
                  'BỐI CẢNH',
                  '$_locationCount',
                  Icons.location_on,
                  Colors.green,
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildBentoStatCard(
                      'NHÂN VẬT',
                      '$_characterCount',
                      Icons.groups,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBentoStatCard(
                      'PHÂN CẢNH',
                      '$_totalScenes',
                      Icons.movie_filter,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildBentoStatCard(
                      'HỒI',
                      '$_actCount',
                      Icons.layers,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBentoStatCard(
                      'BỐI CẢNH',
                      '$_locationCount',
                      Icons.location_on,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSubCount(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBentoStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2C)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _ToolbarItem(
              label: 'Kịch Bản',
              icon: Icons.movie_filter_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      WorkspaceScreen(project: _project, initialTab: 0),
                ),
              ).then((_) => _loadProjectData()),
            ),
          ),
          _toolbarDivider(),
          Expanded(
            child: _ToolbarItem(
              label: 'Nhân Vật',
              icon: Icons.people_outline,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      WorkspaceScreen(project: _project, initialTab: 1),
                ),
              ).then((_) => _loadProjectData()),
            ),
          ),
          _toolbarDivider(),
          Expanded(
            child: _ToolbarItem(
              label: 'Bối Cảnh',
              icon: Icons.location_on_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      WorkspaceScreen(project: _project, initialTab: 2),
                ),
              ).then((_) => _loadProjectData()),
            ),
          ),
          _toolbarDivider(),
          Expanded(
            child: _ToolbarItem(
              label: 'Lịch Quay',
              icon: Icons.calendar_month_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectProductionScreen(
                    projectId: _project.id!,
                    projectTitle: _project.title,
                    projectStartDate: _project.startDate,
                    projectEndDate: _project.endDate,
                    initialTab: 0,
                  ),
                ),
              ).then((_) => _loadProjectData()),
            ),
          ),
          _toolbarDivider(),
          Expanded(
            child: _ToolbarItem(
              label: 'Phân Tích',
              icon: Icons.analytics_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectProductionScreen(
                    projectId: _project.id!,
                    projectTitle: _project.title,
                    projectStartDate: _project.startDate,
                    projectEndDate: _project.endDate,
                    initialTab: 1,
                  ),
                ),
              ).then((_) => _loadProjectData()),
            ),
          ),
          _toolbarDivider(),
          Expanded(
            child: _ToolbarItem(
              label: 'Xuất PDF',
              icon: Icons.description_outlined,
              onTap: _showExportOptions,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbarDivider() {
    return Container(
      height: 32,
      width: 1,
      color: const Color(0xFF2C2C2C),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  /// Format date từ ISO string sang dạng dd/MM/yyyy
  String _formatDate(String? dateStr) {
    return formatDateOnly(dateStr);
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _ToolbarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ToolbarItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isLarge = screenWidth > 750;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: isLarge
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
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
