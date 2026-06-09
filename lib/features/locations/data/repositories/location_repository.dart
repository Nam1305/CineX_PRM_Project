import 'package:cinex_application/core/database/database_helper.dart';
import 'package:cinex_application/core/database/db_constants.dart';
import '../models/location.dart';

class LocationRepository {
  final _db = DatabaseHelper();

  Future<List<Location>> getByProject(int projectId) async {
    final db = await _db.database;
    final maps = await db.query(
      DbConstants.tableLocations,
      where: '${DbConstants.colProjectId} = ?',
      whereArgs: [projectId],
      orderBy: DbConstants.colName,
    );
    return maps.map(Location.fromMap).toList();
  }

  Future<Location?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      DbConstants.tableLocations,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Location.fromMap(maps.first);
  }

  Future<int> insert(Location location) async {
    final db = await _db.database;
    return db.insert(DbConstants.tableLocations, location.toMap());
  }

  Future<int> update(Location location) async {
    final db = await _db.database;
    return db.update(
      DbConstants.tableLocations,
      location.toMap(),
      where: '${DbConstants.colId} = ?',
      whereArgs: [location.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete(
      DbConstants.tableLocations,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
  }
}
