import 'package:flutter/material.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';
import 'package:cinex_application/features/locations/data/repositories/location_repository.dart';

class LocationProvider extends ChangeNotifier {
  final _repo = LocationRepository();

  List<Location> _locations = [];
  int? _currentProjectId;
  bool _isLoading = false;

  List<Location> get locations => _locations;
  bool get isLoading => _isLoading;

  Future<void> loadLocations(int projectId) async {
    _currentProjectId = projectId;
    _isLoading = true;
    notifyListeners();
    _locations = await _repo.getByProject(projectId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addLocation(Location location) async {
    await _repo.insert(location);
    if (_currentProjectId != null) await loadLocations(_currentProjectId!);
  }

  Future<void> editLocation(Location location) async {
    await _repo.update(location);
    if (_currentProjectId != null) await loadLocations(_currentProjectId!);
  }

  Future<void> removeLocation(int id) async {
    await _repo.delete(id);
    if (_currentProjectId != null) await loadLocations(_currentProjectId!);
  }
}
