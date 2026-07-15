import 'package:cinex_application/core/utils/enums.dart';

class Character {
  final int? id;
  final int? projectId;
  final String name;
  final RoleType roleType;
  final String? actorName;
  final String? description;
  final String? imagePath;
  final String? castingStatus;

  const Character({
    this.id,
    this.projectId,
    required this.name,
    this.roleType = RoleType.main,
    this.actorName,
    this.description,
    this.imagePath,
    this.castingStatus,
  });

  /// Parse từ JSON OData server (PascalCase)
  factory Character.fromMap(Map<String, dynamic> map) => Character(
        id: map['Id'] as int? ?? map['id'] as int?,
        projectId: map['ProjectId'] as int? ?? map['projectId'] as int?,
        name: (map['Name'] ?? map['name'] ?? '') as String,
        roleType: RoleTypeExt.fromDb(
          map['Role'] as String? ?? map['role_type'] as String? ?? 'MAIN',
        ),
        actorName: map['ActorName'] as String? ?? map['actor_name'] as String?,
        description: map['Description'] as String? ?? map['description'] as String?,
        imagePath: map['ImageUrl'] as String? ?? map['image_path'] as String?,
        castingStatus: map['CastingStatus'] as String? ?? map['casting_status'] as String?,
      );

  /// Body gửi lên server khi tạo/cập nhật (OData PascalCase field names)
  Map<String, dynamic> toMap() => {
        'projectId': projectId,
        'name': name,
        'role': roleType.dbValue,
        'actorName': actorName,
        'description': description,
        'imageUrl': imagePath,
        'castingStatus': castingStatus,
      };

  Character copyWith({
    int? id,
    int? projectId,
    String? name,
    RoleType? roleType,
    String? actorName,
    String? description,
    String? imagePath,
    String? castingStatus,
  }) =>
      Character(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        name: name ?? this.name,
        roleType: roleType ?? this.roleType,
        actorName: actorName ?? this.actorName,
        description: description ?? this.description,
        imagePath: imagePath ?? this.imagePath,
        castingStatus: castingStatus ?? this.castingStatus,
      );
}
