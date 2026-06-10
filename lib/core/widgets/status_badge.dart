import 'package:flutter/material.dart';

enum StatusType { active, completed, pending, approved }

class StatusBadge extends StatelessWidget {
  final StatusType status;
  final String label;

  const StatusBadge({
    super.key,
    required this.status,
    required this.label,
  });

  Color _getColor() {
    switch (status) {
      case StatusType.active:
        return const Color(0xFFFF6B6B);
      case StatusType.completed:
        return const Color(0xFF51CF66);
      case StatusType.pending:
        return const Color(0xFFFFD43B);
      case StatusType.approved:
        return const Color(0xFF4C6EF5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
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
