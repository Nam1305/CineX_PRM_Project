enum NotificationActionType { create, update, delete, statusChange }

class NotificationModel {
  final int? id;
  final int? projectId;
  final String projectTitle;
  final int? actId;
  final int? sceneId;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;
  final NotificationActionType actionType;

  NotificationModel({
    this.id,
    this.projectId,
    required this.projectTitle,
    this.actId,
    this.sceneId,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.actionType = NotificationActionType.update,
  });

  NotificationModel copyWith({
    int? id,
    int? projectId,
    String? projectTitle,
    int? actId,
    int? sceneId,
    String? title,
    String? body,
    DateTime? timestamp,
    bool? isRead,
    NotificationActionType? actionType,
  }) =>
      NotificationModel(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        projectTitle: projectTitle ?? this.projectTitle,
        actId: actId ?? this.actId,
        sceneId: sceneId ?? this.sceneId,
        title: title ?? this.title,
        body: body ?? this.body,
        timestamp: timestamp ?? this.timestamp,
        isRead: isRead ?? this.isRead,
        actionType: actionType ?? this.actionType,
      );

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    NotificationActionType actionType = NotificationActionType.update;
    final actTypeStr = (map['ActionType'] ?? map['action_type'] ?? '').toString().toUpperCase();
    if (actTypeStr == 'CREATE') {
      actionType = NotificationActionType.create;
    } else if (actTypeStr == 'DELETE') {
      actionType = NotificationActionType.delete;
    } else if (actTypeStr == 'STATUS_CHANGE') {
      actionType = NotificationActionType.statusChange;
    }

    return NotificationModel(
      id: map['Id'] as int? ?? map['id'] as int?,
      projectId: map['ProjectId'] as int? ?? map['project_id'] as int?,
      projectTitle: (map['ProjectTitle'] ?? map['project_title'] ?? '') as String,
      actId: map['ActId'] as int? ?? map['act_id'] as int?,
      sceneId: map['SceneId'] as int? ?? map['scene_id'] as int?,
      title: (map['Title'] ?? map['title'] ?? '') as String,
      body: (map['Body'] ?? map['body'] ?? '') as String,
      timestamp: map['Timestamp'] != null
          ? DateTime.parse(map['Timestamp'] as String).toLocal()
          : (map['timestamp'] != null ? DateTime.parse(map['timestamp'] as String).toLocal() : DateTime.now()),
      isRead: (map['IsRead'] ?? map['is_read'] ?? false) as bool,
      actionType: actionType,
    );
  }

  Map<String, dynamic> toMap() {
    String actionTypeStr = 'UPDATE';
    switch (actionType) {
      case NotificationActionType.create:
        actionTypeStr = 'CREATE';
        break;
      case NotificationActionType.delete:
        actionTypeStr = 'DELETE';
        break;
      case NotificationActionType.statusChange:
        actionTypeStr = 'STATUS_CHANGE';
        break;
      case NotificationActionType.update:
        actionTypeStr = 'UPDATE';
        break;
    }

    return {
      if (id != null) 'Id': id,
      'ProjectId': projectId,
      'ProjectTitle': projectTitle,
      'ActId': actId,
      'SceneId': sceneId,
      'Title': title,
      'Body': body,
      'Timestamp': timestamp.toUtc().toIso8601String(),
      'IsRead': isRead,
      'ActionType': actionTypeStr,
    };
  }
}
