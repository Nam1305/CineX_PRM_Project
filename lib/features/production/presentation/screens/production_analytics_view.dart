import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cinex_application/features/production/providers/production_provider.dart';
import '../widgets/int_ext_pie_chart.dart';
import '../widgets/character_frequency_chart.dart';
import '../widgets/scene_characters_chart.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/utils/pdf_exporter.dart';
import 'package:cinex_application/core/utils/enums.dart';

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
        color: const Color(0xFF131313),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Chưa có dữ liệu thống kê',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Thêm Scene để xem thống kê sản xuất',
                style: TextStyle(color: Colors.grey, fontSize: 12),
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
      color: const Color(0xFF131313),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Flexible(
                  child: Text(
                    'Thống kê Sản xuất',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _exportReport(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF571A),
                    foregroundColor: Colors.white,
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
                        'Tổng cảnh',
                        provider.allScenes.length.toString(),
                        Icons.movie_creation,
                      ),
                      const SizedBox(height: 8),
                      _buildStatCard(
                        'Bối cảnh',
                        locationCount.toString(),
                        Icons.location_on,
                      ),
                      const SizedBox(height: 8),
                      _buildStatCard(
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
                        'Tổng cảnh',
                        provider.allScenes.length.toString(),
                        Icons.movie_creation,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Bối cảnh',
                        locationCount.toString(),
                        Icons.location_on,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
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
                      const Text(
                        'Tiến độ sản xuất',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${(provider.productionProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF571A),
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
                      backgroundColor: const Color(0xFF2C2C2C),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        provider.productionProgress >= 1.0
                            ? Colors.green
                            : const Color(0xFFFF571A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${provider.completedScenesCount} / ${provider.allScenes.length} cảnh đã hoàn thành quay',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
            content: Text('Lỗi tải báo cáo PDF: ${e}'),
            backgroundColor: Colors.redAccent,
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
    return Container(
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
              Text(
                'PHÂN TÍCH CHUYÊN SÂU',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: const Color(0xFFFF571A),
                ),
              ),
              const Icon(
                Icons.psychology_outlined,
                color: Color(0xFFFF571A),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightRow(
            icon: Icons.person_pin,
            iconColor: Colors.blueAccent,
            title: 'Nhân vật chủ chốt',
            value: keyCharacter != 'N/A' ? keyCharacter : 'Chưa có',
            subtitle: keyCharacter != 'N/A'
                ? 'Xuất hiện trong ${maxCharScenes} cảnh (${charCoverage.toStringAsFixed(0)}% thời lượng kịch bản)'
                : 'Thêm nhân vật vào cảnh để thống kê',
          ),
          const Divider(color: Color(0xFF2C2C2C), height: 24),
          _buildInsightRow(
            icon: Icons.location_history,
            iconColor: Colors.green,
            title: 'Bối cảnh quay trọng điểm',
            value: keyLocation != 'N/A' ? keyLocation : 'Chưa có',
            subtitle: keyLocation != 'N/A'
                ? 'Được sử dụng cho ${maxLocScenes} phân cảnh kịch bản'
                : 'Thêm bối cảnh vào cảnh để thống kê',
          ),
          const Divider(color: Color(0xFF2C2C2C), height: 24),
          _buildInsightRow(
            icon: Icons.groups_outlined,
            iconColor: Colors.orangeAccent,
            title: 'Mức độ phức tạp trung bình',
            value: '${avgCharsPerScene.toStringAsFixed(1)} nhân vật/cảnh',
            subtitle:
                'Đoàn phim cần lưu ý sắp xếp lịch điều phối nhân sự phù hợp',
          ),
          if (maxSceneChars > 0) ...[
            const Divider(color: Color(0xFF2C2C2C), height: 24),
            _buildInsightRow(
              icon: Icons.report_problem_outlined,
              iconColor: Colors.redAccent,
              title: 'Cảnh phức tạp nhất (Cảnh ${complexSceneNum})',
              value: complexSceneTitle,
              subtitle:
                  'Đòi hỏi sự xuất hiện của ${maxSceneChars} diễn viên cùng lúc:\n(${complexSceneChars.join(', ')})',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
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
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
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

    return Container(
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
              Text(
                'KẾ HOẠCH BẤM MÁY CHI TIẾT',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: const Color(0xFFFF571A),
                ),
              ),
              Row(
                children: [
                  if (hasManyDays)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Text(
                        'Cuộn để xem thêm',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ),
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: Color(0xFFFF571A),
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
                    const Divider(color: Color(0xFF2C2C2C), height: 24),
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
                          color: const Color(0xFFFF571A).withValues(alpha: 0.1),
                          border: Border.all(
                            color: const Color(
                              0xFFFF571A,
                            ).withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          children: [
                            Text(
                              date == null
                                  ? 'CHƯA XẾP NGÀY'
                                  : 'NGÀY ${index + 1}',
                              style: const TextStyle(
                                color: Color(0xFFFF571A),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                color: Colors.grey,
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$settingStr · ${group.value.length} phân cảnh (Cảnh: ${group.value.map((s) => s.sceneNumber).join(', ')})',
                              style: const TextStyle(
                                color: Colors.grey,
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

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
