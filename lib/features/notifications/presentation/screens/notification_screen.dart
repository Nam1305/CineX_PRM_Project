import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cinex_application/features/notifications/providers/notification_provider.dart';
import 'package:cinex_application/features/notifications/data/models/notification_model.dart';
import 'package:cinex_application/shared/widgets/app_snackbar.dart';
import 'package:cinex_application/core/theme/app_colors.dart';

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
        return context.appColors.success;
      case NotificationActionType.update:
        return context.appColors.info;
      case NotificationActionType.delete:
        return context.appColors.danger;
      case NotificationActionType.statusChange:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final groupedMap = provider.groupedByProject;
    final theme = Theme.of(context);
    final appColors = context.appColors;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Row(
          children: [
            const Text('Thông báo'),
            if (provider.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${provider.unreadCount} mới',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
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
              icon: Icon(
                Icons.done_all,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              label: Text(
                'Đọc tất cả',
                style: TextStyle(color: theme.colorScheme.primary, fontSize: 12),
              ),
            ),
        ],
      ),
      body: provider.isLoading && groupedMap.isEmpty
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => provider.loadNotifications(),
              color: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surface,
              child: groupedMap.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 200),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_none,
                                size: 64,
                                color: appColors.textFaint,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                provider.error ?? 'Không có thông báo nào',
                                style: TextStyle(
                                  color: provider.error == null
                                      ? appColors.textFaint
                                      : appColors.warning,
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
                          color: theme.colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: appColors.surfaceElevated),
                          ),
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.movie_outlined,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    projectTitle,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
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
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$unreadInProj chưa đọc',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
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
                                        : theme.colorScheme.primary.withValues(
                                            alpha: 0.05,
                                          ),
                                    border: Border(
                                      top: BorderSide(
                                        color: appColors.surfaceElevated,
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
                                                          ? appColors.textMuted
                                                          : theme
                                                                .colorScheme
                                                                .onSurface,
                                                      fontWeight: n.isRead
                                                          ? FontWeight.normal
                                                          : FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  _formatTimeAgo(n.timestamp),
                                                  style: TextStyle(
                                                    color: appColors.textFaint,
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
                                                    ? appColors.textFaint
                                                    : appColors.textMuted,
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
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary,
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
