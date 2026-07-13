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
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2C2C2C)),
        ),
        child: const Center(
          child: Text('Chưa có bối cảnh', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final intPercent = (interior / total * 100).round();
    final extPercent = (exterior / total * 100).round();

    return Container(
      height: 220,
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
                'Tỷ lệ Bối cảnh',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Icon(Icons.location_city, color: Color(0xFFFF571A), size: 20),
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
                          color: const Color(0xFFFF571A), // primary
                          radius: 50,
                          titleStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          value: exterior.toDouble(),
                          title: '$extPercent%',
                          color: const Color(0xFFC9A900), // tertiary container
                          radius: 40,
                          titleStyle: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ],
                      sectionsSpace: 4,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegend('NỘI (INT)', const Color(0xFFFF571A), interior),
                    const SizedBox(height: 12),
                    _buildLegend('NGOẠI (EXT)', const Color(0xFFC9A900), exterior),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String title, Color color, int value) {
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
              style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'JetBrains Mono'),
            ),
            Text(
              '$value cảnh',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }
}
