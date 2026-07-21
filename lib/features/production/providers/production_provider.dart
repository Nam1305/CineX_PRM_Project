import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/storage/local_cache_service.dart';
import 'package:cinex_application/core/utils/enums.dart';

class ProductionProvider extends ChangeNotifier {
  final _apiService = ApiService();
  final _cache = LocalCacheService.instance;

  List<Scene> _allScenes = [];
  List<Scene> _filtered = [];
  bool _isLoading = false;
  ProductionGroupMode _groupMode = ProductionGroupMode.byLocation;

  // Active filters
  int? filterCharacterId;
  SceneTime? filterTimeOfDay;

  // Map of locationName -> custom ISO Date String
  Map<String, String> _customDates = {};

  // Map of sceneId -> custom Shooting SceneStatus
  Map<int, SceneStatus> _sceneShootingStatuses = {};

  List<Scene> get allScenes => _allScenes;
  List<Scene> get filteredScenes => _filtered;
  bool get isLoading => _isLoading;
  ProductionGroupMode get groupMode => _groupMode;
  Map<String, String> get customDates => _customDates;
  Map<int, SceneStatus> get sceneShootingStatuses => _sceneShootingStatuses;

  /// Tiến độ sản xuất (%) dựa trên số cảnh đã quay xong / tổng cảnh
  double get productionProgress {
    if (_allScenes.isEmpty) return 0.0;
    final completed = _allScenes
        .where((s) => getShootingStatus(s) == SceneStatus.done)
        .length;
    return completed / _allScenes.length;
  }

  /// Số cảnh đã hoàn thành quay
  int get completedScenesCount =>
      _allScenes.where((s) => getShootingStatus(s) == SceneStatus.done).length;

  void setGroupMode(ProductionGroupMode mode) {
    _groupMode = mode;
    notifyListeners();
  }

  /// Scenes grouped by location name or character name, sorted chronologically by shooting date
  Map<String, List<Scene>> get groupedByLocation {
    final map = <String, List<Scene>>{};
    if (_groupMode == ProductionGroupMode.byLocation) {
      for (final scene in _filtered) {
        final key = scene.location?.name ?? 'Chưa có bối cảnh';
        map.putIfAbsent(key, () => []).add(scene);
      }
      // Sắp xếp cảnh Ban ngày trước, Ban đêm sau trong cùng một bối cảnh
      for (final list in map.values) {
        list.sort((a, b) {
          final aOrder = a.timeOfDay == SceneTime.day ? 0 : 1;
          final bOrder = b.timeOfDay == SceneTime.day ? 0 : 1;
          return aOrder.compareTo(bOrder);
        });
      }

      // Sắp xếp các nhóm bối cảnh theo Ngày quay (Shooting Date) tăng dần
      final sortedEntries = map.entries.toList()
        ..sort((entryA, entryB) {
          final dateStrA = _customDates[entryA.key];
          final dateStrB = _customDates[entryB.key];
          if (dateStrA != null && dateStrB != null) {
            return dateStrA.compareTo(dateStrB);
          } else if (dateStrA != null) {
            return -1;
          } else if (dateStrB != null) {
            return 1;
          }
          return 0;
        });

      final sortedMap = <String, List<Scene>>{};
      for (final e in sortedEntries) {
        sortedMap[e.key] = e.value;
      }
      return sortedMap;
    } else {
      // Gom nhóm theo Nhân vật
      for (final scene in _filtered) {
        if (scene.characters.isEmpty) {
          map.putIfAbsent('Không có nhân vật', () => []).add(scene);
        } else {
          for (final char in scene.characters) {
            map.putIfAbsent(char.name, () => []).add(scene);
          }
        }
      }
      // Sắp xếp theo số thứ tự phân cảnh
      for (final list in map.values) {
        list.sort((a, b) => Scene.compareNumbers(a.sceneNumber, b.sceneNumber));
      }
      return map;
    }
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
    List<Scene> cached = [];
    try {
      cached = await _cache.getScenesForProject(projectId);
    } catch (_) {}
    if (cached.isNotEmpty) {
      _allScenes = cached;
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    }
    try {
      _allScenes = await _apiService.getScenesForProject(projectId);
      try {
        await _cache.replaceScenesForProject(projectId, _allScenes);
      } catch (_) {}
    } catch (_) {
      if (cached.isEmpty) _allScenes = [];
    }

    // Load custom dates and shooting statuses from SharedPreferences
    _customDates = {};
    _sceneShootingStatuses = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final scene in _allScenes) {
        final key = scene.location?.name ?? 'Chưa có bối cảnh';
        final savedVal = prefs.getString('proj_${projectId}_loc_${key}_date');
        if (savedVal != null) {
          _customDates[key] = savedVal;
        }

        if (scene.id != null) {
          final savedStatus = prefs.getString(
            'proj_${projectId}_scene_${scene.id}_shooting_status',
          );
          if (savedStatus != null) {
            _sceneShootingStatuses[scene.id!] = SceneStatusExt.fromDb(
              savedStatus,
            );
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

  Future<void> setCustomDate(
    int projectId,
    String locationLabel,
    String dateStr,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'proj_${projectId}_loc_${locationLabel}_date',
        dateStr,
      );
      _customDates[locationLabel] = dateStr;
      notifyListeners();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> updateShootingStatus(
    int projectId,
    int sceneId,
    SceneStatus status,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'proj_${projectId}_scene_${sceneId}_shooting_status',
        status.dbValue,
      );
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
      if (filterCharacterId != null) {
        final hasChar = scene.characters.any((c) => c.id == filterCharacterId);
        if (!hasChar) return false;
      }
      if (filterTimeOfDay != null) {
        final effectiveTime = scene.location?.timeOfDay ?? scene.timeOfDay;
        if (effectiveTime != filterTimeOfDay) return false;
      }
      return true;
    }).toList();
  }
}
