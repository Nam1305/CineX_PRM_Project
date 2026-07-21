import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/core/utils/enums.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cinex_local.db');

    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Kích hoạt hỗ trợ khóa ngoại của SQLite để tự động cascade update/delete
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. PROJECTS Table
    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        genre TEXT,
        description TEXT,
        director TEXT,
        start_date TEXT,
        end_date TEXT,
        poster_url TEXT,
        progress REAL DEFAULT 0.0,
        status TEXT DEFAULT 'PLANNING',
        crew_count INTEGER DEFAULT 0,
        created_at TEXT,
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    // 2. ACTS Table
    await db.execute('''
      CREATE TABLE acts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        sequence_order INTEGER NOT NULL,
        summary TEXT,
        status TEXT DEFAULT 'WAITING',
        sync_status TEXT DEFAULT 'synced',
        FOREIGN KEY (project_id) REFERENCES projects (id) ON UPDATE CASCADE ON DELETE CASCADE
      )
    ''');

    // 3. LOCATIONS Table
    await db.execute('''
      CREATE TABLE locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER,
        name TEXT NOT NULL,
        setting TEXT DEFAULT 'INT',
        time TEXT DEFAULT 'DAY',
        notes TEXT,
        sync_status TEXT DEFAULT 'synced',
        FOREIGN KEY (project_id) REFERENCES projects (id) ON UPDATE CASCADE ON DELETE CASCADE
      )
    ''');

    // 4. CHARACTERS Table
    await db.execute('''
      CREATE TABLE characters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER,
        name TEXT NOT NULL,
        role_type TEXT DEFAULT 'MAIN',
        actor_name TEXT,
        description TEXT,
        image_path TEXT,
        casting_status TEXT,
        sync_status TEXT DEFAULT 'synced',
        FOREIGN KEY (project_id) REFERENCES projects (id) ON UPDATE CASCADE ON DELETE CASCADE
      )
    ''');

    // 5. SCENES Table
    await db.execute('''
      CREATE TABLE scenes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        act_id INTEGER NOT NULL,
        location_id INTEGER,
        scene_number INTEGER NOT NULL,
        title TEXT NOT NULL,
        summary TEXT,
        status TEXT DEFAULT 'TODO',
        setting TEXT DEFAULT 'INT',
        time TEXT DEFAULT 'DAY',
        sync_status TEXT DEFAULT 'synced',
        FOREIGN KEY (act_id) REFERENCES acts (id) ON UPDATE CASCADE ON DELETE CASCADE,
        FOREIGN KEY (location_id) REFERENCES locations (id) ON UPDATE CASCADE ON DELETE SET NULL
      )
    ''');

    // 6. SCENE_CHARACTERS Table (N-N)
    await db.execute('''
      CREATE TABLE scene_characters (
        scene_id INTEGER NOT NULL,
        character_id INTEGER NOT NULL,
        sync_status TEXT DEFAULT 'synced',
        PRIMARY KEY (scene_id, character_id),
        FOREIGN KEY (scene_id) REFERENCES scenes (id) ON UPDATE CASCADE ON DELETE CASCADE,
        FOREIGN KEY (character_id) REFERENCES characters (id) ON UPDATE CASCADE ON DELETE CASCADE
      )
    ''');
  }

  // ==========================================
  // GENERAL HELPER METHODS
  // ==========================================

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('scene_characters');
    await db.delete('scenes');
    await db.delete('characters');
    await db.delete('locations');
    await db.delete('acts');
    await db.delete('projects');
  }

  // ==========================================
  // PROJECTS CRUD
  // ==========================================

  Future<List<Project>> getProjects() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      where: 'sync_status != ?',
      whereArgs: ['pending_delete'],
    );
    return maps.map((map) => Project.fromMap(map)).toList();
  }

  Future<Project?> getProjectById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      where: 'id = ? AND sync_status != ?',
      whereArgs: [id, 'pending_delete'],
    );
    if (maps.isEmpty) return null;
    return Project.fromMap(maps.first);
  }

  Future<int> insertProject(Project project, {String syncStatus = 'synced'}) async {
    final db = await database;
    final map = project.toMap();
    map['sync_status'] = syncStatus;
    if (project.id != null) {
      map['id'] = project.id;
    }
    return await db.insert('projects', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateProject(Project project, {String? syncStatus}) async {
    final db = await database;
    final map = project.toMap();
    if (syncStatus != null) {
      map['sync_status'] = syncStatus;
    }
    return await db.update(
      'projects',
      map,
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<int> deleteProject(int id) async {
    final db = await database;
    // Kiểm tra xem dự án này có được tạo offline và chưa đồng bộ hay không
    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      columns: ['sync_status'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty && maps.first['sync_status'] == 'pending_create') {
      // Chưa từng đồng bộ -> Xóa cứng luôn khỏi SQLite
      return await db.delete('projects', where: 'id = ?', whereArgs: [id]);
    } else {
      // Đã đồng bộ -> Đánh dấu soft-delete để SyncManager đồng bộ xóa sau
      return await db.update(
        'projects',
        {'sync_status': 'pending_delete'},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // ==========================================
  // ACTS CRUD
  // ==========================================

  // Lấy toàn bộ Hồi/Phân đoạn của dự án
  Future<List<Map<String, dynamic>>> getActs(int projectId) async {
    final db = await database;
    return await db.query(
      'acts',
      where: 'project_id = ? AND sync_status != ?',
      whereArgs: [projectId, 'pending_delete'],
      orderBy: 'act_number ASC',
    );
  }

  Future<int> insertAct(Map<String, dynamic> act, {String syncStatus = 'synced'}) async {
    final db = await database;
    final map = Map<String, dynamic>.from(act);
    map['sync_status'] = syncStatus;
    // Chuẩn hóa tên khóa ngoại cho sqlite
    if (map.containsKey('ProjectId') && !map.containsKey('project_id')) {
      map['project_id'] = map['ProjectId'];
    }
    if (map.containsKey('Id') && !map.containsKey('id')) {
      map['id'] = map['Id'];
    }
    return await db.insert('acts', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateAct(Map<String, dynamic> act, {String? syncStatus}) async {
    final db = await database;
    final map = Map<String, dynamic>.from(act);
    if (syncStatus != null) {
      map['sync_status'] = syncStatus;
    }
    final int id = map['id'] ?? map['Id'];
    return await db.update(
      'acts',
      map,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAct(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'acts',
      columns: ['sync_status'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty && maps.first['sync_status'] == 'pending_create') {
      return await db.delete('acts', where: 'id = ?', whereArgs: [id]);
    } else {
      return await db.update(
        'acts',
        {'sync_status': 'pending_delete'},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // ==========================================
  // LOCATIONS CRUD
  // ==========================================

  Future<List<Location>> getLocations(int projectId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where: 'project_id = ? AND sync_status != ?',
      whereArgs: [projectId, 'pending_delete'],
    );
    return maps.map((e) => Location.fromMap(e)).toList();
  }

  Future<int> insertLocation(Location location, {String syncStatus = 'synced'}) async {
    final db = await database;
    final map = {
      if (location.id != null) 'id': location.id,
      'project_id': location.projectId,
      'name': location.name,
      'setting': location.setting.dbValue,
      'time': location.timeOfDay.dbValue,
      'notes': location.notes,
      'sync_status': syncStatus,
    };
    return await db.insert('locations', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateLocation(Location location, {String? syncStatus}) async {
    final db = await database;
    final map = {
      'project_id': location.projectId,
      'name': location.name,
      'setting': location.setting.dbValue,
      'time': location.timeOfDay.dbValue,
      'notes': location.notes,
      if (syncStatus != null) 'sync_status': syncStatus,
    };
    return await db.update(
      'locations',
      map,
      where: 'id = ?',
      whereArgs: [location.id],
    );
  }

  Future<int> deleteLocation(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      columns: ['sync_status'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty && maps.first['sync_status'] == 'pending_create') {
      return await db.delete('locations', where: 'id = ?', whereArgs: [id]);
    } else {
      return await db.update(
        'locations',
        {'sync_status': 'pending_delete'},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // ==========================================
  // CHARACTERS CRUD
  // ==========================================

  Future<List<Character>> getCharacters(int projectId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'characters',
      where: 'project_id = ? AND sync_status != ?',
      whereArgs: [projectId, 'pending_delete'],
    );
    return maps.map((e) => Character.fromMap(e)).toList();
  }

  Future<int> insertCharacter(Character character, {String syncStatus = 'synced'}) async {
    final db = await database;
    final map = {
      if (character.id != null) 'id': character.id,
      'project_id': character.projectId,
      'name': character.name,
      'role_type': character.roleType.dbValue,
      'actor_name': character.actorName,
      'description': character.description,
      'image_path': character.imagePath,
      'casting_status': character.castingStatus,
      'sync_status': syncStatus,
    };
    return await db.insert('characters', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateCharacter(Character character, {String? syncStatus}) async {
    final db = await database;
    final map = {
      'project_id': character.projectId,
      'name': character.name,
      'role_type': character.roleType.dbValue,
      'actor_name': character.actorName,
      'description': character.description,
      'image_path': character.imagePath,
      'casting_status': character.castingStatus,
      if (syncStatus != null) 'sync_status': syncStatus,
    };
    return await db.update(
      'characters',
      map,
      where: 'id = ?',
      whereArgs: [character.id],
    );
  }

  Future<int> deleteCharacter(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'characters',
      columns: ['sync_status'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty && maps.first['sync_status'] == 'pending_create') {
      return await db.delete('characters', where: 'id = ?', whereArgs: [id]);
    } else {
      return await db.update(
        'characters',
        {'sync_status': 'pending_delete'},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // ==========================================
  // SCENES CRUD
  // ==========================================

  Future<List<Scene>> getScenesForAct(int actId) async {
    final db = await database;
    final List<Map<String, dynamic>> sceneMaps = await db.query(
      'scenes',
      where: 'act_id = ? AND sync_status != ?',
      whereArgs: [actId, 'pending_delete'],
      orderBy: 'scene_number ASC',
    );

    List<Scene> scenes = [];
    for (var sMap in sceneMaps) {
      final sceneId = sMap['id'] as int;

      // Lấy location
      Location? loc;
      final locId = sMap['location_id'] as int?;
      if (locId != null) {
        final List<Map<String, dynamic>> locMaps = await db.query(
          'locations',
          where: 'id = ?',
          whereArgs: [locId],
        );
        if (locMaps.isNotEmpty) {
          loc = Location.fromMap(locMaps.first);
        }
      }

      // Lấy danh sách nhân vật tham gia
      final List<Map<String, dynamic>> linkMaps = await db.rawQuery('''
        SELECT c.* FROM characters c
        INNER JOIN scene_characters sc ON c.id = sc.character_id
        WHERE sc.scene_id = ? AND sc.sync_status != 'pending_delete'
      ''', [sceneId]);
      final chars = linkMaps.map((cMap) => Character.fromMap(cMap)).toList();

      scenes.add(Scene(
        id: sceneId,
        actId: sMap['act_id'] as int,
        locationId: locId,
        sceneNumber: sMap['scene_number'] as int,
        title: sMap['title'] as String,
        summary: sMap['summary'] as String?,
        status: SceneStatusExt.fromDb(sMap['status'] as String? ?? 'TODO'),
        setting: LocationSettingExt.fromDb(sMap['setting'] as String? ?? 'INT'),
        timeOfDay: SceneTimeExt.fromDb(sMap['time'] as String? ?? 'DAY'),
        location: loc,
        characters: chars,
      ));
    }
    return scenes;
  }

  Future<List<Scene>> getScenesForProject(int projectId) async {
    final db = await database;
    // Tìm các scene của các act thuộc project này
    final List<Map<String, dynamic>> sceneMaps = await db.rawQuery('''
      SELECT s.* FROM scenes s
      INNER JOIN acts a ON s.act_id = a.id
      WHERE a.project_id = ? AND s.sync_status != 'pending_delete'
    ''', [projectId]);

    List<Scene> scenes = [];
    for (var sMap in sceneMaps) {
      final sceneId = sMap['id'] as int;

      Location? loc;
      final locId = sMap['location_id'] as int?;
      if (locId != null) {
        final List<Map<String, dynamic>> locMaps = await db.query(
          'locations',
          where: 'id = ?',
          whereArgs: [locId],
        );
        if (locMaps.isNotEmpty) {
          loc = Location.fromMap(locMaps.first);
        }
      }

      final List<Map<String, dynamic>> linkMaps = await db.rawQuery('''
        SELECT c.* FROM characters c
        INNER JOIN scene_characters sc ON c.id = sc.character_id
        WHERE sc.scene_id = ? AND sc.sync_status != 'pending_delete'
      ''', [sceneId]);
      final chars = linkMaps.map((cMap) => Character.fromMap(cMap)).toList();

      scenes.add(Scene(
        id: sceneId,
        actId: sMap['act_id'] as int,
        locationId: locId,
        sceneNumber: sMap['scene_number'] as int,
        title: sMap['title'] as String,
        summary: sMap['summary'] as String?,
        status: SceneStatusExt.fromDb(sMap['status'] as String? ?? 'TODO'),
        setting: LocationSettingExt.fromDb(sMap['setting'] as String? ?? 'INT'),
        timeOfDay: SceneTimeExt.fromDb(sMap['time'] as String? ?? 'DAY'),
        location: loc,
        characters: chars,
      ));
    }
    return scenes;
  }

  Future<int> insertScene(Scene scene, {String syncStatus = 'synced'}) async {
    final db = await database;
    final map = {
      if (scene.id != null) 'id': scene.id,
      'act_id': scene.actId,
      'location_id': scene.locationId,
      'scene_number': scene.sceneNumber,
      'title': scene.title,
      'summary': scene.summary,
      'status': scene.status.dbValue,
      'setting': scene.setting.dbValue,
      'time': scene.timeOfDay.dbValue,
      'sync_status': syncStatus,
    };
    final sceneId = await db.insert('scenes', map, conflictAlgorithm: ConflictAlgorithm.replace);

    // Lưu các nhân vật liên kết
    await db.delete('scene_characters', where: 'scene_id = ?', whereArgs: [sceneId]);
    for (var character in scene.characters) {
      if (character.id != null) {
        await db.insert('scene_characters', {
          'scene_id': sceneId,
          'character_id': character.id,
          'sync_status': syncStatus,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    return sceneId;
  }

  Future<int> updateScene(Scene scene, {String? syncStatus}) async {
    final db = await database;
    final map = {
      'act_id': scene.actId,
      'location_id': scene.locationId,
      'scene_number': scene.sceneNumber,
      'title': scene.title,
      'summary': scene.summary,
      'status': scene.status.dbValue,
      'setting': scene.setting.dbValue,
      'time': scene.timeOfDay.dbValue,
      if (syncStatus != null) 'sync_status': syncStatus,
    };
    final count = await db.update(
      'scenes',
      map,
      where: 'id = ?',
      whereArgs: [scene.id],
    );

    // Cập nhật lại liên kết nhân vật trong scene
    if (scene.id != null) {
      await db.delete('scene_characters', where: 'scene_id = ?', whereArgs: [scene.id]);
      for (var character in scene.characters) {
        if (character.id != null) {
          await db.insert('scene_characters', {
            'scene_id': scene.id,
            'character_id': character.id,
            'sync_status': syncStatus ?? 'synced',
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    }

    return count;
  }

  Future<int> deleteScene(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scenes',
      columns: ['sync_status'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty && maps.first['sync_status'] == 'pending_create') {
      return await db.delete('scenes', where: 'id = ?', whereArgs: [id]);
    } else {
      // Đánh dấu xóa cho cả phân cảnh và liên kết nhân vật
      await db.update(
        'scene_characters',
        {'sync_status': 'pending_delete'},
        where: 'scene_id = ?',
        whereArgs: [id],
      );
      return await db.update(
        'scenes',
        {'sync_status': 'pending_delete'},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // ==========================================
  // DIRECT PRIMARY KEY UPDATE (FOR SYNC UPDATE)
  // ==========================================

  // Cập nhật ID của dự án và kích hoạt CASCADE của SQLite
  Future<void> updateProjectIdDirectly(int oldId, int newId) async {
    final db = await database;
    await db.rawUpdate('UPDATE projects SET id = ? WHERE id = ?', [newId, oldId]);
  }

  Future<void> updateActIdDirectly(int oldId, int newId) async {
    final db = await database;
    await db.rawUpdate('UPDATE acts SET id = ? WHERE id = ?', [newId, oldId]);
  }

  Future<void> updateLocationIdDirectly(int oldId, int newId) async {
    final db = await database;
    await db.rawUpdate('UPDATE locations SET id = ? WHERE id = ?', [newId, oldId]);
  }

  Future<void> updateCharacterIdDirectly(int oldId, int newId) async {
    final db = await database;
    await db.rawUpdate('UPDATE characters SET id = ? WHERE id = ?', [newId, oldId]);
  }

  Future<void> updateSceneIdDirectly(int oldId, int newId) async {
    final db = await database;
    await db.rawUpdate('UPDATE scenes SET id = ? WHERE id = ?', [newId, oldId]);
  }
}
