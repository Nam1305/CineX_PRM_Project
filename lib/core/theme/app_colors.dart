import 'package:flutter/material.dart';

/// Semantic colors not covered by [ColorScheme] (status/tag colors, layered
/// surfaces). Access via `Theme.of(context).extension<AppColors>()!`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.surfaceElevated,
    required this.border,
    required this.textMuted,
    required this.textFaint,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  /// A layer above [ColorScheme.surface] (elevated tiles/panels inside a card).
  final Color surfaceElevated;
  final Color border;
  /// Secondary text/icons (was `Colors.white70` in the old dark-only palette).
  final Color textMuted;
  /// Least-emphasis text/icons (was `Colors.grey`).
  final Color textFaint;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  static const dark = AppColors(
    surfaceElevated: Color(0xFF2C2C2C),
    border: Color(0xFF393939),
    textMuted: Colors.white70,
    textFaint: Colors.grey,
    success: Color(0xFF51CF66),
    warning: Color(0xFFFFD43B),
    danger: Color(0xFFFF6B6B),
    info: Color(0xFF42A5F5),
  );

  static const light = AppColors(
    surfaceElevated: Color(0xFFF1F1F1),
    border: Color(0xFFDBDBDB),
    textMuted: Color(0xFF4A4A4A),
    textFaint: Color(0xFF6B6B6B),
    success: Color(0xFF2B9348),
    warning: Color(0xFFB07D00),
    danger: Color(0xFFD64545),
    info: Color(0xFF1971C2),
  );

  @override
  AppColors copyWith({
    Color? surfaceElevated,
    Color? border,
    Color? textMuted,
    Color? textFaint,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
  }) {
    return AppColors(
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
