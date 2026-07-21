class Act {
  final int? id;
  final int projectId;
  final String title;
  final int sequenceOrder;
  final String? summary;
  /// WAITING / IN_PROGRESS / DONE
  final String status;

  const Act({
    this.id,
    required this.projectId,
    required this.title,
    required this.sequenceOrder,
    this.summary,
    this.status = 'WAITING',
  });

  /// Parse từ JSON OData server (PascalCase) hoặc local map (snake_case)
  factory Act.fromMap(Map<String, dynamic> map) => Act(
        id: map['Id'] as int? ?? map['id'] as int?,
        projectId: map['ProjectId'] as int? ?? map['project_id'] as int? ?? 0,
        title: (map['Title'] ?? map['title'] ?? '') as String,
        sequenceOrder: map['SequenceOrder'] as int? ?? map['sequence_order'] as int? ?? 0,
        summary: map['Summary'] as String? ?? map['summary'] as String?,
        status: map['Status'] as String? ?? map['status'] as String? ?? 'WAITING',
      );

  /// Body gửi lên server khi tạo/cập nhật
  Map<String, dynamic> toMap() => {
        'projectId': projectId,
        'title': title,
        'sequenceOrder': sequenceOrder,
        'summary': summary,
        'status': status,
      };

  Act copyWith({
    int? id,
    int? projectId,
    String? title,
    int? sequenceOrder,
    String? summary,
    String? status,
  }) =>
      Act(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        title: title ?? this.title,
        sequenceOrder: sequenceOrder ?? this.sequenceOrder,
        summary: summary ?? this.summary,
        status: status ?? this.status,
      );
}
