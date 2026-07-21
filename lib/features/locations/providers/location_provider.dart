import 'package:flutter/material.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/services/database_helper.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';
import 'package:cinex_application/data/mock_data.dart';

class LocationProvider extends ChangeNotifier {
  final _api = ApiService();
  final _db = DatabaseHelper.instance;

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
      final fetched = await _api.getLocations(projectId);
      if (fetched.isNotEmpty) {
        _locations = fetched;
        await _db.saveLocations(fetched);
      } else {
        final local = await _db.getLocations(projectId);
        if (local.isNotEmpty) {
          _locations = local;
        } else {
          _locations = MockData.mockLocations.where((l) => l.projectId == projectId || l.projectId == null).toList();
          await _db.saveLocations(_locations);
        }
      }
    } catch (e) {
      _error = 'Không thể tải bối cảnh từ server, đọc từ SQLite: $e';
      final local = await _db.getLocations(projectId);
      if (local.isNotEmpty) {
        _locations = local;
      } else {
        _locations = MockData.mockLocations.where((l) => l.projectId == projectId || l.projectId == null).toList();
        await _db.saveLocations(_locations);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addLocation(Location location) async {
    try {
      final created = await _api.createLocation(location);
      if (created != null) {
        _locations.add(created);
        await _db.saveLocations([created]);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = 'Không thể thêm bối cảnh: $e';
    }

    final newId = DateTime.now().millisecondsSinceEpoch % 10000;
    final fallback = location.copyWith(id: newId);
    _locations.add(fallback);
    await _db.saveLocations([fallback]);
    notifyListeners();
    return true;
  }

  Future<bool> editLocation(Location location) async {
    try {
      final ok = await _api.updateLocation(location);
      if (ok) {
        final index = _locations.indexWhere((l) => l.id == location.id);
        if (index >= 0) {
          _locations[index] = location;
        }
        await _db.saveLocations([location]);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = 'Không thể cập nhật bối cảnh: $e';
    }

    final index = _locations.indexWhere((l) => l.id == location.id);
    if (index >= 0) {
      _locations[index] = location;
      await _db.saveLocations([location]);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> removeLocation(int id) async {
    final index = _locations.indexWhere((l) => l.id == id);
    if (index < 0) return false;
    final backup = _locations[index];

    _locations.removeAt(index);
    await _db.deleteLocation(id);
    notifyListeners();

    try {
      final ok = await _api.deleteLocation(id);
      if (!ok) {
        _locations.insert(index, backup);
        await _db.saveLocations([backup]);
        _error = 'Không thể xoá bối cảnh từ máy chủ';
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      return true;
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
