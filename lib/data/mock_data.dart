import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';
import 'package:cinex_application/core/utils/enums.dart';

class MockData {
  // Character data
  static final List<Character> characters = [
    Character(
      id: 1,
      projectId: 1,
      name: 'Lâm',
      roleType: RoleType.main,
      description: 'Thám tử Nam, cứng rắn và tận tâm với công việc',
      imagePath: null,
    ),
    Character(
      id: 2,
      projectId: 1,
      name: 'Linh',
      roleType: RoleType.main,
      description: 'Nữ luật sư tài ba, quyết đoán',
      imagePath: null,
    ),
    Character(
      id: 3,
      projectId: 1,
      name: 'Minh',
      roleType: RoleType.support,
      description: 'Đồng sự của Lâm',
      imagePath: null,
    ),
  ];

  static Map<int, int> characterSceneCount = {
    1: 12,
    2: 8,
    3: 5,
  };

  static Map<int, String> characterStatus = {
    1: 'Đã duyệt',
    2: 'Đã duyệt',
    3: 'Chờ quay',
  };

  static Map<int, bool> characterStatusGreen = {
    1: true,
    2: true,
    3: false,
  };

  // Project data
  static final List<Project> projects = [
    Project(
      id: 1,
      title: 'Ánh Sáng Thành Phố',
      genre: 'Tâm lý - Tội phạm',
      description: 'Câu chuyện về một thám tử tìm kiếm sự thật giữa những bóng tối của thành phố.',
      director: 'Nguyễn A',
      startDate: '2024-01-15',
      endDate: '2024-06-30',
      posterUrl: 'https://via.placeholder.com/300x450/FF4D00/FFFFFF?text=Project+1',
      progress: 0.65,
      status: 'SHOOTING',
      crewCount: 45,
    ),
    Project(
      id: 2,
      title: 'Mưa Hè',
      genre: 'Drama',
      description: 'Một bộ phim về tình bạn, tình yêu và những lựa chọn cuộc đời.',
      director: 'Trần B',
      startDate: '2024-03-01',
      endDate: '2024-08-15',
      posterUrl: 'https://via.placeholder.com/300x450/4C6EF5/FFFFFF?text=Project+2',
      progress: 0.40,
      status: 'SHOOTING',
      crewCount: 38,
    ),
    Project(
      id: 3,
      title: 'Quái Vật Đêm',
      genre: 'Kinh dị',
      description: 'Một bộ phim kinh dị về những bí mật ẩn giấu trong ngôi nhà cũ.',
      director: 'Lê C',
      startDate: '2024-02-01',
      endDate: '2024-07-20',
      posterUrl: 'https://via.placeholder.com/300x450/51CF66/FFFFFF?text=Project+3',
      progress: 0.85,
      status: 'POST_PRODUCTION',
      crewCount: 32,
    ),
  ];

  // Location data
  static final List<Location> locations = [
    Location(
      id: 1,
      projectId: 1,
      name: 'Nhà Hát Lớn',
      setting: LocationSetting.interior,
      timeOfDay: SceneTime.night,
      notes: 'Cần đèn chiếu sáng chuyên nghiệp, có âm thanh surround',
    ),
    Location(
      id: 2,
      projectId: 1,
      name: 'Phố Cũ Hàng Nón',
      setting: LocationSetting.exterior,
      timeOfDay: SceneTime.day,
      notes: 'Quay vào buổi sáng, tránh đám đông',
    ),
    Location(
      id: 3,
      projectId: 1,
      name: 'Nhà Máy Khai Thác',
      setting: LocationSetting.interior,
      timeOfDay: SceneTime.night,
      notes: 'Cấu trúc bê tông bị phá hủy, yêu cầu an toàn cao',
    ),
    Location(
      id: 4,
      projectId: 2,
      name: 'Quán Cà Phê Vỉa Hè',
      setting: LocationSetting.exterior,
      timeOfDay: SceneTime.day,
      notes: 'Bàn ghế gỗ cũ, không quá sáng',
    ),
  ];
}
