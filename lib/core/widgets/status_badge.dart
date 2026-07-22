import 'package:flutter/material.dart';
import 'package:cinex_application/core/theme/app_colors.dart';

enum StatusType { active, completed, pending, approved }

class StatusBadge extends StatelessWidget {
  final StatusType status;
  final String label;

  const StatusBadge({
    super.key,
    required this.status,
    required this.label,
  });

  Color _getColor(BuildContext context) {
    final appColors = context.appColors;
    switch (status) {
      case StatusType.active:
        return appColors.danger;
      case StatusType.completed:
        return appColors.success;
      case StatusType.pending:
        return appColors.warning;
      case StatusType.approved:
        return appColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
