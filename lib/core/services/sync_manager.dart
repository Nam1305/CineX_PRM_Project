import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/services/database_helper.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/features/acts/data/models/act.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';

/// Quản lý đồng bộ dữ liệu giữa SQLite cục bộ và Backend API.
///
/// Workflow:
/// 1. Khi online: Tải dữ liệu từ API -> Lưu vào SQLite (synced)
/// 2. Khi offline: Đọc/ghi trực tiếp vào SQLite (pending_*)
/// 3. Khi online trở lại: Đẩy các bản ghi pending lên API, cập nhật ID
class SyncManager extends ChangeNotifier {
  static final SyncManager instance = SyncManager._();

  final _db = DatabaseHelper.instance;
  final _api = ApiService();
  final _connectivity = Connectivity();

  bool _isSyncing = false;
  bool _isOnline = true;
  String? _lastSyncError;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;
  String? get lastSyncError => _lastSyncError;

  SyncManager._();

  /// Khởi tạo theo dõi kết nối mạng và tự động đồng bộ khi online trở lại
  void init() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final wasOffline = !_isOnline;
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      notifyListeners();

      // Khi online trở lại sau khi offline -> tự động đồng bộ
      if (wasOffline && _isOnline) {
        debugPrint('SyncManager: Kết nối mạng khôi phục – bắt đầu đồng bộ...');
        syncAll();
      }
    });

    // Kiểm tra trạng thái kết nối ban đầu
    _connectivity.checkConnectivity().then((results) {
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      notifyListeners();
    });
  }

  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  /// Kiểm tra kết nối mạng hiện tại
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      notifyListeners();
      return _isOnline;
    } catch (e) {
      _isOnline = false;
      notifyListeners();
      return false;
    }
  }

  // ============================
  // FULL SYNC (Online -> SQLite)
  // ============================

  /// Tải toàn bộ dữ liệu từ API về và lưu vào SQLite
  /// Chỉ chạy khi online, dùng để đồng bộ ban đầu hoặc pull-to-refresh
  Future<void> pullAllFromServer() async {
    if (!_isOnline) return;

    try {
      // 1. Tải Projects
      final projects = await _api.getProjects();
      for (var p in projects) {
        await _db.insertProject(p, syncStatus: 'synced');
      }

      // 2. Tải Acts, Locations, Characters cho từng project
      for (var p in projects) {
        if (p.id == null) continue;

        final acts = await _api.getActsForProject(p.id!);
        for (var a in acts) {
          final actMap = a.toMap();
          actMap['sync_status'] = 'synced';
          await _db.insertAct(actMap, syncStatus: 'synced');
        }

        final locations = await _api.getLocations(p.id!);
        for (var l in locations) {
          await _db.insertLocation(l, syncStatus: 'synced');
        }

        final characters = await _api.getCharacters(projectId: p.id!);
        for (var c in characters) {
          await _db.insertCharacter(c, syncStatus: 'synced');
        }

        // 3. Tải Scenes cho từng act
        for (var a in acts) {
          if (a.id == null) continue;
          final scenes = await _api.getScenesForAct(a.id!);
          for (var s in scenes) {
            await _db.insertScene(s, syncStatus: 'synced');
          }
        }
      }

      debugPrint('SyncManager: pullAllFromServer hoàn tất.');
    } catch (e) {
      debugPrint('SyncManager: pullAllFromServer lỗi: $e');
    }
  }

  // ============================
  // PUSH PENDING (SQLite -> API)
  // ============================

  /// Đồng bộ tất cả các bản ghi pending trong SQLite lên API
  Future<void> syncAll() async {
    if (_isSyncing || !_isOnline) return;

    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      await _syncProjects();
      await _syncActs();
      await _syncLocations();
      await _syncCharacters();
      await _syncScenes();
      debugPrint('SyncManager: syncAll hoàn tất.');
    } catch (e) {
      _lastSyncError = 'Lỗi đồng bộ: $e';
      debugPrint('SyncManager: syncAll lỗi: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // --- PROJECTS ---
  Future<void> _syncProjects() async {
    final db = await _db.database;

    // 1. pending_create
    final pendingCreates = await db.query(
      'projects',
      where: 'sync_status = ?',
      whereArgs: ['pending_create'],
    );
    for (var row in pendingCreates) {
      final localId = row['id'] as int;
      final project = Project.fromMap(row);
      try {
        final created = await _api.createProject(project);
        if (created != null && created.id != null) {
          // Cập nhật ID local -> server ID (CASCADE sẽ lan truyền FK)
          await _db.updateProjectIdDirectly(localId, created.id!);
          await db.update(
            'projects',
            {'sync_status': 'synced'},
            where: 'id = ?',
            whereArgs: [created.id],
          );
        }
      } catch (e) {
        debugPrint('SyncManager: Sync project (create) id=$localId lỗi: $e');
      }
    }

    // 2. pending_update
    final pendingUpdates = await db.query(
      'projects',
      where: 'sync_status = ?',
      whereArgs: ['pending_update'],
    );
    for (var row in pendingUpdates) {
      final project = Project.fromMap(row);
      try {
        await _api.updateProject(project);
        await db.update(
          'projects',
          {'sync_status': 'synced'},
          where: 'id = ?',
          whereArgs: [project.id],
        );
      } catch (e) {
        debugPrint('SyncManager: Sync project (update) id=${project.id} lỗi: $e');
      }
    }

    // 3. pending_delete
    final pendingDeletes = await db.query(
      'projects',
      where: 'sync_status = ?',
      whereArgs: ['pending_delete'],
    );
    for (var row in pendingDeletes) {
      final id = row['id'] as int;
      try {
        await _api.deleteProject(id);
        await db.delete('projects', where: 'id = ?', whereArgs: [id]);
      } catch (e) {
        debugPrint('SyncManager: Sync project (delete) id=$id lỗi: $e');
      }
    }
  }

  // --- ACTS ---
  Future<void> _syncActs() async {
    final db = await _db.database;

    final pendingCreates = await db.query(
      'acts',
      where: 'sync_status = ?',
      whereArgs: ['pending_create'],
    );
    for (var row in pendingCreates) {
      final localId = row['id'] as int;
      final act = Act.fromMap(row);
      try {
        final created = await _api.createAct(act);
        if (created != null && created.id != null) {
          await _db.updateActIdDirectly(localId, created.id!);
          await db.update(
            'acts',
            {'sync_status': 'synced'},
            where: 'id = ?',
            whereArgs: [created.id],
          );
        }
      } catch (e) {
        debugPrint('SyncManager: Sync act (create) id=$localId lỗi: $e');
      }
    }

    final pendingUpdates = await db.query(
      'acts',
      where: 'sync_status = ?',
      whereArgs: ['pending_update'],
    );
    for (var row in pendingUpdates) {
      final act = Act.fromMap(row);
      try {
        await _api.updateAct(act);
        await db.update(
          'acts',
          {'sync_status': 'synced'},
          where: 'id = ?',
          whereArgs: [act.id],
        );
      } catch (e) {
        debugPrint('SyncManager: Sync act (update) id=${act.id} lỗi: $e');
      }
    }

    final pendingDeletes = await db.query(
      'acts',
      where: 'sync_status = ?',
      whereArgs: ['pending_delete'],
    );
    for (var row in pendingDeletes) {
      final id = row['id'] as int;
      try {
        await _api.deleteAct(id);
        await db.delete('acts', where: 'id = ?', whereArgs: [id]);
      } catch (e) {
        debugPrint('SyncManager: Sync act (delete) id=$id lỗi: $e');
      }
    }
  }

  // --- LOCATIONS ---
  Future<void> _syncLocations() async {
    final db = await _db.database;

    final pendingCreates = await db.query(
      'locations',
      where: 'sync_status = ?',
      whereArgs: ['pending_create'],
    );
    for (var row in pendingCreates) {
      final localId = row['id'] as int;
      final location = Location.fromMap(row);
      try {
        final created = await _api.createLocation(location);
        if (created != null && created.id != null) {
          await _db.updateLocationIdDirectly(localId, created.id!);
          await db.update(
            'locations',
            {'sync_status': 'synced'},
            where: 'id = ?',
            whereArgs: [created.id],
          );
        }
      } catch (e) {
        debugPrint('SyncManager: Sync location (create) id=$localId lỗi: $e');
      }
    }

    final pendingUpdates = await db.query(
      'locations',
      where: 'sync_status = ?',
      whereArgs: ['pending_update'],
    );
    for (var row in pendingUpdates) {
      final location = Location.fromMap(row);
      try {
        await _api.updateLocation(location);
        await db.update(
          'locations',
          {'sync_status': 'synced'},
          where: 'id = ?',
          whereArgs: [location.id],
        );
      } catch (e) {
        debugPrint('SyncManager: Sync location (update) id=${location.id} lỗi: $e');
      }
    }

    final pendingDeletes = await db.query(
      'locations',
      where: 'sync_status = ?',
      whereArgs: ['pending_delete'],
    );
    for (var row in pendingDeletes) {
      final id = row['id'] as int;
      try {
        await _api.deleteLocation(id);
        await db.delete('locations', where: 'id = ?', whereArgs: [id]);
      } catch (e) {
        debugPrint('SyncManager: Sync location (delete) id=$id lỗi: $e');
      }
    }
  }

  // --- CHARACTERS ---
  Future<void> _syncCharacters() async {
    final db = await _db.database;

    final pendingCreates = await db.query(
      'characters',
      where: 'sync_status = ?',
      whereArgs: ['pending_create'],
    );
    for (var row in pendingCreates) {
      final localId = row['id'] as int;
      final character = Character.fromMap(row);
      try {
        final created = await _api.createCharacter(character);
        if (created != null && created.id != null) {
          await _db.updateCharacterIdDirectly(localId, created.id!);
          await db.update(
            'characters',
            {'sync_status': 'synced'},
            where: 'id = ?',
            whereArgs: [created.id],
          );
        }
      } catch (e) {
        debugPrint('SyncManager: Sync character (create) id=$localId lỗi: $e');
      }
    }

    final pendingUpdates = await db.query(
      'characters',
      where: 'sync_status = ?',
      whereArgs: ['pending_update'],
    );
    for (var row in pendingUpdates) {
      final character = Character.fromMap(row);
      try {
        await _api.updateCharacter(character);
        await db.update(
          'characters',
          {'sync_status': 'synced'},
          where: 'id = ?',
          whereArgs: [character.id],
        );
      } catch (e) {
        debugPrint('SyncManager: Sync character (update) id=${character.id} lỗi: $e');
      }
    }

    final pendingDeletes = await db.query(
      'characters',
      where: 'sync_status = ?',
      whereArgs: ['pending_delete'],
    );
    for (var row in pendingDeletes) {
      final id = row['id'] as int;
      try {
        await _api.deleteCharacter(id);
        await db.delete('characters', where: 'id = ?', whereArgs: [id]);
      } catch (e) {
        debugPrint('SyncManager: Sync character (delete) id=$id lỗi: $e');
      }
    }
  }

  // --- SCENES ---
  Future<void> _syncScenes() async {
    final db = await _db.database;

    final pendingCreates = await db.query(
      'scenes',
      where: 'sync_status = ?',
      whereArgs: ['pending_create'],
    );
    for (var row in pendingCreates) {
      final localId = row['id'] as int;
      // Lấy scene kèm characters từ SQLite
      final scenesForAct = await _db.getScenesForAct(row['act_id'] as int);
      final scene = scenesForAct.firstWhere(
        (s) => s.id == localId,
        orElse: () => Scene(
          id: localId,
          actId: row['act_id'] as int,
          sceneNumber: row['scene_number'] as int,
          title: row['title'] as String,
        ),
      );
      final characterIds = scene.characters.map((c) => c.id!).toList();

      try {
        final created = await _api.createScene(scene, characterIds);
        if (created != null && created.id != null) {
          await _db.updateSceneIdDirectly(localId, created.id!);
          await db.update(
            'scenes',
            {'sync_status': 'synced'},
            where: 'id = ?',
            whereArgs: [created.id],
          );
          // Cập nhật scene_characters
          await db.update(
            'scene_characters',
            {'sync_status': 'synced'},
            where: 'scene_id = ?',
            whereArgs: [created.id],
          );
        }
      } catch (e) {
        debugPrint('SyncManager: Sync scene (create) id=$localId lỗi: $e');
      }
    }

    final pendingUpdates = await db.query(
      'scenes',
      where: 'sync_status = ?',
      whereArgs: ['pending_update'],
    );
    for (var row in pendingUpdates) {
      final sceneId = row['id'] as int;
      final scenesForAct = await _db.getScenesForAct(row['act_id'] as int);
      final scene = scenesForAct.firstWhere(
        (s) => s.id == sceneId,
        orElse: () => Scene(
          id: sceneId,
          actId: row['act_id'] as int,
          sceneNumber: row['scene_number'] as int,
          title: row['title'] as String,
        ),
      );
      final characterIds = scene.characters.map((c) => c.id!).toList();

      try {
        await _api.updateScene(
          scene,
          characterIds,
          previousCharacterIds: characterIds,
        );
        await db.update(
          'scenes',
          {'sync_status': 'synced'},
          where: 'id = ?',
          whereArgs: [sceneId],
        );
        await db.update(
          'scene_characters',
          {'sync_status': 'synced'},
          where: 'scene_id = ?',
          whereArgs: [sceneId],
        );
      } catch (e) {
        debugPrint('SyncManager: Sync scene (update) id=$sceneId lỗi: $e');
      }
    }

    final pendingDeletes = await db.query(
      'scenes',
      where: 'sync_status = ?',
      whereArgs: ['pending_delete'],
    );
    for (var row in pendingDeletes) {
      final id = row['id'] as int;
      try {
        await _api.deleteScene(id);
        await db.delete('scene_characters', where: 'scene_id = ?', whereArgs: [id]);
        await db.delete('scenes', where: 'id = ?', whereArgs: [id]);
      } catch (e) {
        debugPrint('SyncManager: Sync scene (delete) id=$id lỗi: $e');
      }
    }
  }
}
