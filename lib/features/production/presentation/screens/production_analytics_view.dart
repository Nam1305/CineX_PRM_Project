import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/production/providers/production_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../widgets/int_ext_pie_chart.dart';
import '../widgets/character_frequency_chart.dart';
import 'package:cinex_application/core/utils/enums.dart';

class ProductionAnalyticsView extends StatelessWidget {
  final ProductionProvider provider;

  const ProductionAnalyticsView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
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

    return Container(
      color: const Color(0xFF131313),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thống kê Sản xuất',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _exportReport(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF571A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Tải báo cáo'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Tổng cảnh', provider.allScenes.length.toString(), Icons.movie_creation),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Bối cảnh', provider.groupedByLocation.length.toString(), Icons.location_on),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Đã quay',
                    provider.allScenes.where((s) => s.status.name == 'done').length.toString(),
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Int vs Ext Chart
            IntExtPieChart(scenes: provider.allScenes),
            const SizedBox(height: 24),
            
            // Character Frequency Chart
            CharacterFrequencyChart(scenes: provider.allScenes),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _exportReport(BuildContext context) async {
    final provider = context.read<ProductionProvider>();
    if (provider.allScenes.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang tạo báo cáo PDF...'),
        backgroundColor: Colors.blueGrey,
      ),
    );

    try {
      final pdf = pw.Document();

      // Tính toán thống kê
      final totalScenes = provider.allScenes.length;
      final doneScenes = provider.allScenes.where((s) => s.status.name == 'done').length;
      
      int intCount = 0;
      int extCount = 0;
      for (var s in provider.allScenes) {
        if (s.location?.setting == LocationSetting.interior) intCount++;
        if (s.location?.setting == LocationSetting.exterior) extCount++;
      }

      final charCounts = <String, int>{};
      for (var scene in provider.allScenes) {
        for (var c in scene.characters) {
          charCounts[c.name] = (charCounts[c.name] ?? 0) + 1;
        }
      }
      final sortedChars = charCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Font hỗ trợ tiếng Việt
      final ttf = await PdfGoogleFonts.notoSansRegular();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('BÁO CÁO SẢN XUẤT CINEX', style: pw.TextStyle(font: ttf, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                
                pw.Text('1. Tổng quan:', style: pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Bullet(text: 'Tổng số phân cảnh: $totalScenes', style: pw.TextStyle(font: ttf)),
                pw.Bullet(text: 'Đã quay xong: $doneScenes', style: pw.TextStyle(font: ttf)),
                pw.SizedBox(height: 10),

                pw.Text('2. Bối cảnh (INT/EXT):', style: pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Bullet(text: 'Nội cảnh (INT): $intCount', style: pw.TextStyle(font: ttf)),
                pw.Bullet(text: 'Ngoại cảnh (EXT): $extCount', style: pw.TextStyle(font: ttf)),
                pw.SizedBox(height: 10),

                pw.Text('3. Tần suất xuất hiện nhân vật:', style: pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.ListView.builder(
                  itemCount: sortedChars.length,
                  itemBuilder: (context, index) {
                    final e = sortedChars[index];
                    return pw.Bullet(text: '${e.key}: ${e.value} phân cảnh', style: pw.TextStyle(font: ttf));
                  },
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'BaoCaoSảnXuất_CineX.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
              fontFamily: 'JetBrains Mono',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
