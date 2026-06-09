import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'db_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DbConstants.dbName);
    return openDatabase(
      path,
      version: DbConstants.dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  // Must enable FK support per connection — sqflite does NOT enable it by default
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE ${DbConstants.tableProjects} (
        ${DbConstants.colId}          INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colTitle}       TEXT    NOT NULL,
        ${DbConstants.colGenre}       TEXT,
        ${DbConstants.colDescription} TEXT,
        ${DbConstants.colCreatedAt}   TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbConstants.tableActs} (
        ${DbConstants.colId}            INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colProjectId}     INTEGER NOT NULL,
        ${DbConstants.colTitle}         TEXT    NOT NULL,
        ${DbConstants.colSequenceOrder} INTEGER NOT NULL,
        FOREIGN KEY (${DbConstants.colProjectId})
          REFERENCES ${DbConstants.tableProjects}(${DbConstants.colId})
          ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbConstants.tableCharacters} (
        ${DbConstants.colId}          INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colProjectId}   INTEGER NOT NULL,
        ${DbConstants.colName}        TEXT    NOT NULL,
        ${DbConstants.colRoleType}    TEXT    NOT NULL DEFAULT 'MAIN',
        ${DbConstants.colDescription} TEXT,
        ${DbConstants.colImagePath}   TEXT,
        FOREIGN KEY (${DbConstants.colProjectId})
          REFERENCES ${DbConstants.tableProjects}(${DbConstants.colId})
          ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbConstants.tableLocations} (
        ${DbConstants.colId}          INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colProjectId}   INTEGER NOT NULL,
        ${DbConstants.colName}        TEXT    NOT NULL,
        ${DbConstants.colSetting}     TEXT    NOT NULL DEFAULT 'INT',
        ${DbConstants.colTimeOfDay}   TEXT    NOT NULL DEFAULT 'DAY',
        ${DbConstants.colNotes}       TEXT,
        FOREIGN KEY (${DbConstants.colProjectId})
          REFERENCES ${DbConstants.tableProjects}(${DbConstants.colId})
          ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbConstants.tableScenes} (
        ${DbConstants.colId}          INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colActId}       INTEGER NOT NULL,
        ${DbConstants.colLocationId}  INTEGER,
        ${DbConstants.colSceneNumber} INTEGER NOT NULL,
        ${DbConstants.colSummary}     TEXT,
        ${DbConstants.colStatus}      TEXT    NOT NULL DEFAULT 'TODO',
        FOREIGN KEY (${DbConstants.colActId})
          REFERENCES ${DbConstants.tableActs}(${DbConstants.colId})
          ON DELETE CASCADE,
        FOREIGN KEY (${DbConstants.colLocationId})
          REFERENCES ${DbConstants.tableLocations}(${DbConstants.colId})
          ON DELETE SET NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbConstants.tableSceneCharacters} (
        ${DbConstants.colSceneId}     INTEGER NOT NULL,
        ${DbConstants.colCharacterId} INTEGER NOT NULL,
        PRIMARY KEY (${DbConstants.colSceneId}, ${DbConstants.colCharacterId}),
        FOREIGN KEY (${DbConstants.colSceneId})
          REFERENCES ${DbConstants.tableScenes}(${DbConstants.colId})
          ON DELETE CASCADE,
        FOREIGN KEY (${DbConstants.colCharacterId})
          REFERENCES ${DbConstants.tableCharacters}(${DbConstants.colId})
          ON DELETE CASCADE
      )
    ''');

    await batch.commit(noResult: true);
  }

  /// Wipes and recreates the DB — for development/testing only
  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DbConstants.dbName);
    await deleteDatabase(path);
    _database = null;
    await database;
  }
}
