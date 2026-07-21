import 'package:sqflite_common/sqlite_api.dart';

DatabaseFactory createPlatformDatabaseFactory() =>
    throw UnsupportedError('SQLite is not supported on this platform.');
