import 'package:cinex_application/core/utils/enums.dart';

class Location {
  final int? id;
  final int? projectId;
  final String name;
  final LocationSetting setting;
  final SceneTime timeOfDay;
  final String? address;
  final String? notes;

  const Location({
    this.id,
    this.projectId,
    required this.name,
    this.setting = LocationSetting.interior,
    this.timeOfDay = SceneTime.day,
    this.address,
    this.notes,
  });

  /// Parse từ JSON OData server (PascalCase)
  factory Location.fromMap(Map<String, dynamic> map) => Location(
        id: map['Id'] as int? ?? map['id'] as int?,
        projectId: map['ProjectId'] as int? ?? map['project_id'] as int?,
        name: (map['Name'] ?? map['name'] ?? '') as String,
        setting: LocationSettingExt.fromDb(
          map['Setting'] as String? ?? map['setting'] as String? ?? 'INT',
        ),
        timeOfDay: SceneTimeExt.fromDb(
          map['Time'] as String? ?? map['time_of_day'] as String? ?? 'DAY',
        ),
        address: map['Address'] as String? ?? map['address'] as String?,
        notes: map['Notes'] as String? ?? map['notes'] as String?,
      );

  /// Body gửi lên server khi tạo/cập nhật (OData PascalCase field names)
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (projectId != null) 'projectId': projectId,
        'name': name,
        'setting': setting.dbValue,
        'time': timeOfDay.dbValue,
        'address': address,
        'notes': notes,
      };

  Location copyWith({
    int? id,
    int? projectId,
    String? name,
    LocationSetting? setting,
    SceneTime? timeOfDay,
    String? address,
    String? notes,
  }) =>
      Location(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        name: name ?? this.name,
        setting: setting ?? this.setting,
        timeOfDay: timeOfDay ?? this.timeOfDay,
        address: address ?? this.address,
        notes: notes ?? this.notes,
      );

  /// Formatted label e.g. "INT. QUÁN CÀ PHÊ - NGÀY"
  String get sceneLabel => '${setting.label}. $name - ${timeOfDay.label}';
}
