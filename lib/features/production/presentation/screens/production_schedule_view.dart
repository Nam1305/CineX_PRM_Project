import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/production/providers/production_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import '../widgets/scene_filter_bar.dart';
import '../widgets/shooting_day_group.dart';
import 'package:cinex_application/core/utils/enums.dart';

class ProductionScheduleView extends StatelessWidget {
  final ProductionProvider provider;
  final int projectId;

  const ProductionScheduleView({
    super.key,
    required this.provider,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF131313),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lịch sản xuất',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _exportSchedule(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF571A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.ios_share, size: 18),
                        label: const Text('Export Lịch'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SceneFilterBar(
                    projectId: projectId,
                    provider: provider,
                  ),
                ],
              ),
            ),
          ),
          if (provider.groupedByLocation.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.movie_creation_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Chưa có phân cảnh nào',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Thêm Scene trong tab Storyboard để xem lịch quay',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
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
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final entry = provider.groupedByLocation.entries.elementAt(i);
                    return ShootingDayGroup(
                      locationLabel: entry.key,
                      scenes: entry.value,
                    );
                  },
                  childCount: provider.groupedByLocation.length,
                ),
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
        TextCellValue('Bối cảnh'),
        TextCellValue('Cảnh số'),
        TextCellValue('INT/EXT'),
        TextCellValue('DAY/NIGHT'),
        TextCellValue('Tiêu đề'),
        TextCellValue('Trạng thái'),
      ]);

      // Data
      for (var entry in provider.groupedByLocation.entries) {
        final locationLabel = entry.key;
        for (var scene in entry.value) {
          sheet.appendRow([
            TextCellValue(locationLabel),
            TextCellValue(scene.sceneNumber.toString()),
            TextCellValue(scene.location?.setting.label ?? ''),
            TextCellValue(scene.location?.timeOfDay.label ?? ''),
            TextCellValue(scene.summary ?? 'Cảnh ${scene.sceneNumber}'),
            TextCellValue(scene.status.name.toUpperCase()),
          ]);
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/LichQuay_Project_$projectId.xlsx';
      final fileBytes = excel.encode();
      if (fileBytes != null) {
        final file = File(path);
        await file.writeAsBytes(fileBytes);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã lưu Excel tại: $path'),
              backgroundColor: const Color(0xFF51CF66),
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
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
