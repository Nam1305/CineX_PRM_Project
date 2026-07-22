import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cinex_application/features/production/providers/production_provider.dart';
import 'package:excel/excel.dart';
import 'package:cinex_application/core/utils/file_saver.dart';
import '../widgets/scene_filter_bar.dart';
import '../widgets/shooting_day_group.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/core/theme/app_colors.dart';

class ProductionScheduleView extends StatelessWidget {
  final ProductionProvider provider;
  final int projectId;
  final String? projectStartDate;
  final String? projectEndDate;

  const ProductionScheduleView({
    super.key,
    required this.provider,
    required this.projectId,
    this.projectStartDate,
    this.projectEndDate,
  });

  /// Returns only a shooting date that has actually been persisted.
  /// Unscheduled locations must not receive a generated display date because
  /// that date was never saved and cannot be used consistently for sorting.
  DateTime? _shootingDate(String locationLabel) {
    final customDateStr = provider.customDates[locationLabel];
    if (customDateStr != null && customDateStr.isNotEmpty) {
      return DateTime.tryParse(customDateStr);
    }
    return null;
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupEntries = provider.groupedByLocation.entries.toList();

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Lịch sản xuất',
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
                        onPressed: () => _exportSchedule(context),
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
                        icon: const Icon(Icons.ios_share, size: 18),
                        label: const Text('Export'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SceneFilterBar(projectId: projectId, provider: provider),
                ],
              ),
            ),
          ),
          if (groupEntries.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.movie_creation_outlined,
                      size: 64,
                      color: context.appColors.textFaint,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có phân cảnh nào',
                      style: TextStyle(
                        color: context.appColors.textFaint,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thêm Scene trong tab Storyboard để xem lịch quay',
                      style: TextStyle(
                        color: context.appColors.textFaint,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, i) {
                  final entry = groupEntries[i];
                  return ShootingDayGroup(
                    locationLabel: entry.key,
                    scenes: entry.value,
                    dayNumber: i + 1,
                    shootingDate: _shootingDate(entry.key),
                    projectId: projectId,
                    projectStartDate: projectStartDate,
                    projectEndDate: projectEndDate,
                  );
                }, childCount: groupEntries.length),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Future<void> _exportSchedule(BuildContext context) async {
    final provider = context.read<ProductionProvider>();
    if (provider.groupedByLocation.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang tạo file Excel...'),
        backgroundColor: Colors.blueGrey,
      ),
    );

    try {
      final excel = Excel.createExcel();
      final sheet = excel['Lịch Quay'];
      excel.setDefaultSheet('Lịch Quay');

      // Header
      sheet.appendRow([
        TextCellValue('Ngày quay'),
        TextCellValue('Bối cảnh'),
        TextCellValue('Cảnh số'),
        TextCellValue('INT/EXT'),
        TextCellValue('DAY/NIGHT'),
        TextCellValue('Tiêu đề'),
        TextCellValue('Trạng thái'),
      ]);

      // Data
      int dayCounter = 0;
      for (var entry in provider.groupedByLocation.entries) {
        final locationLabel = entry.key;
        final dt = _shootingDate(locationLabel);
        final dayLabel = dt != null
            ? 'Ngày ${dayCounter + 1} (${_formatDate(dt)})'
            : 'Chưa xếp ngày';
        for (var scene in entry.value) {
          sheet.appendRow([
            TextCellValue(dayLabel),
            TextCellValue(locationLabel),
            TextCellValue(scene.sceneNumber.toString()),
            TextCellValue(scene.setting.label),
            TextCellValue(scene.timeOfDay.label),
            TextCellValue(scene.summary ?? 'Cảnh ${scene.sceneNumber}'),
            TextCellValue(scene.status.shootingLabel),
          ]);
        }
        dayCounter++;
      }

      final fileBytes = excel.encode();
      if (fileBytes != null) {
        final filename = 'LichQuay_Project_$projectId.xlsx';
        final savedPath = await saveAndDownloadFile(
          bytes: Uint8List.fromList(fileBytes),
          filename: filename,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                savedPath == 'Tải xuống trình duyệt'
                    ? 'Đã tải xuống lịch quay thành công!'
                    : 'Đã lưu Excel tại: $savedPath',
              ),
              backgroundColor: context.appColors.success,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất file: $e'),
            backgroundColor: context.appColors.danger,
          ),
        );
      }
    }
  }
}
