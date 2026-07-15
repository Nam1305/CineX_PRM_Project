import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';

class SceneCharactersChart extends StatelessWidget {
  final List<Scene> scenes;

  const SceneCharactersChart({super.key, required this.scenes});

  @override
  Widget build(BuildContext context) {
    if (scenes.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sắp xếp các cảnh theo số phân cảnh để biểu đồ tuần tự khoa học
    final sortedScenes = List<Scene>.from(scenes)
      ..sort((a, b) => a.sceneNumber.compareTo(b.sceneNumber));

    // Lấy tối đa 10 cảnh để tránh biểu đồ quá dày
    final displayScenes = sortedScenes.take(10).toList();

    final maxVal = displayScenes
        .map((s) => s.characters.length)
        .fold<int>(0, (max, val) => val > max ? val : max);

    // Ensure maxY is at least 1 and always integer
    final maxY = maxVal > 0 ? maxVal.toDouble() + 1 : 5.0;

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
          const Text(
            'Số lượng Nhân vật theo Phân cảnh',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barGroups: displayScenes.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.characters.length.toDouble(),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                        ),
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: const Color(0xFF2A2A2A),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= displayScenes.length) {
                          return const SizedBox();
                        }
                        final sceneNum = displayScenes[idx].sceneNumber;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Cảnh $sceneNum',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
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
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
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
                      final scene = displayScenes[groupIndex];
                      final charList =
                          scene.characters.map((c) => c.name).join(', ');
                      return BarTooltipItem(
                        'Cảnh ${scene.sceneNumber}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toInt()} nhân vật\n',
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 10,
                            ),
                          ),
                          TextSpan(
                            text: charList.isNotEmpty ? '($charList)' : '(Trống)',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 9,
                            ),
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
