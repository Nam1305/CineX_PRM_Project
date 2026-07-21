import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/features/acts/data/models/act.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/shared/widgets/app_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

      String formatDateStr(String? isoString) {
        if (isoString == null || isoString.isEmpty) return 'Chưa rõ';
        try {
          final dt = DateTime.parse(isoString);
          return DateFormat('dd/MM/yyyy').format(dt);
        } catch (_) {
          return isoString;
        }
      }

      // Sắp xếp các hồi theo SequenceOrder
      final sortedActs = List<Act>.from(acts)
        ..sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));

      // Sắp xếp toàn bộ cảnh theo thứ tự dòng thời gian để thống kê
      final chronologicalScenes = List<Scene>.from(allScenes)
        ..sort((a, b) {
          final actA = acts.firstWhere((act) => act.id == a.actId, orElse: () => const Act(id: 0, projectId: 0, sequenceOrder: 99, title: '', status: 'TODO'));
          final actB = acts.firstWhere((act) => act.id == b.actId, orElse: () => const Act(id: 0, projectId: 0, sequenceOrder: 99, title: '', status: 'TODO'));
          final actCompare = actA.sequenceOrder.compareTo(actB.sequenceOrder);
          if (actCompare != 0) return actCompare;
          return a.sceneNumber.compareTo(b.sceneNumber);
        });

      // Sắp xếp các nhân vật xuất hiện trong các phân cảnh của dự án
      final uniqueCharacters = allScenes
          .expand((s) => s.characters)
          .fold<Map<int, Character>>({}, (map, char) {
            if (char.id != null) map[char.id!] = char;
            return map;
          })
          .values
          .toList();

      // Gom nhóm lịch bấm máy dự kiến theo bối cảnh
      final groupedMap = <String, List<Scene>>{};
      for (final scene in chronologicalScenes) {
        final key = scene.location?.name ?? 'Chưa có bối cảnh';
        groupedMap.putIfAbsent(key, () => []).add(scene);
      }

      // Load custom dates from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final customDates = <String, String>{};
      final sceneShootingStatuses = <int, SceneStatus>{};
      for (final scene in chronologicalScenes) {
        final key = scene.location?.name ?? 'Chưa có bối cảnh';
        final savedVal = prefs.getString('proj_${project.id}_loc_${key}_date');
        if (savedVal != null) {
          customDates[key] = savedVal;
        }

        if (scene.id != null) {
          final savedStatus = prefs.getString('proj_${project.id}_scene_${scene.id}_shooting_status');
          if (savedStatus != null) {
            sceneShootingStatuses[scene.id!] = SceneStatusExt.fromDb(savedStatus);
          } else {
            sceneShootingStatuses[scene.id!] = SceneStatus.todo;
          }
        }
      }

      DateTime? getShootingDate(int dayIndex) {
        if (groupedMap.isEmpty || dayIndex >= groupedMap.length) return null;
        final entry = groupedMap.entries.elementAt(dayIndex);
        final customDateStr = customDates[entry.key];
        if (customDateStr != null && customDateStr.isNotEmpty) {
          try {
            return DateTime.parse(customDateStr);
          } catch (_) {}
        }
        if (project.startDate == null || project.startDate!.isEmpty) return null;
        try {
          final base = DateTime.parse(project.startDate!);
          return base.add(Duration(days: dayIndex));
        } catch (_) {
          return null;
        }
      }

      // Tính toán thống kê dự án (tiến độ quay thực tế)
      final totalScenes = chronologicalScenes.length;
      final doneScenes = chronologicalScenes.where((s) => s.status == SceneStatus.done && sceneShootingStatuses[s.id] == SceneStatus.done).length;
      final inProgressScenes = chronologicalScenes.where((s) => s.status == SceneStatus.done && sceneShootingStatuses[s.id] == SceneStatus.inProgress).length;
      final todoScenes = totalScenes - doneScenes - inProgressScenes;
      final progressPercent = totalScenes == 0 ? 0 : (doneScenes / totalScenes * 100).round();

      final totalLocations = chronologicalScenes.map((s) => s.locationId).whereType<int>().toSet().length;
      final intCount = chronologicalScenes.where((s) => s.setting == LocationSetting.interior).length;
      final extCount = chronologicalScenes.where((s) => s.setting == LocationSetting.exterior).length;
      final intPercent = totalScenes == 0 ? 0 : (intCount / totalScenes * 100).round();
      final extPercent = totalScenes == 0 ? 0 : (extCount / totalScenes * 100).round();

      final charCounts = <String, int>{};
      for (var scene in chronologicalScenes) {
        for (var c in scene.characters) {
          charCounts[c.name] = (charCounts[c.name] ?? 0) + 1;
        }
      }
      final sortedChars = charCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // ─── 1. TRANG BÌA (COVER PAGE) ──────────────────────────────────────────
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
                  pw.Spacer(flex: 1),
                  pw.Text(
                    'BÁO CÁO DỰ ÁN ĐIỆN ẢNH CHUẨN HÓA',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 14,
                      color: PdfColor.fromHex('#777777'),
                      letterSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    project.title.toUpperCase(),
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 34,
                      color: PdfColor.fromHex('#FF571A'),
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    width: 120,
                    height: 3,
                    color: PdfColor.fromHex('#FF571A'),
                  ),
                  pw.SizedBox(height: 24),
                  
                  // Metadata Table
                  pw.Container(
                    width: 320,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#FAFAFA'),
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      children: [
                        if (project.director != null && project.director!.isNotEmpty)
                          _buildCoverMetaRow(fontBold, fontRegular, 'Đạo diễn:', project.director!),
                        if (project.genre != null && project.genre!.isNotEmpty)
                          _buildCoverMetaRow(fontBold, fontRegular, 'Thể loại:', project.genre!),
                        _buildCoverMetaRow(fontBold, fontRegular, 'Đoàn phim:', '${project.crewCount} thành viên'),
                        if (project.startDate != null || project.endDate != null)
                          _buildCoverMetaRow(
                            fontBold, 
                            fontRegular, 
                            'Thời gian:', 
                            '${formatDateStr(project.startDate)} - ${formatDateStr(project.endDate)}'
                          ),
                        _buildCoverMetaRow(fontBold, fontRegular, 'Tổng quy mô:', '${acts.length} hồi / ${allScenes.length} phân cảnh'),
                      ],
                    ),
                  ),
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
                            'Tóm tắt cốt truyện (Logline):',
                            style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColor.fromHex('#333333')),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            project.description!,
                            style: pw.TextStyle(font: fontRegular, fontSize: 11, height: 1.4, color: PdfColors.grey800),
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
                        'Phát triển bởi nền tảng CineX',
                        style: pw.TextStyle(font: fontItalic, fontSize: 10, color: PdfColors.grey500),
                      ),
                      pw.Text(
                        'Ngày tạo báo cáo: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
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

      // ─── 2. BÁO CÁO TỔNG QUAN SẢN XUẤT (EXECUTIVE SUMMARY) ────────────────
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'I. BÁO CÁO TỔNG QUAN DỰ ÁN',
                    style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.black),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Divider(color: PdfColors.black, thickness: 1.5),
                  pw.SizedBox(height: 20),

                  // Stats grid row
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _buildSummaryCard(fontBold, fontRegular, 'TIẾN ĐỘ CHUNG', '$progressPercent%', 'Đang quay: $inProgressScenes | Chờ: $todoScenes'),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: _buildSummaryCard(fontBold, fontRegular, 'QUY MÔ NHÂN SỰ', '${uniqueCharacters.length} Diễn viên', 'Thành viên đoàn: ${project.crewCount}'),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: _buildSummaryCard(fontBold, fontRegular, 'ĐỊA ĐIỂM QUAY', '$totalLocations Bối cảnh', 'Nội $intCount / Ngoại $extCount cảnh'),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 24),

                  // Interior vs Exterior details
                  pw.Text(
                    '1. Phân Tích Bối Cảnh Quay (INT vs EXT)',
                    style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColor.fromHex('#FF571A')),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Tổng số phân cảnh sử dụng bối cảnh Trong nhà (Interior) chiếm $intPercent% ($intCount cảnh), trong khi bối cảnh Ngoài trời (Exterior) chiếm $extPercent% ($extCount cảnh). Điều này giúp phòng thiết kế ánh sáng và đạo diễn hình ảnh (DOP) chủ động chuẩn bị các thiết bị chiếu sáng phù hợp cho từng ngày quay.',
                    style: pw.TextStyle(font: fontRegular, fontSize: 10.5, height: 1.4, color: PdfColors.grey800),
                  ),
                  pw.SizedBox(height: 20),

                  // Character frequency table
                  pw.Text(
                    '2. Tần Suất Xuất Hiện Của Nhân Vật Qua Các Cảnh Quay',
                    style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColor.fromHex('#FF571A')),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(1),
                      1: pw.FlexColumnWidth(3),
                      2: pw.FlexColumnWidth(2),
                      3: pw.FlexColumnWidth(2),
                    },
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('STT', style: pw.TextStyle(font: fontBold, fontSize: 9.5), textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Tên Nhân Vật', style: pw.TextStyle(font: fontBold, fontSize: 9.5)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Số Phân Cảnh', style: pw.TextStyle(font: fontBold, fontSize: 9.5), textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Tỷ Lệ Xuất Hiện', style: pw.TextStyle(font: fontBold, fontSize: 9.5), textAlign: pw.TextAlign.center),
                          ),
                        ],
                      ),
                      if (sortedChars.isEmpty)
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('-', textAlign: pw.TextAlign.center),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Chưa có nhân vật nào được phân vai', style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('0', textAlign: pw.TextAlign.center),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('0%', textAlign: pw.TextAlign.center),
                            ),
                          ],
                        )
                      else
                        ...sortedChars.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final char = entry.value;
                          final count = char.value;
                          final ratio = totalScenes == 0 ? 0 : (count / totalScenes * 100).round();
                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text('$idx', style: pw.TextStyle(font: fontRegular, fontSize: 9), textAlign: pw.TextAlign.center),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(char.key, style: pw.TextStyle(font: fontBold, fontSize: 9)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text('$count cảnh', style: pw.TextStyle(font: fontRegular, fontSize: 9), textAlign: pw.TextAlign.center),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text('$ratio%', style: pw.TextStyle(font: fontRegular, fontSize: 9), textAlign: pw.TextAlign.center),
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

      // ─── 3. DANH SÁCH NHÂN VẬT (CAST) ──────────────────────────────────────
      if (uniqueCharacters.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Padding(
                padding: const pw.EdgeInsets.all(32),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'II. DANH SÁCH NHÂN VẬT (CAST LIST)',
                      style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.black),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Divider(color: PdfColors.black, thickness: 1.5),
                    pw.SizedBox(height: 16),
                    
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(2),
                        1: pw.FlexColumnWidth(1.5),
                        2: pw.FlexColumnWidth(2),
                        3: pw.FlexColumnWidth(4.5),
                      },
                      children: [
                        // Table Header
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Nhân vật', style: pw.TextStyle(font: fontBold, fontSize: 10.5)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Vai trò', style: pw.TextStyle(font: fontBold, fontSize: 10.5)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Diễn viên', style: pw.TextStyle(font: fontBold, fontSize: 10.5)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Mô tả tâm lý & tạo hình', style: pw.TextStyle(font: fontBold, fontSize: 10.5)),
                            ),
                          ],
                        ),
                        // Table Body Rows
                        ...uniqueCharacters.map((Character c) {
                          final RoleType role = c.roleType;
                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(c.name, style: pw.TextStyle(font: fontBold, fontSize: 9.5)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(role.label, style: pw.TextStyle(font: fontRegular, fontSize: 9.5)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(c.actorName ?? 'Chờ tuyển vai', style: pw.TextStyle(font: fontRegular, fontSize: 9.5)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(c.description ?? 'Không có mô tả chi tiết.', style: pw.TextStyle(font: fontRegular, fontSize: 9, height: 1.3)),
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

      // ─── 3. LỊCH BẤM MÁY DỰ KIẾN (SHOOTING SCHEDULE) ───────────────────────
      if (groupedMap.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Padding(
                padding: const pw.EdgeInsets.all(32),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'III. LỊCH TRÌNH BẤM MÁY DỰ KIẾN',
                      style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.black),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Divider(color: PdfColors.black, thickness: 1.5),
                    pw.SizedBox(height: 16),
                    pw.Text(
                      'Kế hoạch bấm máy được tự động sắp xếp thông minh bằng cách tối ưu hóa và gom nhóm các phân cảnh có cùng bối cảnh, giúp tiết kiệm tối đa chi phí thiết lập ánh sáng, thiết bị và đi lại cho đoàn làm phim.',
                      style: pw.TextStyle(font: fontItalic, fontSize: 10, color: PdfColors.grey700, height: 1.4),
                    ),
                    pw.SizedBox(height: 20),
                    
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(2),
                        1: pw.FlexColumnWidth(5.5),
                        2: pw.FlexColumnWidth(1.5),
                        3: pw.FlexColumnWidth(2),
                      },
                      children: [
                        // Table Header
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Ngày quay', style: pw.TextStyle(font: fontBold, fontSize: 10.5)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Bối cảnh / Địa điểm', style: pw.TextStyle(font: fontBold, fontSize: 10.5)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Số cảnh', style: pw.TextStyle(font: fontBold, fontSize: 10.5), textAlign: pw.TextAlign.center),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Cảnh chi tiết', style: pw.TextStyle(font: fontBold, fontSize: 10.5), textAlign: pw.TextAlign.center),
                            ),
                          ],
                        ),
                        // Table Body Rows
                        ...groupedMap.entries.toList().asMap().entries.map((entryIdx) {
                          final idx = entryIdx.key;
                          final group = entryIdx.value;
                          final date = getShootingDate(idx);
                          final dateStr = date != null ? DateFormat('dd/MM/yyyy').format(date) : '';
                          final dayLabel = dateStr.isNotEmpty ? 'Ngày ${idx + 1}\n($dateStr)' : 'Ngày ${idx + 1}';
                          final sceneNums = group.value.map((s) => s.sceneNumber).join(', ');

                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(dayLabel, style: pw.TextStyle(font: fontBold, fontSize: 9)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(group.key, style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text('${group.value.length}', style: pw.TextStyle(font: fontRegular, fontSize: 9), textAlign: pw.TextAlign.center),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(sceneNums, style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColor.fromHex('#FF571A')), textAlign: pw.TextAlign.center),
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

      // ─── 4. CHI TIẾT PHÂN CẢNH THEO HỒI (CHRONOLOGICAL SCENARIO) ───────────
      for (final act in sortedActs) {
        // Lấy tất cả phân cảnh thuộc Hồi hiện tại, sắp xếp theo SceneNumber để đúng thứ tự thời gian
        final actScenes = allScenes.where((s) => s.actId == act.id).toList()
          ..sort((a, b) => a.sceneNumber.compareTo(b.sceneNumber));

        if (actScenes.isEmpty) continue;

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            header: (pw.Context context) {
              return pw.Container(
                alignment: pw.Alignment.centerRight,
                padding: const pw.EdgeInsets.only(bottom: 6),
                margin: const pw.EdgeInsets.only(bottom: 12),
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
                margin: const pw.EdgeInsets.only(top: 12),
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
                  final setting = scene.location?.setting == LocationSetting.interior ? 'INT' : 'EXT';
                  final locName = scene.location?.name ?? 'CHƯA CÓ BỐI CẢNH';
                  final time = scene.location?.timeOfDay == SceneTime.day ? 'NGÀY' : 'ĐÊM';
                  final charactersList = scene.characters.map((c) => c.name).join(', ');

                  // Xác định ngày quay cho cảnh này
                  int sceneDayNum = 0;
                  String sceneDateStr = '';
                  int keyIdx = 0;
                  for (var entry in groupedMap.entries) {
                    if (entry.value.any((s) => s.id == scene.id)) {
                      sceneDayNum = keyIdx + 1;
                      final sDate = getShootingDate(keyIdx);
                      if (sDate != null) {
                        sceneDateStr = DateFormat('dd/MM/yyyy').format(sDate);
                      }
                      break;
                    }
                    keyIdx++;
                  }

                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 20),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Scene Header: e.g. "CẢNH 1. INT. PHỐ CỔ - NGÀY"
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#F9F9F9'),
                            border: pw.Border.all(color: PdfColors.grey300),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'CẢNH ${scene.sceneNumber.toString().padLeft(2, '0')}. $setting. $locName - $time',
                                    style: pw.TextStyle(font: fontBold, fontSize: 10.5, color: PdfColors.black),
                                  ),
                                  pw.Text(
                                    '[Trạng thái: ${scene.status.shootingLabel}]',
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      fontSize: 8.5,
                                      color: scene.status == SceneStatus.done
                                          ? PdfColors.green
                                          : (scene.status == SceneStatus.inProgress
                                              ? PdfColors.amber
                                              : PdfColors.grey700),
                                    ),
                                  ),
                                ],
                              ),
                              if (sceneDayNum > 0) ...[
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'Lịch quay dự kiến: Ngày $sceneDayNum${sceneDateStr.isNotEmpty ? ' ($sceneDateStr)' : ''}',
                                  style: pw.TextStyle(
                                    font: fontItalic,
                                    fontSize: 8.5,
                                    color: PdfColor.fromHex('#FF571A'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        
                        // Scene Title / Name
                        pw.Text(
                          'Tiêu đề phân cảnh: ${scene.title}',
                          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey800),
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
                                  style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey800),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 6),
                        ],

                        // Scene outline/action summary
                        pw.Text(
                          'Nội dung diễn biến phân cảnh:',
                          style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey600),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          scene.summary ?? 'Chưa soạn thảo nội dung phân cảnh.',
                          style: pw.TextStyle(font: fontRegular, fontSize: 9.5, height: 1.4, color: PdfColors.grey900),
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
        name: 'BaoCaoDuAn_${project.title.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      print('PdfExporter.exportScreenplay error: $e');
      if (context.mounted) {
        AppSnackbar.error(context, 'Lỗi xuất file PDF kịch bản: $e');
      }
    }
  }

  // Cover page meta row helper
  static pw.Widget _buildCoverMetaRow(pw.Font fontBold, pw.Font fontRegular, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  // Summary card widget builder
  static pw.Widget _buildSummaryCard(pw.Font fontBold, pw.Font fontRegular, String title, String value, String sub) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F5F5'),
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColor.fromHex('#FF571A')),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            sub,
            style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }
}
