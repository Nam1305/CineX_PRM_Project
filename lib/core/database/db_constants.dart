class DbConstants {
  static const String dbName = 'cinex.db';
  static const int dbVersion = 1;

  // Table names
  static const String tableProjects = 'projects';
  static const String tableActs = 'acts';
  static const String tableCharacters = 'characters';
  static const String tableLocations = 'locations';
  static const String tableScenes = 'scenes';
  static const String tableSceneCharacters = 'scene_characters';

  // Common columns
  static const String colId = 'id';
  static const String colProjectId = 'project_id';

  // Projects
  static const String colTitle = 'title';
  static const String colGenre = 'genre';
  static const String colDescription = 'description';
  static const String colCreatedAt = 'created_at';

  // Acts
  static const String colSequenceOrder = 'sequence_order';

  // Characters
  static const String colName = 'name';
  static const String colRoleType = 'role_type';
  static const String colImagePath = 'image_path';

  // Locations
  static const String colSetting = 'setting';
  static const String colTimeOfDay = 'time_of_day';
  static const String colNotes = 'notes';

  // Scenes
  static const String colActId = 'act_id';
  static const String colLocationId = 'location_id';
  static const String colSceneNumber = 'scene_number';
  static const String colSummary = 'summary';
  static const String colStatus = 'status';

  // Scene_Characters
  static const String colSceneId = 'scene_id';
  static const String colCharacterId = 'character_id';
}
