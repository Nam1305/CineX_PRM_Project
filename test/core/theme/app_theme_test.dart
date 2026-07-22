import 'package:cinex_application/core/theme/app_colors.dart';
import 'package:cinex_application/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('darkTheme and lightTheme report their own brightness', () {
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
      expect(AppTheme.lightTheme.brightness, Brightness.light);
    });

    test('lightTheme is a real theme, not an alias of darkTheme', () {
      expect(
        AppTheme.lightTheme.scaffoldBackgroundColor,
        isNot(AppTheme.darkTheme.scaffoldBackgroundColor),
      );
      expect(
        AppTheme.lightTheme.colorScheme.surface,
        isNot(AppTheme.darkTheme.colorScheme.surface),
      );
    });

    test('brand primary color stays identical across both themes', () {
      const brandOrange = Color(0xFFFF571A);
      expect(AppTheme.darkTheme.colorScheme.primary, brandOrange);
      expect(AppTheme.lightTheme.colorScheme.primary, brandOrange);
    });

    test('each theme carries the matching AppColors extension', () {
      expect(AppTheme.darkTheme.extension<AppColors>(), AppColors.dark);
      expect(AppTheme.lightTheme.extension<AppColors>(), AppColors.light);
    });

    test('dark scaffold background matches the original cinematic palette', () {
      expect(
        AppTheme.darkTheme.scaffoldBackgroundColor,
        const Color(0xFF131313),
      );
      expect(AppTheme.darkTheme.colorScheme.surface, const Color(0xFF1C1B1B));
    });
  });
}
