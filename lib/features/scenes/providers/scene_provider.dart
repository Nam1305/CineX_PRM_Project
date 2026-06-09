import 'package:flutter/material.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/features/scenes/data/repositories/scene_repository.dart';

class SceneProvider extends ChangeNotifier {
  final _repo = SceneRepository();

  // Map of actId → scenes list for quick lookup per act
  final Map<int, List<Scene>> _scenesByAct = {};
  bool _isLoading = false;

  List<Scene> scenesForAct(int actId) => _scenesByAct[actId] ?? [];
  bool get isLoading => _isLoading;

  Future<void> loadScenesForAct(int actId) async {
    _isLoading = true;
    notifyListeners();
    _scenesByAct[actId] = await _repo.getScenesForAct(actId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addScene(Scene scene, List<int> characterIds) async {
    await _repo.insert(scene, characterIds);
    await loadScenesForAct(scene.actId);
  }

  Future<void> editScene(Scene scene, List<int> characterIds) async {
    await _repo.update(scene, characterIds);
    await loadScenesForAct(scene.actId);
  }

  Future<void> removeScene(int id, int actId) async {
    await _repo.delete(id);
    await loadScenesForAct(actId);
  }

  Future<bool> isSceneNumberTaken(int actId, int sceneNumber,
          {int? excludeId}) =>
      _repo.isSceneNumberTaken(actId, sceneNumber, excludeId: excludeId);
}
