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
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2C2C2C)),
        ),
        child: const Center(
          child: Text('Chưa có dữ liệu nhân vật', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();

    return Container(
      height: 260,
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
                'Tần suất Nhân vật',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('XEM TẤT CẢ', style: TextStyle(color: Color(0xFFFF571A), fontSize: 10, fontFamily: 'JetBrains Mono')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: top.asMap().entries.map((e) {
                  return BarChartGroupData(x: e.key, barRods: [
                    BarChartRodData(
                      toY: e.value.value.toDouble(),
                      color: const Color(0xFFFF571A),
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: top.first.value.toDouble(),
                        color: const Color(0xFF2A2A2A),
                      ),
                    ),
                  ]);
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= top.length) return const SizedBox();
                        final name = top[idx].key;
                        final shortName = name.split(' ').last; // Get last word (e.g. 'Nam')
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            shortName,
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF2A2A2A),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '\${top[groupIndex].key}\n',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        children: [
                          TextSpan(
                            text: '\${rod.toY.toInt()} cảnh',
                            style: const TextStyle(color: Color(0xFFFF571A), fontSize: 10),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
