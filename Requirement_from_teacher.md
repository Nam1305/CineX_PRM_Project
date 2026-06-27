HỆ THỐNG QUẢN LÝ Ý TƯỞNG VÀ PHÂN CẢNH KỊCH BẢN (CINE-X)

1. Tổng quan dự án (Project Overview)
Trong ngành điện ảnh và sân khấu, việc chuyển từ một ý tưởng thô sang một kịch bản chi tiết là một quá trình phức tạp. Biên kịch và nhà sản xuất cần quản lý hàng trăm nhân vật, bối cảnh và kết nối chúng lại thành các phân cảnh hợp lý.
Cine-X là một ứng dụng di động/desktop (phát triển bằng Flutter) giúp các nhóm làm phim độc lập quản lý cấu trúc cốt truyện, hồ sơ nhân vật, bối cảnh và tự động hóa việc lập lịch trình sản xuất dựa trên kịch bản. 

Dự án này giả định sinh viên đã có nền tảng vững chắc về lập trình hướng đối tượng (Java/.NET), do đó ứng dụng sẽ tập trung mạnh vào tính toàn vẹn của dữ liệu, tư duy thiết kế hệ thống và khả năng làm việc nhóm thông qua Git.

Thời gian thực hiện: 06 tuần.
Quy mô nhóm: 4 – 5 sinh viên.
Công nghệ cốt lõi: Flutter (Dart), State Management (Provider hoặc ChangeNotifier), Local Database (Sqflite hoặc Hive).

2. Phân tích nghiệp vụ (Business Analysis)
2.1. Quy trình nghiệp vụ (Workflow)
Một dự án kịch bản sẽ trải qua các bước nghiệp vụ sau trong hệ thống:
Khởi tạo: Biên kịch tạo một Dự án phim mới và xác định các thông tin cơ bản.
Xây dựng tài nguyên (Casting & Scouting): Biên kịch nhập danh sách hồ sơ Nhân vật dự kiến và các Địa điểm/Bối cảnh sẽ xuất hiện trong phim.
Xây dựng cấu trúc (Storyboarding): Phim được chia thành các Hồi (Acts). Trong mỗi Hồi, biên kịch tạo các Thẻ phân cảnh (Scene Cards). Tại mỗi thẻ, biên kịch kéo thả hoặc chọn các Nhân vật và Bối cảnh đã tạo ở bước 2 vào cảnh đó, sau đó viết tóm tắt hành động.
Tối ưu sản xuất (Production Planning): Nhà sản xuất sử dụng hệ thống để tự động gom nhóm các cảnh có cùng bối cảnh hoặc nhân vật nhằm lên lịch quay tối ưu (ví dụ: gom tất cả cảnh ở "Quán cà phê" để quay trong cùng một ngày).

2.2. Đối tượng sử dụng (Actors)
Biên kịch (Screenwriter): Tập trung vào việc tạo nhân vật, bối cảnh và nội dung các phân cảnh.
Nhà sản xuất/Trợ lý đạo diễn (Producer/Assistant Director): Sử dụng dữ liệu phân cảnh để theo dõi tiến độ, lập lịch trình quay phim và xuất báo cáo.

3. Yêu cầu chức năng (Functional Requirements)

Hệ thống được chia thành 5 module chức năng chính để phân chia công việc cho nhóm 5 thành viên:

Module 1: Quản trị Dự án & Cấu trúc (Project & Act Management)
F1.1: Thêm, sửa, xóa, xem danh sách dự án phim (Tên, thể loại, mô tả, ngày bắt đầu).
F1.2: Phân chia dự án thành các Hồi (Act) - ví dụ: Hồi 1 (Mở đầu), Hồi 2 (Thắt nút), Hồi 3 (Mở nút).
F1.3: Hiển thị Dashboard tổng quan: Tổng số nhân vật, tổng số cảnh quay, tiến độ hoàn thành của dự án (%).

Module 2: Quản lý Tài nguyên Phim (Character & Location Directory)
F2.1: CRUD Nhân vật: Tên, vai trò (Chính/Phụ/Quần chúng), mô tả tâm lý, hình ảnh (chọn từ thiết bị thông qua image_picker).
F2.2: CRUD Bối cảnh: Tên địa điểm, thuộc tính vị trí (Trong nhà - Interior / Ngoài trời - Exterior), thời gian (Ngày - Day / Đêm - Night), ghi chú chuẩn bị đạo cụ.

Module 3: Trình soạn thảo Phân cảnh (Scene Board Editor)
F3.1: Thêm, sửa, xóa các Thẻ phân cảnh (Scene Card) nằm trong một Hồi.
F3.2: Liên kết dữ liệu: Trong một cảnh, cho phép chọn 1 Bối cảnh (Dropdown) và chọn nhiều Nhân vật xuất hiện (Multi-select Checkbox/Filter Chips).
F3.3: Nhập nội dung tóm tắt phân cảnh (Scene Outline/Action) và cập nhật trạng thái phân cảnh (Mới tạo, Đang viết, Đã xong).

Module 4: Trợ lý Lập lịch Sản xuất (Production Planner)
F4.1: Tự động nhóm (Group by) các phân cảnh có cùng một Địa điểm/Bối cảnh để tạo thành danh sách ngày quay (Shooting Day) đề xuất.
F4.2: Bộ lọc nâng cao (Advance Filter): Tìm kiếm nhanh các phân cảnh dựa trên điều kiện (Ví dụ: Tìm tất cả cảnh có Nhân vật A VÀ quay vào Ban đêm).

Module 5: Thống kê & Xuất bản (Analytics & Export)
F5.1: Biểu đồ trực quan (fl_chart): Thể hiện tần suất xuất hiện của các nhân vật qua các cảnh; Tỷ lệ các cảnh Interior vs Exterior.
F5.2: Export PDF: Xuất toàn bộ thông tin dự án bao gồm Danh sách nhân vật và nội dung toàn bộ phân cảnh theo đúng thứ tự dòng thời gian ra một file PDF chuẩn hóa.

4. Thiết kế Cơ sở dữ liệu (Database Design)
Để phù hợp với tư duy lập trình hệ thống (Java/.NET), cơ sở dữ liệu (sử dụng SQLite thông qua sqflite hoặc drift) được thiết kế theo mô hình quan hệ chặt chẽ dưới đây:
Các bảng dữ liệu (Tables)
1. Bảng Projects (Quản lý dự án)
id (INTEGER, Primary Key, Auto Increment)
title (TEXT, Not Null)
genre (TEXT)
description (TEXT)
created_at (TEXT)
2. Bảng Acts (Quản lý Hồi - Quan hệ 1-n với Projects)
id (INTEGER, Primary Key)
project_id (INTEGER, Foreign Key to Projects(id) ON DELETE CASCADE)
title (TEXT)
sequence_order (INTEGER) - Thứ tự hiển thị của Hồi
3. Bảng Characters (Quản lý nhân vật - Quan hệ 1-n với Projects)
id (INTEGER, Primary Key)
project_id (INTEGER, Foreign Key to Projects(id))
name (TEXT, Not Null)
role_type (TEXT) - MAIN, SUPPORT, CROWD
description (TEXT)
image_path (TEXT) - Đường dẫn ảnh lưu trong máy
4. Bảng Locations (Quản lý bối cảnh - Quan hệ 1-n với Projects)
id (INTEGER, Primary Key)
project_id (INTEGER, Foreign Key to Projects(id))
name (TEXT, Not Null)
setting (TEXT) - INT (Trong nhà) / EXT (Ngoài trời)
time_of_day (TEXT) - DAY / NIGHT
notes (TEXT)
5. Bảng Scenes (Quản lý phân cảnh - Quan hệ 1-n với Acts, 1-n với Locations)
id (INTEGER, Primary Key)
act_id (INTEGER, Foreign Key to Acts(id) ON DELETE CASCADE)
location_id (INTEGER, Foreign Key to Locations(id))
scene_number (INTEGER) - Số thứ tự cảnh
summary (TEXT) - Nội dung tóm tắt cảnh
status (TEXT) - TODO, IN_PROGRESS, DONE
6. Bảng trung gian Scene_Characters (Quan hệ n-n giữa Scenes và Characters)
scene_id (INTEGER, Foreign Key to Scenes(id) ON DELETE CASCADE)
character_id (INTEGER, Foreign Key to Characters(id) ON DELETE CASCADE)
Primary Key (scene_id, character_id)

5. Yêu cầu thiết kế Wireframe (UI/UX)
Sinh viên cần sử dụng hệ thống UI của Material Design 3 (hoặc Cupertino nếu làm style iOS) có sẵn trong Flutter để thiết kế các màn hình. Không yêu cầu vẽ Figma trước, nhưng cấu trúc giao diện của ứng dụng phải đảm bảo các tiêu chuẩn sau:

5.1. Luồng màn hình chính (Navigation Flow)
Màn hình Chọn Dự án (Project Launcher): Dạng GridView hiển thị các dự án dưới dạng các poster/card lớn. Có nút FloatingActionButton (FAB) dấu cộng + ở góc dưới bên phải để thêm nhanh dự án mới.
Màn hình Workspace chính (Sử dụng BottomNavigationBar gồm 4 Tab):
Tab 1: Story Board: Hiển thị một ListView lồng nhau. Mỗi Hồi (Act) là một ExpansionTile (cho phép đóng/mở). Bên trong là các Card đại diện cho từng cảnh phim. Trên mỗi Card hiển thị: Số cảnh, Tên bối cảnh (ví dụ: CẢNH 1: INT. QUÁN CÀ PHÊ - NGÀY) và các avatar tròn nhỏ (CircleAvatar) của các nhân vật tham gia.
Tab 2: Characters: Giao diện dạng lưới (SliverGrid) hiển thị các thẻ nhân vật gồm ảnh, tên và nhãn vai trò (bằng Chip màu sắc khác nhau).
Tab 3: Locations: Danh sách ListTile gọn gàng, hiển thị kèm icon biểu tượng (Ví dụ: Icon Mặt trời cho DAY, Mặt trăng cho NIGHT).
Tab 4: Production & Analytics: Phía trên cùng là biểu đồ, phía dưới là danh sách các cảnh được gom nhóm theo địa điểm quay.
5.2. Nguyên tắc UX bắt buộc
Form Validation: Tất cả các màn hình thêm/sửa dữ liệu (Nhân vật, Bối cảnh) phải sử dụng Widget Form và TextFormField có kiểm tra tính hợp lệ của dữ liệu (Ví dụ: Không được bỏ trống tên nhân vật, không trùng số thứ tự cảnh).
Trạng thái trống (Empty State): Khi một dự án mới tinh chưa có nhân vật hay phân cảnh nào, màn hình không được để trắng hoàn toàn mà phải hiển thị một hình minh họa (hoặc Icon lớn) kèm dòng chữ hướng dẫn: "Chưa có nhân vật nào. Bấm nút + để thêm nhân vật đầu tiên".
Phản hồi người dùng (Feedback): Khi xóa một phân cảnh hoặc một nhân vật, hệ thống phải hiển thị một AlertDialog để xác nhận. Sau khi thực hiện thành công các thao tác CRUD, phải thông báo cho người dùng bằng SnackBar.

6. Tiêu chí đánh giá dự án (Grading Rubric)
Phân tích & Thiết kế (20%): Database chuẩn hóa, không dư thừa dữ liệu; Wireframe logic, luồng đi của người dùng (User Flow) hợp lý.
UI/UX (30%): Giao diện đẹp, chuyên nghiệp, không vỡ layout khi đổi kích thước màn hình (Mobile vs Web). Các nút bấm, form nhập liệu có độ phản hồi tốt.
Frontend Flutter (40%): * Giao diện responsive (đẹp trên cả máy màn hình nhỏ và máy tính bảng). Áp dụng State Management tốt (Bloc, Riverpod, hoặc Provider).
Tính năng PDF & Lưu trữ (10%) : Xuất file PDF đúng chuẩn layout, hiển thị đúng font tiếng Việt


