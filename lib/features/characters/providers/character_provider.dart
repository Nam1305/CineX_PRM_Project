import 'package:flutter/material.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/services/database_helper.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/data/mock_data.dart';

class CharacterProvider extends ChangeNotifier {
  final _api = ApiService();
  final _db = DatabaseHelper.instance;

  List<Character> _characters = [];
  bool _isLoading = false;
  String? _error;

  List<Character> get characters => _characters;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCharacters(int projectId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final fetched = await _api.getCharacters(projectId: projectId);
      if (fetched.isNotEmpty) {
        _characters = fetched;
        await _db.saveCharacters(fetched);
      } else {
        final local = await _db.getCharacters(projectId: projectId);
        if (local.isNotEmpty) {
          _characters = local;
        } else {
          _characters = MockData.mockCharacters.where((c) => c.projectId == projectId || c.projectId == null).toList();
          await _db.saveCharacters(_characters);
        }
      }
    } catch (e) {
      _error = 'Không thể tải nhân vật từ server, đọc từ SQLite: $e';
      final local = await _db.getCharacters(projectId: projectId);
      if (local.isNotEmpty) {
        _characters = local;
      } else {
        _characters = MockData.mockCharacters.where((c) => c.projectId == projectId || c.projectId == null).toList();
        await _db.saveCharacters(_characters);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCharacter(Character character) async {
    try {
      final created = await _api.createCharacter(character);
      if (created != null) {
        _characters.add(created);
        await _db.saveCharacters([created]);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = 'Không thể thêm nhân vật: $e';
    }

    final newId = DateTime.now().millisecondsSinceEpoch % 10000;
    final fallback = character.copyWith(id: newId);
    _characters.add(fallback);
    await _db.saveCharacters([fallback]);
    notifyListeners();
    return true;
  }

  Future<bool> editCharacter(Character character) async {
    try {
      final ok = await _api.updateCharacter(character);
      if (ok) {
        final index = _characters.indexWhere((c) => c.id == character.id);
        if (index >= 0) {
          _characters[index] = character;
        }
        await _db.saveCharacters([character]);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = 'Không thể cập nhật nhân vật: $e';
    }

    final index = _characters.indexWhere((c) => c.id == character.id);
    if (index >= 0) {
      _characters[index] = character;
      await _db.saveCharacters([character]);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> removeCharacter(int id) async {
    final index = _characters.indexWhere((c) => c.id == id);
    if (index < 0) return false;
    final backup = _characters[index];

    _characters.removeAt(index);
    await _db.deleteCharacter(id);
    notifyListeners();

    try {
      final ok = await _api.deleteCharacter(id);
      if (!ok) {
        _characters.insert(index, backup);
        await _db.saveCharacters([backup]);
        _error = 'Không thể xoá nhân vật từ máy chủ';
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      return true;
    }
  }
}
