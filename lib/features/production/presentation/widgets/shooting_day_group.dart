import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/auth/providers/auth_provider.dart';
import 'package:cinex_application/features/production/providers/production_provider.dart';
import 'package:cinex_application/features/notifications/providers/notification_provider.dart';
import 'package:cinex_application/features/notifications/data/models/notification_model.dart';
import 'package:cinex_application/core/theme/app_colors.dart';

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
        SnackBar(
          content: const Text(
            'Chỉ Nhà sản xuất / Trợ lý đạo diễn mới có quyền thay đổi lịch quay.',
          ),
          backgroundColor: context.appColors.warning,
        ),
      );
      return;
    }

    DateTime? baseStartDate;
    if (widget.projectStartDate != null &&
        widget.projectStartDate!.isNotEmpty) {
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
        final pickerTheme = Theme.of(context);
        return Theme(
          data: pickerTheme.copyWith(
            colorScheme: pickerTheme.colorScheme.copyWith(
              onPrimary: pickerTheme.colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null && context.mounted) {
      // 1. Validation: Không chọn ngày trong quá khứ
      final selectedMidnight = DateTime(
        selected.year,
        selected.month,
        selected.day,
      );
      if (selectedMidnight.isBefore(todayMidnight)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ngày quay không được ở trong quá khứ!'),
            backgroundColor: context.appColors.danger,
          ),
        );
        return;
      }

      // 2. Validation: Ngày bắt đầu / kết thúc dự án
      if (baseStartDate != null &&
          selectedMidnight.isBefore(
            DateTime(
              baseStartDate.year,
              baseStartDate.month,
              baseStartDate.day,
            ),
          )) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ngày chọn không được trước ngày bắt đầu dự án (${DateFormat('dd/MM/yyyy').format(baseStartDate)})',
            ),
            backgroundColor: context.appColors.danger,
          ),
        );
        return;
      }
      if (baseEndDate != null &&
          selectedMidnight.isAfter(
            DateTime(baseEndDate.year, baseEndDate.month, baseEndDate.day),
          )) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ngày chọn không được sau ngày kết thúc dự án (${DateFormat('dd/MM/yyyy').format(baseEndDate)})',
            ),
            backgroundColor: context.appColors.danger,
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
            content: Text(
              'Ngày ${DateFormat('dd/MM/yyyy').format(selected)} đã được gán cho bối cảnh khác! Vui lòng chọn ngày khác.',
            ),
            backgroundColor: context.appColors.danger,
          ),
        );
        return;
      }

      final saved = await provider.setCustomDate(
        widget.projectId,
        widget.locationLabel,
        dateStr,
      );
      if (!saved) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'Không thể cập nhật ngày quay.'),
              backgroundColor: context.appColors.danger,
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        context.read<NotificationProvider>().addNotification(
          projectId: widget.projectId,
          title: 'Cập nhật lịch quay',
          body:
              'Bối cảnh "${widget.locationLabel}" đã được gán ngày quay ${DateFormat('dd/MM/yyyy').format(selected)}.',
          actionType: NotificationActionType.update,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Đã cập nhật ngày quay thành công! Danh sách ngày quay đã được sắp xếp theo thời gian.',
            ),
            backgroundColor: context.appColors.success,
          ),
        );
      }
    }
  }

  Future<void> _changeShootingStatus(BuildContext context, Scene s) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isProducer) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Chỉ Nhà sản xuất / Trợ lý đạo diễn mới có quyền thay đổi trạng thái lịch quay.',
          ),
          backgroundColor: context.appColors.warning,
        ),
      );
      return;
    }

    if (s.status != SceneStatus.done) {
      showDialog(
        context: context,
        builder: (context) {
          final theme = Theme.of(context);
          final appColors = context.appColors;
          return AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            title: Text(
              'Kịch bản chưa hoàn thành',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            content: Text(
              'Phân cảnh này chưa hoàn thành viết kịch bản. Vui lòng cập nhật trạng thái kịch bản sang "Đã xong" trong tab Storyboard trước khi bắt đầu quay.',
              style: TextStyle(color: appColors.textFaint),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Đóng',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          );
        },
      );
      return;
    }

    final provider = context.read<ProductionProvider>();
    final currentStatus = provider.getShootingStatus(s);

    final selected = await showDialog<SceneStatus>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return SimpleDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            'Trạng thái quay - Cảnh ${s.sceneNumber}',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          children: [
            _statusOption(
              context,
              SceneStatus.todo,
              'Chờ quay',
              currentStatus == SceneStatus.todo,
            ),
            _statusOption(
              context,
              SceneStatus.inProgress,
              'Đang quay',
              currentStatus == SceneStatus.inProgress,
            ),
            _statusOption(
              context,
              SceneStatus.done,
              'Đã quay xong',
              currentStatus == SceneStatus.done,
            ),
          ],
        );
      },
    );

    if (selected != null && s.id != null && context.mounted) {
      final saved = await provider.updateShootingStatus(
        widget.projectId,
        s.id!,
        selected,
      );
      if (!saved) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                provider.error ?? 'Không thể cập nhật trạng thái quay.',
              ),
              backgroundColor: context.appColors.danger,
            ),
          );
        }
        return;
      }
      if (context.mounted) {
        context.read<NotificationProvider>().addNotification(
          projectId: widget.projectId,
          sceneId: s.id,
          title: 'Cập nhật trạng thái quay - Cảnh ${s.sceneNumber}',
          body:
              'Cảnh ${s.sceneNumber} (${widget.locationLabel}) đã chuyển sang: ${selected.shootingLabel}.',
          actionType: NotificationActionType.statusChange,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã cập nhật trạng thái quay sang: ${selected.shootingLabel}',
            ),
            backgroundColor: context.appColors.success,
          ),
        );
      }
    }
  }

  Widget _statusOption(
    BuildContext context,
    SceneStatus value,
    String label,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, value),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected)
            Icon(Icons.check, color: theme.colorScheme.primary, size: 18),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.scenes.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final appColors = context.appColors;
    final groupMode = context.watch<ProductionProvider>().groupMode;
    final isByCharacter = groupMode == ProductionGroupMode.byCharacter;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: appColors.surfaceElevated),
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
                color: appColors.surfaceElevated,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: _isExpanded ? Radius.zero : const Radius.circular(12),
                ),
                border: Border(
                  bottom: BorderSide(color: appColors.surfaceElevated),
                ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.15,
                                ),
                                border: Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.shootingDate != null
                                        ? 'NGÀY ${widget.dayNumber} · ${DateFormat('dd/MM').format(widget.shootingDate!)}'
                                        : 'CHƯA XẾP NGÀY',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (context
                                      .watch<AuthProvider>()
                                      .isProducer) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.edit_calendar,
                                      color: theme.colorScheme.primary,
                                      size: 12,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: appColors.info.withValues(alpha: 0.15),
                              border: Border.all(color: appColors.info, width: 1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  color: appColors.info,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'DIỄN VIÊN',
                                  style: TextStyle(
                                    color: appColors.info,
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
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.scenes.length} cảnh',
                        style: TextStyle(
                          fontSize: 11,
                          color: appColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: appColors.textFaint,
                        size: 18,
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
              separatorBuilder: (context, index) =>
                  Divider(color: appColors.surfaceElevated, height: 1),
              itemBuilder: (context, index) {
                final s = widget.scenes[index];
                final provider = context.watch<ProductionProvider>();
                final shootingStatus = provider.getShootingStatus(s);

                final String displayLabel;
                final Color badgeColor;
                final Color textColor;

                if (s.status != SceneStatus.done) {
                  displayLabel = 'Chờ viết';
                  badgeColor = appColors.textFaint.withAlpha(25);
                  textColor = appColors.textFaint;
                } else {
                  if (shootingStatus == SceneStatus.todo) {
                    displayLabel = 'Chờ quay';
                    badgeColor = appColors.textFaint.withAlpha(25);
                    textColor = appColors.textFaint;
                  } else if (shootingStatus == SceneStatus.inProgress) {
                    displayLabel = 'Đang quay';
                    badgeColor = appColors.warning.withAlpha(25);
                    textColor = appColors.warning;
                  } else {
                    displayLabel = 'Đã quay xong';
                    badgeColor = appColors.success.withAlpha(25);
                    textColor = appColors.success;
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
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: appColors.surfaceElevated),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'CẢNH',
                              style: TextStyle(
                                fontSize: 10,
                                color: appColors.textFaint,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.sceneNumber.toString(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
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
                                    s.summary ??
                                        (s.title.isNotEmpty
                                            ? s.title
                                            : 'Chưa có tiêu đề'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                InkWell(
                                  onTap: () =>
                                      _changeShootingStatus(context, s),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
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
                                        if (s.status == SceneStatus.done &&
                                            context
                                                .watch<AuthProvider>()
                                                .isProducer) ...[
                                          const SizedBox(width: 2),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            color: textColor,
                                            size: 12,
                                          ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: s.setting == LocationSetting.interior
                                        ? Colors.blue.shade900.withValues(
                                            alpha: 0.3,
                                          )
                                        : Colors.orange.shade900.withValues(
                                            alpha: 0.3,
                                          ),
                                    border: Border.all(
                                      color:
                                          s.setting == LocationSetting.interior
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
                                      color:
                                          s.setting == LocationSetting.interior
                                          ? Colors.blue.shade200
                                          : Colors.orange.shade200,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: s.timeOfDay == SceneTime.day
                                        ? Colors.amber.shade900.withValues(
                                            alpha: 0.3,
                                          )
                                        : Colors.indigo.shade900.withValues(
                                            alpha: 0.3,
                                          ),
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
                                  Icon(
                                    Icons.groups,
                                    size: 14,
                                    color: appColors.textFaint,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      s.characters
                                          .map((e) => e.name)
                                          .join(', '),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: appColors.textFaint,
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
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: appColors.textFaint,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      s.location?.name ?? 'Chưa có bối cảnh',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: appColors.textFaint,
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
