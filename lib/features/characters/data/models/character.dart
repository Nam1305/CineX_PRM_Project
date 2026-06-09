import 'package:cinex_application/core/utils/enums.dart';

class Character {
  final int? id;
  final int projectId;
  final String name;
  final RoleType roleType;
  final String? description;
  final String? imagePath;

  const Character({
    this.id,
    required this.projectId,
    required this.name,
    this.roleType = RoleType.main,
    this.description,
    this.imagePath,
  });

  factory Character.fromMap(Map<String, dynamic> map) => Character(
        id: map['id'] as int?,
        projectId: map['project_id'] as int,
        name: map['name'] as String,
        roleType: RoleTypeExt.fromDb(map['role_type'] as String? ?? 'MAIN'),
        description: map['description'] as String?,
        imagePath: map['image_path'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'project_id': projectId,
        'name': name,
        'role_type': roleType.dbValue,
        'description': description,
        'image_path': imagePath,
      };

  Character copyWith({
    int? id,
    int? projectId,
    String? name,
    RoleType? roleType,
    String? description,
    String? imagePath,
  }) =>
      Character(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        name: name ?? this.name,
        roleType: roleType ?? this.roleType,
        description: description ?? this.description,
        imagePath: imagePath ?? this.imagePath,
      );
}
