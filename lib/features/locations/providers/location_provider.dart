import 'package:flutter/material.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';
import 'package:cinex_application/data/mock_data.dart';

class LocationProvider extends ChangeNotifier {
  List<Location> _locations = [];
  bool _isLoading = false;

  List<Location> get locations => _locations;
  bool get isLoading => _isLoading;

  Future<void> loadLocations(int projectId) async {
    _isLoading = true;
    notifyListeners();
    // Load mock data for now
    _locations = MockData.locations.where((l) => l.projectId == projectId).toList();
    await Future.delayed(const Duration(milliseconds: 500));
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addLocation(Location location) async {
    _locations.add(location.copyWith(
      id: (_locations.isEmpty ? 0 : _locations.last.id ?? 0) + 1,
    ));
    notifyListeners();
  }

  Future<void> editLocation(Location location) async {
    final index = _locations.indexWhere((l) => l.id == location.id);
    if (index >= 0) {
      _locations[index] = location;
      notifyListeners();
    }
  }

  Future<void> removeLocation(int id) async {
    _locations.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  Location? getLocationById(int id) {
    try {
      return _locations.firstWhere((l) => l.id == id);
    } catch (e) {
      return null;
    }
  }
}
