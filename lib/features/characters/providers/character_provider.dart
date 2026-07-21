import 'package:flutter/material.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/services/database_helper.dart';
import 'package:cinex_application/core/services/sync_manager.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';

class CharacterProvider extends ChangeNotifier {
  final _api = ApiService();
  final _db = DatabaseHelper.instance;
  final _sync = SyncManager.instance;

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
      if (_sync.isOnline) {
        final fetched = await _api.getCharacters(projectId: projectId);
        if (fetched.isNotEmpty) {
          for (var c in fetched) {
            await _db.insertCharacter(c, syncStatus: 'synced');
          }
        }
      }
      _characters = await _db.getCharacters(projectId);
    } catch (e) {
      debugPrint('CharacterProvider.loadCharacters error: $e');
      try {
        _characters = await _db.getCharacters(projectId);
      } catch (_) {
        _error = 'Không thể tải nhân vật: $e';
        _characters = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCharacter(Character character) async {
    try {
      if (_sync.isOnline) {
        final created = await _api.createCharacter(character);
        if (created != null) {
          await _db.insertCharacter(created, syncStatus: 'synced');
          _characters.add(created);
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('CharacterProvider.addCharacter API error: $e');
    }

    // Offline hoặc API lỗi: lưu vào SQLite với pending_create
    final localId = await _db.insertCharacter(character, syncStatus: 'pending_create');
    final savedCharacter = character.copyWith(id: localId);
    _characters.add(savedCharacter);
    notifyListeners();
    return true;
  }

  Future<bool> editCharacter(Character character) async {
    if (character.id == null) return false;
    _error = null;

    final syncStatus = _sync.isOnline ? 'synced' : 'pending_update';
    await _db.updateCharacter(character, syncStatus: syncStatus);

    final index = _characters.indexWhere((c) => c.id == character.id);
    if (index >= 0) {
      _characters[index] = character;
    }
    notifyListeners();

    if (_sync.isOnline) {
      try {
        final ok = await _api.updateCharacter(character);
        if (ok) {
          await _db.updateCharacter(character, syncStatus: 'synced');
        } else {
          await _db.updateCharacter(character, syncStatus: 'pending_update');
        }
      } catch (e) {
        await _db.updateCharacter(character, syncStatus: 'pending_update');
        debugPrint('CharacterProvider.editCharacter API error: $e');
      }
    }

    return true;
  }

  Future<bool> removeCharacter(int id) async {
    final index = _characters.indexWhere((c) => c.id == id);
    if (index < 0) return false;
    final backup = _characters[index];

    _characters.removeAt(index);
    notifyListeners();

    await _db.deleteCharacter(id);

    if (_sync.isOnline) {
      try {
        final ok = await _api.deleteCharacter(id);
        if (!ok) {
          _characters.insert(index, backup);
          await _db.insertCharacter(backup, syncStatus: 'synced');
          _error = 'Không thể xoá nhân vật từ máy chủ';
          notifyListeners();
          return false;
        }
      } catch (e) {
        debugPrint('CharacterProvider.removeCharacter API error: $e');
      }
    }

    return true;
  }
}
