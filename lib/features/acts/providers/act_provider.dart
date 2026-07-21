import 'package:flutter/material.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/services/database_helper.dart';
import 'package:cinex_application/core/services/sync_manager.dart';
import 'package:cinex_application/features/acts/data/models/act.dart';

class ActProvider extends ChangeNotifier {
  final _api = ApiService();
  final _db = DatabaseHelper.instance;
  final _sync = SyncManager.instance;

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
      if (_sync.isOnline) {
        final fetched = await _api.getActsForProject(projectId);
        if (fetched.isNotEmpty) {
          for (var a in fetched) {
            await _db.insertAct(a.toMap(), syncStatus: 'synced');
          }
        }
      }
      final maps = await _db.getActs(projectId);
      _acts = maps.map((e) => Act.fromMap(e)).toList();
    } catch (e) {
      debugPrint('ActProvider.loadActs error: $e');
      try {
        final maps = await _db.getActs(projectId);
        _acts = maps.map((e) => Act.fromMap(e)).toList();
      } catch (_) {
        _error = 'Không thể tải hồi: $e';
        _acts = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAct(Act act) async {
    try {
      if (_sync.isOnline) {
        final created = await _api.createAct(act);
        if (created != null) {
          await _db.insertAct(created.toMap(), syncStatus: 'synced');
          _acts.add(created);
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('ActProvider.addAct API error: $e');
    }

    // Offline hoặc API lỗi: lưu vào SQLite với pending_create
    final localId = await _db.insertAct(act.toMap(), syncStatus: 'pending_create');
    final savedAct = act.copyWith(id: localId);
    _acts.add(savedAct);
    notifyListeners();
    return true;
  }

  Future<bool> editAct(Act act) async {
    if (act.id == null) return false;
    _error = null;

    final syncStatus = _sync.isOnline ? 'synced' : 'pending_update';
    await _db.updateAct(act.toMap(), syncStatus: syncStatus);

    final index = _acts.indexWhere((a) => a.id == act.id);
    if (index >= 0) {
      _acts[index] = act;
    }
    notifyListeners();

    if (_sync.isOnline) {
      try {
        final ok = await _api.updateAct(act);
        if (ok) {
          await _db.updateAct(act.toMap(), syncStatus: 'synced');
        } else {
          await _db.updateAct(act.toMap(), syncStatus: 'pending_update');
        }
      } catch (e) {
        await _db.updateAct(act.toMap(), syncStatus: 'pending_update');
        debugPrint('ActProvider.editAct API error: $e');
      }
    }

    return true;
  }

  Future<bool> removeAct(int id) async {
    final index = _acts.indexWhere((a) => a.id == id);
    if (index < 0) return false;
    final backup = _acts[index];

    _acts.removeAt(index);
    notifyListeners();

    await _db.deleteAct(id);

    if (_sync.isOnline) {
      try {
        final ok = await _api.deleteAct(id);
        if (!ok) {
          _acts.insert(index, backup);
          await _db.insertAct(backup.toMap(), syncStatus: 'synced');
          _error = 'Không thể xoá hồi từ máy chủ';
          notifyListeners();
          return false;
        }
      } catch (e) {
        debugPrint('ActProvider.removeAct API error: $e');
      }
    }

    return true;
  }

  Future<bool> restoreAct(int id, int projectId) async {
    try {
      if (_sync.isOnline) {
        final ok = await _api.restoreAct(id);
        if (ok) {
          await _db.insertAct(
            _acts.firstWhere((a) => a.id == id).toMap(),
            syncStatus: 'synced',
          );
          await loadActs(projectId);
          return true;
        }
      }
    } catch (e) {
      debugPrint('ActProvider.restoreAct API error: $e');
    }

    // Nếu offline, chỉ cần khôi phục trạng thái local
    final index = _acts.indexWhere((a) => a.id == id);
    if (index >= 0) {
      await _db.updateAct(_acts[index].toMap(), syncStatus: 'synced');
      await loadActs(projectId);
      return true;
    }
    return false;
  }
}
