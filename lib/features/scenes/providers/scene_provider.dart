import 'package:flutter/material.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/services/database_helper.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/data/mock_data.dart';

class SceneProvider extends ChangeNotifier {
  final _api = ApiService();
  final _db = DatabaseHelper.instance;

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
      final fetched = await _api.getScenesForAct(actId);
      if (fetched.isNotEmpty) {
        _scenesByAct[actId] = fetched;
        await _db.saveScenes(fetched);
      } else {
        final local = await _db.getScenesForAct(actId);
        if (local.isNotEmpty) {
          _scenesByAct[actId] = local;
        } else {
          final mockScenesForAct = MockData.mockScenes.where((s) => s.actId == actId).toList();
          _scenesByAct[actId] = mockScenesForAct.isNotEmpty ? mockScenesForAct : MockData.mockScenes;
          await _db.saveScenes(_scenesByAct[actId]!);
        }
      }
    } catch (e) {
      _error = 'Không thể tải cảnh quay từ server, đọc từ SQLite: $e';
      final local = await _db.getScenesForAct(actId);
      if (local.isNotEmpty) {
        _scenesByAct[actId] = local;
      } else {
        final mockScenesForAct = MockData.mockScenes.where((s) => s.actId == actId).toList();
        _scenesByAct[actId] = mockScenesForAct.isNotEmpty ? mockScenesForAct : MockData.mockScenes;
        await _db.saveScenes(_scenesByAct[actId]!);
      }
    } finally {
      _scenesByAct[actId]?.sort((a, b) => a.sceneNumber.compareTo(b.sceneNumber));
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addScene(Scene scene, List<int> characterIds) async {
    try {
      final created = await _api.createScene(scene, characterIds);
      if (created != null) {
        await _db.saveScenes([created]);
        await loadScenesForAct(scene.actId);
        return true;
      }
    } catch (e) {
      _error = 'Không thể thêm cảnh lên server: $e';
    }

    final newId = DateTime.now().millisecondsSinceEpoch % 10000;
    final fallback = scene.copyWith(id: newId);
    await _db.saveScenes([fallback]);
    await loadScenesForAct(scene.actId);
    return true;
  }

  Future<bool> editScene(
    Scene scene,
    List<int> characterIds, {
    required List<int> previousCharacterIds,
  }) async {
    try {
      final updated = await _api.updateScene(
        scene,
        characterIds,
        previousCharacterIds: previousCharacterIds,
      );
      if (updated != null) {
        await _db.saveScenes([updated]);
        await loadScenesForAct(scene.actId);
        return true;
      }
    } catch (e) {
      _error = 'Không thể cập nhật cảnh trên server: $e';
    }

    await _db.saveScenes([scene]);
    await loadScenesForAct(scene.actId);
    return true;
  }

  Future<bool> removeScene(int id, int actId) async {
    final list = _scenesByAct[actId];
    if (list == null) return false;
    final index = list.indexWhere((s) => s.id == id);
    if (index < 0) return false;
    final backup = list[index];

    list.removeAt(index);
    await _db.deleteScene(id);
    notifyListeners();

    try {
      final ok = await _api.deleteScene(id);
      if (!ok) {
        _scenesByAct[actId]?.insert(index, backup);
        await _db.saveScenes([backup]);
        _error = 'Không thể xoá cảnh từ máy chủ';
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      return true;
    }
  }

  bool isSceneNumberTaken(int actId, int sceneNumber, {int? excludeId}) {
    return scenesForAct(actId).any(
      (s) => s.sceneNumber == sceneNumber && s.id != excludeId,
    );
  }

  Future<bool> updateSceneStatus(Scene scene, SceneStatus newStatus) async {
    try {
      final updated = scene.copyWith(status: newStatus);
      final result = await _api.updateScene(
        updated,
        scene.characters.map((c) => c.id!).toList(),
        previousCharacterIds: scene.characters.map((c) => c.id!).toList(),
      );
      if (result != null) {
        await _db.saveScenes([result]);
      } else {
        await _db.saveScenes([updated]);
      }
      await loadScenesForAct(scene.actId);
      return true;
    } catch (e) {
      _error = 'Không thể cập nhật trạng thái: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> restoreScene(int id, int actId) async {
    try {
      final ok = await _api.restoreScene(id);
      if (ok) {
        await loadScenesForAct(actId);
      }
      return ok;
    } catch (e) {
      _error = 'Không thể khôi phục phân cảnh: $e';
      notifyListeners();
      return false;
    }
  }
}
