import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/features/acts/data/models/act.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/shared/widgets/app_snackbar.dart';

class PdfExporter {
  /// Xuất toàn bộ kịch bản phim dưới dạng PDF chuẩn hóa
  static Future<void> exportScreenplay({
    required BuildContext context,
    required Project project,
    required List<Act> acts,
    required List<Scene> allScenes,
  }) async {
    try {
      final pdf = pw.Document();

      // Sử dụng Google Fonts để tải font hỗ trợ tiếng Việt tại runtime
      final fontRegular = await PdfGoogleFonts.notoSansRegular();
      final fontBold = await PdfGoogleFonts.notoSansBold();
      final fontItalic = await PdfGoogleFonts.notoSansItalic();

      // Sắp xếp các hồi theo SequenceOrder
      final sortedActs = List<Act>.from(acts)
        ..sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));

      // Thu thập danh sách nhân vật xuất hiện trong các phân cảnh của dự án
      final uniqueCharacters = allScenes
          .expand((s) => s.characters)
          .fold<Map<int, dynamic>>({}, (map, char) {
            if (char.id != null) map[char.id!] = char;
            return map;
          })
          .values
          .toList();

      // 1. TRANG BÌA (COVER PAGE)
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Spacer(flex: 2),
                  pw.Text(
                    'KỊCH BẢN PHÂN CẢNH CHI TIẾT',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 16,
                      color: PdfColor.fromHex('#666666'),
                      letterSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    project.title.toUpperCase(),
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 32,
                      color: PdfColor.fromHex('#FF571A'),
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 24),
                  if (project.director != null && project.director!.isNotEmpty) ...[
                    pw.Text(
                      'Đạo diễn: ${project.director}',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 16,
                      ),
                    ),
                  ],
                  if (project.genre != null) ...[
                    pw.Text(
                      'Thể loại: ${project.genre}',
                      style: pw.TextStyle(
                        font: fontItalic,
                        fontSize: 14,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                  pw.Spacer(flex: 1),
                  if (project.description != null && project.description!.isNotEmpty) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Tóm tắt (Logline):',
                            style: pw.TextStyle(font: fontBold, fontSize: 12),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            project.description!,
                            style: pw.TextStyle(font: fontRegular, fontSize: 11, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                  pw.Spacer(flex: 2),
                  pw.Divider(color: PdfColors.grey300),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Phát triển bởi CineX',
                        style: pw.TextStyle(font: fontItalic, fontSize: 10, color: PdfColors.grey500),
                      ),
                      pw.Text(
                        'Ngày xuất bản: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                        style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey500),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      // 2. DANH SÁCH NHÂN VẬT (CHARACTERS PAGE)
      if (uniqueCharacters.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Padding(
                padding: const pw.EdgeInsets.all(24),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'I. DANH SÁCH NHÂN VẬT (CAST)',
                      style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.black),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Divider(color: PdfColors.black, thickness: 1.5),
                    pw.SizedBox(height: 16),
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(2),
                        1: pw.FlexColumnWidth(1.5),
                        2: pw.FlexColumnWidth(1.5),
                        3: pw.FlexColumnWidth(4),
                      },
                      children: [
                        // Table Header
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Nhân vật', style: pw.TextStyle(font: fontBold, fontSize: 11)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Vai trò', style: pw.TextStyle(font: fontBold, fontSize: 11)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Diễn viên', style: pw.TextStyle(font: fontBold, fontSize: 11)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Mô tả', style: pw.TextStyle(font: fontBold, fontSize: 11)),
                            ),
                          ],
                        ),
                        // Table Body Rows
                        ...uniqueCharacters.map((c) {
                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(c.name, style: pw.TextStyle(font: fontBold, fontSize: 10)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(c.roleType.label, style: pw.TextStyle(font: fontRegular, fontSize: 10)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(c.actorName ?? 'Chờ tuyển vai', style: pw.TextStyle(font: fontRegular, fontSize: 10)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(c.description ?? 'Không có mô tả.', style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }

      // 3. CHI TIẾT PHÂN CẢNH THEO HỒI (SCENES PAGES)
      for (final act in sortedActs) {
        // Lấy tất cả phân cảnh thuộc Hồi hiện tại, sắp xếp theo SceneNumber
        final actScenes = allScenes.where((s) => s.actId == act.id).toList()
          ..sort((a, b) => a.sceneNumber.compareTo(b.sceneNumber));

        if (actScenes.isEmpty) continue;

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            header: (pw.Context context) {
              return pw.Container(
                alignment: pw.Alignment.centerRight,
                padding: const pw.EdgeInsets.only(bottom: 8),
                margin: const pw.EdgeInsets.only(bottom: 16),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                ),
                child: pw.Text(
                  '${project.title.toUpperCase()} - ${act.title.toUpperCase()}',
                  style: pw.TextStyle(font: fontItalic, fontSize: 8, color: PdfColors.grey500),
                ),
              );
            },
            footer: (pw.Context context) {
              return pw.Container(
                alignment: pw.Alignment.center,
                margin: const pw.EdgeInsets.only(top: 16),
                child: pw.Text(
                  'Trang ${context.pageNumber} / ${context.pagesCount}',
                  style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey500),
                ),
              );
            },
            build: (pw.Context context) {
              return [
                pw.Text(
                  act.title.toUpperCase(),
                  style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.black),
                ),
                if (act.summary != null && act.summary!.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    act.summary!,
                    style: pw.TextStyle(font: fontItalic, fontSize: 11, color: PdfColors.grey700),
                  ),
                ],
                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.grey400, thickness: 1),
                pw.SizedBox(height: 12),

                ...actScenes.map((scene) {
                  final setting = scene.location?.setting.label ?? 'INT';
                  final locName = scene.location?.name ?? 'CHƯA RÕ BỐI CẢNH';
                  final time = scene.location?.timeOfDay.label ?? 'NGÀY';
                  final charactersList = scene.characters.map((c) => c.name).join(', ');

                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 24),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Scene Header: e.g. "CẢNH 1. INT. PHỐ CỔ - NGÀY"
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#F5F5F5'),
                            border: pw.Border.all(color: PdfColors.grey300),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'CẢNH ${scene.sceneNumber}. $setting. $locName - $time',
                                style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.black),
                              ),
                              pw.Text(
                                '[Trạng thái: ${scene.status.label}]',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 9,
                                  color: scene.status == SceneStatus.done
                                      ? PdfColors.green
                                      : (scene.status == SceneStatus.inProgress
                                          ? PdfColors.amber
                                          : PdfColors.grey700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        
                        // Scene Title / Name
                        pw.Text(
                          'Tiêu đề: ${scene.title}',
                          style: pw.TextStyle(font: fontBold, fontSize: 10),
                        ),
                        pw.SizedBox(height: 4),

                        // Characters appearing
                        if (charactersList.isNotEmpty) ...[
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: 'Nhân vật xuất hiện: ',
                                  style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.black),
                                ),
                                pw.TextSpan(
                                  text: charactersList,
                                  style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey700),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 6),
                        ],

                        // Scene outline/action summary
                        pw.Text(
                          'Hành động phân cảnh:',
                          style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey600),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          scene.summary ?? 'Chưa có tóm tắt nội dung.',
                          style: pw.TextStyle(font: fontRegular, fontSize: 10, height: 1.4),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Divider(color: PdfColors.grey200, thickness: 0.5),
                      ],
                    ),
                  );
                }),
              ];
            },
          ),
        );
      }

      // Khởi chạy trình xem và in PDF hệ thống
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'KichBan_${project.title.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      print('PdfExporter.exportScreenplay error: $e');
      if (context.mounted) {
        AppSnackbar.error(context, 'Lỗi xuất file PDF kịch bản: $e');
      }
    }
  }
}
