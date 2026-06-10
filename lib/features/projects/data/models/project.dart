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

  factory Project.fromMap(Map<String, dynamic> map) => Project(
        id: map['id'] as int?,
        title: map['title'] as String,
        genre: map['genre'] as String?,
        description: map['description'] as String?,
        director: map['director'] as String?,
        startDate: map['start_date'] as String?,
        endDate: map['end_date'] as String?,
        posterUrl: map['poster_url'] as String?,
        progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
        status: map['status'] as String? ?? 'PLANNING',
        crewCount: map['crew_count'] as int? ?? 0,
        createdAt: map['created_at'] as String?,
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
