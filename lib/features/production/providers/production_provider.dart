import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/utils/enums.dart';

class ProductionProvider extends ChangeNotifier {
  final _apiService = ApiService();

  List<Scene> _allScenes = [];
  List<Scene> _filtered = [];
  bool _isLoading = false;

  // Active filters
  int? filterCharacterId;
  SceneTime? filterTimeOfDay;

  // Map of locationLabel -> custom ISO Date String
  Map<String, String> _customDates = {};

  // Map of sceneId -> custom Shooting SceneStatus
  Map<int, SceneStatus> _sceneShootingStatuses = {};

  List<Scene> get allScenes => _allScenes;
  List<Scene> get filteredScenes => _filtered;
  bool get isLoading => _isLoading;
  Map<String, String> get customDates => _customDates;
  Map<int, SceneStatus> get sceneShootingStatuses => _sceneShootingStatuses;

  /// Scenes grouped by location name for the Shooting Day planner (F4.1)
  Map<String, List<Scene>> get groupedByLocation {
    final map = <String, List<Scene>>{};
    for (final scene in _filtered) {
      final key = scene.location?.sceneLabel ?? 'Chưa có bối cảnh';
      map.putIfAbsent(key, () => []).add(scene);
    }
    return map;
  }

  SceneStatus getShootingStatus(Scene scene) {
    if (scene.status != SceneStatus.done) {
      // Script is not written yet, so it is implicitly waiting for script
      return SceneStatus.todo;
    }
    return _sceneShootingStatuses[scene.id] ?? SceneStatus.todo;
  }

  Future<void> loadForProject(int projectId) async {
    _isLoading = true;
    notifyListeners();
    _allScenes = await _apiService.getScenesForProject(projectId);
    
    // Load custom dates and shooting statuses from SharedPreferences
    _customDates = {};
    _sceneShootingStatuses = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final scene in _allScenes) {
        final key = scene.location?.sceneLabel ?? 'Chưa có bối cảnh';
        final savedVal = prefs.getString('proj_${projectId}_loc_${key}_date');
        if (savedVal != null) {
          _customDates[key] = savedVal;
        }

        if (scene.id != null) {
          final savedStatus = prefs.getString('proj_${projectId}_scene_${scene.id}_shooting_status');
          if (savedStatus != null) {
            _sceneShootingStatuses[scene.id!] = SceneStatusExt.fromDb(savedStatus);
          } else {
            _sceneShootingStatuses[scene.id!] = SceneStatus.todo;
          }
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }

    _applyFilters();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setCustomDate(int projectId, String locationLabel, String dateStr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('proj_${projectId}_loc_${locationLabel}_date', dateStr);
      _customDates[locationLabel] = dateStr;
      notifyListeners();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> updateShootingStatus(int projectId, int sceneId, SceneStatus status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('proj_${projectId}_scene_${sceneId}_shooting_status', status.dbValue);
      _sceneShootingStatuses[sceneId] = status;
      notifyListeners();
    } catch (e) {
      debugPrint('Error: $e');
    }
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
