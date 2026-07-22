import 'package:flutter/material.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/storage/local_cache_service.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';

class CharacterProvider extends ChangeNotifier {
  final _api = ApiService();
  final _cache = LocalCacheService.instance;

  List<Character> _characters = [];
  bool _isLoading = false;
  String? _error;
  int _dataVersion = 0;

  List<Character> get characters => _characters;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get dataVersion => _dataVersion;

  /// Load danh sách nhân vật từ server, fallback sang dữ liệu cục bộ khi không có kết nối
  Future<void> loadCharacters(int projectId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    List<Character> cached = [];
    try {
      cached = await _cache.getCharacters(projectId);
    } catch (_) {}
    if (cached.isNotEmpty) {
      _characters = cached;
      _isLoading = false;
      notifyListeners();
    }
    try {
      final fetched = await _api.getCharacters(projectId: projectId);
      try {
        await _cache.replaceCharacters(projectId, fetched);
      } catch (_) {}
      _characters = fetched;
    } catch (e) {
      _error = 'Không thể tải nhân vật từ server, dùng dữ liệu cục bộ: $e';
      if (cached.isEmpty) _characters = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCharacter(Character character) async {
    try {
      final created = await _api.createCharacter(character);
      if (created == null) return false;
      try {
        await _cache.upsertCharacter(created);
      } catch (_) {}
      _characters.add(created);
      _dataVersion++;
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
        try {
          await _cache.upsertCharacter(character);
        } catch (_) {}
        final index = _characters.indexWhere((c) => c.id == character.id);
        if (index >= 0) {
          _characters[index] = character;
        }
        _dataVersion++;
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
      try {
        await _cache.deleteCharacter(id);
      } catch (_) {}
      _dataVersion++;
      notifyListeners();
      return true;
    } catch (e) {
      _characters.insert(index, backup);
      _error = 'Không thể xoá nhân vật: $e';
      notifyListeners();
      return false;
    }
  }
}
