import 'package:flutter/material.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/features/characters/data/repositories/character_repository.dart';

class CharacterProvider extends ChangeNotifier {
  final _repo = CharacterRepository();

  List<Character> _characters = [];
  int? _currentProjectId;
  bool _isLoading = false;

  List<Character> get characters => _characters;
  bool get isLoading => _isLoading;

  Future<void> loadCharacters(int projectId) async {
    _currentProjectId = projectId;
    _isLoading = true;
    notifyListeners();
    _characters = await _repo.getByProject(projectId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCharacter(Character character) async {
    await _repo.insert(character);
    if (_currentProjectId != null) await loadCharacters(_currentProjectId!);
  }

  Future<void> editCharacter(Character character) async {
    await _repo.update(character);
    if (_currentProjectId != null) await loadCharacters(_currentProjectId!);
  }

  Future<void> removeCharacter(int id) async {
    await _repo.delete(id);
    if (_currentProjectId != null) await loadCharacters(_currentProjectId!);
  }
}
