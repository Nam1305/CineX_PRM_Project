import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/notifications/providers/notification_provider.dart';
import 'package:cinex_application/features/notifications/presentation/screens/notification_screen.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSearch;
  final VoidCallback? onNotification;
  final VoidCallback? onAdd;

  const AppHeader({
    super.key,
    required this.title,
    this.onSearch,
    this.onNotification,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineLarge,
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.search_outlined),
                onPressed: onSearch ?? () {},
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: onNotification ??
                        () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationScreen(),
                              ),
                            ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF571A),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              if (onAdd != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.tealAccent),
                  onPressed: onAdd,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
