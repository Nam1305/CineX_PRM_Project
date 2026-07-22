class ProductionPlan {
  final int projectId;
  final Map<int, String> locationDates;
  final Map<int, String> sceneStatuses;
  final int version;
  final DateTime? updatedAt;

  const ProductionPlan({
    required this.projectId,
    this.locationDates = const {},
    this.sceneStatuses = const {},
    this.version = 0,
    this.updatedAt,
  });

  factory ProductionPlan.empty(int projectId) =>
      ProductionPlan(projectId: projectId);

  factory ProductionPlan.fromMap(Map<String, dynamic> map) {
    final rawDates = map['locationDates'] ?? map['LocationDates'];
    final rawStatuses = map['sceneStatuses'] ?? map['SceneStatuses'];
    return ProductionPlan(
      projectId: _asInt(map['projectId'] ?? map['ProjectId']) ?? 0,
      locationDates: _stringMap(rawDates),
      sceneStatuses: _stringMap(rawStatuses),
      version: _asInt(map['version'] ?? map['Version']) ?? 0,
      updatedAt: DateTime.tryParse(
        (map['updatedAt'] ?? map['UpdatedAt'] ?? '').toString(),
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'projectId': projectId,
    'locationDates': locationDates.map(
      (key, value) => MapEntry(key.toString(), value),
    ),
    'sceneStatuses': sceneStatuses.map(
      (key, value) => MapEntry(key.toString(), value),
    ),
    'version': version,
    'updatedAt': updatedAt?.toUtc().toIso8601String(),
  };

  Map<String, dynamic> toUpdateMap() => {
    'locationDates': locationDates.map(
      (key, value) => MapEntry(key.toString(), value),
    ),
    'sceneStatuses': sceneStatuses.map(
      (key, value) => MapEntry(key.toString(), value),
    ),
    'version': version,
  };

  ProductionPlan copyWith({
    Map<int, String>? locationDates,
    Map<int, String>? sceneStatuses,
    int? version,
    DateTime? updatedAt,
  }) => ProductionPlan(
    projectId: projectId,
    locationDates: locationDates ?? this.locationDates,
    sceneStatuses: sceneStatuses ?? this.sceneStatuses,
    version: version ?? this.version,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  static Map<int, String> _stringMap(Object? value) {
    if (value is! Map) return {};
    final result = <int, String>{};
    for (final entry in value.entries) {
      final key = int.tryParse(entry.key.toString());
      final item = entry.value?.toString();
      if (key != null && item != null) result[key] = item;
    }
    return result;
  }

  static int? _asInt(Object? value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');
}
