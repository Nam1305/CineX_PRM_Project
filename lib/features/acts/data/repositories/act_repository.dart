import 'package:cinex_application/core/database/database_helper.dart';
import 'package:cinex_application/core/database/db_constants.dart';
import '../models/act.dart';

class ActRepository {
  final _db = DatabaseHelper();

  Future<List<Act>> getByProject(int projectId) async {
    final db = await _db.database;
    final maps = await db.query(
      DbConstants.tableActs,
      where: '${DbConstants.colProjectId} = ?',
      whereArgs: [projectId],
      orderBy: DbConstants.colSequenceOrder,
    );
    return maps.map(Act.fromMap).toList();
  }

  Future<int> insert(Act act) async {
    final db = await _db.database;
    return db.insert(DbConstants.tableActs, act.toMap());
  }

  Future<int> update(Act act) async {
    final db = await _db.database;
    return db.update(
      DbConstants.tableActs,
      act.toMap(),
      where: '${DbConstants.colId} = ?',
      whereArgs: [act.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete(
      DbConstants.tableActs,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
  }
}
