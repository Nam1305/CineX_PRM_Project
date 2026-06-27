class Project {
  final int? id;
  final String title;
  final String? genre;
  final String? description;
  final String? director;
  final String? startDate;
  final String? endDate;
  final String? posterUrl;
  final double progress;
  final String status;
  final int crewCount;
  final String? createdAt;

  const Project({
    this.id,
    required this.title,
    this.genre,
    this.description,
    this.director,
    this.startDate,
    this.endDate,
    this.posterUrl,
    this.progress = 0.0,
    this.status = 'PLANNING',
    this.crewCount = 0,
    this.createdAt,
  });

  /// Parse từ JSON OData server (PascalCase) hoặc local map (snake_case)
  factory Project.fromMap(Map<String, dynamic> map) => Project(
        id: map['Id'] as int? ?? map['id'] as int?,
        title: (map['Title'] ?? map['title'] ?? '') as String,
        genre: map['Genre'] as String? ?? map['genre'] as String?,
        description: map['Description'] as String? ?? map['description'] as String?,
        director: map['Director'] as String? ?? map['director'] as String?,
        startDate: map['StartDate'] as String? ?? map['start_date'] as String?,
        endDate: map['EndDate'] as String? ?? map['end_date'] as String?,
        posterUrl: map['PosterUrl'] as String? ?? map['poster_url'] as String?,
        progress: (map['Progress'] as num? ?? map['progress'] as num?)?.toDouble() ?? 0.0,
        status: map['Status'] as String? ?? map['status'] as String? ?? 'PLANNING',
        crewCount: map['CrewCount'] as int? ?? map['crew_count'] as int? ?? 0,
        createdAt: map['CreatedAt'] as String? ?? map['created_at'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'genre': genre,
        'description': description,
        'director': director,
        'start_date': startDate,
        'end_date': endDate,
        'poster_url': posterUrl,
        'progress': progress,
        'status': status,
        'crew_count': crewCount,
        'created_at': createdAt,
      };

  Project copyWith({
    int? id,
    String? title,
    String? genre,
    String? description,
    String? director,
    String? startDate,
    String? endDate,
    String? posterUrl,
    double? progress,
    String? status,
    int? crewCount,
    String? createdAt,
  }) =>
      Project(
        id: id ?? this.id,
        title: title ?? this.title,
        genre: genre ?? this.genre,
        description: description ?? this.description,
        director: director ?? this.director,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        posterUrl: posterUrl ?? this.posterUrl,
        progress: progress ?? this.progress,
        status: status ?? this.status,
        crewCount: crewCount ?? this.crewCount,
        createdAt: createdAt ?? this.createdAt,
      );
}
