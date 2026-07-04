import 'package:flutter/material.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';

class CharacterProvider extends ChangeNotifier {
  final _api = ApiService();

  List<Character> _characters = [];
  bool _isLoading = false;
  String? _error;

  List<Character> get characters => _characters;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Nhân vật là dữ liệu dùng chung toàn hệ thống trên backend (không thuộc
  /// riêng 1 project), nên danh sách này không lọc theo project.
  Future<void> loadCharacters() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _characters = await _api.getCharacters();
    } catch (e) {
      _error = 'Không thể tải nhân vật: $e';
      _characters = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCharacter(Character character) async {
    try {
      final created = await _api.createCharacter(character);
      if (created == null) return false;
      await loadCharacters();
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
      if (ok) await loadCharacters();
      return ok;
    } catch (e) {
      _error = 'Không thể cập nhật nhân vật: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeCharacter(int id) async {
    try {
      final ok = await _api.deleteCharacter(id);
      if (ok) await loadCharacters();
      return ok;
    } catch (e) {
      _error = 'Không thể xoá nhân vật: $e';
      notifyListeners();
      return false;
    }
  }
}
