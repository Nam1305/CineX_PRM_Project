import 'package:flutter/material.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/storage/local_cache_service.dart';
import 'package:cinex_application/features/acts/data/models/act.dart';

class ActProvider extends ChangeNotifier {
  final _api = ApiService();
  final _cache = LocalCacheService.instance;

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
    List<Act> cached = [];
    try {
      cached = await _cache.getActs(projectId);
    } catch (_) {}
    if (cached.isNotEmpty) {
      _acts = cached;
      _isLoading = false;
      notifyListeners();
    }
    try {
      final fetched = await _api.getActsForProject(projectId);
      try {
        await _cache.replaceActs(projectId, fetched);
      } catch (_) {}
      _acts = fetched;
    } catch (e) {
      _error = 'Không thể tải hồi từ server, dùng dữ liệu cục bộ: $e';
      if (cached.isEmpty) _acts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAct(Act act) async {
    try {
      final created = await _api.createAct(act);
      if (created == null) return false;
      try {
        await _cache.upsertAct(created);
      } catch (_) {}
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
        try {
          await _cache.upsertAct(act);
        } catch (_) {}
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
      try {
        await _cache.deleteAct(id);
      } catch (_) {}
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
