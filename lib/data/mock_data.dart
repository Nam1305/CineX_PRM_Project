import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/acts/data/models/act.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';
import 'package:cinex_application/features/notifications/data/models/notification_model.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';

class MockData {
  static final List<Project> mockProjects = [
    const Project(
      id: 1,
      title: 'Dem Dau Tien',
      genre: 'Tam ly / Gian diep',
      description: 'Mot cuu diep vien nhan nhiem vu cuoi cung trong thanh pho suong mu.',
      director: 'Tran Van Nam',
      startDate: '2026-08-01T00:00:00',
      endDate: '2026-11-15T00:00:00',
      posterUrl: 'https://images.unsplash.com/photo-1485846234645-a62644f84728?w=800',
      progress: 0.58,
      status: 'SHOOTING',
      crewCount: 45,
      createdAt: '2026-07-01T10:00:00Z',
    ),
    const Project(
      id: 2,
      title: 'Ranh Gioi Binh Yen',
      genre: 'Hanh dong / Drama',
      description: 'Luc luong cuu ho doi mat voi tran sat lo lon tren vung cao.',
      director: 'Le Minh',
      startDate: '2026-09-10T00:00:00',
      endDate: '2027-01-20T00:00:00',
      posterUrl: 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800',
      progress: 0.18,
      status: 'SHOOTING',
      crewCount: 36,
      createdAt: '2026-07-05T08:30:00Z',
    ),
    const Project(
      id: 3,
      title: 'Hao Quang Ruc Ro',
      genre: 'Am nhac / Lich su',
      description: 'Hanh trinh vinh quang va mat trai san khau cua mot ngoi sao thap nien 90.',
      director: 'Pham Hoang Anh',
      startDate: '2025-01-15T00:00:00',
      endDate: '2025-06-30T00:00:00',
      posterUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800',
      progress: 1,
      status: 'COMPLETED',
      crewCount: 65,
      createdAt: '2025-01-01T08:00:00Z',
    ),
    const Project(
      id: 4,
      title: 'Ky Uc Thoi Gian',
      genre: 'Vien tuong / Tinh cam',
      description: 'Mot nha vat ly tro ve nam 1995 de sua sai lam tuoi tre.',
      director: 'Nguyen Vu',
      startDate: '2026-02-01T00:00:00',
      endDate: '2026-08-30T00:00:00',
      posterUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800',
      progress: 0.82,
      status: 'POST_PRODUCTION',
      crewCount: 50,
      createdAt: '2026-01-15T09:00:00Z',
    ),
    const Project(
      id: 5,
      title: 'Bao Xanh',
      genre: 'Phieu luu / Tham hiem',
      description: 'Doan thuy thu tre ra khoi va doi mat voi con bao lon tren bien Dong.',
      director: 'Dang Tuan',
      startDate: '2026-11-01T00:00:00',
      endDate: '2027-03-15T00:00:00',
      posterUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
      progress: 0,
      status: 'PLANNING',
      crewCount: 28,
      createdAt: '2026-07-12T14:00:00Z',
    ),
    const Project(
      id: 6,
      title: 'Vet Sang Dem Thu',
      genre: 'Lang man / Tam ly',
      description: 'Mot hoa si Da Lat tim lai cam hung giua mua suong mu.',
      director: 'Vu Ha',
      startDate: '2026-05-10T00:00:00',
      endDate: '2026-09-30T00:00:00',
      posterUrl: 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=800',
      progress: 0.43,
      status: 'SHOOTING',
      crewCount: 38,
      createdAt: '2026-04-20T11:20:00Z',
    ),
    const Project(
      id: 7,
      title: 'Thanh Pho Khong Ngu',
      genre: 'Toi pham / Thriller',
      description: 'Doi dieu tra truy theo duong day tien ao trong dem Sai Gon.',
      director: 'Bui Quoc Huy',
      startDate: '2026-07-20T00:00:00',
      endDate: '2026-12-22T00:00:00',
      posterUrl: 'https://images.unsplash.com/photo-1519608487953-e999c86e7455?w=800',
      progress: 0.35,
      status: 'SHOOTING',
      crewCount: 52,
      createdAt: '2026-06-18T13:15:00Z',
    ),
    const Project(
      id: 8,
      title: 'Tram Cuoi Mua Dong',
      genre: 'Tinh cam / Chien tranh',
      description: 'Hai nguoi tre gap lai nhau tai mot ga tau cu sau nhieu nam xa cach.',
      director: 'Do Mai Anh',
      startDate: '2025-10-01T00:00:00',
      endDate: '2026-04-12T00:00:00',
      posterUrl: 'https://images.unsplash.com/photo-1488415032361-b7e238421f1b?w=800',
      progress: 0.78,
      status: 'POST_PRODUCTION',
      crewCount: 41,
      createdAt: '2025-09-12T09:45:00Z',
    ),
    const Project(
      id: 9,
      title: 'Duong Den Sao Hoa',
      genre: 'Khoa hoc vien tuong',
      description: 'Phi hanh doan Viet dau tien chuan bi chuyen bay mo phong len Sao Hoa.',
      director: 'Hoang Nhat',
      startDate: '2027-01-10T00:00:00',
      endDate: '2027-07-30T00:00:00',
      posterUrl: 'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?w=800',
      progress: 0,
      status: 'PLANNING',
      crewCount: 60,
      createdAt: '2026-07-15T16:10:00Z',
    ),
    const Project(
      id: 10,
      title: 'Nhung Ngay Khong Ten',
      genre: 'Gia dinh / Doi thuong',
      description: 'Mot gia dinh ba the he hoc cach tha thu trong nhung ngay cuoi nam.',
      director: 'Nguyen Khanh Linh',
      startDate: '2024-08-05T00:00:00',
      endDate: '2025-02-28T00:00:00',
      posterUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800',
      progress: 1,
      status: 'COMPLETED',
      crewCount: 24,
      createdAt: '2024-07-22T07:50:00Z',
    ),
  ];

  static final List<Act> mockActs = [
    const Act(id: 1, projectId: 1, sequenceOrder: 1, title: 'Hoi I - Tin Hieu', summary: 'Nam nhan thong diep ma hoa dau tien.', status: 'DONE'),
    const Act(id: 2, projectId: 1, sequenceOrder: 2, title: 'Hoi II - Dot Nhap', summary: 'Nhom dieu tra lan theo dau vet trong dem.', status: 'IN_PROGRESS'),
    const Act(id: 3, projectId: 1, sequenceOrder: 3, title: 'Hoi III - Lat Mat', summary: 'Ke chu muu lo dien tai can ho bi mat.', status: 'WAITING'),
    const Act(id: 4, projectId: 2, sequenceOrder: 1, title: 'Hoi I - Len Duong', summary: 'Doi cuu ho nhan tin bao khan cap.', status: 'IN_PROGRESS'),
    const Act(id: 5, projectId: 2, sequenceOrder: 2, title: 'Hoi II - Tam Bao', summary: 'Ca doi doi mat voi mua lu va sat lo.', status: 'WAITING'),
    const Act(id: 6, projectId: 2, sequenceOrder: 3, title: 'Hoi III - Binh Minh', summary: 'Nguoi bi nan duoc dua ve noi an toan.', status: 'WAITING'),
    const Act(id: 7, projectId: 3, sequenceOrder: 1, title: 'Hoi I - Ban Demo', summary: 'Bao Ngoc gap Dang Khoa tai phong thu.', status: 'DONE'),
    const Act(id: 8, projectId: 3, sequenceOrder: 2, title: 'Hoi II - Ap Luc', summary: 'Danh tieng keo theo xung dot nghe thuat.', status: 'DONE'),
    const Act(id: 9, projectId: 3, sequenceOrder: 3, title: 'Hoi III - Dem Nhac', summary: 'Concert lon khep lai hanh trinh ruc ro.', status: 'DONE'),
    const Act(id: 10, projectId: 4, sequenceOrder: 1, title: 'Hoi I - Co May', summary: 'Giao su Tri kich hoat thiet bi thoi gian.', status: 'DONE'),
    const Act(id: 11, projectId: 4, sequenceOrder: 2, title: 'Hoi II - Nam 1995', summary: 'Tri tim lai Linh giua pho cu.', status: 'DONE'),
    const Act(id: 12, projectId: 4, sequenceOrder: 3, title: 'Hoi III - Vong Lap', summary: 'Su that ve ky uc duoc giai ma.', status: 'IN_PROGRESS'),
    const Act(id: 13, projectId: 5, sequenceOrder: 1, title: 'Hoi I - Ra Khoi', summary: 'Thuyen truong Son tap hop thuy thu.', status: 'WAITING'),
    const Act(id: 14, projectId: 5, sequenceOrder: 2, title: 'Hoi II - Tam Bao Xanh', summary: 'Con tau di vao vung ap thap nguy hiem.', status: 'WAITING'),
    const Act(id: 15, projectId: 5, sequenceOrder: 3, title: 'Hoi III - Hai Dang', summary: 'Anh sang cuu ho xuat hien tren bien.', status: 'WAITING'),
    const Act(id: 16, projectId: 6, sequenceOrder: 1, title: 'Hoi I - Buc Tranh', summary: 'Hoang tim thay khung canh mua thu.', status: 'DONE'),
    const Act(id: 17, projectId: 6, sequenceOrder: 2, title: 'Hoi II - La Thu', summary: 'Mai gui lai nhung dieu chua tung noi.', status: 'IN_PROGRESS'),
    const Act(id: 18, projectId: 6, sequenceOrder: 3, title: 'Hoi III - Vet Sang', summary: 'Buc tranh cuoi cung duoc hoan thanh.', status: 'WAITING'),
    const Act(id: 19, projectId: 7, sequenceOrder: 1, title: 'Hoi I - Man Dem', summary: 'Doi dieu tra tiep can vu an tien ao.', status: 'DONE'),
    const Act(id: 20, projectId: 7, sequenceOrder: 2, title: 'Hoi II - Giao Dich', summary: 'Dau vet dan den mot club ngam.', status: 'IN_PROGRESS'),
    const Act(id: 21, projectId: 7, sequenceOrder: 3, title: 'Hoi III - Mat Na', summary: 'Noi bo doi dieu tra co ke phan boi.', status: 'IN_PROGRESS'),
    const Act(id: 22, projectId: 8, sequenceOrder: 1, title: 'Hoi I - Ga Tau', summary: 'Hai nguoi cu gap lai trong mua dong.', status: 'DONE'),
    const Act(id: 23, projectId: 8, sequenceOrder: 2, title: 'Hoi II - Buc Thu', summary: 'Qua khu chien tranh hien ve qua nhung la thu.', status: 'DONE'),
    const Act(id: 24, projectId: 8, sequenceOrder: 3, title: 'Hoi III - Chuyen Tau Cuoi', summary: 'Ho chon cach roi di hay o lai.', status: 'IN_PROGRESS'),
    const Act(id: 25, projectId: 9, sequenceOrder: 1, title: 'Hoi I - Mo Phong', summary: 'Phi hanh doan bat dau chuong trinh huan luyen.', status: 'WAITING'),
    const Act(id: 26, projectId: 9, sequenceOrder: 2, title: 'Hoi II - Su Co', summary: 'He thong mo phong mat on dinh.', status: 'WAITING'),
    const Act(id: 27, projectId: 9, sequenceOrder: 3, title: 'Hoi III - Quyet Dinh', summary: 'Lenh phong duoc can nhac trong 24 gio.', status: 'WAITING'),
    const Act(id: 28, projectId: 10, sequenceOrder: 1, title: 'Hoi I - Tro Ve', summary: 'Cac thanh vien gia dinh ve nha cuoi nam.', status: 'DONE'),
    const Act(id: 29, projectId: 10, sequenceOrder: 2, title: 'Hoi II - Khoang Cach', summary: 'Nhung xung dot cu duoc goi lai.', status: 'DONE'),
    const Act(id: 30, projectId: 10, sequenceOrder: 3, title: 'Hoi III - Bua Com', summary: 'Bua com tat nien noi lai gia dinh.', status: 'DONE'),
  ];

  static final List<Location> mockLocations = [
    const Location(id: 1, projectId: 1, name: 'Quan Cafe Co', setting: LocationSetting.interior, timeOfDay: SceneTime.day, notes: 'Khong gian hep, anh sang tu cua kinh lon.'),
    const Location(id: 2, projectId: 1, name: 'Ben Cang Dem', setting: LocationSetting.exterior, timeOfDay: SceneTime.night, notes: 'Can may tao suong va den xanh do phan quang.'),
    const Location(id: 3, projectId: 2, name: 'Tram Cuu Ho Vung Cao', setting: LocationSetting.interior, timeOfDay: SceneTime.day, notes: 'Tram go don so, nhieu ban do dia hinh.'),
    const Location(id: 4, projectId: 2, name: 'Rung Gia Mu Suong', setting: LocationSetting.exterior, timeOfDay: SceneTime.day, notes: 'Duong dat doc, can thiet bi bao ho.'),
    const Location(id: 5, projectId: 3, name: 'Phong Thu Bang Coi', setting: LocationSetting.interior, timeOfDay: SceneTime.day, notes: 'Phong thu co dien voi may ghi am analog.'),
    const Location(id: 6, projectId: 3, name: 'Nha Hat Lon', setting: LocationSetting.interior, timeOfDay: SceneTime.night, notes: 'San khau lon, anh den vang va hang ghe khan gia.'),
    const Location(id: 7, projectId: 4, name: 'Phong Thi Nghiem Co Kinh', setting: LocationSetting.interior, timeOfDay: SceneTime.night, notes: 'May gia toc trung tam va bang mach sang.'),
    const Location(id: 8, projectId: 4, name: 'Pho Cu Thap Nien 90', setting: LocationSetting.exterior, timeOfDay: SceneTime.day, notes: 'Bang hieu ve tay va xe dap co.'),
    const Location(id: 9, projectId: 5, name: 'Boong Tau Bien Dong', setting: LocationSetting.exterior, timeOfDay: SceneTime.day, notes: 'Gio manh, day neo va thung hang.'),
    const Location(id: 10, projectId: 5, name: 'Khoang May Tau', setting: LocationSetting.interior, timeOfDay: SceneTime.night, notes: 'Khong gian hep, can am thanh dong co.'),
    const Location(id: 11, projectId: 6, name: 'Xuong Ve Da Lat', setting: LocationSetting.interior, timeOfDay: SceneTime.day, notes: 'Nha go nhin ra thung lung may.'),
    const Location(id: 12, projectId: 6, name: 'Doi Thong Suong Mu', setting: LocationSetting.exterior, timeOfDay: SceneTime.day, notes: 'Duong mon day la kho va suong som.'),
    const Location(id: 13, projectId: 7, name: 'Van Phong An Ninh Mang', setting: LocationSetting.interior, timeOfDay: SceneTime.night, notes: 'Man hinh lon va den neon lanh.'),
    const Location(id: 14, projectId: 7, name: 'Hem Sai Gon Mua Dem', setting: LocationSetting.exterior, timeOfDay: SceneTime.night, notes: 'Mat duong uot, bien quang cao phan chieu.'),
    const Location(id: 15, projectId: 8, name: 'Ga Tau Cu', setting: LocationSetting.interior, timeOfDay: SceneTime.day, notes: 'San ga vang nguoi voi ghe go cu.'),
    const Location(id: 16, projectId: 8, name: 'Cau Sat Mua Dong', setting: LocationSetting.exterior, timeOfDay: SceneTime.night, notes: 'Can canh tuyet gia va den pha tau.'),
    const Location(id: 17, projectId: 9, name: 'Trung Tam Mo Phong Vu Tru', setting: LocationSetting.interior, timeOfDay: SceneTime.day, notes: 'Buong lai mo phong va man hinh chien thuat.'),
    const Location(id: 18, projectId: 9, name: 'Sa Mac Do Mo Phong', setting: LocationSetting.exterior, timeOfDay: SceneTime.day, notes: 'Cat do, khong gian rong cho rover.'),
    const Location(id: 19, projectId: 10, name: 'Can Nha Cuoi Nam', setting: LocationSetting.interior, timeOfDay: SceneTime.day, notes: 'Phong khach am ap va ban tho gia dinh.'),
    const Location(id: 20, projectId: 10, name: 'San Thuong Dem Giao Thua', setting: LocationSetting.exterior, timeOfDay: SceneTime.night, notes: 'Phap hoa xa va anh den thanh pho.'),
  ];

  static final List<Character> mockCharacters = [
    const Character(id: 1, projectId: 1, name: 'Vu Quoc Nam', roleType: RoleType.main, actorName: 'Nguyen Thai Hoa', description: 'Cuu diep vien tram lang va quyet doan.', imagePath: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400', castingStatus: 'APPROVED'),
    const Character(id: 2, projectId: 1, name: 'Le Mai Anh', roleType: RoleType.main, actorName: 'Tran Thu Ha', description: 'Nha bao dieu tra sac sao.', imagePath: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400', castingStatus: 'APPROVED'),
    const Character(id: 3, projectId: 1, name: 'Hoang Bach', roleType: RoleType.support, actorName: 'Pham Huy', description: 'Chuyen gia ma hoa ho tro tu xa.', imagePath: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400', castingStatus: 'PENDING'),
    const Character(id: 4, projectId: 2, name: 'Doi Truong Hung', roleType: RoleType.main, actorName: 'Dang Quan', description: 'Chi huy cuu ho day kinh nghiem.', imagePath: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400', castingStatus: 'APPROVED'),
    const Character(id: 5, projectId: 2, name: 'Bac Si Tuan', roleType: RoleType.support, actorName: 'Trinh Thang', description: 'Bac si tre theo doi cuu ho.', imagePath: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400', castingStatus: 'APPROVED'),
    const Character(id: 6, projectId: 2, name: 'Tinh Nguyen Vien Thao', roleType: RoleType.support, actorName: 'Le Thanh', description: 'Phu trach hau can va lien lac.', imagePath: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400', castingStatus: 'PENDING'),
    const Character(id: 7, projectId: 3, name: 'Bao Ngoc', roleType: RoleType.main, actorName: 'Minh Hang', description: 'Ngoi sao am nhac co giong hat noi bat.', imagePath: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400', castingStatus: 'APPROVED'),
    const Character(id: 8, projectId: 3, name: 'Dang Khoa', roleType: RoleType.main, actorName: 'Hua Vi Van', description: 'Nhac si dung sau cac ban hit.', imagePath: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400', castingStatus: 'APPROVED'),
    const Character(id: 9, projectId: 3, name: 'Quang Huy', roleType: RoleType.support, actorName: 'Quang Minh', description: 'Nha san xuat am nhac quyen luc.', imagePath: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=400', castingStatus: 'APPROVED'),
    const Character(id: 10, projectId: 4, name: 'Giao Su Tri', roleType: RoleType.main, actorName: 'Thanh Loc', description: 'Nha vat ly tao ra co may thoi gian.', imagePath: 'https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=400', castingStatus: 'APPROVED'),
    const Character(id: 11, projectId: 4, name: 'Linh 90s', roleType: RoleType.main, actorName: 'Ninh Duong Lan Ngoc', description: 'Co gai nam 1995 gan voi ky uc cua Tri.', imagePath: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400', castingStatus: 'APPROVED'),
    const Character(id: 12, projectId: 4, name: 'Tro Ly An', roleType: RoleType.support, actorName: 'Lam Bao Chau', description: 'Nguoi canh giu phong thi nghiem.', imagePath: 'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=400', castingStatus: 'PENDING'),
    const Character(id: 13, projectId: 5, name: 'Thuyen Truong Son', roleType: RoleType.main, actorName: 'Lien Binh Phat', description: 'Thuyen truong tre kien cuong.', imagePath: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400', castingStatus: 'PENDING'),
    const Character(id: 14, projectId: 5, name: 'May Truong Kiet', roleType: RoleType.support, actorName: 'Huynh Dong', description: 'Nguoi giu trai tim con tau.', imagePath: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400', castingStatus: 'PENDING'),
    const Character(id: 15, projectId: 5, name: 'Hoa Tieu Linh', roleType: RoleType.support, actorName: 'Kha Ngan', description: 'Hoa tieu tre co ban linh bien.', imagePath: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400', castingStatus: 'PENDING'),
    const Character(id: 16, projectId: 6, name: 'Hoa Si Hoang', roleType: RoleType.main, actorName: 'Quoc Truong', description: 'Hoa si tim lai cam hung sang tac.', imagePath: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400', castingStatus: 'APPROVED'),
    const Character(id: 17, projectId: 6, name: 'Mai', roleType: RoleType.main, actorName: 'Jun Vu', description: 'Nguoi giu nhung la thu chua gui.', imagePath: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400', castingStatus: 'APPROVED'),
    const Character(id: 18, projectId: 6, name: 'Chu Quan Tung', roleType: RoleType.support, actorName: 'Cong Ninh', description: 'Nguoi chung kien cau chuyen tinh cu.', imagePath: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=400', castingStatus: 'PENDING'),
    const Character(id: 19, projectId: 7, name: 'Thanh Tra Khoa', roleType: RoleType.main, actorName: 'Kieu Minh Tuan', description: 'Canh sat dieu tra toi pham cong nghe.', imagePath: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400', castingStatus: 'APPROVED'),
    const Character(id: 20, projectId: 7, name: 'Hacker Nhi', roleType: RoleType.main, actorName: 'Hoang Yen Chibi', description: 'Chuyen gia truy vet tien ao.', imagePath: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400', castingStatus: 'APPROVED'),
    const Character(id: 21, projectId: 7, name: 'Ong Trum Zero', roleType: RoleType.support, actorName: 'Thai Hoa', description: 'Ke dieu hanh duong day ngam.', imagePath: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400', castingStatus: 'PENDING'),
    const Character(id: 22, projectId: 8, name: 'An', roleType: RoleType.main, actorName: 'Avin Lu', description: 'Nguoi linh tre tro ve ga tau cu.', imagePath: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400', castingStatus: 'APPROVED'),
    const Character(id: 23, projectId: 8, name: 'Hoa', roleType: RoleType.main, actorName: 'Miu Le', description: 'Co gai giu buc thu cuoi cung.', imagePath: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400', castingStatus: 'APPROVED'),
    const Character(id: 24, projectId: 8, name: 'Ong Bao Ve Ga', roleType: RoleType.support, actorName: 'Huu Chau', description: 'Nguoi giu nhung cau chuyen cua ga tau.', imagePath: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=400', castingStatus: 'APPROVED'),
    const Character(id: 25, projectId: 9, name: 'Chi Huy Lan', roleType: RoleType.main, actorName: 'Ngo Thanh Van', description: 'Chi huy chuong trinh vu tru.', imagePath: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400', castingStatus: 'PENDING'),
    const Character(id: 26, projectId: 9, name: 'Ky Su Minh', roleType: RoleType.support, actorName: 'Song Luan', description: 'Ky su dieu khien rover mo phong.', imagePath: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400', castingStatus: 'PENDING'),
    const Character(id: 27, projectId: 10, name: 'Ba Hanh', roleType: RoleType.main, actorName: 'Le Khanh', description: 'Nguoi me giu nep nha cuoi nam.', imagePath: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400', castingStatus: 'APPROVED'),
    const Character(id: 28, projectId: 10, name: 'Minh', roleType: RoleType.support, actorName: 'Tran Nghia', description: 'Nguoi con tro ve sau nhieu nam xa cach.', imagePath: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400', castingStatus: 'APPROVED'),
  ];

  static final List<Scene> mockScenes = _buildScenes();

  static final List<NotificationModel> mockNotifications = [
    NotificationModel(id: 1, projectId: 1, projectTitle: 'Dem Dau Tien', actId: 2, sceneId: 4, title: 'Cap nhat canh quay', body: 'Canh truy duoi tren cang da chuyen sang dang viet.', timestamp: DateTime.utc(2026, 7, 21, 8), actionType: NotificationActionType.statusChange),
    NotificationModel(id: 2, projectId: 3, projectTitle: 'Hao Quang Ruc Ro', actId: 9, sceneId: 18, title: 'Du an hoan tat', body: 'Concert bung no da duoc danh dau hoan tat.', timestamp: DateTime.utc(2026, 7, 21, 8, 15), isRead: true, actionType: NotificationActionType.statusChange),
    NotificationModel(id: 3, projectId: 7, projectTitle: 'Thanh Pho Khong Ngu', actId: 20, sceneId: 39, title: 'Them phan canh', body: 'May chu bi khoa da duoc them vao storyboard.', timestamp: DateTime.utc(2026, 7, 21, 8, 30), actionType: NotificationActionType.create),
    NotificationModel(id: 4, projectId: 9, projectTitle: 'Duong Den Sao Hoa', actId: 25, sceneId: 49, title: 'Can chot lich quay', body: 'Buoi mo phong dau tien dang cho lich san xuat.', timestamp: DateTime.utc(2026, 7, 21, 8, 45)),
    NotificationModel(id: 5, projectTitle: 'Thong bao chung', title: 'Seed demo moi', body: 'Neon da duoc lam moi voi bo du lieu demo day du.', timestamp: DateTime.utc(2026, 7, 21, 9), actionType: NotificationActionType.create),
    NotificationModel(id: 6, projectId: 10, projectTitle: 'Nhung Ngay Khong Ten', actId: 30, sceneId: 60, title: 'Khoa du an', body: 'Du an da san sang de demo man hinh completed.', timestamp: DateTime.utc(2026, 7, 21, 9, 15), isRead: true),
  ];

  static const Set<int> _deletedActIds = {3};
  static const Set<int> _deletedSceneIds = {5, 6};

  static Map<int, int> get characterSceneCount {
    final counts = <int, int>{};
    for (final scene in mockScenes.where((scene) => !_deletedSceneIds.contains(scene.id))) {
      for (final character in scene.characters) {
        final id = character.id;
        if (id != null) counts[id] = (counts[id] ?? 0) + 1;
      }
    }
    return counts;
  }

  static Map<int, String> get characterStatus => {
        for (final character in mockCharacters)
          if (character.id != null) character.id!: character.castingStatus ?? 'PENDING',
      };

  static Map<int, bool> get characterStatusGreen => {
        for (final character in mockCharacters)
          if (character.id != null) character.id!: character.castingStatus == 'APPROVED',
      };

  static List<Project> projectsCopy() => List<Project>.from(mockProjects);

  static List<Act> actsForProject(int projectId) => List<Act>.from(
        mockActs.where((act) => act.projectId == projectId && !_deletedActIds.contains(act.id)),
      );

  static List<Act> deletedActsForProject(int projectId) => List<Act>.from(
        mockActs.where((act) => act.projectId == projectId && _deletedActIds.contains(act.id)),
      );

  static List<Location> locationsForProject(int projectId) => List<Location>.from(
        mockLocations.where((location) => location.projectId == projectId),
      );

  static List<Character> charactersForProject(int? projectId) => List<Character>.from(
        projectId == null
            ? mockCharacters
            : mockCharacters.where((character) => character.projectId == projectId),
      );

  static List<Scene> scenesForProject(int projectId) {
    final actIds = mockActs
        .where((act) => act.projectId == projectId)
        .map((act) => act.id)
        .whereType<int>()
        .toSet();
    return _copyScenes(
      mockScenes.where(
        (scene) => actIds.contains(scene.actId) && !_deletedSceneIds.contains(scene.id),
      ),
    );
  }

  static List<Scene> scenesForAct(int actId) => _copyScenes(
        mockScenes.where((scene) => scene.actId == actId && !_deletedSceneIds.contains(scene.id)),
      );

  static List<Scene> deletedScenesForProject(int projectId) {
    final actIds = mockActs
        .where((act) => act.projectId == projectId)
        .map((act) => act.id)
        .whereType<int>()
        .toSet();
    return _copyScenes(
      mockScenes.where(
        (scene) => actIds.contains(scene.actId) && _deletedSceneIds.contains(scene.id),
      ),
    );
  }

  static List<NotificationModel> notificationsCopy() => mockNotifications
      .map((notification) => notification.copyWith())
      .toList();

  static List<Scene> _copyScenes(Iterable<Scene> scenes) => scenes
      .map((scene) => scene.copyWith(characters: List<Character>.from(scene.characters)))
      .toList();

  static List<Scene> _buildScenes() {
    final scenes = <Scene>[];
    for (var projectId = 1; projectId <= 10; projectId++) {
      final specs = _sceneSpecs[projectId]!;
      final characterIds = _projectCharacterIds[projectId]!;
      final baseActId = (projectId - 1) * 3 + 1;
      final baseLocationId = (projectId - 1) * 2 + 1;

      for (var i = 0; i < specs.length; i++) {
        final spec = specs[i];
        final sceneOrder = i + 1;
        final sceneId = (projectId - 1) * 6 + sceneOrder;
        final location = _locationById(baseLocationId + (i % 2));
        final characters = <Character>[
          _characterById(characterIds[i % characterIds.length]),
          _characterById(characterIds[(i + 1) % characterIds.length]),
        ];
        if (characterIds.length > 2 && (sceneOrder == 1 || sceneOrder == 4)) {
          characters.add(_characterById(characterIds[2]));
        }

        scenes.add(
          Scene(
            id: sceneId,
            actId: baseActId + (i ~/ 2),
            locationId: location.id,
            sceneNumber: sceneOrder.toString(),
            title: spec.title,
            summary: spec.summary,
            status: spec.status,
            setting: location.setting,
            timeOfDay: location.timeOfDay,
            location: location,
            characters: characters,
          ),
        );
      }
    }
    return scenes;
  }

  static Location _locationById(int id) => mockLocations.firstWhere((location) => location.id == id);

  static Character _characterById(int id) => mockCharacters.firstWhere((character) => character.id == id);

  static const Map<int, List<int>> _projectCharacterIds = {
    1: [1, 2, 3],
    2: [4, 5, 6],
    3: [7, 8, 9],
    4: [10, 11, 12],
    5: [13, 14, 15],
    6: [16, 17, 18],
    7: [19, 20, 21],
    8: [22, 23, 24],
    9: [25, 26],
    10: [27, 28],
  };

  static final Map<int, List<_SceneSpec>> _sceneSpecs = {
    1: [
      _SceneSpec('Tin hieu luc nua dem', 'Nam nhan tap tin ma hoa tai quan cafe.', SceneStatus.done),
      _SceneSpec('Theo dau container', 'Mai Anh lan theo chiec container kha nghi.', SceneStatus.done),
      _SceneSpec('Giai ma du lieu', 'Bach phat hien khoa truy cap bi an.', SceneStatus.inProgress),
      _SceneSpec('Cuoc truy duoi tren cang', 'Nhom doi dau voi ke theo doi.', SceneStatus.inProgress),
      _SceneSpec('Loi khai bat ngo', 'Nhan chung tiet lo danh tinh ke chu muu.', SceneStatus.todo),
      _SceneSpec('Mat na trong dem', 'Nam doi mat voi nguoi quen cu.', SceneStatus.todo),
    ],
    2: [
      _SceneSpec('Lenh goi khan cap', 'Doi cuu ho chuan bi roi tram.', SceneStatus.done),
      _SceneSpec('Dau chan tren bun', 'Hung phat hien dau vet cua nguoi mat tich.', SceneStatus.inProgress),
      _SceneSpec('Phong phau thuat tam', 'Bac si Tuan xu ly ca chan thuong dau tien.', SceneStatus.todo),
      _SceneSpec('Vuot doc sat lo', 'Doan cuu ho vuot qua con doc nguy hiem.', SceneStatus.todo),
      _SceneSpec('Tin hieu tu ban lang', 'Thao bat duoc lien lac bi dut quang.', SceneStatus.todo),
      _SceneSpec('Binh minh sau mua', 'Nguoi dan duoc dua ra khoi vung nguy hiem.', SceneStatus.todo),
    ],
    3: [
      _SceneSpec('Ban demo dau tien', 'Bao Ngoc thu am ca khuc chu de.', SceneStatus.done),
      _SceneSpec('Buoi dien tap', 'Dang Khoa huong dan tong duyet tren san khau.', SceneStatus.done),
      _SceneSpec('Hop dong doc quyen', 'Quang Huy de nghi mot thoa thuan mao hiem.', SceneStatus.done),
      _SceneSpec('Anh den san khau', 'Bao Ngoc doi mat voi ap luc danh tieng.', SceneStatus.done),
      _SceneSpec('Dem mat ngu', 'Dang Khoa viet lai phan cao trao.', SceneStatus.done),
      _SceneSpec('Concert bung no', 'Dem dien khep lai hanh trinh ruc ro.', SceneStatus.done),
    ],
    4: [
      _SceneSpec('Kich hoat co may', 'Tri bat dau thu nghiem thoi gian.', SceneStatus.done),
      _SceneSpec('Cua hang bang dia', 'Tri dat chan den nam 1995.', SceneStatus.done),
      _SceneSpec('Nhat ky thoi gian', 'Du lieu tuong lai bat dau bien doi.', SceneStatus.done),
      _SceneSpec('Gap lai Linh', 'Tri gap Linh tren con pho cu.', SceneStatus.inProgress),
      _SceneSpec('Canh bao nghich ly', 'Tro ly An phat hien su co vong lap.', SceneStatus.inProgress),
      _SceneSpec('Chuyen xe cuoi ngay', 'Tri phai lua chon giua qua khu va hien tai.', SceneStatus.todo),
    ],
    5: [
      _SceneSpec('Kiem tra day neo', 'Son chuan bi cho chuyen ra khoi.', SceneStatus.todo),
      _SceneSpec('Dong co bat thuong', 'Kiet nghe thay am thanh la trong khoang may.', SceneStatus.todo),
      _SceneSpec('Song lon dau tien', 'Con tau bat dau rung lac manh.', SceneStatus.todo),
      _SceneSpec('Mat dien toan bo', 'Hoa tieu Linh chuyen sang dieu huong thu cong.', SceneStatus.todo),
      _SceneSpec('Tin hieu hai dang', 'Anh sang cuu ho xuat hien phia chan troi.', SceneStatus.todo),
      _SceneSpec('Giu trai tim tau', 'Kiet co gang khoi dong lai dong co.', SceneStatus.todo),
    ],
    6: [
      _SceneSpec('Net ve dau tien', 'Hoang bat dau buc tranh mua thu.', SceneStatus.done),
      _SceneSpec('Duong mon suong som', 'Mai dan Hoang den doi thong vang.', SceneStatus.done),
      _SceneSpec('La thu chua gui', 'Hoang tim thay la thu cu trong hop go.', SceneStatus.inProgress),
      _SceneSpec('Cuoc hen bi lo', 'Mai tranh ne loi noi that.', SceneStatus.todo),
      _SceneSpec('Mau sac cuoi cung', 'Buc tranh gan hoan thanh.', SceneStatus.todo),
      _SceneSpec('Vet sang dem thu', 'Hai nguoi gap lai duoi anh hoang hon.', SceneStatus.todo),
    ],
    7: [
      _SceneSpec('Ban do tien ao', 'Khoa tim ra dong tien bat thuong.', SceneStatus.done),
      _SceneSpec('Doi dau trong mua', 'Nhi theo dau vi dien tu trong hem toi.', SceneStatus.inProgress),
      _SceneSpec('May chu bi khoa', 'He thong an ninh bi tan cong.', SceneStatus.inProgress),
      _SceneSpec('Giao dich luc 2 gio', 'Zero sap xep cuoc giao dich ngam.', SceneStatus.todo),
      _SceneSpec('Noi gian', 'Khoa nghi ngo mot dong doi.', SceneStatus.todo),
      _SceneSpec('Mat na Zero', 'Ke chu muu lo dien giua man mua.', SceneStatus.todo),
    ],
    8: [
      _SceneSpec('Chuyen tau tre', 'An tro ve nha ga cu sau chien tranh.', SceneStatus.done),
      _SceneSpec('Cay cau dong bang', 'Hoa dung cho ben cau sat.', SceneStatus.done),
      _SceneSpec('Buc thu trong vali', 'Ong bao ve giao lai buc thu cu.', SceneStatus.done),
      _SceneSpec('Tieng coi tau dem', 'Qua khu hien ve trong tieng coi tau.', SceneStatus.done),
      _SceneSpec('Phong cho vang', 'An doc loi hua da bo lo.', SceneStatus.inProgress),
      _SceneSpec('Tram cuoi mua dong', 'Hoa quyet dinh len chuyen tau cuoi.', SceneStatus.todo),
    ],
    9: [
      _SceneSpec('Buoi mo phong dau tien', 'Lan trien khai giao an huan luyen.', SceneStatus.todo),
      _SceneSpec('Rover qua doi cat', 'Minh dieu khien rover vuot dia hinh do.', SceneStatus.todo),
      _SceneSpec('Canh bao oxy', 'Chi so oxy trong khoang lai tut nhanh.', SceneStatus.todo),
      _SceneSpec('Bao cat mo phong', 'Phi hanh doan mat lien lac voi trung tam.', SceneStatus.todo),
      _SceneSpec('Lenh phong thu nghiem', 'Lan phai bao cao hoi dong.', SceneStatus.todo),
      _SceneSpec('Binh minh Sao Hoa', 'Minh nhin thay thanh cong dau tien.', SceneStatus.todo),
    ],
    10: [
      _SceneSpec('Ngay tro ve', 'Minh ve nha sau nhieu nam xa cach.', SceneStatus.done),
      _SceneSpec('Thanh pho len den', 'Ba Hanh cho con tren san thuong.', SceneStatus.done),
      _SceneSpec('Chiec hop cu', 'Gia dinh tim lai nhung ky vat cu.', SceneStatus.done),
      _SceneSpec('Loi xin loi muon', 'Minh noi loi xin loi voi me.', SceneStatus.done),
      _SceneSpec('Bua com tat nien', 'Moi nguoi cung quay lai ban an.', SceneStatus.done),
      _SceneSpec('Phap hoa sau mai nha', 'Gia dinh don nam moi trong yen binh.', SceneStatus.done),
    ],
  };
}

class _SceneSpec {
  final String title;
  final String summary;
  final SceneStatus status;

  const _SceneSpec(this.title, this.summary, this.status);
}
