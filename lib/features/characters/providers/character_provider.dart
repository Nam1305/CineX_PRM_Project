import 'package:flutter/material.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/data/mock_data.dart';

class CharacterProvider extends ChangeNotifier {
  final _api = ApiService();

  List<Character> _characters = [];
  bool _isLoading = false;
  String? _error;

  List<Character> get characters => _characters;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load danh sách nhân vật từ server, fallback sang dữ liệu cục bộ khi không có kết nối
  Future<void> loadCharacters(int projectId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _characters = await _api.getCharacters(projectId: projectId);
    } catch (e) {
      _error = 'Không thể tải nhân vật từ server, dùng dữ liệu cục bộ: $e';
      _characters = MockData.mockCharacters.where((c) => c.projectId == projectId || c.projectId == null).toList();
      if (_characters.isEmpty) {
        _characters = List.from(MockData.mockCharacters);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCharacter(Character character) async {
    try {
      final created = await _api.createCharacter(character);
      if (created == null) return false;
      _characters.add(created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Không thể thêm nhân vật: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> editCharacter(Character character) async {
    try {
      final ok = await _api.updateCharacter(character);
      if (ok) {
        final index = _characters.indexWhere((c) => c.id == character.id);
        if (index >= 0) {
          _characters[index] = character;
        }
        notifyListeners();
      }
      return ok;
    } catch (e) {
      _error = 'Không thể cập nhật nhân vật: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeCharacter(int id) async {
    final index = _characters.indexWhere((c) => c.id == id);
    if (index < 0) return false;
    final backup = _characters[index];

    _characters.removeAt(index);
    notifyListeners();

    try {
      final ok = await _api.deleteCharacter(id);
      if (!ok) {
        _characters.insert(index, backup);
        _error = 'Không thể xoá nhân vật từ máy chủ';
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      _characters.insert(index, backup);
      _error = 'Không thể xoá nhân vật: $e';
      notifyListeners();
      return false;
    }
  }
}
