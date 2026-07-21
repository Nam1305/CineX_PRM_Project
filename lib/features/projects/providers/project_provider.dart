import 'package:flutter/material.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/services/database_helper.dart';
import 'package:cinex_application/core/services/sync_manager.dart';

class ProjectProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final DatabaseHelper _db = DatabaseHelper.instance;
  final SyncManager _sync = SyncManager.instance;

  List<Project> _projects = [];
  bool _isLoading = false;
  String? _error;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load danh sách dự án:
  /// - Online: Tải từ API -> lưu vào SQLite -> hiển thị
  /// - Offline: Đọc từ SQLite
  Future<void> loadProjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_sync.isOnline) {
        // Online: Tải từ API
        final fetched = await _api.getProjects();
        if (fetched.isNotEmpty) {
          // Lưu vào SQLite
          for (var p in fetched) {
            await _db.insertProject(p, syncStatus: 'synced');
          }
        }
      }
      // Đọc từ SQLite (nguồn duy nhất)
      _projects = await _db.getProjects();
    } catch (e) {
      debugPrint('ProjectProvider.loadProjects error: $e');
      // Fallback đọc từ SQLite khi API lỗi
      try {
        _projects = await _db.getProjects();
      } catch (_) {
        _error = 'Không thể tải dự án: $e';
        _projects = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tạo dự án mới: Lưu vào SQLite trước, thử đẩy lên API
  Future<int?> addProject(Project project) async {
    try {
      if (_sync.isOnline) {
        // Thử tạo trên server trước
        final created = await _api.createProject(project);
        if (created != null) {
          await _db.insertProject(created, syncStatus: 'synced');
          _projects.add(created);
          notifyListeners();
          return created.id;
        }
      }
    } catch (e) {
      debugPrint('ProjectProvider.addProject API error: $e');
    }

    // Offline hoặc API lỗi: Lưu vào SQLite với pending_create
    final localId = await _db.insertProject(project, syncStatus: 'pending_create');
    final savedProject = project.copyWith(id: localId);
    _projects.add(savedProject);
    notifyListeners();
    return localId;
  }

  /// Cập nhật dự án: Cập nhật SQLite trước, thử đẩy lên API
  Future<bool> editProject(Project project) async {
    if (project.id == null) return false;
    _error = null;

    // Cập nhật SQLite cục bộ ngay
    final syncStatus = _sync.isOnline ? 'synced' : 'pending_update';
    await _db.updateProject(project, syncStatus: syncStatus);

    // Cập nhật UI ngay
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      _projects[index] = project;
    }
    notifyListeners();

    if (_sync.isOnline) {
      try {
        final updated = await _api.updateProject(project);
        if (updated != null) {
          await _db.updateProject(updated, syncStatus: 'synced');
          if (index >= 0) _projects[index] = updated;
          notifyListeners();
        }
      } catch (e) {
        // API lỗi -> đánh dấu pending_update để đồng bộ sau
        await _db.updateProject(project, syncStatus: 'pending_update');
        debugPrint('ProjectProvider.editProject API error: $e');
      }
    }

    return true;
  }

  /// Xóa dự án: Xóa/đánh dấu trong SQLite trước, thử đẩy lên API
  Future<bool> removeProject(int id) async {
    final index = _projects.indexWhere((p) => p.id == id);
    if (index < 0) return false;
    final backup = _projects[index];

    // Xóa khỏi UI ngay
    _projects.removeAt(index);
    notifyListeners();

    // Xóa/đánh dấu trong SQLite
    await _db.deleteProject(id);

    if (_sync.isOnline) {
      try {
        final success = await _api.deleteProject(id);
        if (!success) {
          // Server từ chối -> hoàn tác
          _projects.insert(index, backup);
          await _db.insertProject(backup, syncStatus: 'synced');
          _error = 'Không thể xóa dự án từ máy chủ';
          notifyListeners();
          return false;
        }
      } catch (e) {
        // Lỗi mạng -> giữ nguyên pending_delete để đồng bộ sau
        debugPrint('ProjectProvider.removeProject API error: $e');
      }
    }

    return true;
  }

  /// Lấy project theo id từ danh sách đang giữ
  Project? getProjectById(int id) {
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}
