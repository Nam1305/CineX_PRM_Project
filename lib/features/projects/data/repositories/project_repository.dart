import 'package:cinex_application/core/database/database_helper.dart';
import 'package:cinex_application/core/database/db_constants.dart';
import '../models/project.dart';

class ProjectRepository {
  final _db = DatabaseHelper();

  Future<List<Project>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(
      DbConstants.tableProjects,
      orderBy: '${DbConstants.colId} DESC',
    );
    return maps.map(Project.fromMap).toList();
  }

  Future<Project?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      DbConstants.tableProjects,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Project.fromMap(maps.first);
  }

  Future<int> insert(Project project) async {
    final db = await _db.database;
    return db.insert(DbConstants.tableProjects, project.toMap());
  }

  Future<int> update(Project project) async {
    final db = await _db.database;
    return db.update(
      DbConstants.tableProjects,
      project.toMap(),
      where: '${DbConstants.colId} = ?',
      whereArgs: [project.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete(
      DbConstants.tableProjects,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
  }
}
