import 'dart:async';

import 'package:cinex_application/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to ThemeMode.dark when no preference is saved', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = ThemeProvider();
    await _settle();

    expect(provider.themeMode, ThemeMode.dark);
  });

  test('loads a previously saved theme mode on construction', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
    final provider = ThemeProvider();

    final loaded = Completer<void>();
    provider.addListener(() {
      if (!loaded.isCompleted) loaded.complete();
    });
    await loaded.future.timeout(const Duration(seconds: 1));

    expect(provider.themeMode, ThemeMode.light);
  });

  test('falls back to ThemeMode.dark for an unrecognized saved value', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'not-a-real-mode'});
    final provider = ThemeProvider();
    await _settle();

    expect(provider.themeMode, ThemeMode.dark);
  });

  test('setThemeMode updates state, notifies listeners, and persists the choice', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = ThemeProvider();
    await _settle();

    var notified = false;
    provider.addListener(() => notified = true);

    await provider.setThemeMode(ThemeMode.light);

    expect(provider.themeMode, ThemeMode.light);
    expect(notified, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'light');
  });

  test('setThemeMode is a no-op when the mode is unchanged', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = ThemeProvider();
    await _settle();

    var notifyCount = 0;
    provider.addListener(() => notifyCount++);

    await provider.setThemeMode(ThemeMode.dark);

    expect(notifyCount, 0);
  });
}
