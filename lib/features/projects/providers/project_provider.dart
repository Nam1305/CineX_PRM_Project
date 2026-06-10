import 'package:flutter/material.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/data/mock_data.dart';

class ProjectProvider extends ChangeNotifier {

  List<Project> _projects = [];
  bool _isLoading = false;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;

  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();
    // Load mock data for now
    _projects = MockData.projects;
    await Future.delayed(const Duration(milliseconds: 500));
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addProject(Project project) async {
    _projects.add(project.copyWith(id: (_projects.isEmpty ? 0 : _projects.last.id ?? 0) + 1));
    notifyListeners();
    return project.id ?? 0;
  }

  Future<void> editProject(Project project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      _projects[index] = project;
      notifyListeners();
    }
  }

  Future<void> removeProject(int id) async {
    _projects.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Project? getProjectById(int id) {
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}
