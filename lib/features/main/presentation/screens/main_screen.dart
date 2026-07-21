import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/auth/providers/auth_provider.dart';
import 'package:cinex_application/features/projects/presentation/screens/project_list_screen.dart';
import 'package:cinex_application/core/connectivity/network_status_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const ProjectListScreen(),
      const _ProfilePlaceholder(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Consumer<NetworkStatusProvider>(
            builder: (context, network, _) {
              if (!network.isOffline) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                color: Colors.orange.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const SafeArea(
                  top: false,
                  bottom: false,
                  child: Text(
                    'Đang offline: chỉ xem, lọc và xuất dữ liệu đã lưu. Các thay đổi cần kết nối mạng.',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.movie_filter_outlined),
            selectedIcon: Icon(Icons.movie_filter),
            label: 'Dự án',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Icon(
                  Icons.person,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                auth.fullName ?? 'Người dùng',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '@${auth.username}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Chip(
                label: Text(
                  auth.role == 'SCREENWRITER' ? 'Biên kịch' : 'Nhà sản xuất',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
                backgroundColor: theme.colorScheme.primary,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('ĐĂNG XUẤT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => auth.logout(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
