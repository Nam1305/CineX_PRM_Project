enum RoleType { main, support, crowd }

extension RoleTypeExt on RoleType {
  String get dbValue => name.toUpperCase();

  String get label {
    switch (this) {
      case RoleType.main:
        return 'Chính';
      case RoleType.support:
        return 'Phụ';
      case RoleType.crowd:
        return 'Quần chúng';
    }
  }

  static RoleType fromDb(String value) {
    switch (value.toUpperCase()) {
      case 'SUPPORT':
        return RoleType.support;
      case 'CROWD':
        return RoleType.crowd;
      default:
        return RoleType.main;
    }
  }
}

enum LocationSetting { interior, exterior }

extension LocationSettingExt on LocationSetting {
  String get dbValue => this == LocationSetting.interior ? 'INT' : 'EXT';
  String get label => this == LocationSetting.interior ? 'INT' : 'EXT';
  String get fullLabel =>
      this == LocationSetting.interior ? 'Trong nhà' : 'Ngoài trời';

  static LocationSetting fromDb(String value) =>
      value == 'EXT' ? LocationSetting.exterior : LocationSetting.interior;
}

// Named SceneTime to avoid collision with Flutter's TimeOfDay
enum SceneTime { day, night }

extension SceneTimeExt on SceneTime {
  String get dbValue => this == SceneTime.day ? 'DAY' : 'NIGHT';
  String get label => this == SceneTime.day ? 'NGÀY' : 'ĐÊM';
  String get fullLabel => this == SceneTime.day ? 'Ban ngày' : 'Ban đêm';

  static SceneTime fromDb(String value) =>
      value == 'NIGHT' ? SceneTime.night : SceneTime.day;
}

enum SceneStatus { todo, inProgress, done }

extension SceneStatusExt on SceneStatus {
  String get dbValue {
    switch (this) {
      case SceneStatus.todo:
        return 'TODO';
      case SceneStatus.inProgress:
        return 'IN_PROGRESS';
      case SceneStatus.done:
        return 'DONE';
    }
  }

  String get label {
    switch (this) {
      case SceneStatus.todo:
        return 'Mới tạo';
      case SceneStatus.inProgress:
        return 'Đang viết';
      case SceneStatus.done:
        return 'Đã xong';
    }
  }

  static SceneStatus fromDb(String value) {
    switch (value) {
      case 'IN_PROGRESS':
        return SceneStatus.inProgress;
      case 'DONE':
        return SceneStatus.done;
      default:
        return SceneStatus.todo;
    }
  }
}
