import 'package:flutter/material.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/services/database_helper.dart';
import 'package:cinex_application/core/services/sync_manager.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/core/utils/enums.dart';

class SceneProvider extends ChangeNotifier {
  final _api = ApiService();
  final _db = DatabaseHelper.instance;
  final _sync = SyncManager.instance;

  final Map<int, List<Scene>> _scenesByAct = {};
  bool _isLoading = false;
  String? _error;

  List<Scene> scenesForAct(int actId) => _scenesByAct[actId] ?? [];
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadScenesForAct(int actId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (_sync.isOnline) {
        final fetched = await _api.getScenesForAct(actId);
        if (fetched.isNotEmpty) {
          for (var s in fetched) {
            await _db.insertScene(s, syncStatus: 'synced');
          }
        }
      }
      final loaded = await _db.getScenesForAct(actId);
      loaded.sort((a, b) => a.sceneNumber.compareTo(b.sceneNumber));
      _scenesByAct[actId] = loaded;
    } catch (e) {
      debugPrint('SceneProvider.loadScenesForAct error: $e');
      try {
        final loaded = await _db.getScenesForAct(actId);
        loaded.sort((a, b) => a.sceneNumber.compareTo(b.sceneNumber));
        _scenesByAct[actId] = loaded;
      } catch (_) {
        _error = 'Không thể tải cảnh quay: $e';
        _scenesByAct[actId] = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addScene(Scene scene, List<int> characterIds) async {
    final populatedScene = scene.copyWith(
      characters: characterIds.map((id) => Character(id: id, name: '')).toList(),
    );

    try {
      if (_sync.isOnline) {
        final created = await _api.createScene(scene, characterIds);
        if (created != null) {
          // Lấy location phong phú hơn nếu có
          final enriched = created.copyWith(location: scene.location);
          await _db.insertScene(enriched, syncStatus: 'synced');
          _scenesByAct.putIfAbsent(scene.actId, () => []);
          _scenesByAct[scene.actId]!.add(enriched);
          _scenesByAct[scene.actId]!.sort((a, b) => a.sceneNumber.compareTo(b.sceneNumber));
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('SceneProvider.addScene API error: $e');
    }

    // Offline hoặc API lỗi: lưu vào SQLite với pending_create
    final localId = await _db.insertScene(populatedScene, syncStatus: 'pending_create');
    final savedScene = populatedScene.copyWith(id: localId, location: scene.location);
    _scenesByAct.putIfAbsent(scene.actId, () => []);
    _scenesByAct[scene.actId]!.add(savedScene);
    _scenesByAct[scene.actId]!.sort((a, b) => a.sceneNumber.compareTo(b.sceneNumber));
    notifyListeners();
    return true;
  }

  Future<bool> editScene(
    Scene scene,
    List<int> characterIds, {
    required List<int> previousCharacterIds,
  }) async {
    final populatedScene = scene.copyWith(
      characters: characterIds.map((id) => Character(id: id, name: '')).toList(),
    );

    final syncStatus = _sync.isOnline ? 'synced' : 'pending_update';
    await _db.updateScene(populatedScene, syncStatus: syncStatus);

    final list = _scenesByAct[scene.actId];
    if (list != null) {
      final index = list.indexWhere((s) => s.id == scene.id);
      if (index >= 0) {
        list[index] = populatedScene.copyWith(location: scene.location);
      } else {
        list.add(populatedScene.copyWith(location: scene.location));
      }
      list.sort((a, b) => a.sceneNumber.compareTo(b.sceneNumber));
    }
    notifyListeners();

    if (_sync.isOnline) {
      try {
        final updated = await _api.updateScene(
          scene,
          characterIds,
          previousCharacterIds: previousCharacterIds,
        );
        if (updated != null) {
          final enriched = updated.copyWith(location: scene.location);
          await _db.insertScene(enriched, syncStatus: 'synced');
          if (list != null) {
            final index = list.indexWhere((s) => s.id == scene.id || s.id == updated.id);
            if (index >= 0) {
              list[index] = enriched;
            }
            list.sort((a, b) => a.sceneNumber.compareTo(b.sceneNumber));
          }
          notifyListeners();
        }
      } catch (e) {
        await _db.updateScene(populatedScene, syncStatus: 'pending_update');
        debugPrint('SceneProvider.editScene API error: $e');
      }
    }

    return true;
  }

  Future<bool> removeScene(int id, int actId) async {
    final list = _scenesByAct[actId];
    if (list == null) return false;
    final index = list.indexWhere((s) => s.id == id);
    if (index < 0) return false;
    final backup = list[index];

    list.removeAt(index);
    notifyListeners();

    await _db.deleteScene(id);

    if (_sync.isOnline) {
      try {
        final ok = await _api.deleteScene(id);
        if (!ok) {
          _scenesByAct[actId]?.insert(index, backup);
          await _db.insertScene(backup, syncStatus: 'synced');
          _error = 'Không thể xoá cảnh từ máy chủ';
          notifyListeners();
          return false;
        }
      } catch (e) {
        debugPrint('SceneProvider.removeScene API error: $e');
      }
    }

    return true;
  }

  bool isSceneNumberTaken(int actId, int sceneNumber, {int? excludeId}) {
    return scenesForAct(actId).any(
      (s) => s.sceneNumber == sceneNumber && s.id != excludeId,
    );
  }

  Future<bool> updateSceneStatus(Scene scene, SceneStatus newStatus) async {
    final updated = scene.copyWith(status: newStatus);
    final syncStatus = _sync.isOnline ? 'synced' : 'pending_update';
    await _db.updateScene(updated, syncStatus: syncStatus);

    final list = _scenesByAct[scene.actId];
    if (list != null) {
      final index = list.indexWhere((s) => s.id == scene.id);
      if (index >= 0) {
        list[index] = updated;
      }
    }
    notifyListeners();

    if (_sync.isOnline) {
      try {
        final characterIds = scene.characters.map((c) => c.id!).toList();
        final result = await _api.updateScene(
          updated,
          characterIds,
          previousCharacterIds: characterIds,
        );
        if (result != null) {
          final enriched = result.copyWith(
            location: scene.location,
            characters: scene.characters,
          );
          await _db.insertScene(enriched, syncStatus: 'synced');
          if (list != null) {
            final index = list.indexWhere((s) => s.id == scene.id);
            if (index >= 0) {
              list[index] = enriched;
            }
          }
          notifyListeners();
        }
      } catch (e) {
        await _db.updateScene(updated, syncStatus: 'pending_update');
        debugPrint('SceneProvider.updateSceneStatus API error: $e');
      }
    }

    return true;
  }

  Future<bool> restoreScene(int id, int actId) async {
    try {
      if (_sync.isOnline) {
        final ok = await _api.restoreScene(id);
        if (ok) {
          await loadScenesForAct(actId);
          return true;
        }
      }
    } catch (e) {
      debugPrint('SceneProvider.restoreScene API error: $e');
    }

    // Nếu offline, phục hồi cục bộ
    final list = _scenesByAct[actId];
    if (list != null) {
      final index = list.indexWhere((s) => s.id == id);
      if (index >= 0) {
        await _db.updateScene(list[index], syncStatus: 'synced');
        await loadScenesForAct(actId);
        return true;
      }
    }
    return false;
  }
}
