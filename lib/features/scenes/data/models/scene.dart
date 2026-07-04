import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';

class Scene {
  final int? id;
  final int actId;
  final int? locationId;
  final int sceneNumber;
  final String title;
  final String? summary;
  final SceneStatus status;

  // Enriched at runtime — not sent back to the server directly
  final Location? location;
  final List<Character> characters;

  const Scene({
    this.id,
    required this.actId,
    this.locationId,
    required this.sceneNumber,
    required this.title,
    this.summary,
    this.status = SceneStatus.todo,
    this.location,
    this.characters = const [],
  });

  Scene copyWith({
    int? id,
    int? actId,
    int? locationId,
    int? sceneNumber,
    String? title,
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
        title: title ?? this.title,
        summary: summary ?? this.summary,
        status: status ?? this.status,
        location: location ?? this.location,
        characters: characters ?? this.characters,
      );
}
