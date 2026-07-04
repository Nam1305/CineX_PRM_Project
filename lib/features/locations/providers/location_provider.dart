import 'package:flutter/material.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';

class LocationProvider extends ChangeNotifier {
  final _api = ApiService();

  List<Location> _locations = [];
  bool _isLoading = false;
  String? _error;

  List<Location> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Bối cảnh là dữ liệu dùng chung toàn hệ thống trên backend (không thuộc
  /// riêng 1 project), nên danh sách này không lọc theo project.
  Future<void> loadLocations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _locations = await _api.getLocations();
    } catch (e) {
      _error = 'Không thể tải bối cảnh: $e';
      _locations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addLocation(Location location) async {
    try {
      final created = await _api.createLocation(location);
      if (created == null) return false;
      await loadLocations();
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
      if (ok) await loadLocations();
      return ok;
    } catch (e) {
      _error = 'Không thể cập nhật bối cảnh: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeLocation(int id) async {
    try {
      final ok = await _api.deleteLocation(id);
      if (ok) await loadLocations();
      return ok;
    } catch (e) {
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
