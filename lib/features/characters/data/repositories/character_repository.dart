import 'package:cinex_application/core/database/database_helper.dart';
import 'package:cinex_application/core/database/db_constants.dart';
import '../models/character.dart';

class CharacterRepository {
  final _db = DatabaseHelper();

  Future<List<Character>> getByProject(int projectId) async {
    final db = await _db.database;
    final maps = await db.query(
      DbConstants.tableCharacters,
      where: '${DbConstants.colProjectId} = ?',
      whereArgs: [projectId],
      orderBy: DbConstants.colName,
    );
    return maps.map(Character.fromMap).toList();
  }

  Future<Character?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      DbConstants.tableCharacters,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Character.fromMap(maps.first);
  }

  Future<int> insert(Character character) async {
    final db = await _db.database;
    return db.insert(DbConstants.tableCharacters, character.toMap());
  }

  Future<int> update(Character character) async {
    final db = await _db.database;
    return db.update(
      DbConstants.tableCharacters,
      character.toMap(),
      where: '${DbConstants.colId} = ?',
      whereArgs: [character.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete(
      DbConstants.tableCharacters,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
  }
}
