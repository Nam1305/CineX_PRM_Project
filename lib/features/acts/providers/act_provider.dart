import 'package:flutter/material.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/storage/local_cache_service.dart';
import 'package:cinex_application/features/acts/data/models/act.dart';

class ActProvider extends ChangeNotifier {
  final _api = ApiService();
  final _cache = LocalCacheService.instance;

  final Map<int, List<Act>> _actsByProject = {};
  final Set<int> _loadingProjects = {};
  final Map<int, String> _errorsByProject = {};
  final Map<int, int> _loadRevisions = {};

  List<Act> actsForProject(int projectId) =>
      List.unmodifiable(_actsByProject[projectId] ?? const <Act>[]);
  bool hasLoadedProject(int projectId) => _actsByProject.containsKey(projectId);
  bool isLoadingForProject(int projectId) =>
      _loadingProjects.contains(projectId);
  String? errorForProject(int projectId) => _errorsByProject[projectId];

  Future<void> loadActs(int projectId) async {
    final revision = (_loadRevisions[projectId] ?? 0) + 1;
    _loadRevisions[projectId] = revision;
    _loadingProjects.add(projectId);
    _errorsByProject.remove(projectId);
    notifyListeners();
    List<Act> cached = [];
    try {
      cached = _forProject(await _cache.getActs(projectId), projectId);
    } catch (_) {}
    if (_isCurrentLoad(projectId, revision) && cached.isNotEmpty) {
      _actsByProject[projectId] = cached;
      _loadingProjects.remove(projectId);
      notifyListeners();
    }
    try {
      final scoped = _forProject(
        await _api.getActsForProject(projectId),
        projectId,
      );
      try {
        await _cache.replaceActs(projectId, scoped);
      } catch (_) {}
      if (_isCurrentLoad(projectId, revision)) {
        _actsByProject[projectId] = scoped;
      }
    } catch (e) {
      if (_isCurrentLoad(projectId, revision)) {
        _errorsByProject[projectId] =
            'Không thể tải hồi từ server, dùng dữ liệu cục bộ: $e';
        if (cached.isEmpty) _actsByProject[projectId] = [];
      }
    } finally {
      if (_isCurrentLoad(projectId, revision)) {
        _loadingProjects.remove(projectId);
        notifyListeners();
      }
    }
  }

  bool _isCurrentLoad(int projectId, int revision) =>
      _loadRevisions[projectId] == revision;

  Future<bool> addAct(Act act) async {
    try {
      final created = await _api.createAct(act);
      if (created == null) return false;
      try {
        await _cache.upsertAct(created);
      } catch (_) {}
      final acts = _actsByProject.putIfAbsent(created.projectId, () => []);
      if (!acts.any((item) => item.id == created.id)) acts.add(created);
      _sortActs(acts);
      notifyListeners();
      return true;
    } catch (e) {
      _errorsByProject[act.projectId] = 'Không thể thêm hồi: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> editAct(Act act) async {
    try {
      final ok = await _api.updateAct(act);
      if (ok) {
        try {
          await _cache.upsertAct(act);
        } catch (_) {}
        final acts = _actsByProject.putIfAbsent(act.projectId, () => []);
        final index = acts.indexWhere((a) => a.id == act.id);
        if (index >= 0) {
          acts[index] = act;
        }
        _sortActs(acts);
        notifyListeners();
      }
      return ok;
    } catch (e) {
      _errorsByProject[act.projectId] = 'Không thể cập nhật hồi: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeAct(int id) async {
    int? ownerProjectId;
    var index = -1;
    for (final entry in _actsByProject.entries) {
      final foundIndex = entry.value.indexWhere((a) => a.id == id);
      if (foundIndex >= 0) {
        ownerProjectId = entry.key;
        index = foundIndex;
        break;
      }
    }
    if (index < 0) return false;
    final acts = _actsByProject[ownerProjectId]!;
    final backup = acts[index];

    acts.removeAt(index);
    notifyListeners();

    try {
      final ok = await _api.deleteAct(id);
      if (!ok) {
        acts.insert(index, backup);
        _errorsByProject[ownerProjectId!] = 'Không thể xoá hồi từ máy chủ';
        notifyListeners();
        return false;
      }
      try {
        await _cache.deleteAct(id);
      } catch (_) {}
      return true;
    } catch (e) {
      acts.insert(index, backup);
      _errorsByProject[ownerProjectId!] = 'Không thể xoá hồi: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> restoreAct(int id, int projectId) async {
    try {
      final ok = await _api.restoreAct(id);
      if (ok) {
        await loadActs(projectId);
      }
      return ok;
    } catch (e) {
      _errorsByProject[projectId] = 'Không thể khôi phục hồi: $e';
      notifyListeners();
      return false;
    }
  }

  List<Act> _forProject(List<Act> acts, int projectId) {
    final scoped = acts.where((act) => act.projectId == projectId).toList();
    _sortActs(scoped);
    return scoped;
  }

  void _sortActs(List<Act> acts) =>
      acts.sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));
}
