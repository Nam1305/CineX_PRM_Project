import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/main/presentation/screens/main_screen.dart';

class CineXApp extends StatelessWidget {
  const CineXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const MainScreen(),
    );
  }
}
