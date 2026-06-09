import 'package:flutter/material.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/features/scenes/data/repositories/scene_repository.dart';
import 'package:cinex_application/core/utils/enums.dart';

class ProductionProvider extends ChangeNotifier {
  final _repo = SceneRepository();

  List<Scene> _allScenes = [];
  List<Scene> _filtered = [];
  bool _isLoading = false;

  // Active filters
  int? filterCharacterId;
  SceneTime? filterTimeOfDay;

  List<Scene> get allScenes => _allScenes;
  List<Scene> get filteredScenes => _filtered;
  bool get isLoading => _isLoading;

  /// Scenes grouped by location name for the Shooting Day planner (F4.1)
  Map<String, List<Scene>> get groupedByLocation {
    final map = <String, List<Scene>>{};
    for (final scene in _filtered) {
      final key = scene.location?.sceneLabel ?? 'Chưa có bối cảnh';
      map.putIfAbsent(key, () => []).add(scene);
    }
    return map;
  }

  Future<void> loadForProject(int projectId) async {
    _isLoading = true;
    notifyListeners();
    _allScenes = await _repo.getScenesForProject(projectId);
    _applyFilters();
    _isLoading = false;
    notifyListeners();
  }

  void setFilter({int? characterId, SceneTime? timeOfDay}) {
    filterCharacterId = characterId;
    filterTimeOfDay = timeOfDay;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    filterCharacterId = null;
    filterTimeOfDay = null;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filtered = _allScenes.where((scene) {
      if (filterCharacterId != null &&
          !scene.characters.any((c) => c.id == filterCharacterId)) {
        return false;
      }
      if (filterTimeOfDay != null &&
          scene.location?.timeOfDay != filterTimeOfDay) {
        return false;
      }
      return true;
    }).toList();
  }
}
