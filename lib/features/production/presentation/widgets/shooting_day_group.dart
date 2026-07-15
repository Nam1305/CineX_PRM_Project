import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/auth/providers/auth_provider.dart';
import 'package:cinex_application/features/production/providers/production_provider.dart';

class ShootingDayGroup extends StatelessWidget {
  final String locationLabel;
  final List<Scene> scenes;
  final int dayNumber;
  final DateTime? shootingDate;
  final int projectId;
  final String? projectStartDate;
  final String? projectEndDate;

  const ShootingDayGroup({
    super.key,
    required this.locationLabel,
    required this.scenes,
    required this.dayNumber,
    this.shootingDate,
    required this.projectId,
    this.projectStartDate,
    this.projectEndDate,
  });

  Future<void> _selectDate(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isProducer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ Nhà sản xuất / Trợ lý đạo diễn mới có quyền thay đổi lịch quay.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    DateTime? baseStartDate;
    if (projectStartDate != null && projectStartDate!.isNotEmpty) {
      baseStartDate = DateTime.tryParse(projectStartDate!);
    }
    
    DateTime? baseEndDate;
    if (projectEndDate != null && projectEndDate!.isNotEmpty) {
      baseEndDate = DateTime.tryParse(projectEndDate!);
    }

    // Determine initial date for date picker
    DateTime initial = DateTime.now();
    if (shootingDate != null) {
      initial = shootingDate!;
    } else if (baseStartDate != null) {
      initial = baseStartDate;
    }

    // Ensure initial date is within bounds
    if (baseStartDate != null && initial.isBefore(baseStartDate)) {
      initial = baseStartDate;
    }
    if (baseEndDate != null && initial.isAfter(baseEndDate)) {
      initial = baseEndDate;
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: baseStartDate ?? DateTime(2000),
      lastDate: baseEndDate ?? DateTime(2100),
      helpText: 'Chọn lịch quay cho $locationLabel',
      cancelText: 'Hủy',
      confirmText: 'Lưu',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: const Color(0xFFFF571A),
              onPrimary: Colors.white,
              surface: const Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null && context.mounted) {
      // Validate
      if (baseStartDate != null && selected.isBefore(baseStartDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ngày chọn không được trước ngày bắt đầu dự án (${DateFormat('dd/MM/yyyy').format(baseStartDate)})'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      if (baseEndDate != null && selected.isAfter(baseEndDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ngày chọn không được sau ngày kết thúc dự án (${DateFormat('dd/MM/yyyy').format(baseEndDate)})'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(selected);
      await context.read<ProductionProvider>().setCustomDate(projectId, locationLabel, dateStr);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật lịch quay thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _changeShootingStatus(BuildContext context, Scene s) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isProducer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ Nhà sản xuất / Trợ lý đạo diễn mới có quyền thay đổi trạng thái lịch quay.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    if (s.status != SceneStatus.done) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Kịch bản chưa hoàn thành', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Phân cảnh này chưa hoàn thành viết kịch bản. Vui lòng cập nhật trạng thái kịch bản sang "Đã xong" trong tab Storyboard trước khi bắt đầu quay.',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng', style: TextStyle(color: const Color(0xFFFF571A))),
            ),
          ],
        ),
      );
      return;
    }

    final provider = context.read<ProductionProvider>();
    final currentStatus = provider.getShootingStatus(s);

    final selected = await showDialog<SceneStatus>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('Trạng thái quay - Cảnh ${s.sceneNumber}', style: const TextStyle(color: Colors.white)),
        children: [
          _statusOption(context, SceneStatus.todo, 'Chờ quay', currentStatus == SceneStatus.todo),
          _statusOption(context, SceneStatus.inProgress, 'Đang quay', currentStatus == SceneStatus.inProgress),
          _statusOption(context, SceneStatus.done, 'Đã quay xong', currentStatus == SceneStatus.done),
        ],
      ),
    );

    if (selected != null && s.id != null && context.mounted) {
      await provider.updateShootingStatus(projectId, s.id!, selected);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái quay sang: ${selected.shootingLabel}'),
            backgroundColor: const Color(0xFF51CF66),
          ),
        );
      }
    }
  }

  Widget _statusOption(BuildContext context, SceneStatus value, String label, bool isSelected) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, value),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFFFF571A) : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected) const Icon(Icons.check, color: const Color(0xFFFF571A), size: 18),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (scenes.isEmpty) return const SizedBox.shrink();
    
    // Guess setting and time from the first scene in group if available
    final firstLoc = scenes.first.location;
    final settingStr = (firstLoc?.setting.toString() == LocationSetting.interior.toString() || firstLoc?.setting.toString() == 'LocationSetting.interior' || firstLoc?.setting.toString() == 'INT') ? 'Nội (INT)' : 'Ngoại (EXT)';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // slate-surface
        border: Border.all(color: const Color(0xFF2C2C2C)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A2A), // surface-container-high
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Color(0xFF2C2C2C))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => _selectDate(context),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF571A).withValues(alpha: 0.15),
                            border: Border.all(color: const Color(0xFFFF571A), width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                shootingDate != null
                                    ? 'NGÀY $dayNumber · ${DateFormat('dd/MM').format(shootingDate!)}'
                                    : 'NGÀY $dayNumber',
                                style: const TextStyle(
                                  color: Color(0xFFFF571A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'JetBrains Mono',
                                ),
                              ),
                              if (context.watch<AuthProvider>().isProducer) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.edit_calendar, color: Color(0xFFFF571A), size: 12),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          locationLabel.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  settingStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE6BEB2),
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
          ),
          
          // Scenes List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: scenes.length,
            separatorBuilder: (context, index) => const Divider(color: Color(0xFF2C2C2C), height: 1),
            itemBuilder: (context, index) {
              final s = scenes[index];
              final provider = context.watch<ProductionProvider>();
              final shootingStatus = provider.getShootingStatus(s);

              final String displayLabel;
              final Color badgeColor;
              final Color textColor;

              if (s.status != SceneStatus.done) {
                displayLabel = 'Chờ viết';
                badgeColor = Colors.grey.withAlpha(25);
                textColor = Colors.grey;
              } else {
                if (shootingStatus == SceneStatus.todo) {
                  displayLabel = 'Chờ quay';
                  badgeColor = Colors.grey.withAlpha(25);
                  textColor = Colors.grey;
                } else if (shootingStatus == SceneStatus.inProgress) {
                  displayLabel = 'Đang quay';
                  badgeColor = Colors.amber.withAlpha(25);
                  textColor = Colors.amber;
                } else {
                  displayLabel = 'Đã quay xong';
                  badgeColor = Colors.green.withAlpha(25);
                  textColor = Colors.green;
                }
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scene Number Left
                    Container(
                      width: 60,
                      padding: const EdgeInsets.only(right: 16),
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: Color(0xFF2C2C2C))),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'CẢNH',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.sceneNumber.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF571A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Scene Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  s.summary ?? 'Chưa có tiêu đề',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              InkWell(
                                onTap: () => _changeShootingStatus(context, s),
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    border: Border.all(
                                      color: textColor.withAlpha(51),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        displayLabel,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: textColor,
                                          fontFamily: 'JetBrains Mono',
                                        ),
                                      ),
                                      if (s.status == SceneStatus.done && context.watch<AuthProvider>().isProducer) ...[
                                        const SizedBox(width: 2),
                                        Icon(Icons.arrow_drop_down, color: textColor, size: 12),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (s.characters.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.groups, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    s.characters.map((e) => e.name).join(', '),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontFamily: 'JetBrains Mono',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
