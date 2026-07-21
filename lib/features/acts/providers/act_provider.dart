import 'package:flutter/material.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/features/acts/data/models/act.dart';
import 'package:cinex_application/data/mock_data.dart';

class ActProvider extends ChangeNotifier {
  final _api = ApiService();

  List<Act> _acts = [];
  bool _isLoading = false;
  String? _error;

  List<Act> get acts => _acts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadActs(int projectId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _acts = await _api.getActsForProject(projectId);
    } catch (e) {
      _error = 'Không thể tải hồi từ server, dùng dữ liệu cục bộ: $e';
      _acts = MockData.mockActs.where((a) => a.projectId == projectId).toList();
      if (_acts.isEmpty) {
        _acts = List.from(MockData.mockActs);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAct(Act act) async {
    try {
      final created = await _api.createAct(act);
      if (created == null) return false;
      _acts.add(created);
      notifyListeners();
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
      if (ok) {
        final index = _acts.indexWhere((a) => a.id == act.id);
        if (index >= 0) {
          _acts[index] = act;
        }
        notifyListeners();
      }
      return ok;
    } catch (e) {
      _error = 'Không thể cập nhật hồi: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeAct(int id) async {
    final index = _acts.indexWhere((a) => a.id == id);
    if (index < 0) return false;
    final backup = _acts[index];

    _acts.removeAt(index);
    notifyListeners();

    try {
      final ok = await _api.deleteAct(id);
      if (!ok) {
        _acts.insert(index, backup);
        _error = 'Không thể xoá hồi từ máy chủ';
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      _acts.insert(index, backup);
      _error = 'Không thể xoá hồi: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> restoreAct(int id, int projectId) async {
    try {
      final ok = await _api.restoreAct(id);
      if (ok) {
        await loadActs(projectId);
      }
      return ok;
    } catch (e) {
      _error = 'Không thể khôi phục hồi: $e';
      notifyListeners();
      return false;
    }
  }
}
