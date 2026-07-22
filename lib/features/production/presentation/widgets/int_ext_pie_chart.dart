import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/core/theme/app_colors.dart';

class IntExtPieChart extends StatelessWidget {
  final List<Scene> scenes;
  const IntExtPieChart({super.key, required this.scenes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = context.appColors;
    final interior = scenes
        .where((s) => s.location?.setting.toString() == LocationSetting.interior.toString() || s.location?.setting.toString() == 'INT' || s.location?.setting.toString() == 'LocationSetting.interior')
        .length;
    final exterior = scenes
        .where((s) => s.location?.setting.toString() == LocationSetting.exterior.toString() || s.location?.setting.toString() == 'EXT' || s.location?.setting.toString() == 'LocationSetting.exterior')
        .length;
    final total = interior + exterior;

    if (total == 0) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: appColors.surfaceElevated),
        ),
        child: Center(
          child: Text('Chưa có bối cảnh', style: TextStyle(color: appColors.textFaint)),
        ),
      );
    }

    final intPercent = (interior / total * 100).round();
    final extPercent = (exterior / total * 100).round();

    return Container(
      height: 220,
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
                'Tỷ lệ Bối cảnh',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              Icon(Icons.location_city, color: theme.colorScheme.primary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: interior.toDouble(),
                          title: '$intPercent%',
                          color: Colors.blue.shade600,
                          radius: 50,
                          titleStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          value: exterior.toDouble(),
                          title: '$extPercent%',
                          color: Colors.orange.shade700,
                          radius: 40,
                          titleStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                      sectionsSpace: 4,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegend(theme, 'NỘI (INT)', Colors.blue.shade600, interior),
                      const SizedBox(height: 12),
                      _buildLegend(theme, 'NGOẠI (EXT)', Colors.orange.shade700, exterior),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(ThemeData theme, String title, Color color, int value) {
    final appColors = theme.extension<AppColors>()!;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 10, color: appColors.textFaint, fontFamily: 'JetBrains Mono'),
            ),
            Text(
              '$value cảnh',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
          ],
        ),
      ],
    );
  }
}
