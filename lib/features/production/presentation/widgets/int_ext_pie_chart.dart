import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';

class IntExtPieChart extends StatelessWidget {
  final List<Scene> scenes;
  const IntExtPieChart({super.key, required this.scenes});

  @override
  Widget build(BuildContext context) {
    final interior = scenes
        .where((s) => s.location?.setting == LocationSetting.interior)
        .length;
    final exterior = scenes
        .where((s) => s.location?.setting == LocationSetting.exterior)
        .length;
    final total = interior + exterior;

    if (total == 0) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('Chưa có dữ liệu')),
      );
    }
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INT vs EXT', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: interior.toDouble(),
                    title: 'INT\n$interior',
                    color: cs.primary,
                    radius: 60,
                    titleStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    value: exterior.toDouble(),
                    title: 'EXT\n$exterior',
                    color: cs.secondary,
                    radius: 60,
                    titleStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
