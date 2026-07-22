import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cinex_application/features/production/providers/production_provider.dart';
import '../widgets/int_ext_pie_chart.dart';
import '../widgets/character_frequency_chart.dart';
import '../widgets/scene_characters_chart.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/utils/pdf_exporter.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/core/theme/app_colors.dart';

class ProductionAnalyticsView extends StatelessWidget {
  final ProductionProvider provider;
  final int projectId;
  final String? projectStartDate;
  final String? projectEndDate;

  const ProductionAnalyticsView({
    super.key,
    required this.provider,
    required this.projectId,
    this.projectStartDate,
    this.projectEndDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (provider.allScenes.isEmpty) {
      return Container(
        color: theme.scaffoldBackgroundColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: context.appColors.textFaint,
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có dữ liệu thống kê',
                style: TextStyle(
                  color: context.appColors.textFaint,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thêm Scene để xem thống kê sản xuất',
                style: TextStyle(
                  color: context.appColors.textFaint,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final locationCount = provider.allScenes
        .map((scene) => scene.locationId ?? scene.location?.id)
        .whereType<int>()
        .toSet()
        .length;
    // Calculate Insights
    String keyCharacter = 'N/A';
    int maxCharScenes = 0;
    double charCoverage = 0.0;

    final charCounts = <String, int>{};
    for (var scene in provider.allScenes) {
      for (var c in scene.characters) {
        charCounts[c.name] = (charCounts[c.name] ?? 0) + 1;
      }
    }
    if (charCounts.isNotEmpty) {
      final sortedChars = charCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      keyCharacter = sortedChars.first.key;
      maxCharScenes = sortedChars.first.value;
      charCoverage = maxCharScenes / provider.allScenes.length * 100;
    }

    String keyLocation = 'N/A';
    int maxLocScenes = 0;
    final locCounts = <String, int>{};
    for (var scene in provider.allScenes) {
      final locName = scene.location?.name ?? 'Chưa rõ';
      locCounts[locName] = (locCounts[locName] ?? 0) + 1;
    }
    if (locCounts.isNotEmpty) {
      final sortedLocs = locCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      keyLocation = sortedLocs.first.key;
      maxLocScenes = sortedLocs.first.value;
    }

    String mostComplexSceneNum = 'N/A';
    String mostComplexSceneTitle = 'N/A';
    int maxSceneChars = 0;
    List<String> complexSceneChars = [];
    double totalCharsInScenes = 0.0;
    for (var scene in provider.allScenes) {
      totalCharsInScenes += scene.characters.length;
      if (scene.characters.length > maxSceneChars) {
        maxSceneChars = scene.characters.length;
        mostComplexSceneNum = scene.sceneNumber.toString();
        mostComplexSceneTitle = scene.title;
        complexSceneChars = scene.characters.map((c) => c.name).toList();
      }
    }
    double avgCharsPerScene = provider.allScenes.isEmpty
        ? 0.0
        : totalCharsInScenes / provider.allScenes.length;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Thống kê Sản xuất',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _exportReport(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final doneCount = provider.allScenes
                    .where(
                      (s) => provider.getShootingStatus(s) == SceneStatus.done,
                    )
                    .length;
                if (constraints.maxWidth < 360) {
                  return Column(
                    children: [
                      _buildStatCard(
                        theme,
                        'Tổng cảnh',
                        provider.allScenes.length.toString(),
                        Icons.movie_creation,
                      ),
                      const SizedBox(height: 8),
                      _buildStatCard(
                        theme,
                        'Bối cảnh',
                        locationCount.toString(),
                        Icons.location_on,
                      ),
                      const SizedBox(height: 8),
                      _buildStatCard(
                        theme,
                        'Đã quay',
                        doneCount.toString(),
                        Icons.check_circle,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        theme,
                        'Tổng cảnh',
                        provider.allScenes.length.toString(),
                        Icons.movie_creation,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        theme,
                        'Bối cảnh',
                        locationCount.toString(),
                        Icons.location_on,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        theme,
                        'Đã quay',
                        doneCount.toString(),
                        Icons.check_circle,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Production Progress Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appColors.surfaceElevated),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tiến độ sản xuất',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${(provider.productionProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: provider.productionProgress,
                      minHeight: 10,
                      backgroundColor: context.appColors.surfaceElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        provider.productionProgress >= 1.0
                            ? context.appColors.success
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${provider.completedScenesCount} / ${provider.allScenes.length} cảnh đã hoàn thành quay',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appColors.textFaint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Int vs Ext Chart
            IntExtPieChart(scenes: provider.allScenes),
            const SizedBox(height: 24),

            // Scene Characters Chart
            SceneCharactersChart(scenes: provider.allScenes),
            const SizedBox(height: 24),

            // Character Frequency Chart
            CharacterFrequencyChart(scenes: provider.allScenes),
            const SizedBox(height: 24),

            // Production Insights Section
            _buildInsightsSection(
              theme,
              keyCharacter,
              maxCharScenes,
              charCoverage,
              keyLocation,
              maxLocScenes,
              mostComplexSceneNum,
              mostComplexSceneTitle,
              maxSceneChars,
              complexSceneChars,
              avgCharsPerScene,
            ),
            const SizedBox(height: 24),

            // Production Shooting Plan Summary
            _buildShootingPlanSection(theme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _exportReport(BuildContext context) async {
    if (provider.allScenes.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang thu thập thông tin dự án...'),
        backgroundColor: Colors.blueGrey,
      ),
    );

    try {
      final api = ApiService();
      // Tải danh sách dự án để tìm dự án hiện tại
      final projects = await api.getProjects();
      final matchingProjects = projects.where(
        (project) => project.id == projectId,
      );
      if (matchingProjects.isEmpty) {
        throw StateError('Không tìm thấy dự án để xuất báo cáo.');
      }
      final project = matchingProjects.first;

      // Tải danh sách hồi (Acts)
      final acts = await api.getActsForProject(projectId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang tạo báo cáo kịch bản & sản xuất PDF...'),
            backgroundColor: Colors.indigo,
          ),
        );
        await PdfExporter.exportScreenplay(
          context: context,
          project: project,
          acts: acts,
          allScenes: provider.allScenes,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải báo cáo PDF: $e'),
            backgroundColor: context.appColors.danger,
          ),
        );
      }
    }
  }

  Widget _buildInsightsSection(
    ThemeData theme,
    String keyCharacter,
    int maxCharScenes,
    double charCoverage,
    String keyLocation,
    int maxLocScenes,
    String complexSceneNum,
    String complexSceneTitle,
    int maxSceneChars,
    List<String> complexSceneChars,
    double avgCharsPerScene,
  ) {
    final appColors = theme.extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appColors.surfaceElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PHÂN TÍCH CHUYÊN SÂU',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: theme.colorScheme.primary,
                ),
              ),
              Icon(
                Icons.psychology_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightRow(
            theme: theme,
            icon: Icons.person_pin,
            iconColor: appColors.info,
            title: 'Nhân vật chủ chốt',
            value: keyCharacter != 'N/A' ? keyCharacter : 'Chưa có',
            subtitle: keyCharacter != 'N/A'
                ? 'Xuất hiện trong $maxCharScenes cảnh (${charCoverage.toStringAsFixed(0)}% thời lượng kịch bản)'
                : 'Thêm nhân vật vào cảnh để thống kê',
          ),
          Divider(color: appColors.surfaceElevated, height: 24),
          _buildInsightRow(
            theme: theme,
            icon: Icons.location_history,
            iconColor: appColors.success,
            title: 'Bối cảnh quay trọng điểm',
            value: keyLocation != 'N/A' ? keyLocation : 'Chưa có',
            subtitle: keyLocation != 'N/A'
                ? 'Được sử dụng cho $maxLocScenes phân cảnh kịch bản'
                : 'Thêm bối cảnh vào cảnh để thống kê',
          ),
          Divider(color: appColors.surfaceElevated, height: 24),
          _buildInsightRow(
            theme: theme,
            icon: Icons.groups_outlined,
            iconColor: appColors.warning,
            title: 'Mức độ phức tạp trung bình',
            value: '${avgCharsPerScene.toStringAsFixed(1)} nhân vật/cảnh',
            subtitle:
                'Đoàn phim cần lưu ý sắp xếp lịch điều phối nhân sự phù hợp',
          ),
          if (maxSceneChars > 0) ...[
            Divider(color: appColors.surfaceElevated, height: 24),
            _buildInsightRow(
              theme: theme,
              icon: Icons.report_problem_outlined,
              iconColor: appColors.danger,
              title: 'Cảnh phức tạp nhất (Cảnh $complexSceneNum)',
              value: complexSceneTitle,
              subtitle:
                  'Đòi hỏi sự xuất hiện của $maxSceneChars diễn viên cùng lúc:\n(${complexSceneChars.join(', ')})',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightRow({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    final appColors = theme.extension<AppColors>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: appColors.textFaint,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: appColors.textFaint,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShootingPlanSection(ThemeData theme) {
    if (provider.groupedByLocation.isEmpty) return const SizedBox.shrink();

    final groups = provider.groupedByLocation.entries.toList();

    DateTime? getShootingDate(int dayIndex) {
      final customDate = provider.customDates[groups[dayIndex].key];
      return customDate == null ? null : DateTime.tryParse(customDate);
    }

    final hasManyDays = groups.length > 3;
    final appColors = theme.extension<AppColors>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appColors.surfaceElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KẾ HOẠCH BẤM MÁY CHI TIẾT',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: theme.colorScheme.primary,
                ),
              ),
              Row(
                children: [
                  if (hasManyDays)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        'Cuộn để xem thêm',
                        style: TextStyle(
                          color: appColors.textFaint,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  Icon(
                    Icons.calendar_today_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            constraints: BoxConstraints(
              maxHeight: hasManyDays ? 340 : double.infinity,
            ),
            child: Scrollbar(
              thumbVisibility: hasManyDays,
              child: ListView.separated(
                shrinkWrap: true,
                physics: hasManyDays
                    ? const AlwaysScrollableScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: groups.length,
                separatorBuilder: (context, index) =>
                    Divider(color: appColors.surfaceElevated, height: 24),
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final date = getShootingDate(index);
                  final dateStr = date != null
                      ? DateFormat('dd/MM/yyyy').format(date)
                      : 'Chưa thiết lập ngày';
                  final firstLoc = group.value.first.location;
                  final settingStr =
                      (firstLoc?.setting.toString() ==
                              LocationSetting.interior.toString() ||
                          firstLoc?.setting.toString() ==
                              'LocationSetting.interior' ||
                          firstLoc?.setting.toString() == 'INT')
                      ? 'Nội (INT)'
                      : 'Ngoại (EXT)';

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 95,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          children: [
                            Text(
                              date == null
                                  ? 'CHƯA XẾP NGÀY'
                                  : 'NGÀY ${index + 1}',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateStr,
                              style: TextStyle(
                                color: appColors.textFaint,
                                fontSize: 9,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.key.toUpperCase(),
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$settingStr · ${group.value.length} phân cảnh (Cảnh: ${group.value.map((s) => s.sceneNumber).join(', ')})',
                              style: TextStyle(
                                color: appColors.textFaint,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
  ) {
    final appColors = theme.extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appColors.surfaceElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: appColors.textFaint, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: appColors.textFaint)),
        ],
      ),
    );
  }
}
