import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/features/acts/data/models/act.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/core/utils/enums.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cinex_local.db');
    return _database!;
  }

  static void initDatabaseFactory() {
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> _initDB(String filePath) async {
    initDatabaseFactory();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        genre TEXT,
        description TEXT,
        director TEXT,
        start_date TEXT,
        end_date TEXT,
        poster_url TEXT,
        progress REAL,
        status TEXT,
        crew_count INTEGER,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE acts (
        id INTEGER PRIMARY KEY,
        project_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        sequence_order INTEGER NOT NULL,
        summary TEXT,
        status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE locations (
        id INTEGER PRIMARY KEY,
        project_id INTEGER,
        name TEXT NOT NULL,
        setting TEXT,
        time_of_day TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE characters (
        id INTEGER PRIMARY KEY,
        project_id INTEGER,
        name TEXT NOT NULL,
        role_type TEXT,
        description TEXT,
        actor_name TEXT,
        image_path TEXT,
        casting_status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE scenes (
        id INTEGER PRIMARY KEY,
        act_id INTEGER NOT NULL,
        location_id INTEGER,
        scene_number INTEGER NOT NULL,
        title TEXT NOT NULL,
        summary TEXT,
        status TEXT,
        setting TEXT,
        time_of_day TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE scene_characters (
        scene_id INTEGER NOT NULL,
        character_id INTEGER NOT NULL,
        PRIMARY KEY (scene_id, character_id)
      )
    ''');
  }

  // ─── PROJECTS ─────────────────────────────────────────────────────────────

  Future<void> saveProjects(List<Project> projects) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var p in projects) {
      if (p.id == null) continue;
      batch.insert(
        'projects',
        {
          'id': p.id,
          'title': p.title,
          'genre': p.genre,
          'description': p.description,
          'director': p.director,
          'start_date': p.startDate,
          'end_date': p.endDate,
          'poster_url': p.posterUrl,
          'progress': p.progress,
          'status': p.status,
          'crew_count': p.crewCount,
          'created_at': p.createdAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveSingleProject(Project project) async {
    if (project.id == null) return;
    await saveProjects([project]);
  }

  Future<List<Project>> getProjects() async {
    final db = await instance.database;
    final maps = await db.query('projects', orderBy: 'id DESC');
    return maps.map((e) => Project(
      id: e['id'] as int?,
      title: e['title'] as String? ?? '',
      genre: e['genre'] as String? ?? 'Drama',
      description: e['description'] as String?,
      director: e['director'] as String?,
      startDate: e['start_date'] as String?,
      endDate: e['end_date'] as String?,
      posterUrl: e['poster_url'] as String?,
      progress: (e['progress'] as num?)?.toDouble() ?? 0.0,
      status: e['status'] as String? ?? 'PLANNING',
      crewCount: e['crew_count'] as int? ?? 0,
      createdAt: e['created_at'] as String?,
    )).toList();
  }

  Future<void> deleteProject(int id) async {
    final db = await instance.database;
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  // ─── ACTS ─────────────────────────────────────────────────────────────────

  Future<void> saveActs(List<Act> acts) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var a in acts) {
      if (a.id == null) continue;
      batch.insert(
        'acts',
        {
          'id': a.id,
          'project_id': a.projectId,
          'title': a.title,
          'sequence_order': a.sequenceOrder,
          'summary': a.summary,
          'status': a.status,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Act>> getActsForProject(int projectId) async {
    final db = await instance.database;
    final maps = await db.query(
      'acts',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'sequence_order ASC',
    );
    return maps.map((e) => Act(
      id: e['id'] as int?,
      projectId: e['project_id'] as int,
      title: e['title'] as String,
      sequenceOrder: e['sequence_order'] as int,
      summary: e['summary'] as String?,
      status: e['status'] as String? ?? 'WAITING',
    )).toList();
  }

  Future<void> deleteAct(int id) async {
    final db = await instance.database;
    await db.delete('acts', where: 'id = ?', whereArgs: [id]);
  }

  // ─── LOCATIONS ────────────────────────────────────────────────────────────

  Future<void> saveLocations(List<Location> locations) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var loc in locations) {
      if (loc.id == null) continue;
      batch.insert(
        'locations',
        {
          'id': loc.id,
          'project_id': loc.projectId,
          'name': loc.name,
          'setting': loc.setting.dbValue,
          'time_of_day': loc.timeOfDay.dbValue,
          'notes': loc.notes,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Location>> getLocations(int projectId) async {
    final db = await instance.database;
    final maps = await db.query(
      'locations',
      where: 'project_id = ? OR project_id IS NULL',
      whereArgs: [projectId],
    );
    return maps.map((e) => Location(
      id: e['id'] as int?,
      projectId: e['project_id'] as int?,
      name: e['name'] as String,
      setting: LocationSettingExt.fromDb(e['setting'] as String? ?? 'INT'),
      timeOfDay: SceneTimeExt.fromDb(e['time_of_day'] as String? ?? 'DAY'),
      notes: e['notes'] as String?,
    )).toList();
  }

  Future<void> deleteLocation(int id) async {
    final db = await instance.database;
    await db.delete('locations', where: 'id = ?', whereArgs: [id]);
  }

  // ─── CHARACTERS ───────────────────────────────────────────────────────────

  Future<void> saveCharacters(List<Character> characters) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var c in characters) {
      if (c.id == null) continue;
      batch.insert(
        'characters',
        {
          'id': c.id,
          'project_id': c.projectId,
          'name': c.name,
          'role_type': c.roleType.dbValue,
          'description': c.description,
          'actor_name': c.actorName,
          'image_path': c.imagePath,
          'casting_status': c.castingStatus,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Character>> getCharacters({int? projectId}) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps;
    if (projectId != null) {
      maps = await db.query(
        'characters',
        where: 'project_id = ? OR project_id IS NULL',
        whereArgs: [projectId],
      );
    } else {
      maps = await db.query('characters');
    }
    return maps.map((e) => Character(
      id: e['id'] as int?,
      projectId: e['project_id'] as int?,
      name: e['name'] as String,
      roleType: RoleTypeExt.fromDb(e['role_type'] as String? ?? 'MAIN'),
      description: e['description'] as String?,
      actorName: e['actor_name'] as String?,
      imagePath: e['image_path'] as String?,
      castingStatus: e['casting_status'] as String?,
    )).toList();
  }

  Future<void> deleteCharacter(int id) async {
    final db = await instance.database;
    await db.delete('characters', where: 'id = ?', whereArgs: [id]);
  }

  // ─── SCENES ───────────────────────────────────────────────────────────────

  Future<void> saveScenes(List<Scene> scenes) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var s in scenes) {
      if (s.id == null) continue;
      batch.insert(
        'scenes',
        {
          'id': s.id,
          'act_id': s.actId,
          'location_id': s.locationId,
          'scene_number': s.sceneNumber,
          'title': s.title,
          'summary': s.summary,
          'status': s.status.dbValue,
          'setting': s.setting.dbValue,
          'time_of_day': s.timeOfDay.dbValue,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Save N-N relations
      batch.delete('scene_characters', where: 'scene_id = ?', whereArgs: [s.id]);
      for (var char in s.characters) {
        if (char.id != null) {
          batch.insert('scene_characters', {
            'scene_id': s.id,
            'character_id': char.id,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    }
    await batch.commit(noResult: true);
  }

  Future<List<Scene>> getScenesForAct(int actId) async {
    final db = await instance.database;
    final maps = await db.query(
      'scenes',
      where: 'act_id = ?',
      whereArgs: [actId],
      orderBy: 'scene_number ASC',
    );
    return _hydrateScenes(db, maps);
  }

  Future<List<Scene>> getScenesForProject(int projectId) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT s.* FROM scenes s
      INNER JOIN acts a ON s.act_id = a.id
      WHERE a.project_id = ?
      ORDER BY s.scene_number ASC
    ''', [projectId]);

    if (maps.isEmpty) {
      final allScenesMaps = await db.query('scenes', orderBy: 'scene_number ASC');
      return _hydrateScenes(db, allScenesMaps);
    }

    return _hydrateScenes(db, maps);
  }

  Future<List<Scene>> _hydrateScenes(Database db, List<Map<String, dynamic>> maps) async {
    final List<Scene> scenes = [];
    for (var e in maps) {
      final sceneId = e['id'] as int;
      Location? loc;
      if (e['location_id'] != null) {
        final locMaps = await db.query(
          'locations',
          where: 'id = ?',
          whereArgs: [e['location_id']],
          limit: 1,
        );
        if (locMaps.isNotEmpty) {
          final lMap = locMaps.first;
          loc = Location(
            id: lMap['id'] as int?,
            projectId: lMap['project_id'] as int?,
            name: lMap['name'] as String,
            setting: LocationSettingExt.fromDb(lMap['setting'] as String? ?? 'INT'),
            timeOfDay: SceneTimeExt.fromDb(lMap['time_of_day'] as String? ?? 'DAY'),
            notes: lMap['notes'] as String?,
          );
        }
      }

      // Query scene characters
      final charMaps = await db.rawQuery('''
        SELECT c.* FROM characters c
        INNER JOIN scene_characters sc ON c.id = sc.character_id
        WHERE sc.scene_id = ?
      ''', [sceneId]);

      final chars = charMaps.map((cMap) => Character(
        id: cMap['id'] as int?,
        projectId: cMap['project_id'] as int?,
        name: cMap['name'] as String,
        roleType: RoleTypeExt.fromDb(cMap['role_type'] as String? ?? 'MAIN'),
        description: cMap['description'] as String?,
        actorName: cMap['actor_name'] as String?,
        imagePath: cMap['image_path'] as String?,
        castingStatus: cMap['casting_status'] as String?,
      )).toList();

      scenes.add(Scene(
        id: sceneId,
        actId: e['act_id'] as int,
        locationId: e['location_id'] as int?,
        sceneNumber: e['scene_number'] as int,
        title: e['title'] as String? ?? '',
        summary: e['summary'] as String?,
        status: SceneStatusExt.fromDb(e['status'] as String? ?? 'TODO'),
        setting: LocationSettingExt.fromDb(e['setting'] as String? ?? 'INT'),
        timeOfDay: SceneTimeExt.fromDb(e['time_of_day'] as String? ?? 'DAY'),
        location: loc,
        characters: chars,
      ));
    }
    return scenes;
  }

  Future<void> deleteScene(int id) async {
    final db = await instance.database;
    await db.delete('scenes', where: 'id = ?', whereArgs: [id]);
    await db.delete('scene_characters', where: 'scene_id = ?', whereArgs: [id]);
  }
}
