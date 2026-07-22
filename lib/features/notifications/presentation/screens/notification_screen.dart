import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cinex_application/features/notifications/providers/notification_provider.dart';
import 'package:cinex_application/features/notifications/data/models/notification_model.dart';
import 'package:cinex_application/shared/widgets/app_snackbar.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  Future<void> _markAllAsRead(NotificationProvider provider) async {
    final success = await provider.markAllAsRead();
    if (!success && mounted) {
      AppSnackbar.error(
        context,
        provider.error ?? 'Không thể đánh dấu tất cả thông báo đã đọc.',
      );
    }
  }

  Future<void> _markAsRead(
    NotificationProvider provider,
    int? notificationId,
  ) async {
    final success = await provider.markAsRead(notificationId);
    if (!success && mounted) {
      AppSnackbar.error(
        context,
        provider.error ?? 'Không thể đánh dấu thông báo đã đọc.',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  IconData _getActionIcon(NotificationActionType type) {
    switch (type) {
      case NotificationActionType.create:
        return Icons.add_circle_outline;
      case NotificationActionType.update:
        return Icons.edit_outlined;
      case NotificationActionType.delete:
        return Icons.delete_outline;
      case NotificationActionType.statusChange:
        return Icons.check_circle_outline;
    }
  }

  Color _getActionColor(NotificationActionType type) {
    switch (type) {
      case NotificationActionType.create:
        return Colors.greenAccent;
      case NotificationActionType.update:
        return Colors.lightBlueAccent;
      case NotificationActionType.delete:
        return Colors.redAccent;
      case NotificationActionType.statusChange:
        return const Color(0xFFFF571A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final groupedMap = provider.groupedByProject;

    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1B1B),
        title: Row(
          children: [
            const Text('Thông báo'),
            if (provider.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF571A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${provider.unreadCount} mới',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (provider.unreadCount > 0)
            TextButton.icon(
              onPressed: () => _markAllAsRead(provider),
              icon: const Icon(
                Icons.done_all,
                size: 16,
                color: Color(0xFFFF571A),
              ),
              label: const Text(
                'Đọc tất cả',
                style: TextStyle(color: Color(0xFFFF571A), fontSize: 12),
              ),
            ),
        ],
      ),
      body: provider.isLoading && groupedMap.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF571A)),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => provider.loadNotifications(),
              color: const Color(0xFFFF571A),
              backgroundColor: const Color(0xFF1E1E1E),
              child: groupedMap.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 200),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.notifications_none,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                provider.error ?? 'Không có thông báo nào',
                                style: TextStyle(
                                  color: provider.error == null
                                      ? Colors.grey
                                      : Colors.orangeAccent,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: groupedMap.length,
                      itemBuilder: (context, index) {
                        final projectTitle = groupedMap.keys.elementAt(index);
                        final notifs = groupedMap[projectTitle]!;
                        final unreadInProj = notifs
                            .where((n) => !n.isRead)
                            .length;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: const Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFF2C2C2C)),
                          ),
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFF571A,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.movie_outlined,
                                color: Color(0xFFFF571A),
                                size: 20,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    projectTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                if (unreadInProj > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF571A),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$unreadInProj chưa đọc',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            children: notifs.map((n) {
                              return InkWell(
                                onTap: () => _markAsRead(provider, n.id),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: n.isRead
                                        ? Colors.transparent
                                        : const Color(
                                            0xFFFF571A,
                                          ).withValues(alpha: 0.05),
                                    border: const Border(
                                      top: BorderSide(
                                        color: Color(0xFF2C2C2C),
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        _getActionIcon(n.actionType),
                                        color: _getActionColor(n.actionType),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    n.title,
                                                    style: TextStyle(
                                                      color: n.isRead
                                                          ? Colors.white70
                                                          : Colors.white,
                                                      fontWeight: n.isRead
                                                          ? FontWeight.normal
                                                          : FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  _formatTimeAgo(n.timestamp),
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              n.body,
                                              style: TextStyle(
                                                color: n.isRead
                                                    ? Colors.grey
                                                    : Colors.grey.shade300,
                                                fontSize: 12,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!n.isRead) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFF571A),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
