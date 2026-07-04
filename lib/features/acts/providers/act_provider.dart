import 'package:flutter/material.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/features/acts/data/models/act.dart';

class ActProvider extends ChangeNotifier {
  final _api = ApiService();

  List<Act> _acts = [];
  int? _currentProjectId;
  bool _isLoading = false;
  String? _error;

  List<Act> get acts => _acts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadActs(int projectId) async {
    _currentProjectId = projectId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _acts = await _api.getActsForProject(projectId);
    } catch (e) {
      _error = 'Không thể tải hồi: $e';
      _acts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAct(Act act) async {
    try {
      final created = await _api.createAct(act);
      if (created == null) return false;
      if (_currentProjectId != null) await loadActs(_currentProjectId!);
      return true;
    } catch (e) {
      _error = 'Không thể thêm hồi: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> editAct(Act act) async {
    try {
      final ok = await _api.updateAct(act);
      if (ok && _currentProjectId != null) await loadActs(_currentProjectId!);
      return ok;
    } catch (e) {
      _error = 'Không thể cập nhật hồi: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeAct(int id) async {
    try {
      final ok = await _api.deleteAct(id);
      if (ok && _currentProjectId != null) await loadActs(_currentProjectId!);
      return ok;
    } catch (e) {
      _error = 'Không thể xoá hồi: $e';
      notifyListeners();
      return false;
    }
  }
}
