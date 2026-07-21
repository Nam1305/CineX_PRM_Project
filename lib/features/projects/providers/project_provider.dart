import 'package:flutter/material.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/data/mock_data.dart';

class ProjectProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Project> _projects = [];
  bool _isLoading = false;
  String? _error;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load danh sách dự án từ server, tự động nạp dữ liệu cục bộ mẫu nếu rỗng hoặc lỗi
  Future<void> loadProjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetched = await _api.getProjects();
      if (fetched.isNotEmpty) {
        _projects = fetched;
      } else {
        _projects = List.from(MockData.mockProjects);
      }
    } catch (e) {
      _error = 'Không thể tải dự án: $e';
      _projects = List.from(MockData.mockProjects);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tạo dự án mới qua API, thêm vào danh sách local sau khi thành công
  Future<int?> addProject(Project project) async {
    try {
      final created = await _api.createProject(project);
      if (created != null) {
        _projects.add(created);
        notifyListeners();
        return created.id;
      }
    } catch (e) {
      _error = 'Không thể tạo dự án: $e';
    }

    // Fallback nếu server lỗi/offline
    final newId = DateTime.now().millisecondsSinceEpoch % 10000;
    final fallbackProject = project.copyWith(id: newId);
    _projects.add(fallbackProject);
    notifyListeners();
    return newId;
  }

  /// Cập nhật dự án qua API, cập nhật danh sách local sau khi thành công
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
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = 'Không thể cập nhật dự án: $e';
    }

    // Fallback: Nếu API không thành công (offline / mock data), cập nhật dữ liệu cục bộ
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      _projects[index] = project;
      notifyListeners();
      return true;
    }

    _error = 'Không thể tìm thấy dự án để cập nhật';
    notifyListeners();
    return false;
  }

  /// Xóa dự án qua API, xóa khỏi danh sách local sau khi thành công
  Future<bool> removeProject(int id) async {
    final index = _projects.indexWhere((p) => p.id == id);
    if (index < 0) return false;
    final backup = _projects[index];

    _projects.removeAt(index);
    notifyListeners();

    try {
      final success = await _api.deleteProject(id);
      if (!success) {
        _projects.insert(index, backup);
        _error = 'Không thể xóa dự án từ máy chủ';
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      _projects.insert(index, backup);
      _error = 'Không thể xóa dự án: $e';
      notifyListeners();
      return false;
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
