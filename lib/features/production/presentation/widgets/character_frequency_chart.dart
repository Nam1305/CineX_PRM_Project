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
    final maxFreq = top.first.value.toDouble();
    final maxY = maxFreq + 1;

    // Generate vibrant colors for each character bar
    final barColors = [
      const Color(0xFFFF571A),
      const Color(0xFFFFB74D),
      const Color(0xFF42A5F5),
      const Color(0xFF66BB6A),
      const Color(0xFFAB47BC),
      const Color(0xFF26C6DA),
    ];

    return Container(
      height: 280,
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
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0xFF1E1E1E),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tần suất Xuất hiện Nhân vật',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.grey),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.separated(
                                itemCount: sorted.length,
                                separatorBuilder: (_, __) => const Divider(color: Color(0xFF2C2C2C)),
                                itemBuilder: (context, idx) {
                                  final entry = sorted[idx];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      entry.key,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF571A).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${entry.value} phân cảnh',
                                        style: const TextStyle(
                                          color: Color(0xFFFF571A),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: const Text('XEM TẤT CẢ', style: TextStyle(color: Color(0xFFFF571A), fontSize: 10, fontFamily: 'JetBrains Mono')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barGroups: top.asMap().entries.map((e) {
                  final color = barColors[e.key % barColors.length];
                  return BarChartGroupData(x: e.key, barRods: [
                    BarChartRodData(
                      toY: e.value.value.toDouble(),
                      color: color,
                      width: 28,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY,
                        color: const Color(0xFF2A2A2A),
                      ),
                    ),
                  ]);
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= top.length) return const SizedBox();
                        final name = top[idx].key;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1, // Force integer intervals
                      getTitlesWidget: (value, _) {
                        if (value == value.roundToDouble() && value >= 0) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: const Color(0xFF2A2A2A),
                    strokeWidth: 0.5,
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF2A2A2A),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${top[groupIndex].key}\n',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toInt()} cảnh',
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
