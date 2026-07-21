import 'package:flutter/material.dart';
import 'package:cinex_application/features/notifications/data/models/notification_model.dart';
import 'package:cinex_application/core/services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final _api = ApiService();
  final List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  NotificationProvider() {
    loadNotifications();
  }

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;

  /// Tổng số thông báo chưa đọc toàn hệ thống
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Số lượng thông báo chưa đọc theo từng dự án
  int unreadCountForProject(int? projectId) {
    if (projectId == null) {
      return _notifications.where((n) => !n.isRead && n.projectId == null).length;
    }
    return _notifications.where((n) => !n.isRead && n.projectId == projectId).length;
  }

  /// Danh sách thông báo gom nhóm theo Dự án (Project)
  Map<String, List<NotificationModel>> get groupedByProject {
    final map = <String, List<NotificationModel>>{};
    for (final n in _notifications) {
      final key = n.projectTitle.isNotEmpty ? n.projectTitle : 'Thông báo chung';
      map.putIfAbsent(key, () => []).add(n);
    }
    // Sắp xếp thông báo mới nhất lên đầu trong từng nhóm
    for (final list in map.values) {
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    return map;
  }

  /// Tải thông báo từ database
  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await _api.getNotifications();
      _notifications.clear();
      _notifications.addAll(list);
    } catch (e) {
      print('NotificationProvider.loadNotifications error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tự động tạo và lưu thông báo mới khi có thao tác Thêm/Sửa/Xóa
  Future<void> addNotification({
    int? projectId,
    required String projectTitle,
    int? actId,
    int? sceneId,
    required String title,
    required String body,
    NotificationActionType actionType = NotificationActionType.update,
  }) async {
    final notif = NotificationModel(
      projectId: projectId,
      projectTitle: projectTitle,
      actId: actId,
      sceneId: sceneId,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: false,
      actionType: actionType,
    );

    // Lưu tạm thời vào list local để UI cập nhật ngay lập tức
    _notifications.insert(0, notif);
    notifyListeners();

    try {
      final saved = await _api.createNotification(notif);
      if (saved != null) {
        // Tìm và thay thế bằng bản ghi có Id thực từ DB
        final idx = _notifications.indexWhere((n) => n.id == null && n.title == title && n.body == body);
        if (idx >= 0) {
          _notifications[idx] = saved;
          notifyListeners();
        }
      }
    } catch (e) {
      print('NotificationProvider.addNotification error: $e');
    }
  }

  /// Đánh dấu một thông báo là đã đọc
  Future<void> markAsRead(int? id) async {
    if (id == null) return;
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index >= 0 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();

      try {
        await _api.markNotificationAsRead(id);
      } catch (e) {
        print('NotificationProvider.markAsRead error: $e');
      }
    }
  }

  /// Đánh dấu tất cả thông báo của một dự án là đã đọc
  Future<void> markProjectAsRead(int? projectId, String projectTitle) async {
    bool changed = false;
    for (final n in _notifications) {
      if (n.projectTitle == projectTitle && !n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      try {
        if (projectId != null) {
          await _api.markProjectNotificationsAsRead(projectId);
        }
      } catch (e) {
        print('NotificationProvider.markProjectAsRead error: $e');
      }
    }
  }

  /// Đánh dấu toàn bộ thông báo là đã đọc
  Future<void> markAllAsRead() async {
    bool changed = false;
    for (final n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      try {
        await _api.markAllNotificationsAsRead();
      } catch (e) {
        print('NotificationProvider.markAllAsRead error: $e');
      }
    }
  }
}
