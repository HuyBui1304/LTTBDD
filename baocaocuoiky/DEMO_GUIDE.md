# 🎬 Hướng dẫn Demo App Điểm danh QR - Mức Dễ

## Chuẩn bị

1. **Chạy app:**
```bash
cd /Users/huybui/Documents/LTTBDD/baocaocuoiky
flutter run
```

2. **Chạy tests:**
```bash
flutter test
```

## Quy trình demo (5-7 phút)

### 1. Giới thiệu màn hình Home (1 phút)
- Mở app, giới thiệu giao diện chính
- Dashboard hiển thị thống kê: Sinh viên, Buổi học, Buổi học sắp tới
- Thao tác nhanh: Thêm SV, Tạo buổi học, Quét QR (coming soon)
- Danh sách buổi học gần đây
- **Nhấn mạnh:** Loading state, Empty state

### 2. Quản lý Sinh viên (2 phút)

**Thêm sinh viên mới:**
- Nhấn "Quản lý sinh viên" hoặc nút FAB
- Thêm sinh viên:
  - Mã SV: `SV001234`
  - Họ tên: `Nguyễn Văn A`
  - Email: `nguyenvana@example.com`
  - SĐT: `0123456789`
  - Mã lớp: `IT01`
- **Demo validation:** Thử nhập email sai, mã SV ngắn
- Lưu thành công

**Thêm thêm 2-3 sinh viên nữa:**
- `SV001235`, `Trần Thị B`, `tranthib@example.com`, `IT01`
- `SV001236`, `Lê Văn C`, `levanc@example.com`, `IT02`

**Tìm kiếm và lọc:**
- Tìm kiếm: "Nguyen"
- Lọc theo lớp: IT01
- Sắp xếp: Tên A-Z, Tên Z-A, Mã SV
- Clear filter

**Sửa/Xóa:**
- Nhấn menu 3 chấm → Sửa → Thay đổi số điện thoại
- Nhấn menu 3 chấm → Xóa → Xác nhận

**Xem chi tiết:**
- Nhấn vào 1 sinh viên
- Xem thông tin chi tiết
- Thống kê điểm danh (chưa có dữ liệu)
- Lịch sử điểm danh (empty state)

### 3. Quản lý Buổi học (2 phút)

**Tạo buổi học mới:**
- Quay về Home → Nhấn "Quản lý buổi học"
- Tạo buổi học:
  - Mã buổi: `SS001`
  - Tiêu đề: `Lập trình Mobile - Buổi 1`
  - Mô tả: `Giới thiệu Flutter`
  - Mã lớp: `IT01`
  - Ngày giờ: Chọn ngày hôm nay, giờ 8:00
  - Địa điểm: `Phòng A101`
  - Trạng thái: `Đang diễn ra`
- Lưu

**Tạo thêm 1-2 buổi nữa:**
- Buổi 2: Mã lớp IT02, trạng thái "Đã lên lịch"
- Buổi 3: Mã lớp IT01, trạng thái "Đã hoàn thành"

**Tìm kiếm và lọc:**
- Tìm kiếm: "Mobile"
- Lọc theo trạng thái: "Đang diễn ra"
- Sắp xếp: Ngày mới nhất, Tên A-Z

**Sửa/Xóa buổi học:** (Optional)

### 4. Điểm danh (2 phút)

**Vào buổi học để điểm danh:**
- Nhấn vào buổi học vừa tạo (IT01, Đang diễn ra)
- Xem thông tin buổi học chi tiết
- Danh sách sinh viên của lớp IT01 hiển thị

**Điểm danh từng sinh viên:**
- Nhấn vào sinh viên thứ 1 hoặc nút "Điểm danh"
- Chọn trạng thái: "Có mặt"
- Lưu
- Sinh viên thứ 2: "Muộn", thêm ghi chú: "Đến muộn 5 phút"
- Sinh viên thứ 3: "Vắng"

**Xem thống kê:**
- Scroll lên trên xem thống kê điểm danh:
  - Có mặt: 1
  - Vắng: 1
  - Muộn: 1
  - Có phép: 0

**Điểm danh nhanh:** (Optional)
- Nhấn icon tốc độ trên AppBar
- Xác nhận → Tất cả sinh viên chưa điểm danh → "Có mặt"

### 5. Xem lại và Navigation (30s)

**Quay về Home:**
- Pull to refresh
- Thống kê đã cập nhật
- Buổi học gần đây hiển thị

**Vào Chi tiết sinh viên:**
- Chọn 1 sinh viên đã điểm danh
- Xem lịch sử điểm danh → Có dữ liệu
- Xem thống kê → Có mặt: 1 buổi

### 6. Demo Offline & Data Persistence (30s)

**Tắt mạng:**
- Tắt WiFi/Mobile data
- Reload app hoặc kill & restart
- **Nhấn mạnh:** Dữ liệu vẫn còn (SQLite)
- Browse qua các màn hình → Tất cả hoạt động bình thường

### 7. Demo Tests (30s)

```bash
flutter test
```

- Show kết quả: 44 tests passed ✅
- Giải thích:
  - Model tests: Student, AttendanceSession, AttendanceRecord
  - Validator tests: Email, Phone, StudentId, etc.

## Checklist Demo

Đảm bảo demo đầy đủ các yêu cầu:

### ✅ Giao diện
- [x] Gọn gàng, điều hướng tốt
- [x] Loading state (khi tải dữ liệu)
- [x] Empty state (khi không có dữ liệu)
- [x] Error state (có thể tắt DB để test)

### ✅ CRUD
- [x] Thêm sinh viên
- [x] Sửa sinh viên
- [x] Xóa sinh viên
- [x] Xem chi tiết sinh viên
- [x] Thêm buổi học
- [x] Sửa buổi học
- [x] Xóa buổi học
- [x] Xem chi tiết buổi học
- [x] Điểm danh (tạo/cập nhật AttendanceRecord)

### ✅ Validation
- [x] Email không hợp lệ
- [x] Mã SV quá ngắn
- [x] SĐT không hợp lệ
- [x] Required fields

### ✅ Offline Storage
- [x] Dữ liệu lưu trong SQLite
- [x] Hoạt động không cần mạng
- [x] Data persistence sau khi restart

### ✅ Search & Filter
- [x] Tìm kiếm sinh viên
- [x] Lọc theo lớp
- [x] Tìm kiếm buổi học
- [x] Lọc theo trạng thái
- [x] Sắp xếp (tên, ngày, mã)

### ✅ Tests
- [x] 44 unit tests pass
- [x] Coverage: Models + Validators

## Tips cho Demo

1. **Chuẩn bị dữ liệu trước:**
   - Không cần tạo mới mọi thứ trong demo
   - Có thể có sẵn 2-3 sinh viên, 1-2 buổi học
   - Focus vào show tính năng quan trọng

2. **Nhấn mạnh điểm mạnh:**
   - UI/UX đẹp, modern (Material Design 3)
   - Responsive, smooth animations
   - Validation rõ ràng
   - Offline-first

3. **Xử lý tình huống:**
   - Nếu crash/bug: Đã có tests để catch lỗi
   - Nếu hỏi feature chưa có: "Sẽ có ở mức Trung bình/Khá"

4. **Kết thúc:**
   - Tóm tắt đã hoàn thành 100% yêu cầu Mức Dễ
   - Show README.md với checklist
   - Sẵn sàng cho câu hỏi

## Video Demo Script

**[00:00-00:15] Intro:**
"Xin chào, em xin demo app Điểm danh QR. Đây là mức Dễ với đầy đủ yêu cầu: CRUD, search/filter, offline storage, và unit tests."

**[00:15-01:00] Home Screen:**
"Đây là màn hình Home với dashboard thống kê tổng quan. Có thể thấy Loading state khi tải dữ liệu, và Empty state khi chưa có dữ liệu."

**[01:00-03:00] Quản lý Sinh viên:**
"Bây giờ em sẽ thêm sinh viên mới... [demo add]. App có validation đầy đủ... [demo validation]. Có thể tìm kiếm, lọc theo lớp, và sắp xếp... [demo]."

**[03:00-05:00] Quản lý Buổi học:**
"Tiếp theo là tạo buổi học... [demo create]. Tương tự có search và filter... [demo]."

**[05:00-06:30] Điểm danh:**
"Vào buổi học để điểm danh sinh viên... [demo attendance]. App hiển thị thống kê real-time... [show stats]."

**[06:30-07:00] Offline & Tests:**
"Tất cả dữ liệu được lưu bằng SQLite, hoạt động offline hoàn toàn. Em đã viết 44 unit tests, tất cả đều pass... [show test results]."

**[07:00-07:15] Outro:**
"Vậy là em đã hoàn thành 100% yêu cầu mức Dễ. Cảm ơn thầy đã theo dõi!"

---

**Thời lượng:** 5-7 phút
**Chuẩn bị:** App đã build sẵn, dữ liệu test có sẵn (optional)
**Thiết bị:** Emulator hoặc thiết bị thật

