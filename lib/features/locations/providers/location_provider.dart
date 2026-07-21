import 'package:flutter/material.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/services/database_helper.dart';
import 'package:cinex_application/core/services/sync_manager.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';

class LocationProvider extends ChangeNotifier {
  final _api = ApiService();
  final _db = DatabaseHelper.instance;
  final _sync = SyncManager.instance;

  List<Location> _locations = [];
  bool _isLoading = false;
  String? _error;

  List<Location> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLocations(int projectId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (_sync.isOnline) {
        final fetched = await _api.getLocations(projectId);
        if (fetched.isNotEmpty) {
          for (var l in fetched) {
            await _db.insertLocation(l, syncStatus: 'synced');
          }
        }
      }
      _locations = await _db.getLocations(projectId);
    } catch (e) {
      debugPrint('LocationProvider.loadLocations error: $e');
      try {
        _locations = await _db.getLocations(projectId);
      } catch (_) {
        _error = 'Không thể tải bối cảnh: $e';
        _locations = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addLocation(Location location) async {
    try {
      if (_sync.isOnline) {
        final created = await _api.createLocation(location);
        if (created != null) {
          await _db.insertLocation(created, syncStatus: 'synced');
          _locations.add(created);
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('LocationProvider.addLocation API error: $e');
    }

    // Offline hoặc API lỗi: lưu vào SQLite với pending_create
    final localId = await _db.insertLocation(location, syncStatus: 'pending_create');
    final savedLocation = location.copyWith(id: localId);
    _locations.add(savedLocation);
    notifyListeners();
    return true;
  }

  Future<bool> editLocation(Location location) async {
    if (location.id == null) return false;
    _error = null;

    final syncStatus = _sync.isOnline ? 'synced' : 'pending_update';
    await _db.updateLocation(location, syncStatus: syncStatus);

    final index = _locations.indexWhere((l) => l.id == location.id);
    if (index >= 0) {
      _locations[index] = location;
    }
    notifyListeners();

    if (_sync.isOnline) {
      try {
        final ok = await _api.updateLocation(location);
        if (ok) {
          await _db.updateLocation(location, syncStatus: 'synced');
        } else {
          await _db.updateLocation(location, syncStatus: 'pending_update');
        }
      } catch (e) {
        await _db.updateLocation(location, syncStatus: 'pending_update');
        debugPrint('LocationProvider.editLocation API error: $e');
      }
    }

    return true;
  }

  Future<bool> removeLocation(int id) async {
    final index = _locations.indexWhere((l) => l.id == id);
    if (index < 0) return false;
    final backup = _locations[index];

    _locations.removeAt(index);
    notifyListeners();

    await _db.deleteLocation(id);

    if (_sync.isOnline) {
      try {
        final ok = await _api.deleteLocation(id);
        if (!ok) {
          _locations.insert(index, backup);
          await _db.insertLocation(backup, syncStatus: 'synced');
          _error = 'Không thể xoá bối cảnh từ máy chủ';
          notifyListeners();
          return false;
        }
      } catch (e) {
        debugPrint('LocationProvider.removeLocation API error: $e');
      }
    }

    return true;
  }

  Location? getLocationById(int id) {
    try {
      return _locations.firstWhere((l) => l.id == id);
    } catch (e) {
      return null;
    }
  }
}
