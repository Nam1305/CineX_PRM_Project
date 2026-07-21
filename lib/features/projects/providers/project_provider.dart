import 'package:flutter/material.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/services/database_helper.dart';
import 'package:cinex_application/data/mock_data.dart';

class ProjectProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Project> _projects = [];
  bool _isLoading = false;
  String? _error;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load danh sách dự án từ server, tự động lưu vào SQLite và fallback SQLite khi offline
  Future<void> loadProjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetched = await _api.getProjects();
      if (fetched.isNotEmpty) {
        _projects = fetched;
        await _db.saveProjects(fetched);
      } else {
        // Fallback SQLite
        final local = await _db.getProjects();
        if (local.isNotEmpty) {
          _projects = local;
        } else {
          _projects = List.from(MockData.mockProjects);
          await _db.saveProjects(_projects);
        }
      }
    } catch (e) {
      _error = 'Không thể tải dự án từ server, đọc từ SQLite: $e';
      final local = await _db.getProjects();
      if (local.isNotEmpty) {
        _projects = local;
      } else {
        _projects = List.from(MockData.mockProjects);
        await _db.saveProjects(_projects);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tạo dự án mới qua API, lưu SQLite và local state
  Future<int?> addProject(Project project) async {
    try {
      final created = await _api.createProject(project);
      if (created != null) {
        _projects.add(created);
        await _db.saveSingleProject(created);
        notifyListeners();
        return created.id;
      }
    } catch (e) {
      _error = 'Không thể tạo dự án lên server: $e';
    }

    // Fallback nếu server lỗi/offline -> Lưu SQLite local
    final newId = DateTime.now().millisecondsSinceEpoch % 10000;
    final fallbackProject = project.copyWith(id: newId);
    _projects.add(fallbackProject);
    await _db.saveSingleProject(fallbackProject);
    notifyListeners();
    return newId;
  }

  /// Cập nhật dự án qua API, lưu SQLite
  Future<bool> editProject(Project project) async {
    if (project.id == null) return false;
    _error = null;
    try {
      final updated = await _api.updateProject(project);
      if (updated != null) {
        final index = _projects.indexWhere((p) => p.id == updated.id);
        if (index >= 0) {
          _projects[index] = updated;
        } else {
          _projects.add(updated);
        }
        await _db.saveSingleProject(updated);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = 'Không thể cập nhật dự án trên server: $e';
    }

    // Fallback offline -> Lưu SQLite local
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      _projects[index] = project;
      await _db.saveSingleProject(project);
      notifyListeners();
      return true;
    }

    _error = 'Không thể tìm thấy dự án để cập nhật';
    notifyListeners();
    return false;
  }

  /// Xóa dự án qua API và khỏi SQLite
  Future<bool> removeProject(int id) async {
    final index = _projects.indexWhere((p) => p.id == id);
    if (index < 0) return false;
    final backup = _projects[index];

    _projects.removeAt(index);
    await _db.deleteProject(id);
    notifyListeners();

    try {
      final success = await _api.deleteProject(id);
      if (!success) {
        _projects.insert(index, backup);
        await _db.saveSingleProject(backup);
        _error = 'Không thể xóa dự án từ máy chủ';
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      // Giữ xoá offline trong SQLite nếu mất mạng
      return true;
    }
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
