class Act {
  final int? id;
  final int projectId;
  final String title;
  final int sequenceOrder;

  const Act({
    this.id,
    required this.projectId,
    required this.title,
    required this.sequenceOrder,
  });

  factory Act.fromMap(Map<String, dynamic> map) => Act(
        id: map['id'] as int?,
        projectId: map['project_id'] as int,
        title: map['title'] as String,
        sequenceOrder: map['sequence_order'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'project_id': projectId,
        'title': title,
        'sequence_order': sequenceOrder,
      };

  Act copyWith({
    int? id,
    int? projectId,
    String? title,
    int? sequenceOrder,
  }) =>
      Act(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        title: title ?? this.title,
        sequenceOrder: sequenceOrder ?? this.sequenceOrder,
      );
}
