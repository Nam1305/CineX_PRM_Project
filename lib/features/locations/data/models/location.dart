import 'package:cinex_application/core/utils/enums.dart';

class Location {
  final int? id;
  final int projectId;
  final String name;
  final LocationSetting setting;
  final SceneTime timeOfDay;
  final String? notes;

  const Location({
    this.id,
    required this.projectId,
    required this.name,
    this.setting = LocationSetting.interior,
    this.timeOfDay = SceneTime.day,
    this.notes,
  });

  factory Location.fromMap(Map<String, dynamic> map) => Location(
        id: map['id'] as int?,
        projectId: map['project_id'] as int,
        name: map['name'] as String,
        setting: LocationSettingExt.fromDb(map['setting'] as String? ?? 'INT'),
        timeOfDay: SceneTimeExt.fromDb(map['time_of_day'] as String? ?? 'DAY'),
        notes: map['notes'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'project_id': projectId,
        'name': name,
        'setting': setting.dbValue,
        'time_of_day': timeOfDay.dbValue,
        'notes': notes,
      };

  Location copyWith({
    int? id,
    int? projectId,
    String? name,
    LocationSetting? setting,
    SceneTime? timeOfDay,
    String? notes,
  }) =>
      Location(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        name: name ?? this.name,
        setting: setting ?? this.setting,
        timeOfDay: timeOfDay ?? this.timeOfDay,
        notes: notes ?? this.notes,
      );

  /// Formatted label e.g. "INT. QUÁN CÀ PHÊ - NGÀY"
  String get sceneLabel =>
      '${setting.label}. $name - ${timeOfDay.label}';
}
