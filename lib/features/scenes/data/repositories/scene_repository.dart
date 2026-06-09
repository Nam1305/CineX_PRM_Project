import 'package:cinex_application/core/database/database_helper.dart';
import 'package:cinex_application/core/database/db_constants.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';
import '../models/scene.dart';

class SceneRepository {
  final _db = DatabaseHelper();

  /// Returns scenes for an act, each enriched with its Location and Characters.
  Future<List<Scene>> getScenesForAct(int actId) async {
    final db = await _db.database;

    final maps = await db.rawQuery('''
      SELECT s.*,
             l.${DbConstants.colProjectId} AS loc_project_id,
             l.${DbConstants.colName}      AS loc_name,
             l.${DbConstants.colSetting}   AS loc_setting,
             l.${DbConstants.colTimeOfDay} AS loc_time_of_day,
             l.${DbConstants.colNotes}     AS loc_notes
      FROM   ${DbConstants.tableScenes} s
      LEFT JOIN ${DbConstants.tableLocations} l
             ON s.${DbConstants.colLocationId} = l.${DbConstants.colId}
      WHERE  s.${DbConstants.colActId} = ?
      ORDER BY s.${DbConstants.colSceneNumber}
    ''', [actId]);

    final scenes = <Scene>[];
    for (final map in maps) {
      final locationId = map[DbConstants.colLocationId] as int?;
      Location? location;
      if (locationId != null && map['loc_name'] != null) {
        location = Location.fromMap({
          'id': locationId,
          'project_id': map['loc_project_id'],
          'name': map['loc_name'],
          'setting': map['loc_setting'],
          'time_of_day': map['loc_time_of_day'],
          'notes': map['loc_notes'],
        });
      }

      final charMaps = await db.rawQuery('''
        SELECT c.* FROM ${DbConstants.tableCharacters} c
        INNER JOIN ${DbConstants.tableSceneCharacters} sc
               ON c.${DbConstants.colId} = sc.${DbConstants.colCharacterId}
        WHERE  sc.${DbConstants.colSceneId} = ?
      ''', [map['id']]);

      scenes.add(
        Scene.fromMap(map).copyWith(
          location: location,
          characters: charMaps.map(Character.fromMap).toList(),
        ),
      );
    }
    return scenes;
  }

  /// Returns all scenes for a project (across all acts) — used by Production Planner.
  Future<List<Scene>> getScenesForProject(int projectId) async {
    final db = await _db.database;
    final actMaps = await db.query(
      DbConstants.tableActs,
      columns: [DbConstants.colId],
      where: '${DbConstants.colProjectId} = ?',
      whereArgs: [projectId],
    );
    final scenes = <Scene>[];
    for (final act in actMaps) {
      scenes.addAll(await getScenesForAct(act[DbConstants.colId] as int));
    }
    return scenes;
  }

  Future<int> insert(Scene scene, List<int> characterIds) async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final sceneId = await txn.insert(
        DbConstants.tableScenes,
        scene.toMap(),
      );
      for (final charId in characterIds) {
        await txn.insert(DbConstants.tableSceneCharacters, {
          DbConstants.colSceneId: sceneId,
          DbConstants.colCharacterId: charId,
        });
      }
      return sceneId;
    });
  }

  Future<void> update(Scene scene, List<int> characterIds) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update(
        DbConstants.tableScenes,
        scene.toMap(),
        where: '${DbConstants.colId} = ?',
        whereArgs: [scene.id],
      );
      // Replace character links
      await txn.delete(
        DbConstants.tableSceneCharacters,
        where: '${DbConstants.colSceneId} = ?',
        whereArgs: [scene.id],
      );
      for (final charId in characterIds) {
        await txn.insert(DbConstants.tableSceneCharacters, {
          DbConstants.colSceneId: scene.id,
          DbConstants.colCharacterId: charId,
        });
      }
    });
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete(
      DbConstants.tableScenes,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
  }

  /// Check if scene_number is already used within the same act.
  Future<bool> isSceneNumberTaken(int actId, int sceneNumber,
      {int? excludeId}) async {
    final db = await _db.database;
    final where = StringBuffer(
      '${DbConstants.colActId} = ? AND ${DbConstants.colSceneNumber} = ?',
    );
    final args = <dynamic>[actId, sceneNumber];
    if (excludeId != null) {
      where.write(' AND ${DbConstants.colId} != ?');
      args.add(excludeId);
    }
    final maps = await db.query(
      DbConstants.tableScenes,
      columns: [DbConstants.colId],
      where: where.toString(),
      whereArgs: args,
      limit: 1,
    );
    return maps.isNotEmpty;
  }
}
