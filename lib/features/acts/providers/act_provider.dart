import 'package:flutter/material.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/services/database_helper.dart';
import 'package:cinex_application/features/acts/data/models/act.dart';
import 'package:cinex_application/data/mock_data.dart';

class ActProvider extends ChangeNotifier {
  final _api = ApiService();
  final _db = DatabaseHelper.instance;

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
      final fetched = await _api.getActsForProject(projectId);
      if (fetched.isNotEmpty) {
        _acts = fetched;
        await _db.saveActs(fetched);
      } else {
        final local = await _db.getActsForProject(projectId);
        if (local.isNotEmpty) {
          _acts = local;
        } else {
          _acts = MockData.mockActs.where((a) => a.projectId == projectId).toList();
          await _db.saveActs(_acts);
        }
      }
    } catch (e) {
      _error = 'Không thể tải hồi từ server, đọc từ SQLite: $e';
      final local = await _db.getActsForProject(projectId);
      if (local.isNotEmpty) {
        _acts = local;
      } else {
        _acts = MockData.mockActs.where((a) => a.projectId == projectId).toList();
        await _db.saveActs(_acts);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAct(Act act) async {
    try {
      final created = await _api.createAct(act);
      if (created != null) {
        _acts.add(created);
        await _db.saveActs([created]);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = 'Không thể thêm hồi lên server: $e';
    }

    final newId = DateTime.now().millisecondsSinceEpoch % 10000;
    final fallback = act.copyWith(id: newId);
    _acts.add(fallback);
    await _db.saveActs([fallback]);
    notifyListeners();
    return true;
  }

  Future<bool> editAct(Act act) async {
    try {
      final ok = await _api.updateAct(act);
      if (ok) {
        final index = _acts.indexWhere((a) => a.id == act.id);
        if (index >= 0) {
          _acts[index] = act;
        }
        await _db.saveActs([act]);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = 'Không thể cập nhật hồi: $e';
    }

    final index = _acts.indexWhere((a) => a.id == act.id);
    if (index >= 0) {
      _acts[index] = act;
      await _db.saveActs([act]);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> removeAct(int id) async {
    final index = _acts.indexWhere((a) => a.id == id);
    if (index < 0) return false;
    final backup = _acts[index];

    _acts.removeAt(index);
    await _db.deleteAct(id);
    notifyListeners();

    try {
      final ok = await _api.deleteAct(id);
      if (!ok) {
        _acts.insert(index, backup);
        await _db.saveActs([backup]);
        _error = 'Không thể xoá hồi từ máy chủ';
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      return true;
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
