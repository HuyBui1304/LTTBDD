# Hướng dẫn cài đặt Font cho PDF

## Vấn đề
File PDF xuất ra có thể hiển thị sai font chữ cho các ký tự tiếng Việt (ví dụ: ữ, ệ, ở hiển thị thành ô vuông hoặc ký tự lỗi).

## Giải pháp
Cần tải và thêm font Noto Sans (hỗ trợ đầy đủ tiếng Việt) vào thư mục `assets/fonts/`.

## Các bước thực hiện

### Bước 1: Tải font Noto Sans

**Cách 1: Tải từ Google Fonts (Khuyến nghị)**
1. Truy cập: https://fonts.google.com/noto/specimen/Noto+Sans
2. Click nút "Download family" để tải toàn bộ font family
3. Giải nén file ZIP
4. Tìm file `NotoSans-Regular.ttf` trong thư mục đã giải nén

**Cách 2: Tải trực tiếp**
- Link tải: https://github.com/google/fonts/raw/main/ofl/notosans/NotoSans-Regular.ttf
- Hoặc tìm kiếm "Noto Sans Regular ttf download" trên Google

### Bước 2: Đặt file font vào project

1. Copy file `NotoSans-Regular.ttf` vào thư mục `assets/fonts/`
2. Đảm bảo tên file chính xác là: `NotoSans-Regular.ttf`

**Cấu trúc thư mục sau khi thêm font:**
```
assets/
  └── fonts/
      └── NotoSans-Regular.ttf
```

### Bước 3: Chạy lại ứng dụng

```bash
flutter pub get
flutter run
```

## Font dự phòng (Fallback)

Nếu không tìm thấy `NotoSans-Regular.ttf`, hệ thống sẽ tự động thử các font sau theo thứ tự:
1. `NotoSans-Regular.ttf` (ưu tiên)
2. `NotoSans-Vietnamese.ttf`
3. `Roboto-Regular.ttf`

Bạn có thể thêm bất kỳ font nào trong danh sách trên vào thư mục `assets/fonts/`.

## Kiểm tra

Sau khi thêm font và chạy lại ứng dụng:
1. Xuất một file PDF từ ứng dụng
2. Mở file PDF và kiểm tra xem các ký tự tiếng Việt (như: ữ, ệ, ở, ế, ộ...) có hiển thị đúng không
3. Nếu vẫn còn lỗi, kiểm tra lại:
   - File font đã được đặt đúng vị trí chưa
   - Tên file có chính xác không
   - Đã chạy `flutter pub get` chưa

## Lưu ý

- Font Noto Sans là font mã nguồn mở của Google, hỗ trợ đầy đủ tiếng Việt và nhiều ngôn ngữ khác
- Nếu không thêm font, PDF vẫn hoạt động nhưng có thể hiển thị sai một số ký tự tiếng Việt
- Kích thước file font khoảng 200-500KB, không ảnh hưởng đáng kể đến kích thước ứng dụng

## Hỗ trợ

Nếu gặp vấn đề, vui lòng kiểm tra:
- File `pubspec.yaml` đã có dòng `assets: - assets/fonts/` chưa
- Thư mục `assets/fonts/` đã tồn tại chưa
- File font có định dạng `.ttf` không
