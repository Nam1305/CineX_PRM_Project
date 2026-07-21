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
  final LocationSetting setting;
  final SceneTime timeOfDay;

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
    this.setting = LocationSetting.interior,
    this.timeOfDay = SceneTime.day,
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
    LocationSetting? setting,
    SceneTime? timeOfDay,
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
        setting: setting ?? this.setting,
        timeOfDay: timeOfDay ?? this.timeOfDay,
        location: location ?? this.location,
        characters: characters ?? this.characters,
      );

  String get displaySceneLabel {
    final effSetting = location?.setting ?? setting;
    final effTime = location?.timeOfDay ?? timeOfDay;
    return '${effSetting.label}. ${location?.name ?? title} - ${effTime.label}';
  }

  String get fullFormattedTitle {
    final effSetting = (location?.setting ?? setting).label.toUpperCase();
    final locName = (location?.name ?? title).toUpperCase();
    final effTime = (location?.timeOfDay ?? timeOfDay).label.toUpperCase();
    return 'CẢNH $sceneNumber: $effSetting. $locName - $effTime';
  }
}

