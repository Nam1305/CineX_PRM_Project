# Chế độ offline

## Phạm vi

- `SCREENWRITER` và `PRODUCER` có thể mở, tìm kiếm, lọc và xuất các dữ liệu đã
  được đồng bộ trước đó khi mất mạng.
- Mọi tạo/sửa/xóa vẫn gọi API trước. Chỉ khi server trả về thành công dữ liệu
  mới được ghi vào SQLite; không tạo hàng đợi ghi offline và không phát sinh
  xung đột đồng bộ.
- PostgreSQL trên backend vẫn là nguồn dữ liệu chuẩn. Khi có mạng, provider
  phát dữ liệu SQLite ngay lập tức rồi tải bản mới từ server và thay thế cache.

## Dữ liệu được cache

SQLite lưu payload JSON của Project, Act, Scene, Character và Location cùng các
chỉ mục project/act/status để lọc nhanh. Việc giữ payload giúp không thay đổi
model và API hiện tại.

Ảnh không lưu trực tiếp trong payload:

- Android/iOS/Windows/macOS/Linux: bytes được lưu dưới thư mục documents của
  ứng dụng (`cinex_media/`), SQLite chỉ giữ `local_path`, MIME type và thời gian
  truy cập.
- Flutter Web: bytes được lưu trong bảng `media_cache` (IndexedDB thông qua
  `sqflite_common_ffi_web`) và hiển thị bằng data URL.

Ảnh được tải vào cache lần đầu khi widget hiển thị URL HTTP(S). Nếu tải ảnh
  thất bại, widget vẫn thử URL gốc để không làm thay đổi hành vi online hiện tại.

## Web build

Các file runtime SQLite Web (`web/sqlite3.wasm`, `web/sqflite_sw.js`) phải được
giữ trong source control. Nếu nâng phiên bản `sqflite_common_ffi_web`, chạy:

```text
dart run sqflite_common_ffi_web:setup --force
```

## Giới hạn hiện tại

Ngày quay và trạng thái quay trong Production Planner vẫn dùng cơ chế
`SharedPreferences` hiện có; chúng không được coi là dữ liệu server đồng bộ.
Muốn đồng bộ đa thiết bị cần thêm endpoint production và version/timestamp cho
  từng thay đổi ở backend.
