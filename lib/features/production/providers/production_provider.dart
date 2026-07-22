import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/features/production/data/models/production_plan.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/storage/local_cache_service.dart';
import 'package:cinex_application/core/utils/enums.dart';

class ProductionProvider extends ChangeNotifier {
  final _apiService = ApiService();
  final _cache = LocalCacheService.instance;

  List<Scene> _allScenes = [];
  List<Scene> _filtered = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  int? _projectId;
  int _loadGeneration = 0;
  ProductionPlan? _plan;
  ProductionGroupMode _groupMode = ProductionGroupMode.byLocation;

  int? filterCharacterId;
  SceneTime? filterTimeOfDay;

  // The existing UI remains keyed by location label. Persistence uses LocationId.
  Map<String, String> _customDates = {};
  Map<int, SceneStatus> _sceneShootingStatuses = {};

  List<Scene> get allScenes => _allScenes;
  List<Scene> get filteredScenes => _filtered;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  ProductionGroupMode get groupMode => _groupMode;
  Map<String, String> get customDates => Map.unmodifiable(_customDates);
  Map<int, SceneStatus> get sceneShootingStatuses =>
      Map.unmodifiable(_sceneShootingStatuses);

  double get productionProgress {
    if (_allScenes.isEmpty) return 0.0;
    final completed = _allScenes
        .where((scene) => getShootingStatus(scene) == SceneStatus.done)
        .length;
    return completed / _allScenes.length;
  }

  int get completedScenesCount => _allScenes
      .where((scene) => getShootingStatus(scene) == SceneStatus.done)
      .length;

  void setGroupMode(ProductionGroupMode mode) {
    _groupMode = mode;
    notifyListeners();
  }

  Map<String, List<Scene>> get groupedByLocation {
    final map = <String, List<Scene>>{};
    if (_groupMode == ProductionGroupMode.byLocation) {
      for (final scene in _filtered) {
        final key = scene.location?.name ?? 'Chưa có bối cảnh';
        map.putIfAbsent(key, () => []).add(scene);
      }
      for (final list in map.values) {
        list.sort((a, b) {
          final numberOrder = Scene.compareNumbers(
            a.sceneNumber,
            b.sceneNumber,
          );
          if (numberOrder != 0) return numberOrder;
          final aOrder = a.timeOfDay == SceneTime.day ? 0 : 1;
          final bOrder = b.timeOfDay == SceneTime.day ? 0 : 1;
          return aOrder.compareTo(bOrder);
        });
      }
      // Keep the closest upcoming shooting day at the top. Dates that have
      // already passed are shown afterwards, newest past date first, while
      // locations without an assigned date stay at the bottom.
      final sortedEntries = map.entries.toList();
      final originalOrder = {
        for (var index = 0; index < sortedEntries.length; index++)
          sortedEntries[index].key: index,
      };
      sortedEntries.sort((a, b) {
        final result = _compareScheduleDates(
          _customDates[a.key],
          _customDates[b.key],
        );
        if (result != 0) return result;

        // Keep the original scene/location order for equal or missing dates.
        return originalOrder[a.key]!.compareTo(originalOrder[b.key]!);
      });
      return {for (final entry in sortedEntries) entry.key: entry.value};
    }

    for (final scene in _filtered) {
      if (scene.characters.isEmpty) {
        map.putIfAbsent('Không có nhân vật', () => []).add(scene);
      } else {
        for (final character in scene.characters) {
          map.putIfAbsent(character.name, () => []).add(scene);
        }
      }
    }
    for (final list in map.values) {
      list.sort((a, b) => Scene.compareNumbers(a.sceneNumber, b.sceneNumber));
    }
    return map;
  }

  int _compareScheduleDates(String? first, String? second) {
    final firstDate = first == null ? null : DateTime.tryParse(first);
    final secondDate = second == null ? null : DateTime.tryParse(second);

    if (firstDate == null && secondDate == null) return 0;
    if (firstDate == null) return 1;
    if (secondDate == null) return -1;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final firstOnly = DateTime(firstDate.year, firstDate.month, firstDate.day);
    final secondOnly = DateTime(
      secondDate.year,
      secondDate.month,
      secondDate.day,
    );
    final firstIsPast = firstOnly.isBefore(todayOnly);
    final secondIsPast = secondOnly.isBefore(todayOnly);

    // Upcoming dates (including today) always precede dates in the past.
    if (firstIsPast != secondIsPast) return firstIsPast ? 1 : -1;
    if (firstIsPast) {
      // Among past dates, put the most recently completed day first.
      return secondOnly.compareTo(firstOnly);
    }
    // Among upcoming dates, put the nearest day first.
    return firstOnly.compareTo(secondOnly);
  }

  SceneStatus getShootingStatus(Scene scene) {
    if (scene.status != SceneStatus.done) return SceneStatus.todo;
    return _sceneShootingStatuses[scene.id] ?? SceneStatus.todo;
  }

  Future<void> loadForProject(
    int projectId, {
    bool canMigrateLegacy = false,
  }) async {
    final generation = ++_loadGeneration;
    _projectId = projectId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    List<Scene> cachedScenes = [];
    ProductionPlan? cachedPlan;
    try {
      cachedScenes = await _cache.getScenesForProject(projectId);
      cachedPlan = await _cache.getProductionPlan(projectId);
    } catch (_) {}
    if (generation != _loadGeneration) return;
    if (cachedScenes.isNotEmpty || cachedPlan != null) {
      _allScenes = cachedScenes;
      _applyPlan(cachedPlan ?? ProductionPlan.empty(projectId));
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    }

    try {
      final fetchedScenes = await _apiService.getScenesForProject(projectId);
      if (generation != _loadGeneration) return;
      _allScenes = fetchedScenes;
      try {
        await _cache.replaceScenesForProject(projectId, fetchedScenes);
      } catch (_) {}
    } catch (e) {
      if (generation != _loadGeneration) return;
      if (cachedScenes.isEmpty) _allScenes = [];
      _error = 'Không thể làm mới danh sách cảnh: $e';
    }

    try {
      var serverPlan = await _apiService.getProductionPlan(projectId);
      if (generation != _loadGeneration) return;
      if (canMigrateLegacy && serverPlan.version == 0) {
        final legacyPlan = await _readLegacyPlan(projectId);
        if (legacyPlan.locationDates.isNotEmpty ||
            legacyPlan.sceneStatuses.isNotEmpty) {
          try {
            serverPlan = await _apiService.updateProductionPlan(legacyPlan);
            if (generation != _loadGeneration) return;
            await _clearLegacyPlan(projectId);
          } on ApiException catch (e) {
            if (e.statusCode == 409) {
              serverPlan = await _apiService.getProductionPlan(projectId);
              if (generation != _loadGeneration) return;
            } else {
              rethrow;
            }
          }
        }
      }
      _plan = serverPlan;
      _applyPlan(serverPlan);
      try {
        await _cache.upsertProductionPlan(serverPlan);
      } catch (_) {}
    } catch (e) {
      if (generation != _loadGeneration) return;
      _plan = cachedPlan ?? ProductionPlan.empty(projectId);
      _applyPlan(_plan!);
      _error = 'Không thể làm mới kế hoạch sản xuất: $e';
    }

    _applyFilters();
    if (generation != _loadGeneration) return;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> setCustomDate(
    int projectId,
    String locationLabel,
    String dateStr,
  ) async {
    final locationId = _allScenes
        .where((scene) => scene.location?.name == locationLabel)
        .map((scene) => scene.locationId)
        .whereType<int>()
        .firstOrNull;
    if (locationId == null) {
      _error = 'Không tìm thấy bối cảnh hợp lệ để cập nhật ngày quay.';
      notifyListeners();
      return false;
    }
    final current = _effectivePlan(projectId);
    final dates = Map<int, String>.from(current.locationDates)
      ..[locationId] = dateStr;
    return _savePlan(current.copyWith(locationDates: dates));
  }

  Future<bool> updateShootingStatus(
    int projectId,
    int sceneId,
    SceneStatus status,
  ) async {
    final current = _effectivePlan(projectId);
    final statuses = Map<int, String>.from(current.sceneStatuses)
      ..[sceneId] = status.dbValue;
    return _savePlan(current.copyWith(sceneStatuses: statuses));
  }

  Future<bool> _savePlan(ProductionPlan candidate) async {
    if (_projectId != candidate.projectId) return false;
    if (_isSaving) {
      _error = 'Một thay đổi kế hoạch sản xuất khác đang được xử lý.';
      notifyListeners();
      return false;
    }
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _apiService.updateProductionPlan(candidate);
      _plan = saved;
      _applyPlan(saved);
      try {
        await _cache.upsertProductionPlan(saved);
      } catch (_) {}
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        try {
          final latest = await _apiService.getProductionPlan(
            candidate.projectId,
          );
          _plan = latest;
          _applyPlan(latest);
          try {
            await _cache.upsertProductionPlan(latest);
          } catch (_) {}
        } catch (_) {}
        _error =
            'Dữ liệu đã được cập nhật trên thiết bị khác. Hệ thống đã tải bản mới nhất.';
      } else {
        _error = e.message;
      }
      return false;
    } catch (e) {
      _error = 'Không thể cập nhật kế hoạch sản xuất: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  ProductionPlan _effectivePlan(int projectId) {
    final current = _plan?.projectId == projectId
        ? _plan!
        : ProductionPlan.empty(projectId);
    final validLocationIds = _allScenes
        .map((scene) => scene.locationId)
        .whereType<int>()
        .toSet();
    final scenesById = {
      for (final scene in _allScenes)
        if (scene.id != null) scene.id!: scene,
    };
    return current.copyWith(
      locationDates: {
        for (final entry in current.locationDates.entries)
          if (validLocationIds.contains(entry.key)) entry.key: entry.value,
      },
      sceneStatuses: {
        for (final entry in current.sceneStatuses.entries)
          if (scenesById[entry.key]?.status == SceneStatus.done)
            entry.key: entry.value,
      },
    );
  }

  void _applyPlan(ProductionPlan plan) {
    _plan = plan;
    final locationNames = <int, String>{};
    for (final scene in _allScenes) {
      final id = scene.locationId;
      final name = scene.location?.name;
      if (id != null && name != null) locationNames[id] = name;
    }
    _customDates = {
      for (final entry in plan.locationDates.entries)
        if (locationNames[entry.key] case final name?) name: entry.value,
    };
    _sceneShootingStatuses = {
      for (final entry in plan.sceneStatuses.entries)
        entry.key: SceneStatusExt.fromDb(entry.value),
    };
  }

  Future<ProductionPlan> _readLegacyPlan(int projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final dates = <int, String>{};
    final statuses = <int, String>{};
    for (final scene in _allScenes) {
      final locationId = scene.locationId;
      final locationName = scene.location?.name;
      if (locationId != null && locationName != null) {
        final value = prefs.getString(
          'proj_${projectId}_loc_${locationName}_date',
        );
        if (value != null &&
            DateTime.tryParse(value) != null &&
            !dates.values.contains(value)) {
          dates[locationId] = value;
        }
      }
      if (scene.id case final sceneId?) {
        final value = prefs.getString(
          'proj_${projectId}_scene_${sceneId}_shooting_status',
        );
        if (value != null &&
            (value == SceneStatus.todo.dbValue ||
                scene.status == SceneStatus.done)) {
          statuses[sceneId] = value;
        }
      }
    }
    return ProductionPlan(
      projectId: projectId,
      locationDates: dates,
      sceneStatuses: statuses,
    );
  }

  Future<void> _clearLegacyPlan(int projectId) async {
    final prefs = await SharedPreferences.getInstance();
    for (final scene in _allScenes) {
      final locationName = scene.location?.name;
      if (locationName != null) {
        await prefs.remove('proj_${projectId}_loc_${locationName}_date');
      }
      if (scene.id case final sceneId?) {
        await prefs.remove(
          'proj_${projectId}_scene_${sceneId}_shooting_status',
        );
      }
    }
    await prefs.setBool('proj_${projectId}_production_plan_migrated', true);
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
          !scene.characters.any(
            (character) => character.id == filterCharacterId,
          )) {
        return false;
      }
      if (filterTimeOfDay != null) {
        final effectiveTime = scene.location?.timeOfDay ?? scene.timeOfDay;
        if (effectiveTime != filterTimeOfDay) return false;
      }
      return true;
    }).toList();
  }
}
