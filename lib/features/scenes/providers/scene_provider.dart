import 'package:flutter/material.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';

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
      _error = 'Không thể tải cảnh quay: $e';
      _scenesByAct[actId] = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addScene(Scene scene, List<int> characterIds) async {
    try {
      final created = await _api.createScene(scene, characterIds);
      if (created == null) return false;
      await loadScenesForAct(scene.actId);
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
      await loadScenesForAct(scene.actId);
      return true;
    } catch (e) {
      _error = 'Không thể cập nhật cảnh: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeScene(int id, int actId) async {
    try {
      final ok = await _api.deleteScene(id);
      if (ok) await loadScenesForAct(actId);
      return ok;
    } catch (e) {
      _error = 'Không thể xoá cảnh: $e';
      notifyListeners();
      return false;
    }
  }

  bool isSceneNumberTaken(int actId, int sceneNumber, {int? excludeId}) {
    return scenesForAct(actId).any(
      (s) => s.sceneNumber == sceneNumber && s.id != excludeId,
    );
  }
}
