import 'dart:convert';

import 'package:cinex_application/core/storage/local_database_factory.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/acts/data/models/act.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/features/production/data/models/production_plan.dart';
import 'package:cinex_application/features/notifications/data/models/notification_model.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common/sqlite_api.dart';

class MediaCacheRecord {
  final List<int>? bytes;
  final String? localPath;
  final String contentType;

  const MediaCacheRecord({
    this.bytes,
    this.localPath,
    required this.contentType,
  });
}

/// Persistent, read-only-offline cache. PostgreSQL remains the source of truth.
/// Server writes are mirrored here only after the API confirms success.
class LocalCacheService {
  LocalCacheService._();

  static final LocalCacheService instance = LocalCacheService._();
  static const _databaseName = 'cinex_offline.db';
  static const _schemaVersion = 3;

  Database? _database;
  Future<Database>? _opening;

  Future<Database> get _db {
    if (_database case final database?) return Future.value(database);
    return _opening ??= _open();
  }

  Future<Database> _open() async {
    final factory = createLocalDatabaseFactory();
    final root = await factory.getDatabasesPath();
    final database = await factory.openDatabase(
      p.join(root, _databaseName),
      options: OpenDatabaseOptions(
        version: _schemaVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await _createSchema(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) await _createProductionPlansTable(db);
          if (oldVersion < 3) await _createNotificationsTable(db);
        },
      ),
    );
    _database = database;
    return database;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY,
        payload TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE acts (
        id INTEGER PRIMARY KEY,
        project_id INTEGER NOT NULL,
        sequence_order INTEGER NOT NULL,
        payload TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX ix_acts_project_order ON acts(project_id, sequence_order)',
    );
    await db.execute('''
      CREATE TABLE characters (
        id INTEGER PRIMARY KEY,
        project_id INTEGER,
        name TEXT NOT NULL,
        payload TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX ix_characters_project_name ON characters(project_id, name)',
    );
    await db.execute('''
      CREATE TABLE locations (
        id INTEGER PRIMARY KEY,
        project_id INTEGER,
        name TEXT NOT NULL,
        payload TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX ix_locations_project_name ON locations(project_id, name)',
    );
    await db.execute('''
      CREATE TABLE scenes (
        id INTEGER PRIMARY KEY,
        act_id INTEGER NOT NULL,
        project_id INTEGER,
        scene_number TEXT NOT NULL,
        status TEXT NOT NULL,
        location_id INTEGER,
        payload TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX ix_scenes_act_number ON scenes(act_id, scene_number)',
    );
    await db.execute(
      'CREATE INDEX ix_scenes_project_status ON scenes(project_id, status)',
    );
    await db.execute('''
      CREATE TABLE sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE media_cache (
        cache_key TEXT PRIMARY KEY,
        content_type TEXT NOT NULL,
        bytes BLOB,
        local_path TEXT,
        cached_at INTEGER NOT NULL,
        last_accessed_at INTEGER NOT NULL
      )
    ''');
    await _createProductionPlansTable(db);
    await _createNotificationsTable(db);
  }

  Future<void> _createProductionPlansTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS production_plans (
        project_id INTEGER PRIMARY KEY,
        payload TEXT NOT NULL,
        version INTEGER NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createNotificationsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        owner_key TEXT NOT NULL,
        id INTEGER NOT NULL,
        project_id INTEGER,
        timestamp INTEGER NOT NULL,
        is_read INTEGER NOT NULL,
        payload TEXT NOT NULL,
        cached_at INTEGER NOT NULL,
        PRIMARY KEY (owner_key, id)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS ix_notifications_owner_time '
      'ON notifications(owner_key, timestamp DESC)',
    );
  }

  Future<List<NotificationModel>> getNotifications(String ownerKey) async {
    final rows = await (await _db).query(
      'notifications',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
      orderBy: 'timestamp DESC',
    );
    return rows.map((row) => NotificationModel.fromMap(_payload(row))).toList();
  }

  Future<void> replaceNotifications(
    String ownerKey,
    List<NotificationModel> notifications,
  ) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        'notifications',
        where: 'owner_key = ?',
        whereArgs: [ownerKey],
      );
      final batch = txn.batch();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final notification in notifications) {
        if (notification.id == null) continue;
        batch.insert('notifications', {
          'owner_key': ownerKey,
          'id': notification.id,
          'project_id': notification.projectId,
          'timestamp': notification.timestamp.millisecondsSinceEpoch,
          'is_read': notification.isRead ? 1 : 0,
          'payload': jsonEncode(notification.toMap()),
          'cached_at': now,
        });
      }
      await batch.commit(noResult: true);
      await _setLastSync(txn, 'notifications:$ownerKey', now);
    });
  }

  Future<void> upsertNotification(
    String ownerKey,
    NotificationModel notification,
  ) async {
    if (notification.id == null) return;
    await (await _db).insert('notifications', {
      'owner_key': ownerKey,
      'id': notification.id,
      'project_id': notification.projectId,
      'timestamp': notification.timestamp.millisecondsSinceEpoch,
      'is_read': notification.isRead ? 1 : 0,
      'payload': jsonEncode(notification.toMap()),
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCachedNotificationReadState(
    String ownerKey,
    Iterable<NotificationModel> notifications,
  ) async {
    final db = await _db;
    await db.transaction((txn) async {
      final batch = txn.batch();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final notification in notifications) {
        if (notification.id == null) continue;
        batch.insert('notifications', {
          'owner_key': ownerKey,
          'id': notification.id,
          'project_id': notification.projectId,
          'timestamp': notification.timestamp.millisecondsSinceEpoch,
          'is_read': notification.isRead ? 1 : 0,
          'payload': jsonEncode(notification.toMap()),
          'cached_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<ProductionPlan?> getProductionPlan(int projectId) async {
    final rows = await (await _db).query(
      'production_plans',
      where: 'project_id = ?',
      whereArgs: [projectId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ProductionPlan.fromMap(_payload(rows.first));
  }

  Future<void> upsertProductionPlan(ProductionPlan plan) async {
    await (await _db).insert('production_plans', {
      'project_id': plan.projectId,
      'payload': jsonEncode(plan.toMap()),
      'version': plan.version,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Project>> getProjects() async {
    final rows = await (await _db).query('projects', orderBy: 'id');
    return rows.map((row) => Project.fromMap(_payload(row))).toList();
  }

  Future<void> replaceProjects(List<Project> projects) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('projects');
      final batch = txn.batch();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final project in projects) {
        if (project.id == null) continue;
        batch.insert('projects', {
          'id': project.id,
          'payload': jsonEncode(project.toMap()),
          'cached_at': now,
        });
      }
      await batch.commit(noResult: true);
      await _setLastSync(txn, 'projects', now);
    });
  }

  Future<void> upsertProject(Project project) async {
    if (project.id == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await (await _db).insert('projects', {
      'id': project.id,
      'payload': jsonEncode(project.toMap()),
      'cached_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteProject(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      final actRows = await txn.query(
        'acts',
        columns: ['id'],
        where: 'project_id = ?',
        whereArgs: [id],
      );
      final actIds = actRows.map((row) => row['id'] as int).toList();
      if (actIds.isNotEmpty) {
        final placeholders = List.filled(actIds.length, '?').join(',');
        await txn.delete(
          'scenes',
          where: 'act_id IN ($placeholders)',
          whereArgs: actIds,
        );
      }
      await txn.delete('acts', where: 'project_id = ?', whereArgs: [id]);
      await txn.delete('characters', where: 'project_id = ?', whereArgs: [id]);
      await txn.delete('locations', where: 'project_id = ?', whereArgs: [id]);
      await txn.delete(
        'production_plans',
        where: 'project_id = ?',
        whereArgs: [id],
      );
      await txn.delete('projects', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Act>> getActs(int projectId) async {
    final rows = await (await _db).query(
      'acts',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'sequence_order',
    );
    return rows.map((row) => Act.fromMap(_payload(row))).toList();
  }

  Future<void> replaceActs(int projectId, List<Act> acts) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('acts', where: 'project_id = ?', whereArgs: [projectId]);
      final batch = txn.batch();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final act in acts) {
        if (act.id == null) continue;
        batch.insert('acts', {
          'id': act.id,
          'project_id': projectId,
          'sequence_order': act.sequenceOrder,
          'payload': jsonEncode({...act.toMap(), 'id': act.id}),
          'cached_at': now,
        });
      }
      await batch.commit(noResult: true);
      await _setLastSync(txn, 'acts:$projectId', now);
    });
  }

  Future<void> upsertAct(Act act) async {
    if (act.id == null) return;
    await (await _db).insert('acts', {
      'id': act.id,
      'project_id': act.projectId,
      'sequence_order': act.sequenceOrder,
      'payload': jsonEncode({...act.toMap(), 'id': act.id}),
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteAct(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('scenes', where: 'act_id = ?', whereArgs: [id]);
      await txn.delete('acts', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Character>> getCharacters(int projectId) async {
    final rows = await (await _db).query(
      'characters',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map((row) => Character.fromMap(_payload(row))).toList();
  }

  Future<void> replaceCharacters(
    int projectId,
    List<Character> characters,
  ) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        'characters',
        where: 'project_id = ?',
        whereArgs: [projectId],
      );
      final batch = txn.batch();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final character in characters) {
        if (character.id == null) continue;
        final map = _characterMap(character);
        batch.insert('characters', {
          'id': character.id,
          'project_id': projectId,
          'name': character.name,
          'payload': jsonEncode(map),
          'cached_at': now,
        });
      }
      await batch.commit(noResult: true);
      await _setLastSync(txn, 'characters:$projectId', now);
    });
  }

  Future<void> upsertCharacter(Character character) async {
    if (character.id == null || character.projectId == null) return;
    await (await _db).insert('characters', {
      'id': character.id,
      'project_id': character.projectId,
      'name': character.name,
      'payload': jsonEncode(_characterMap(character)),
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCharacter(int id) async {
    await (await _db).delete('characters', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Location>> getLocations(int projectId) async {
    final rows = await (await _db).query(
      'locations',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map((row) => Location.fromMap(_payload(row))).toList();
  }

  Future<void> replaceLocations(int projectId, List<Location> locations) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        'locations',
        where: 'project_id = ?',
        whereArgs: [projectId],
      );
      final batch = txn.batch();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final location in locations) {
        if (location.id == null) continue;
        batch.insert('locations', {
          'id': location.id,
          'project_id': projectId,
          'name': location.name,
          'payload': jsonEncode(_locationMap(location)),
          'cached_at': now,
        });
      }
      await batch.commit(noResult: true);
      await _setLastSync(txn, 'locations:$projectId', now);
    });
  }

  Future<void> upsertLocation(Location location) async {
    if (location.id == null || location.projectId == null) return;
    await (await _db).insert('locations', {
      'id': location.id,
      'project_id': location.projectId,
      'name': location.name,
      'payload': jsonEncode(_locationMap(location)),
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteLocation(int id) async {
    await (await _db).delete('locations', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Scene>> getScenesForAct(int actId) async {
    final rows = await (await _db).query(
      'scenes',
      where: 'act_id = ?',
      whereArgs: [actId],
    );
    final scenes = rows.map((row) => _sceneFromMap(_payload(row))).toList();
    scenes.sort((a, b) => Scene.compareNumbers(a.sceneNumber, b.sceneNumber));
    return scenes;
  }

  Future<List<Scene>> getScenesForProject(int projectId) async {
    final rows = await (await _db).query(
      'scenes',
      where: 'project_id = ?',
      whereArgs: [projectId],
    );
    return rows.map((row) => _sceneFromMap(_payload(row))).toList();
  }

  Future<void> replaceScenesForAct(int actId, List<Scene> scenes) async {
    final db = await _db;
    final actRows = await db.query(
      'acts',
      columns: ['project_id'],
      where: 'id = ?',
      whereArgs: [actId],
      limit: 1,
    );
    final projectId = actRows.isEmpty
        ? null
        : actRows.first['project_id'] as int?;
    await _replaceScenes(
      deleteWhere: 'act_id = ?',
      deleteArgs: [actId],
      scenes: scenes,
      projectId: projectId,
      metadataKey: 'scenes:act:$actId',
    );
  }

  Future<void> replaceScenesForProject(int projectId, List<Scene> scenes) =>
      _replaceScenes(
        deleteWhere: 'project_id = ?',
        deleteArgs: [projectId],
        scenes: scenes,
        projectId: projectId,
        metadataKey: 'scenes:project:$projectId',
      );

  Future<void> _replaceScenes({
    required String deleteWhere,
    required List<Object?> deleteArgs,
    required List<Scene> scenes,
    required int? projectId,
    required String metadataKey,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('scenes', where: deleteWhere, whereArgs: deleteArgs);
      final batch = txn.batch();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final scene in scenes) {
        if (scene.id == null) continue;
        batch.insert('scenes', _sceneRow(scene, projectId, now));
      }
      await batch.commit(noResult: true);
      await _setLastSync(txn, metadataKey, now);
    });
  }

  Future<void> upsertScene(Scene scene, {int? projectId}) async {
    if (scene.id == null) return;
    final db = await _db;
    if (projectId == null) {
      final existing = await db.query(
        'scenes',
        columns: ['project_id'],
        where: 'id = ?',
        whereArgs: [scene.id],
        limit: 1,
      );
      projectId = existing.isEmpty
          ? null
          : existing.first['project_id'] as int?;
    }
    if (projectId == null) {
      final actRows = await db.query(
        'acts',
        columns: ['project_id'],
        where: 'id = ?',
        whereArgs: [scene.actId],
        limit: 1,
      );
      projectId = actRows.isEmpty ? null : actRows.first['project_id'] as int?;
    }
    await db.insert(
      'scenes',
      _sceneRow(scene, projectId, DateTime.now().millisecondsSinceEpoch),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteScene(int id) async {
    await (await _db).delete('scenes', where: 'id = ?', whereArgs: [id]);
  }

  Future<DateTime?> lastSync(String key) async {
    final rows = await (await _db).query(
      'sync_metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['last_sync:$key'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final millis = int.tryParse(rows.first['value'] as String);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<MediaCacheRecord?> getMedia(String cacheKey) async {
    final rows = await (await _db).query(
      'media_cache',
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    final now = DateTime.now().millisecondsSinceEpoch;
    await (await _db).update(
      'media_cache',
      {'last_accessed_at': now},
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
    );
    return MediaCacheRecord(
      bytes: row['bytes'] as List<int>?,
      localPath: row['local_path'] as String?,
      contentType: row['content_type'] as String,
    );
  }

  Future<void> putMedia({
    required String cacheKey,
    required String contentType,
    List<int>? bytes,
    String? localPath,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (await _db).insert('media_cache', {
      'cache_key': cacheKey,
      'content_type': contentType,
      'bytes': bytes,
      'local_path': localPath,
      'cached_at': now,
      'last_accessed_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeMedia(String cacheKey) async {
    await (await _db).delete(
      'media_cache',
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
    );
  }

  Future<void> _setLastSync(
    DatabaseExecutor executor,
    String key,
    int millis,
  ) async {
    await executor.insert('sync_metadata', {
      'key': 'last_sync:$key',
      'value': '$millis',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Map<String, dynamic> _payload(Map<String, Object?> row) =>
      jsonDecode(row['payload'] as String) as Map<String, dynamic>;

  Map<String, dynamic> _characterMap(Character character) => {
    'Id': character.id,
    'ProjectId': character.projectId,
    'Name': character.name,
    'Role': character.roleType.dbValue,
    'ActorName': character.actorName,
    'Description': character.description,
    'ImageUrl': character.imagePath,
    'CastingStatus': character.castingStatus,
  };

  Map<String, dynamic> _locationMap(Location location) => {
    'Id': location.id,
    'ProjectId': location.projectId,
    'Name': location.name,
    'Setting': location.setting.dbValue,
    'Time': location.timeOfDay.dbValue,
    'Notes': location.notes,
  };

  Map<String, dynamic> _sceneMap(Scene scene) => {
    'Id': scene.id,
    'ActId': scene.actId,
    'LocationId': scene.locationId,
    'SceneNumber': scene.sceneNumber,
    'Title': scene.title,
    'Summary': scene.summary,
    'Status': scene.status.dbValue,
    'Setting': scene.setting.dbValue,
    'Time': scene.timeOfDay.dbValue,
    'Location': scene.location == null ? null : _locationMap(scene.location!),
    'Characters': scene.characters.map(_characterMap).toList(),
  };

  Map<String, Object?> _sceneRow(Scene scene, int? projectId, int now) => {
    'id': scene.id,
    'act_id': scene.actId,
    'project_id': projectId,
    'scene_number': scene.sceneNumber,
    'status': scene.status.dbValue,
    'location_id': scene.locationId,
    'payload': jsonEncode(_sceneMap(scene)),
    'cached_at': now,
  };

  Scene _sceneFromMap(Map<String, dynamic> map) {
    final locationMap = map['Location'] as Map<String, dynamic>?;
    final characterMaps = map['Characters'] as List<dynamic>? ?? const [];
    return Scene(
      id: map['Id'] as int?,
      actId: map['ActId'] as int,
      locationId: map['LocationId'] as int?,
      sceneNumber: map['SceneNumber'] as String,
      title: map['Title'] as String,
      summary: map['Summary'] as String?,
      status: SceneStatusExt.fromDb(map['Status'] as String? ?? 'TODO'),
      setting: LocationSettingExt.fromDb(map['Setting'] as String? ?? 'INT'),
      timeOfDay: SceneTimeExt.fromDb(map['Time'] as String? ?? 'DAY'),
      location: locationMap == null ? null : Location.fromMap(locationMap),
      characters: characterMaps
          .map((item) => Character.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
