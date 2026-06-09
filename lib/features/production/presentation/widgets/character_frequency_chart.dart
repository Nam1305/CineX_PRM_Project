import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';

class CharacterFrequencyChart extends StatelessWidget {
  final List<Scene> scenes;
  const CharacterFrequencyChart({super.key, required this.scenes});

  @override
  Widget build(BuildContext context) {
    final freq = <String, int>{};
    for (final scene in scenes) {
      for (final c in scene.characters) {
        freq[c.name] = (freq[c.name] ?? 0) + 1;
      }
    }
    if (freq.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('Chưa có dữ liệu')),
      );
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tần suất nhân vật',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                barGroups: top.asMap().entries.map((e) {
                  return BarChartGroupData(x: e.key, barRods: [
                    BarChartRodData(
                      toY: e.value.value.toDouble(),
                      color: primary,
                      width: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ]);
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= top.length) {
                          return const SizedBox();
                        }
                        final name = top[idx].key;
                        return Text(
                          name.length > 6 ? '${name.substring(0, 6)}…' : name,
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
