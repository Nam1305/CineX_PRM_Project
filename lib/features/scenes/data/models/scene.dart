import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';

class Scene {
  final int? id;
  final int actId;
  final int? locationId;
  final int sceneNumber;
  final String? summary;
  final SceneStatus status;

  // Enriched at runtime by SceneRepository — not stored in scenes table
  final Location? location;
  final List<Character> characters;

  const Scene({
    this.id,
    required this.actId,
    this.locationId,
    required this.sceneNumber,
    this.summary,
    this.status = SceneStatus.todo,
    this.location,
    this.characters = const [],
  });

  factory Scene.fromMap(Map<String, dynamic> map) => Scene(
        id: map['id'] as int?,
        actId: map['act_id'] as int,
        locationId: map['location_id'] as int?,
        sceneNumber: map['scene_number'] as int,
        summary: map['summary'] as String?,
        status: SceneStatusExt.fromDb(map['status'] as String? ?? 'TODO'),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'act_id': actId,
        'location_id': locationId,
        'scene_number': sceneNumber,
        'summary': summary,
        'status': status.dbValue,
      };

  Scene copyWith({
    int? id,
    int? actId,
    int? locationId,
    int? sceneNumber,
    String? summary,
    SceneStatus? status,
    Location? location,
    List<Character>? characters,
  }) =>
      Scene(
        id: id ?? this.id,
        actId: actId ?? this.actId,
        locationId: locationId ?? this.locationId,
        sceneNumber: sceneNumber ?? this.sceneNumber,
        summary: summary ?? this.summary,
        status: status ?? this.status,
        location: location ?? this.location,
        characters: characters ?? this.characters,
      );
}
