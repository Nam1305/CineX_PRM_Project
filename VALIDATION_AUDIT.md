# Kiểm toán validation các trường thêm/sửa — CineX

Ngày rà soát: 2026-07-21  
Phạm vi chính: `FE/CineX_PRM_Project/lib`  
Đối chiếu backend: `BE/CineX_API` và yêu cầu trong `Requirement_CineX.md`.

## 1. Phạm vi và cách đọc kết quả

Đã quét các màn hình có thao tác tạo/cập nhật:

- Dự án: `project_form_screen.dart` (thêm + sửa) và `add_project_screen.dart` (màn hình cũ, chỉ thêm).
- Hồi: `act_form_screen.dart` (thêm + sửa).
- Phân cảnh: `scene_form_screen.dart` (thêm + sửa).
- Nhân vật: `character_form_screen.dart` (thêm + sửa).
- Bối cảnh: `location_form_screen.dart` (thêm + sửa) và `add_location_screen.dart` (màn hình cũ, chỉ thêm).
- Tài khoản: `register_screen.dart`, `login_screen.dart` (không phải entity kịch bản nhưng vẫn là dữ liệu được thêm/đăng nhập).

Trong bảng dưới đây:

- **Hiện có**: rule thực sự chạy ở client, kèm vị trí code.
- **Thiếu**: case thực tế hiện có thể lọt qua, hoặc chỉ được phát hiện sau khi gọi API.
- **P0**: có thể làm sai dữ liệu/liên kết hoặc lỗi ngay trong luồng nghiệp vụ; **P1**: cần bổ sung trước khi phát hành; **P2**: hardening/UX.

Validator dùng chung chỉ có `required`, `maxLength` và `positiveInt`; `maxLength` hiện không được dùng ở các form rà soát ([validators.dart](lib/core/utils/validators.dart)).

## 2. Ma trận trường của các màn hình hiện hành

### 2.1 Dự án — thêm/sửa (`ProjectFormScreen`)

Nguồn: [project_form_screen.dart:177-351](lib/features/projects/presentation/screens/project_form_screen.dart:177), rule ngày ở [408-429](lib/features/projects/presentation/screens/project_form_screen.dart:408).

| Trường | Hiện có | Đối chiếu case thực tế | Validation còn thiếu |
|---|---|---|---|
| Poster | Không bắt buộc; chọn ảnh bằng `image_picker`, `maxWidth=1200`, `imageQuality=80` | Người dùng chọn PDF/ảnh cực lớn/tỉ lệ khác 2:3; upload lỗi; URL cũ hỏng | **P1** kiểm tra MIME/đuôi, kích thước byte, tỉ lệ 2:3; báo lỗi upload thay vì âm thầm dùng placeholder; kiểm tra URL khi sửa |
| Tên dự án | Bắt buộc, trim qua `AppValidators.required` (208) | `"   "` bị chặn; tên 1 ký tự, rất dài, ký tự điều khiển vẫn qua | **P1** min/max length, chuẩn hóa Unicode/khoảng trắng, chặn control chars; **P1** kiểm tra trùng tên trong phạm vi tài khoản/hệ thống |
| Đạo diễn | Bắt buộc, trim (220) | Màn hình cũ cho phép bỏ trống; tên dài/emoji/ký tự số vẫn qua | **P1** thống nhất bắt buộc hay tùy chọn giữa hai màn hình; min/max và rule tên |
| Thể loại | Dropdown mặc định `Drama`; không có `validator` (233-237) | Giá trị lạ từ server được thêm vào option (đoạn chuẩn bị options), có thể lưu ngoài allow-list | **P1** allow-list ở client + backend; quyết định có cho `Other` hay không, không tự động tin giá trị lạ |
| Trạng thái | Dropdown mặc định `PLANNING`; không có validator (248-252) | Có thể sửa `COMPLETED` về `PLANNING` hoặc gửi status lạ; không kiểm tra chuyển trạng thái theo tiến độ | **P1** allow-list và state-transition matrix; chặn trạng thái lạ ở backend |
| Ngày bắt đầu | Bắt buộc trong `_save`; tạo mới không cho trước hôm nay; date picker giới hạn đến 2030 (84-103, 410-427) | Sửa dự án cũ có thể chọn ngày quá khứ; dự án kéo dài sau 2030 không chọn được; dữ liệu server `>2030` làm `initialDate` ngoài khoảng | **P0** dùng khoảng ngày nghiệp vụ động (không hard-code 2030); validate lại khi parse dữ liệu cũ; thống nhất timezone/ngày lịch |
| Ngày kết thúc | Bắt buộc; phải `>=` ngày bắt đầu; picker chỉ mở sau khi có ngày bắt đầu (106-120, 414-420) | Không cho ngày kết thúc sau 2030; không kiểm tra thời lượng tối đa; dữ liệu null từ server chỉ báo snackbar khi lưu | **P1** khoảng ngày động, rule duration nếu có; hiển thị lỗi ngay trên field thay vì chỉ snackbar |
| Số thành viên đoàn phim | `positiveInt`: bắt buộc và `>0` (337) | Giá trị mặc định khi tạo là `0`, nên form mở ra ở trạng thái không hợp lệ; `999999999` hoặc số vượt thực tế vẫn qua; backend mặc định cho phép 0 | **P1** thống nhất `0` có hợp lệ hay không; min/max nghiệp vụ; giới hạn độ dài số và xử lý overflow |
| Mô tả/logline | Bắt buộc, trim (349) | Chuỗi 1 ký tự, hàng MB, newline bất thường vẫn qua | **P1** min/max length, giới hạn byte và normalize newline |

Các field hệ thống gửi kèm (`progress`, `createdAt`, `id`) không cho người dùng nhập nhưng vẫn cần invariant backend: `progress` phải nằm trong `[0,1]`, `createdAt` hợp lệ, `id` thuộc đúng người dùng/dự án.

### 2.2 Hồi — thêm/sửa (`ActFormScreen`)

Nguồn: [act_form_screen.dart:45-61](lib/features/acts/presentation/screens/act_form_screen.dart:45), tạo payload [73-85](lib/features/acts/presentation/screens/act_form_screen.dart:73).

| Trường | Hiện có | Case thực tế | Thiếu |
|---|---|---|---|
| Tên hồi | Bắt buộc, trim (53) | Khoảng trắng bị chặn nhưng tên trùng hoặc quá dài vẫn lưu | **P1** min/max, chuẩn hóa và unique trong cùng project |
| Tóm tắt hồi | Bắt buộc (59), dù model biến chuỗi rỗng thành `null` (82) | Nội dung cực dài/markup vẫn qua | **P1** max length/byte và normalize |
| `sequenceOrder` | Tự sinh `acts.length + 1` (81); không có validator | Xóa hồi giữa danh sách rồi thêm mới có thể trùng; hai thiết bị thêm đồng thời cùng số; danh sách local chưa load đủ | **P0** tính số từ server; kiểm tra `>0`, unique trong project ở client **và DB/API**; khi sửa phải validate nếu có thay đổi |
| `status` | Lấy giá trị cũ hoặc mặc định `WAITING`, không có UI validator (83) | Gửi status lạ hoặc chuyển `DONE -> WAITING` không hợp lệ | **P1** enum allow-list + transition rule |
| `projectId` | Nhận từ route, backend chỉ `[Required]` int | Có thể gọi form với project không tồn tại/không thuộc user | **P0** kiểm tra FK và quyền sở hữu ở API |

### 2.3 Phân cảnh — thêm/sửa (`SceneFormScreen`)

Nguồn: [scene_form_screen.dart:88-191](lib/features/scenes/presentation/screens/scene_form_screen.dart:88), kiểm tra trùng số [203-215](lib/features/scenes/presentation/screens/scene_form_screen.dart:203).

| Trường | Hiện có | Case thực tế | Thiếu |
|---|---|---|---|
| Tiêu đề cảnh | Bắt buộc, trim (96) | Tên quá dài hoặc chỉ ký tự điều khiển vẫn qua | **P1** min/max/normalize |
| Số cảnh | `positiveInt`, rồi kiểm tra trùng trong list đã tải của Act (103, 207-215) | Backend seed/Postman có `1A`; FE ép `int`, payload gửi chuỗi số; `1A`/`1B` bị parser backend rút thành cùng `1`; hai client tạo trùng vẫn lọt | **P0** thống nhất contract: chuỗi pattern (ví dụ `^[0-9]+[A-Z]?$`) hoặc số nguyên; unique composite `(ActId, SceneNumber)` ở DB/API; kiểm tra cả khi sửa và race condition |
| Bối cảnh (`locationId`) | Dropdown bắt buộc, chỉ cho location đã load (106-126) | Location đã xóa/thuộc project khác hoặc ID giả có thể gửi trực tiếp qua `_selectedLocationId`; backend không kiểm tra quan hệ Act–Project–Location | **P0** server-side FK/scope check; client phải gửi `effectiveLocationId`, không gửi giá trị stale |
| Setting / time | Tự suy ra từ location; enum FE chỉ `INT/EXT`, `DAY/NIGHT` | Backend model ghi nhận thêm `DUSK/RAIN`; dữ liệu cũ/lạ bị map về mặc định; setting/time có thể không khớp location nếu payload bị sửa | **P1** allow-list thống nhất hai bên và validate consistency với Location |
| Nhân vật tham gia | Multi-select, không bắt buộc; `Set<int>` chống trùng trong UI (150-174) | Có thể chọn character ID không tồn tại/khác project; không có character nào vẫn lưu; payload thay đổi liên kết phụ thuộc backend | **P0** kiểm tra mọi ID tồn tại, cùng project, chưa bị xóa; unique composite đã có ở bảng trung gian nhưng cần validate FK; quyết định rõ có bắt buộc ít nhất một nhân vật hay không |
| Trạng thái | Enum FE `TODO/IN_PROGRESS/DONE`, mặc định TODO (177-184) | Không có validator server-side; PATCH trực tiếp có thể gửi string lạ | **P1** allow-list + transition rule (đặc biệt cảnh đã quay xong) |
| Tóm tắt hành động | Bắt buộc, trim (189) | Nội dung rỗng bị chặn; nội dung quá dài/markup vẫn qua | **P1** min/max/byte và normalize |
| `actId`, `projectId` | Lấy từ route | Act không tồn tại, Act không thuộc project hoặc user khác vẫn có thể bị gửi | **P0** validate quan hệ FK/scope ở API |

**Sai lệch hợp đồng cần sửa trước tiên:** backend `Scene.SceneNumber` là `string?` ([BE/CineX_API/Models/Scene.cs:17-22](../../BE/CineX_API/Models/Scene.cs:17)), seed có các scene số chuỗi; trong khi FE model là `int`, `_numberCtrl` dùng `positiveInt`, và parser còn loại bỏ ký tự không phải số ([lib/core/services/api_service.dart:366-383](lib/core/services/api_service.dart:366)). Đây là lỗi mất thông tin, không chỉ là thiếu message validation.

### 2.4 Nhân vật — thêm/sửa (`CharacterFormScreen`)

Nguồn: [character_form_screen.dart:77-151](lib/features/characters/presentation/screens/character_form_screen.dart:77), lưu payload [208-235](lib/features/characters/presentation/screens/character_form_screen.dart:208).

| Trường | Hiện có | Case thực tế | Thiếu |
|---|---|---|---|
| Ảnh nhân vật | Tùy chọn; picker giới hạn width/quality (198-205) | File không phải ảnh, ảnh > giới hạn byte, tỉ lệ bất thường, upload thất bại nhưng vẫn tiếp tục lưu | **P1** MIME/byte/dimension/aspect; báo lỗi upload và cho retry |
| Tên nhân vật | Bắt buộc, trim (97-99) | Hai nhân vật cùng tên trong project; tên rất dài/ký tự điều khiển | **P1** unique theo project (case-insensitive), min/max/normalize |
| Vai trò | Dropdown enum `MAIN/SUPPORT/CROWD` (103-113) | Giá trị lạ từ server được map mặc định MAIN; PATCH thủ công vẫn có thể gửi lạ | **P1** allow-list ở API |
| Diễn viên | UI bắt buộc (123), model/backend vẫn nullable; lưu thành `null` nếu rỗng (229) | Dữ liệu cũ không có actor mở form sẽ không lưu được nếu không bổ sung; tên diễn viên trùng/nhạy cảm vẫn qua | **P1** thống nhất nullable/required; min/max, normalize; nếu có hồ sơ diễn viên thì kiểm tra liên kết/unique |
| Mô tả | Bắt buộc (149) | Nội dung 1 ký tự hoặc quá lớn vẫn qua | **P1** min/max/byte |
| Casting status | Chỉ hiển thị giá trị cũ, không cho sửa (231) | Có thể gửi giá trị lạ từ dữ liệu cũ; không có luồng chuyển PENDING→APPROVED | **P1** enum/transition và quyền thay đổi |
| `projectId` | Nhận từ route, backend nullable | ID project không tồn tại/không thuộc user; character có thể bị tạo ngoài project | **P0** bắt buộc và kiểm tra quyền sở hữu ở API |

### 2.5 Bối cảnh — thêm/sửa (`LocationFormScreen`)

Nguồn: [location_form_screen.dart:52-100](lib/features/locations/presentation/screens/location_form_screen.dart:52), duplicate check [112-145](lib/features/locations/presentation/screens/location_form_screen.dart:112).

| Trường | Hiện có | Case thực tế | Thiếu |
|---|---|---|---|
| Tên địa điểm | Bắt buộc, trim (63) | Có kiểm tra trùng theo `name + setting + time` không phân biệt hoa thường (118-124) | **P1** min/max/Unicode normalization; unique phải ở server/DB; nếu nghiệp vụ muốn cùng địa điểm ở nhiều thời điểm thì nên tách identity location khỏi time |
| Setting | Dropdown enum `INT/EXT`, mặc định INT (69-76) | Giá trị server lạ bị map thành INT; không có validator | **P1** allow-list server-side |
| Thời gian | Dropdown enum `DAY/NIGHT`, mặc định DAY (80-87) | Backend comment cho phép `DUSK/RAIN`; dữ liệu lạ bị map DAY | **P1** thống nhất enum và allow-list |
| Ghi chú đạo cụ/kỹ thuật | Bắt buộc ở màn hình hiện hành (98) | Màn hình cũ cho phép rỗng; văn bản quá dài vẫn qua | **P1** thống nhất required giữa các entry point; max length/byte |
| `projectId` | Có thể `null` (`int? projectId`) và form có thể mở không truyền project | Bối cảnh mồ côi, trùng check sai phạm vi project | **P0** bắt buộc project context, FK/scope check ở API |

### 2.6 Màn hình cũ cần hợp nhất hoặc loại bỏ

`add_project_screen.dart` và `add_location_screen.dart` vẫn là đường tạo dữ liệu khác với form hiện hành.

| Màn hình/trường | Rule hiện tại | Vấn đề |
|---|---|---|
| `add_project`: tên | Chỉ kiểm tra `value.isEmpty` ([add_project_screen.dart:86-100](lib/features/projects/presentation/screens/add_project_screen.dart:86)) | Chuỗi toàn khoảng trắng lọt qua, sau đó `.trim()` thành tên rỗng |
| `add_project`: đạo diễn | Không validator (111-119) | Không nhất quán với form sửa đang bắt buộc |
| `add_project`: genre | Dropdown cố định, không validator (130-146) | Không có rule server/allow-list rõ ràng |
| `add_project`: logline | Không validator (157-166) | Có thể tạo mô tả rỗng, khác form sửa |
| `add_project`: poster | Chỉ UI placeholder, không chọn/upload ảnh | Field hiển thị nhưng không có dữ liệu/validation thực |
| `add_location`: tên | Chỉ kiểm tra `isEmpty` ([add_location_screen.dart:82-96](lib/features/locations/presentation/screens/add_location_screen.dart:82)) | Chuỗi toàn khoảng trắng lọt qua |
| `add_location`: setting/time | SegmentedButton, giá trị mặc định, không validator | Thiếu allow-list server-side (dù UI khó tạo giá trị lạ) |
| `add_location`: notes | Không validator ([add_location_screen.dart:151-160](lib/features/locations/presentation/screens/add_location_screen.dart:151)) | Cho phép rỗng, khác `LocationFormScreen` |
| `add_location`: moodboard | Chỉ placeholder, không upload | Không có field thực để validate |

## 3. Tài khoản (phụ lục)

Nguồn: [register_screen.dart:118-272](lib/features/auth/presentation/screens/register_screen.dart:118), [login_screen.dart:123-195](lib/features/auth/presentation/screens/login_screen.dart:123), backend DTO [RegisterDto.cs](../../BE/CineX_API/Models/RegisterDto.cs), [LoginDto.cs](../../BE/CineX_API/Models/LoginDto.cs).

| Luồng/trường | Hiện có | Thiếu / case cần kiểm thử |
|---|---|---|
| Đăng ký — họ tên | Required + trim | min/max, control chars, chuẩn hóa khoảng trắng |
| Đăng ký — username | Required + trim | regex (chỉ ký tự hợp lệ), min/max, normalize lowercase, kiểm tra trùng trước submit; backend chỉ có unique index và có thể trả lỗi DB |
| Đăng ký — password | Required, tối thiểu 6 ký tự | Không có xác nhận mật khẩu, max length, độ mạnh, kiểm tra password toàn khoảng trắng; backend cũng chỉ `[MinLength(6)]` |
| Đăng ký — role | Dropdown chỉ `SCREENWRITER/PRODUCER` | Vẫn cần allow-list và authorization ở API, không tin role từ client |
| Đăng nhập — username/password | Required | Không cần lộ rule tồn tại tài khoản; thêm giới hạn độ dài/rate limit/lockout ở backend, xử lý khoảng trắng nhất quán |

## 4. Đối chiếu với backend và yêu cầu nghiệp vụ

1. Backend model chủ yếu chỉ có `[Required]`: `Project.Title`, `Act.Title`, `Scene.ActId/Title`, `Character.Name`, `Location.Name`; không có `MaxLength`, `Range`, enum validator hay cross-field validator ([Project.cs](../../BE/CineX_API/Models/Project.cs:13), [Act.cs](../../BE/CineX_API/Models/Act.cs:14), [Scene.cs](../../BE/CineX_API/Models/Scene.cs:14), [Character.cs](../../BE/CineX_API/Models/Character.cs:13), [Location.cs](../../BE/CineX_API/Models/Location.cs:13)).
2. Controller chỉ kiểm tra `ModelState.IsValid` rồi ghi DB (ví dụ [ScenesController.cs:38-45](../../BE/CineX_API/Controllers/ScenesController.cs:38)); vì vậy các rule quan trọng phải được thực thi lại ở API/DB, không thể chỉ dựa vào Flutter.
3. Có unique index cho `User.Username` ([CineXDbContext.cs:373-376](../../BE/CineX_API/Data/CineXDbContext.cs:373)), nhưng chưa thấy unique constraint cho tên dự án/nhân vật/bối cảnh, `(ProjectId, SequenceOrder)` hoặc `(ActId, SceneNumber)`. Rule “scene_number không trùng trong cùng Act” là yêu cầu bắt buộc ([Requirement_CineX.md](Requirement_CineX.md)), nhưng hiện mới kiểm tra list local.
4. Quan hệ FK có cascade cho Project→Act/Character/Location và Act→Scene ([CineXDbContext.cs:39-65](../../BE/CineX_API/Data/CineXDbContext.cs:39)); controller chưa kiểm tra entity gửi vào có thực sự thuộc cùng project/user hay không. Đây là rủi ro tạo liên kết chéo dữ liệu.
5. Model backend ghi chú `Scene.Time` có thể là `DAY / NIGHT / DUSK / RAIN` ([Scene.cs:27-28](../../BE/CineX_API/Models/Scene.cs:27)), còn FE chỉ có DAY/NIGHT. Cần chốt hợp đồng trước khi thêm validator.

## 5. Bộ case thực tế tối thiểu cần chạy

| ID | Dữ liệu/thao tác | Kết quả đúng mong đợi | Trạng thái hiện tại |
|---|---|---|---|
| V01 | Tên dự án/nhân vật/location = `"   "` | Từ chối tại field | Form hiện hành: đạt; màn hình cũ: **lọt** |
| V02 | Tên hợp lệ nhưng dài hơn giới hạn UI/API | Từ chối với message max length, không 500 | **Thiếu toàn hệ thống** |
| V03 | Hai location cùng tên/setting/time từ hai thiết bị | Chỉ một bản ghi thành công | Check local, race condition **lọt** |
| V04 | Hai scene cùng Act có số `1` tạo đồng thời | Một bản ghi bị từ chối | Check local, DB/API **thiếu** |
| V05 | Scene number `1A`, `1B` | Lưu và hiển thị nguyên chuỗi, không nhập nhằng | FE ép int/parser làm mất hậu tố: **lỗi P0** |
| V06 | Location ID thuộc project khác hoặc đã xóa | Từ chối 4xx | Client/API hiện chưa kiểm tra scope: **lọt** |
| V07 | `endDate < startDate`, ngày sau mốc hỗ trợ | Từ chối trên field, cho phép lịch hợp lệ tương lai | Quan hệ ngày đạt; mốc 2030 hard-code: **thiếu** |
| V08 | Crew count `0`, âm, thập phân, cực lớn | Kết quả nhất quán với nghiệp vụ và backend | `0` bị client chặn dù backend cho phép; max **thiếu** |
| V09 | Status/role/setting/time gửi chuỗi lạ qua API | 400, không fallback âm thầm | Model `string`, controller không allow-list: **lọt** |
| V10 | Upload file không phải ảnh, quá lớn, upload timeout | Không lưu bản ghi thiếu ảnh ngoài ý muốn; có retry | **Thiếu** |
| V11 | Username đã tồn tại | Message thân thiện, không lỗi DB/500 | Unique DB có, client/API mapping **thiếu** |
| V12 | PATCH sửa scene/act/location của project khác | 403/404 | Controller tìm theo ID, thiếu ownership/scope: **rủi ro P0** |

## 6. Ưu tiên triển khai đề xuất

### P0 — trước khi nghiệm thu

1. Chốt và sửa contract `SceneNumber` (hỗ trợ số phân cảnh điện ảnh như `12A`) ở FE model, parser, sort, duplicate check và backend.
2. Đưa kiểm tra uniqueness vào backend/DB: `(ActId, SceneNumber)`; xem xét `(ProjectId, SequenceOrder)` cho Act.
3. Kiểm tra FK + project/owner scope cho mọi create/update Scene, Act, Location, Character.
4. Bắt buộc `projectId` ở các form tài nguyên; loại bỏ đường tạo dữ liệu không có context.

### P1 — trước khi phát hành

1. Thêm validator dùng chung: `minLength`, `maxLength`, `nonNegativeInt`/`boundedInt`, `enum`, `dateRange`, `name` (normalize + control chars), URL/image.
2. Áp dụng cùng một bộ rule cho form hiện hành và màn hình cũ; tốt nhất hợp nhất vào một form duy nhất.
3. Thực thi allow-list status/role/setting/time/genre ở backend; không fallback giá trị lạ thành mặc định.
4. Xử lý lỗi upload và lỗi duplicate từ API thành message field-level; không nuốt lỗi rồi vẫn lưu dữ liệu không đầy đủ.
5. Thêm max length/byte cho mọi text và test tên tiếng Việt có dấu, Unicode tổ hợp, newline.

### P2 — hardening

1. Thêm xác nhận mật khẩu, password policy và rate limit/lockout cho auth.
2. Thêm test tự động cho validators và integration test race condition/ownership.
3. Bổ sung accessibility: `keyboardType`, `inputFormatters`, counter, thông báo lỗi ngay dưới field.

## 7. Kết luận

Các form hiện hành đã bao phủ validation cơ bản (required, số dương, quan hệ ngày và duplicate scene/location ở client). Tuy nhiên, dữ liệu vẫn chưa an toàn khi có nhiều client, dữ liệu cũ hoặc request trực tiếp vào API. Ba vấn đề có mức độ nghiêm trọng nhất là **mismatch SceneNumber**, **thiếu uniqueness server-side**, và **thiếu kiểm tra FK/ownership**. Ngoài ra, hai màn hình cũ đang cho phép dữ liệu mà form sửa không cho phép; nếu còn được route tới, mọi kết quả validation sẽ không nhất quán.

