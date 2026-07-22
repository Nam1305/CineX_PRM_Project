import 'package:flutter/material.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/storage/local_cache_service.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';

class LocationProvider extends ChangeNotifier {
  final _api = ApiService();
  final _cache = LocalCacheService.instance;

  List<Location> _locations = [];
  bool _isLoading = false;
  String? _error;
  int _dataVersion = 0;

  List<Location> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get dataVersion => _dataVersion;

  Future<void> loadLocations(int projectId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    List<Location> cached = [];
    try {
      cached = await _cache.getLocations(projectId);
    } catch (_) {}
    if (cached.isNotEmpty) {
      _locations = cached;
      _isLoading = false;
      notifyListeners();
    }
    try {
      final fetched = await _api.getLocations(projectId);
      try {
        await _cache.replaceLocations(projectId, fetched);
      } catch (_) {}
      _locations = fetched;
    } catch (e) {
      _error = 'Không thể tải bối cảnh từ server, dùng dữ liệu cục bộ: $e';
      if (cached.isEmpty) _locations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addLocation(Location location) async {
    try {
      final created = await _api.createLocation(location);
      if (created == null) return false;
      try {
        await _cache.upsertLocation(created);
      } catch (_) {}
      _locations.add(created);
      _dataVersion++;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Không thể thêm bối cảnh: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> editLocation(Location location) async {
    try {
      final ok = await _api.updateLocation(location);
      if (ok) {
        try {
          await _cache.upsertLocation(location);
        } catch (_) {}
        final index = _locations.indexWhere((l) => l.id == location.id);
        if (index >= 0) {
          _locations[index] = location;
        }
        _dataVersion++;
        notifyListeners();
      }
      return ok;
    } catch (e) {
      _error = 'Không thể cập nhật bối cảnh: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeLocation(int id) async {
    final index = _locations.indexWhere((l) => l.id == id);
    if (index < 0) return false;
    final backup = _locations[index];

    _locations.removeAt(index);
    notifyListeners();

    try {
      final ok = await _api.deleteLocation(id);
      if (!ok) {
        _locations.insert(index, backup);
        _error = 'Không thể xoá bối cảnh từ máy chủ';
        notifyListeners();
        return false;
      }
      try {
        await _cache.deleteLocation(id);
      } catch (_) {}
      _dataVersion++;
      notifyListeners();
      return true;
    } catch (e) {
      _locations.insert(index, backup);
      _error = 'Không thể xoá bối cảnh: $e';
      notifyListeners();
      return false;
    }
  }

  Location? getLocationById(int id) {
    try {
      return _locations.firstWhere((l) => l.id == id);
    } catch (e) {
      return null;
    }
  }
}
