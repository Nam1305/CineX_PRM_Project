import 'package:flutter/material.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/data/mock_data.dart';

class SceneProvider extends ChangeNotifier {
  final _api = ApiService();

  // Map of actId → scenes list for quick lookup per act
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
      _scenesByAct[actId] = await _api.getScenesForAct(actId);
    } catch (e) {
      _error = 'Không thể tải cảnh quay từ server, dùng dữ liệu cục bộ: $e';
      final mockScenesForAct = MockData.mockScenes
          .where((s) => s.actId == actId)
          .toList();
      _scenesByAct[actId] = mockScenesForAct.isNotEmpty
          ? mockScenesForAct
          : MockData.mockScenes;
    } finally {
      _scenesByAct[actId]?.sort(
        (a, b) => Scene.compareNumbers(a.sceneNumber, b.sceneNumber),
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addScene(Scene scene, List<int> characterIds) async {
    try {
      final created = await _api.createScene(scene, characterIds);
      if (created == null) return false;
      _scenesByAct.putIfAbsent(scene.actId, () => []);
      _scenesByAct[scene.actId]!.add(created);
      _scenesByAct[scene.actId]!.sort(
        (a, b) => Scene.compareNumbers(a.sceneNumber, b.sceneNumber),
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Không thể thêm cảnh: $e';
      notifyListeners();
      return false;
    }
  }

  /// [previousCharacterIds] là danh sách nhân vật đang gán cho cảnh trước khi
  /// sửa — cần để phát hiện có cần xoá liên kết cũ hay không (xem ghi chú ở
  /// ApiService.updateScene).
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
      if (updated == null) return false;
      final list = _scenesByAct[scene.actId];
      if (list != null) {
        final index = list.indexWhere(
          (s) => s.id == scene.id || s.id == updated.id,
        );
        if (index >= 0) {
          list[index] = updated;
        } else {
          list.add(updated);
        }
        list.sort((a, b) => Scene.compareNumbers(a.sceneNumber, b.sceneNumber));
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Không thể cập nhật cảnh: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeScene(int id, int actId) async {
    final list = _scenesByAct[actId];
    if (list == null) return false;
    final index = list.indexWhere((s) => s.id == id);
    if (index < 0) return false;
    final backup = list[index];

    list.removeAt(index);
    notifyListeners();

    try {
      final ok = await _api.deleteScene(id);
      if (!ok) {
        _scenesByAct[actId]?.insert(index, backup);
        _error = 'Không thể xoá cảnh từ máy chủ';
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      _scenesByAct[actId]?.insert(index, backup);
      _error = 'Không thể xoá cảnh: $e';
      notifyListeners();
      return false;
    }
  }

  bool isSceneNumberTaken(int actId, String sceneNumber, {int? excludeId}) {
    return scenesForAct(
      actId,
    ).any((s) => s.sceneNumber == sceneNumber && s.id != excludeId);
  }

  /// Quick status update — only changes the status field without touching characters.
  Future<bool> updateSceneStatus(Scene scene, SceneStatus newStatus) async {
    try {
      final updated = scene.copyWith(status: newStatus);
      final result = await _api.updateScene(
        updated,
        scene.characters.map((c) => c.id!).toList(),
        previousCharacterIds: scene.characters.map((c) => c.id!).toList(),
      );
      if (result == null) return false;
      final list = _scenesByAct[scene.actId];
      if (list != null) {
        final index = list.indexWhere((s) => s.id == scene.id);
        if (index >= 0) {
          list[index] = result.copyWith(
            location: scene.location,
            characters: scene.characters,
          );
        }
      }
      notifyListeners();
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
