import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/main/presentation/screens/main_screen.dart';

class CineXApp extends StatefulWidget {
  const CineXApp({super.key});

  @override
  State<CineXApp> createState() => _CineXAppState();
}

class _CineXAppState extends State<CineXApp> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      context.read<AuthProvider>().tryAutoLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return const MainScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
