import 'package:flutter/foundation.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/storage/local_cache_service.dart';
import 'package:cinex_application/features/notifications/data/models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final _api = ApiService();
  final _cache = LocalCacheService.instance;
  final List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  String? _ownerKey;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  int unreadCountForProject(int? projectId) {
    if (projectId == null) {
      return _notifications
          .where((n) => !n.isRead && n.projectId == null)
          .length;
    }
    return _notifications
        .where((n) => !n.isRead && n.projectId == projectId)
        .length;
  }

  Map<String, List<NotificationModel>> get groupedByProject {
    final map = <String, List<NotificationModel>>{};
    for (final notification in _notifications) {
      final key = notification.projectTitle.isNotEmpty
          ? notification.projectTitle
          : 'Thông báo chung';
      map.putIfAbsent(key, () => []).add(notification);
    }
    for (final list in map.values) {
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    return map;
  }

  /// Loads the signed-in user's cache first, then replaces it with server data.
  Future<void> loadNotifications({String? ownerKey}) async {
    final requestedOwner = (ownerKey ?? _ownerKey)?.trim();
    if (requestedOwner == null || requestedOwner.isEmpty) return;
    final ownerChanged = requestedOwner != _ownerKey;
    _ownerKey = requestedOwner;
    _isLoading = true;
    _error = null;
    if (ownerChanged) _notifications.clear();
    notifyListeners();

    try {
      final cached = await _cache.getNotifications(requestedOwner);
      if (_ownerKey == requestedOwner && cached.isNotEmpty) {
        _replaceInMemory(cached);
        _isLoading = false;
        notifyListeners();
      }
    } catch (error, stackTrace) {
      debugPrint('Notification cache read failed: $error\n$stackTrace');
    }

    try {
      final serverNotifications = await _api.getNotifications();
      if (_ownerKey != requestedOwner) return;
      _replaceInMemory(serverNotifications);
      try {
        await _cache.replaceNotifications(requestedOwner, serverNotifications);
      } catch (error, stackTrace) {
        debugPrint('Notification cache write failed: $error\n$stackTrace');
      }
    } catch (error) {
      _error = 'Không thể làm mới thông báo: $error';
    } finally {
      if (_ownerKey == requestedOwner) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> addNotification({
    int? projectId,
    String? projectTitle,
    int? actId,
    int? sceneId,
    required String title,
    required String body,
    NotificationActionType actionType = NotificationActionType.update,
  }) async {
    final effectiveTitle = await _resolveProjectTitle(projectId, projectTitle);
    final notification = NotificationModel(
      projectId: projectId,
      projectTitle: effectiveTitle,
      actId: actId,
      sceneId: sceneId,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: false,
      actionType: actionType,
    );

    try {
      final saved = await _api.createNotification(notification);
      if (saved == null) {
        _error = 'Server không trả về thông báo vừa tạo.';
        notifyListeners();
        return false;
      }
      _notifications.insert(0, saved);
      final owner = _ownerKey;
      if (owner != null) {
        try {
          await _cache.upsertNotification(owner, saved);
        } catch (error, stackTrace) {
          debugPrint('Notification cache insert failed: $error\n$stackTrace');
        }
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (error) {
      _error = 'Không thể tạo thông báo: $error';
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAsRead(int? id) async {
    if (id == null) return false;
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index < 0 || _notifications[index].isRead) return true;
    try {
      final saved = await _api.markNotificationAsRead(id);
      if (!saved) throw Exception('Server từ chối cập nhật thông báo.');
      _notifications[index].isRead = true;
      await _cacheReadState();
      _error = null;
      notifyListeners();
      return true;
    } catch (error) {
      _error = 'Không thể đánh dấu đã đọc: $error';
      notifyListeners();
      return false;
    }
  }

  Future<bool> markProjectAsRead(int? projectId, String projectTitle) async {
    if (projectId == null) return false;
    try {
      final saved = await _api.markProjectNotificationsAsRead(projectId);
      if (!saved) throw Exception('Server từ chối cập nhật thông báo.');
      for (final notification in _notifications) {
        if (notification.projectId == projectId) notification.isRead = true;
      }
      await _cacheReadState();
      _error = null;
      notifyListeners();
      return true;
    } catch (error) {
      _error = 'Không thể đánh dấu thông báo dự án đã đọc: $error';
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final saved = await _api.markAllNotificationsAsRead();
      if (!saved) throw Exception('Server từ chối cập nhật thông báo.');
      for (final notification in _notifications) {
        notification.isRead = true;
      }
      await _cacheReadState();
      _error = null;
      notifyListeners();
      return true;
    } catch (error) {
      _error = 'Không thể đánh dấu tất cả thông báo đã đọc: $error';
      notifyListeners();
      return false;
    }
  }

  Future<String> _resolveProjectTitle(
    int? projectId,
    String? suppliedTitle,
  ) async {
    final supplied = suppliedTitle?.trim();
    if (supplied != null && supplied.isNotEmpty) {
      return supplied;
    }
    if (projectId == null) return 'Thông báo chung';

    try {
      final cachedProjects = await _cache.getProjects();
      for (final project in cachedProjects) {
        if (project.id == projectId) return project.title;
      }
    } catch (_) {}

    try {
      final projects = await _api.getProjects();
      try {
        await _cache.replaceProjects(projects);
      } catch (_) {}
      for (final project in projects) {
        if (project.id == projectId) return project.title;
      }
    } catch (_) {}
    return 'Dự án không khả dụng';
  }

  Future<void> _cacheReadState() async {
    final owner = _ownerKey;
    if (owner == null) return;
    try {
      await _cache.updateCachedNotificationReadState(owner, _notifications);
    } catch (error, stackTrace) {
      debugPrint(
        'Notification cache status update failed: $error\n$stackTrace',
      );
    }
  }

  void _replaceInMemory(List<NotificationModel> notifications) {
    _notifications
      ..clear()
      ..addAll(notifications)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}
