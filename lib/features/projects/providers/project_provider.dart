import 'package:flutter/material.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/core/services/api_service.dart';

class ProjectProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Project> _projects = [];
  bool _isLoading = false;
  String? _error;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load danh sách dự án từ server
  Future<void> loadProjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _projects = await _api.getProjects();
    } catch (e) {
      _error = 'Không thể tải dự án: $e';
      _projects = [];
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
      return null;
    } catch (e) {
      _error = 'Không thể tạo dự án: $e';
      notifyListeners();
      return null;
    }
  }

  /// Xóa dự án qua API, xóa khỏi danh sách local sau khi thành công
  Future<bool> removeProject(int id) async {
    try {
      final success = await _api.deleteProject(id);
      if (success) {
        _projects.removeWhere((p) => p.id == id);
        notifyListeners();
      }
      return success;
    } catch (e) {
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
