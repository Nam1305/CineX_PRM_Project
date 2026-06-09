import 'package:flutter/material.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/features/projects/data/repositories/project_repository.dart';

class ProjectProvider extends ChangeNotifier {
  final _repo = ProjectRepository();

  List<Project> _projects = [];
  bool _isLoading = false;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;

  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();
    _projects = await _repo.getAll();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addProject(Project project) async {
    final id = await _repo.insert(project);
    await loadProjects();
    return id;
  }

  Future<void> editProject(Project project) async {
    await _repo.update(project);
    await loadProjects();
  }

  Future<void> removeProject(int id) async {
    await _repo.delete(id);
    await loadProjects();
  }
}
