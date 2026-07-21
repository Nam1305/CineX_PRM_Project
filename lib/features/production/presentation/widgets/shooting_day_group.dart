import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/auth/providers/auth_provider.dart';
import 'package:cinex_application/features/production/providers/production_provider.dart';
import 'package:cinex_application/features/notifications/providers/notification_provider.dart';
import 'package:cinex_application/features/notifications/data/models/notification_model.dart';

class ShootingDayGroup extends StatefulWidget {
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

  @override
  State<ShootingDayGroup> createState() => _ShootingDayGroupState();
}

class _ShootingDayGroupState extends State<ShootingDayGroup> {
  bool _isExpanded = true;

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
    if (widget.projectStartDate != null && widget.projectStartDate!.isNotEmpty) {
      baseStartDate = DateTime.tryParse(widget.projectStartDate!);
    }
    
    DateTime? baseEndDate;
    if (widget.projectEndDate != null && widget.projectEndDate!.isNotEmpty) {
      baseEndDate = DateTime.tryParse(widget.projectEndDate!);
    }

    DateTime initial = DateTime.now();
    if (widget.shootingDate != null) {
      initial = widget.shootingDate!;
    } else if (baseStartDate != null) {
      initial = baseStartDate;
    }

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    if (baseStartDate != null && initial.isBefore(baseStartDate)) {
      initial = baseStartDate;
    }
    if (initial.isBefore(todayMidnight)) {
      initial = todayMidnight;
    }
    if (baseEndDate != null && initial.isAfter(baseEndDate)) {
      initial = baseEndDate;
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: baseStartDate != null && baseStartDate.isAfter(todayMidnight)
          ? baseStartDate
          : todayMidnight,
      lastDate: baseEndDate ?? DateTime(2100),
      helpText: 'Chọn lịch quay cho ${widget.locationLabel}',
      cancelText: 'Hủy',
      confirmText: 'Lưu',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF571A),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null && context.mounted) {
      // 1. Validation: Không chọn ngày trong quá khứ
      final selectedMidnight = DateTime(selected.year, selected.month, selected.day);
      if (selectedMidnight.isBefore(todayMidnight)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ngày quay không được ở trong quá khứ!'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // 2. Validation: Ngày bắt đầu / kết thúc dự án
      if (baseStartDate != null && selectedMidnight.isBefore(DateTime(baseStartDate.year, baseStartDate.month, baseStartDate.day))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ngày chọn không được trước ngày bắt đầu dự án (${DateFormat('dd/MM/yyyy').format(baseStartDate)})'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      if (baseEndDate != null && selectedMidnight.isAfter(DateTime(baseEndDate.year, baseEndDate.month, baseEndDate.day))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ngày chọn không được sau ngày kết thúc dự án (${DateFormat('dd/MM/yyyy').format(baseEndDate)})'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // 3. Validation: Không trùng ngày quay với các bối cảnh khác
      final provider = context.read<ProductionProvider>();
      final dateStr = DateFormat('yyyy-MM-dd').format(selected);
      final isDuplicate = provider.customDates.entries.any(
        (entry) => entry.key != widget.locationLabel && entry.value == dateStr,
      );

      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ngày ${DateFormat('dd/MM/yyyy').format(selected)} đã được gán cho bối cảnh khác! Vui lòng chọn ngày khác.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      await provider.setCustomDate(widget.projectId, widget.locationLabel, dateStr);

      if (context.mounted) {
        context.read<NotificationProvider>().addNotification(
              projectId: widget.projectId,
              projectTitle: 'Dự án CineX #${widget.projectId}',
              title: 'Cập nhật lịch quay',
              body: 'Bối cảnh "${widget.locationLabel}" đã được gán ngày quay ${DateFormat('dd/MM/yyyy').format(selected)}.',
              actionType: NotificationActionType.update,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật ngày quay thành công! Danh sách ngày quay đã được sắp xếp theo thời gian.'),
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
              child: const Text('Đóng', style: TextStyle(color: Color(0xFFFF571A))),
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
      await provider.updateShootingStatus(widget.projectId, s.id!, selected);
      if (context.mounted) {
        context.read<NotificationProvider>().addNotification(
              projectId: widget.projectId,
              projectTitle: 'Dự án CineX #${widget.projectId}',
              sceneId: s.id,
              title: 'Cập nhật trạng thái quay - Cảnh ${s.sceneNumber}',
              body: 'Cảnh ${s.sceneNumber} (${widget.locationLabel}) đã chuyển sang: ${selected.shootingLabel}.',
              actionType: NotificationActionType.statusChange,
            );
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
          if (isSelected) const Icon(Icons.check, color: Color(0xFFFF571A), size: 18),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.scenes.isEmpty) return const SizedBox.shrink();
    
    final groupMode = context.watch<ProductionProvider>().groupMode;
    final isByCharacter = groupMode == ProductionGroupMode.byCharacter;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border.all(color: const Color(0xFF2C2C2C)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: _isExpanded ? Radius.zero : const Radius.circular(12),
                ),
                border: const Border(bottom: BorderSide(color: Color(0xFF2C2C2C))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (!isByCharacter)
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
                                    widget.shootingDate != null
                                        ? 'NGÀY ${widget.dayNumber} · ${DateFormat('dd/MM').format(widget.shootingDate!)}'
                                        : 'NGÀY ${widget.dayNumber}',
                                    style: const TextStyle(
                                      color: Color(0xFFFF571A),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (context.watch<AuthProvider>().isProducer) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.edit_calendar, color: Color(0xFFFF571A), size: 12),
                                  ],
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.15),
                              border: Border.all(color: Colors.blue, width: 1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_outline, color: Colors.blue, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'DIỄN VIÊN',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.locationLabel.toUpperCase(),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.scenes.length} phân cảnh',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE6BEB2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Scenes List
          if (_isExpanded)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.scenes.length,
              separatorBuilder: (context, index) => const Divider(color: Color(0xFF2C2C2C), height: 1),
              itemBuilder: (context, index) {
                final s = widget.scenes[index];
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
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.sceneNumber.toString(),
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF571A)),
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
                                    s.summary ?? (s.title.isNotEmpty ? s.title : 'Chưa có tiêu đề'),
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
                            const SizedBox(height: 6),
                            // Badges for Setting & TimeOfDay
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: s.setting == LocationSetting.interior
                                        ? Colors.blue.shade900.withValues(alpha: 0.3)
                                        : Colors.orange.shade900.withValues(alpha: 0.3),
                                    border: Border.all(
                                      color: s.setting == LocationSetting.interior
                                          ? Colors.blue.shade700
                                          : Colors.orange.shade700,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    s.setting.fullLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: s.setting == LocationSetting.interior
                                          ? Colors.blue.shade200
                                          : Colors.orange.shade200,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: s.timeOfDay == SceneTime.day
                                        ? Colors.amber.shade900.withValues(alpha: 0.3)
                                        : Colors.indigo.shade900.withValues(alpha: 0.3),
                                    border: Border.all(
                                      color: s.timeOfDay == SceneTime.day
                                          ? Colors.amber.shade700
                                          : Colors.indigo.shade700,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        s.timeOfDay == SceneTime.day
                                            ? Icons.wb_sunny
                                            : Icons.nightlight_round,
                                        size: 10,
                                        color: s.timeOfDay == SceneTime.day
                                            ? Colors.amber.shade200
                                            : Colors.indigo.shade200,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        s.timeOfDay.fullLabel,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: s.timeOfDay == SceneTime.day
                                              ? Colors.amber.shade200
                                              : Colors.indigo.shade200,
                                        ),
                                      ),
                                    ],
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
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            if (isByCharacter) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      s.location?.name ?? 'Chưa có bối cảnh',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
