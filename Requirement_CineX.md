# CINE-X — HỆ THỐNG QUẢN LÝ Ý TƯỞNG VÀ PHÂN CẢNH KỊCH BẢN

---

## 1. Tổng quan dự án

**Cine-X** là ứng dụng di động/desktop phát triển bằng Flutter, hỗ trợ các nhóm làm phim độc lập quản lý cấu trúc cốt truyện, hồ sơ nhân vật, bối cảnh và tự động hóa lập lịch sản xuất dựa trên kịch bản.

| Thông tin | Chi tiết |
|---|---|
| Thời gian thực hiện | 6 tuần |
| Quy mô nhóm | 4 – 5 sinh viên |
| Ngôn ngữ | Dart (Flutter) |
| State Management | Provider hoặc ChangeNotifier |
| Local Database | SQLite (sqflite hoặc drift) |

---

## 2. Phân tích nghiệp vụ

### 2.1. Quy trình nghiệp vụ

```
[1] Khởi tạo dự án
      │
      ▼
[2] Xây dựng tài nguyên (Casting & Scouting)
    ├── Nhập hồ sơ Nhân vật
    └── Nhập Địa điểm / Bối cảnh
      │
      ▼
[3] Xây dựng cấu trúc (Storyboarding)
    ├── Phân chia Dự án → Hồi (Acts)
    └── Tạo Thẻ phân cảnh (Scene Cards) → gán Nhân vật & Bối cảnh
      │
      ▼
[4] Tối ưu sản xuất (Production Planning)
    └── Gom nhóm cảnh theo bối cảnh → Lịch quay đề xuất
```

### 2.2. Đối tượng sử dụng

| Actor | Mô tả |
|---|---|
| **Biên kịch (Screenwriter)** | Tạo nhân vật, bối cảnh, soạn nội dung phân cảnh |
| **Nhà sản xuất / Trợ lý đạo diễn** | Theo dõi tiến độ, lập lịch trình quay, xuất báo cáo |

---

## 3. Yêu cầu chức năng

### Module 1 — Quản trị Dự án & Cấu trúc

| Mã | Tên chức năng | Mô tả |
|---|---|---|
| F1.1 | CRUD Dự án | Thêm, sửa, xóa, xem danh sách dự án phim (Tên, thể loại, mô tả, ngày bắt đầu) |
| F1.2 | Quản lý Hồi (Act) | Phân chia dự án thành các Hồi (VD: Hồi 1 – Mở đầu, Hồi 2 – Thắt nút, Hồi 3 – Mở nút) |
| F1.3 | Dashboard tổng quan | Hiển thị: tổng số nhân vật, tổng số cảnh quay, tiến độ hoàn thành dự án (%) |

---

### Module 2 — Quản lý Tài nguyên Phim

| Mã | Tên chức năng | Mô tả |
|---|---|---|
| F2.1 | CRUD Nhân vật | Tên, vai trò (MAIN / SUPPORT / CROWD), mô tả tâm lý, hình ảnh (chọn từ thiết bị qua `image_picker`) |
| F2.2 | CRUD Bối cảnh | Tên địa điểm, thuộc tính vị trí (INT – Trong nhà / EXT – Ngoài trời), thời gian (DAY / NIGHT), ghi chú đạo cụ |

---

### Module 3 — Trình soạn thảo Phân cảnh

| Mã | Tên chức năng | Mô tả |
|---|---|---|
| F3.1 | CRUD Scene Card | Thêm, sửa, xóa Thẻ phân cảnh (Scene Card) nằm trong một Hồi |
| F3.2 | Liên kết dữ liệu | Chọn 1 Bối cảnh (Dropdown) + chọn nhiều Nhân vật xuất hiện (Multi-select Checkbox / Filter Chips) |
| F3.3 | Nội dung & Trạng thái | Nhập tóm tắt phân cảnh (Scene Outline/Action); Trạng thái: **TODO** / **IN_PROGRESS** / **DONE** |

---

### Module 4 — Trợ lý Lập lịch Sản xuất

| Mã | Tên chức năng | Mô tả |
|---|---|---|
| F4.1 | Tự động nhóm cảnh | Group by theo Địa điểm/Bối cảnh → tạo danh sách ngày quay (Shooting Day) đề xuất |
| F4.2 | Bộ lọc nâng cao | Tìm kiếm cảnh theo điều kiện kết hợp (VD: Nhân vật A **AND** Thời gian = NIGHT) |

---

### Module 5 — Thống kê & Xuất bản

| Mã | Tên chức năng | Mô tả |
|---|---|---|
| F5.1 | Biểu đồ trực quan | Sử dụng `fl_chart`: tần suất xuất hiện của nhân vật; tỷ lệ cảnh INT vs EXT |
| F5.2 | Export PDF | Xuất toàn bộ thông tin dự án (danh sách nhân vật + nội dung phân cảnh theo dòng thời gian), đúng layout, hỗ trợ font tiếng Việt |

---

## 4. Thiết kế Cơ sở dữ liệu

### Sơ đồ quan hệ

```
Projects ──< Acts ──< Scenes >──── Scene_Characters ────< Characters
   │                    │
   └──< Characters      └── location_id ──> Locations
   └──< Locations
```

### Định nghĩa bảng

#### `Projects`
| Cột | Kiểu | Ràng buộc |
|---|---|---|
| `id` | INTEGER | PK, Auto Increment |
| `title` | TEXT | NOT NULL |
| `genre` | TEXT | |
| `description` | TEXT | |
| `created_at` | TEXT | |

#### `Acts`
| Cột | Kiểu | Ràng buộc |
|---|---|---|
| `id` | INTEGER | PK, Auto Increment |
| `project_id` | INTEGER | FK → Projects(id) ON DELETE CASCADE |
| `title` | TEXT | |
| `sequence_order` | INTEGER | Thứ tự hiển thị |

#### `Characters`
| Cột | Kiểu | Ràng buộc |
|---|---|---|
| `id` | INTEGER | PK, Auto Increment |
| `project_id` | INTEGER | FK → Projects(id) ON DELETE CASCADE |
| `name` | TEXT | NOT NULL |
| `role_type` | TEXT | MAIN / SUPPORT / CROWD |
| `description` | TEXT | |
| `image_path` | TEXT | Đường dẫn ảnh trên thiết bị |

#### `Locations`
| Cột | Kiểu | Ràng buộc |
|---|---|---|
| `id` | INTEGER | PK, Auto Increment |
| `project_id` | INTEGER | FK → Projects(id) ON DELETE CASCADE |
| `name` | TEXT | NOT NULL |
| `setting` | TEXT | INT / EXT |
| `time_of_day` | TEXT | DAY / NIGHT |
| `notes` | TEXT | |

#### `Scenes`
| Cột | Kiểu | Ràng buộc |
|---|---|---|
| `id` | INTEGER | PK, Auto Increment |
| `act_id` | INTEGER | FK → Acts(id) ON DELETE CASCADE |
| `location_id` | INTEGER | FK → Locations(id) |
| `scene_number` | INTEGER | Số thứ tự cảnh (không trùng trong 1 Act) |
| `summary` | TEXT | Nội dung tóm tắt |
| `status` | TEXT | TODO / IN_PROGRESS / DONE |

#### `Scene_Characters` (Bảng trung gian n-n)
| Cột | Kiểu | Ràng buộc |
|---|---|---|
| `scene_id` | INTEGER | FK → Scenes(id) ON DELETE CASCADE |
| `character_id` | INTEGER | FK → Characters(id) ON DELETE CASCADE |
| — | — | PK (scene_id, character_id) |

---

## 5. Thiết kế Giao diện (UI/UX)

### 5.1. Navigation Flow

```
[Project Launcher]
  GridView dạng poster/card lớn
  FAB (+) góc dưới phải → thêm dự án mới
        │
        ▼ (chọn dự án)
[Workspace – BottomNavigationBar 4 tab]
  ├── Tab 1: Story Board
  │     ListView lồng nhau
  │     Hồi (Act) → ExpansionTile (đóng/mở)
  │       └── Scene Card: số cảnh, tên bối cảnh (VD: INT. QUÁN CÀ PHÊ – NGÀY),
  │                        CircleAvatar nhân vật tham gia
  │
  ├── Tab 2: Characters
  │     SliverGrid: thẻ nhân vật (ảnh + tên + Chip vai trò màu sắc)
  │
  ├── Tab 3: Locations
  │     ListTile: icon Mặt trời (DAY) / Mặt trăng (NIGHT)
  │
  └── Tab 4: Production & Analytics
        Phía trên: biểu đồ fl_chart
        Phía dưới: danh sách cảnh gom nhóm theo địa điểm
```

### 5.2. Nguyên tắc UX bắt buộc

| Nguyên tắc | Yêu cầu cụ thể |
|---|---|
| **Form Validation** | Dùng `Form` + `TextFormField` cho mọi màn hình thêm/sửa; không được để trống tên; scene_number không trùng trong cùng Act |
| **Empty State** | Khi chưa có dữ liệu, hiển thị icon lớn + hướng dẫn (VD: _"Chưa có nhân vật nào. Bấm nút + để thêm nhân vật đầu tiên"_) |
| **User Feedback** | Xóa dữ liệu → hiện `AlertDialog` xác nhận; thao tác CRUD thành công → hiện `SnackBar` thông báo |
| **Responsive** | Layout không vỡ trên cả màn hình nhỏ (mobile) và màn hình lớn (tablet/desktop) |

---

## 6. Tiêu chí đánh giá

| Hạng mục | Trọng số | Tiêu chí |
|---|---|---|
| Phân tích & Thiết kế | 20% | Database chuẩn hóa, không dư thừa; User Flow hợp lý |
| UI/UX | 30% | Giao diện đẹp, chuyên nghiệp, không vỡ layout; form & nút bấm phản hồi tốt |
| Frontend Flutter | 40% | Responsive (mobile ↔ tablet); State Management đúng chuẩn (Bloc / Riverpod / Provider) |
| PDF & Lưu trữ | 10% | Export PDF đúng layout, hiển thị đúng font tiếng Việt |

---

## 7. Phụ lục — Thư viện đề xuất

| Thư viện | Mục đích |
|---|---|
| `sqflite` / `drift` | Local database (SQLite) |
| `provider` / `flutter_bloc` | State management |
| `image_picker` | Chọn ảnh từ thiết bị |
| `fl_chart` | Vẽ biểu đồ thống kê |
| `pdf` / `printing` | Xuất file PDF (hỗ trợ tiếng Việt) |
