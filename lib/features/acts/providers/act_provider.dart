import 'package:flutter/material.dart';
import 'package:cinex_application/features/acts/data/models/act.dart';
import 'package:cinex_application/features/acts/data/repositories/act_repository.dart';

class ActProvider extends ChangeNotifier {
  final _repo = ActRepository();

  List<Act> _acts = [];
  int? _currentProjectId;
  bool _isLoading = false;

  List<Act> get acts => _acts;
  bool get isLoading => _isLoading;

  Future<void> loadActs(int projectId) async {
    _currentProjectId = projectId;
    _isLoading = true;
    notifyListeners();
    _acts = await _repo.getByProject(projectId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAct(Act act) async {
    await _repo.insert(act);
    if (_currentProjectId != null) await loadActs(_currentProjectId!);
  }

  Future<void> editAct(Act act) async {
    await _repo.update(act);
    if (_currentProjectId != null) await loadActs(_currentProjectId!);
  }

  Future<void> removeAct(int id) async {
    await _repo.delete(id);
    if (_currentProjectId != null) await loadActs(_currentProjectId!);
  }
}
