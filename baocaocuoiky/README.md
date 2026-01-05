# 📱 Hệ thống Quản lý Điểm danh QR Code

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blue)](https://flutter.dev/)

> Ứng dụng quản lý điểm danh sinh viên hiện đại sử dụng công nghệ QR Code, được xây dựng với Flutter và SQLite. Hỗ trợ đầy đủ các tính năng từ quản lý cơ bản đến báo cáo thống kê nâng cao.

## 📋 Mục lục

- [Tổng quan](#-tổng-quan)
- [Tính năng chính](#-tính-năng-chính)
- [Yêu cầu hệ thống](#-yêu-cầu-hệ-thống)
- [Cài đặt](#-cài-đặt)
- [Sử dụng](#-sử-dụng)
- [Cấu trúc dự án](#-cấu-trúc-dự-án)
- [Công nghệ sử dụng](#-công-nghệ-sử-dụng)
- [Kiểm thử](#-kiểm-thử)
- [Tài liệu](#-tài-liệu)
- [Đóng góp](#-đóng-góp)
- [Giấy phép](#-giấy-phép)

## 🎯 Tổng quan

Hệ thống Quản lý Điểm danh QR Code là một ứng dụng di động đa nền tảng được phát triển để số hóa quy trình điểm danh trong môi trường giáo dục. Ứng dụng cho phép giáo viên tạo mã QR cho từng buổi học, sinh viên quét mã để điểm danh tự động, và quản trị viên theo dõi, phân tích dữ liệu điểm danh một cách hiệu quả.

### ✨ Điểm nổi bật

- 🎨 **Giao diện hiện đại**: Material Design 3 với hỗ trợ Dark Mode
- 🔐 **Bảo mật cao**: Token-based QR với thời gian hết hạn và sử dụng một lần
- 📊 **Báo cáo đầy đủ**: Thống kê, biểu đồ và xuất dữ liệu CSV/PDF
- 📱 **Đa nền tảng**: Android, iOS, Web, Windows, macOS, Linux
- 🔄 **Hoạt động offline**: Lưu trữ dữ liệu cục bộ với SQLite
- ♿ **Tiếp cận**: Hỗ trợ đầy đủ accessibility features

## 🚀 Tính năng chính

### 👥 Quản lý người dùng
- ✅ Đăng nhập/Đăng ký với xác thực email
- ✅ Phân quyền 5 cấp độ: Admin, Creator, Approver, Viewer, User
- ✅ Quản lý mật khẩu với mã hóa SHA-256
- ✅ Quên mật khẩu và khôi phục tài khoản

### 🎓 Quản lý học tập
- ✅ Quản lý sinh viên (CRUD đầy đủ)
- ✅ Quản lý môn học và lớp học
- ✅ Quản lý buổi học với trạng thái: Chưa diễn ra / Đã hoàn thành
- ✅ Điểm danh tự động qua QR Code
- ✅ Điểm danh thủ công bởi giáo viên
- ✅ Nhập mã 4 số thay thế quét QR

### 📱 QR Code
- ✅ Tạo mã QR động với token bảo mật
- ✅ Mã 4 số thay thế (60 giây hết hạn)
- ✅ Quét QR để điểm danh tự động
- ✅ Lịch sử quét QR theo người dùng
- ✅ Bảo mật: Token hết hạn, sử dụng một lần, audit log

### 📊 Báo cáo & Thống kê
- ✅ Thống kê điểm danh theo thời gian thực
- ✅ Biểu đồ trực quan với fl_chart
- ✅ Báo cáo theo ngày/tuần/tháng
- ✅ Xuất dữ liệu CSV và PDF
- ✅ Lịch sử xuất dữ liệu với bộ lọc

### 🔄 Đồng bộ & Sao lưu
- ✅ Xuất/Nhập dữ liệu JSON
- ✅ Phát hiện và xử lý xung đột dữ liệu
- ✅ Hỗ trợ đồng bộ đa thiết bị (simulation)

### 🎨 Trải nghiệm người dùng
- ✅ Dark Mode (Light/Dark/System)
- ✅ Responsive layout (Mobile/Tablet/Desktop)
- ✅ Tìm kiếm và lọc nâng cao
- ✅ Sắp xếp dữ liệu linh hoạt
- ✅ Pagination cho danh sách dài
- ✅ Loading states và error handling

## 💻 Yêu cầu hệ thống

### Yêu cầu phát triển
- **Flutter SDK**: >= 3.10.1
- **Dart**: >= 3.10.1
- **Android Studio** / **VS Code** với Flutter extension
- **Git**

### Yêu cầu thiết bị
- **Android**: minSdkVersion 21 (Android 5.0+)
- **iOS**: 12.0+
- **Web**: Chrome, Firefox, Safari, Edge (phiên bản mới nhất)
- **Desktop**: Windows 10+, macOS 10.14+, Linux (Ubuntu 18.04+)

## 📦 Cài đặt

### 1. Clone repository

```bash
git clone <repository-url>
cd baocaocuoiky
```

### 2. Cài đặt dependencies

```bash
flutter pub get
```

### 3. Cấu hình Font cho PDF (Quan trọng)

Để PDF hiển thị đúng font chữ tiếng Việt, bạn cần thêm font Noto Sans:

1. **Tải font Noto Sans**:
   - Truy cập: https://fonts.google.com/noto/specimen/Noto+Sans
   - Tải file `NotoSans-Regular.ttf`

2. **Đặt font vào project**:
   - Copy file `NotoSans-Regular.ttf` vào thư mục `assets/fonts/`
   - Đảm bảo file có tên chính xác: `NotoSans-Regular.ttf`

3. **Xem hướng dẫn chi tiết**: [assets/fonts/README.md](assets/fonts/README.md)

> ⚠️ **Lưu ý**: Nếu không thêm font, PDF vẫn hoạt động nhưng có thể hiển thị sai một số ký tự tiếng Việt.

### 4. Chạy ứng dụng

```bash
# Chạy trên thiết bị mặc định
flutter run

# Chạy trên Android
flutter run -d android

# Chạy trên iOS
flutter run -d ios

# Chạy trên Web
flutter run -d chrome
```

### 5. Build ứng dụng

```bash
# Build APK cho Android
flutter build apk --release

# Build App Bundle cho Android
flutter build appbundle --release

# Build IPA cho iOS
flutter build ios --release

# Build Web
flutter build web --release
```

## 🔐 Tài khoản demo

Ứng dụng đi kèm với dữ liệu demo sẵn có. Bạn có thể sử dụng các tài khoản sau để đăng nhập:

| Vai trò | Email | Mật khẩu | Quyền hạn |
|---------|-------|----------|-----------|
| **Admin** | `admin@gmail.com` | `123` | Toàn quyền quản lý hệ thống |
| **Teacher** | `teacher1@gmail.com` | `123` | Quản lý lớp học và điểm danh |
| **Student** | `student1@gmail.com` | `123` | Xem lịch học và điểm danh |

> ⚠️ **Lưu ý**: Đây là tài khoản demo chỉ dùng cho mục đích phát triển và kiểm thử.

## 📖 Sử dụng

### Cho Giáo viên

1. **Đăng nhập** với tài khoản giáo viên
2. **Chọn môn học** từ danh sách môn học
3. **Chọn buổi học** cần điểm danh
4. **Tạo mã QR** hoặc **Điểm danh thủ công**
5. **Xem danh sách điểm danh** và **Xuất báo cáo**

### Cho Sinh viên

1. **Đăng nhập** với tài khoản sinh viên
2. **Xem lịch học** của các lớp đã đăng ký
3. **Quét QR Code** hoặc **Nhập mã 4 số** để điểm danh
4. **Xem lịch sử điểm danh** của bản thân

### Cho Quản trị viên

1. **Đăng nhập** với tài khoản admin
2. **Quản lý người dùng** (thêm, sửa, xóa)
3. **Quản lý sinh viên và môn học**
4. **Xem thống kê tổng quan** và **Xuất báo cáo**

## 📁 Cấu trúc dự án

```
baocaocuoiky/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── models/                      # Data models
│   │   ├── app_user.dart
│   │   ├── attendance_record.dart
│   │   ├── attendance_session.dart
│   │   ├── export_history.dart
│   │   ├── qr_token.dart
│   │   ├── session_history.dart
│   │   ├── student.dart
│   │   └── subject.dart
│   ├── database/
│   │   └── database_helper.dart     # SQLite database operations
│   ├── providers/                   # State management
│   │   ├── auth_provider.dart
│   │   └── theme_provider.dart
│   ├── screens/                     # UI screens
│   │   ├── home_screen.dart
│   │   ├── login_screen.dart
│   │   ├── students_screen.dart
│   │   ├── subjects_screen.dart
│   │   ├── qr_display_screen.dart
│   │   ├── qr_scanner_screen.dart
│   │   ├── manual_attendance_screen.dart
│   │   ├── statistics_screen.dart
│   │   ├── export_screen.dart
│   │   └── ...
│   ├── services/                    # Business logic
│   │   ├── local_auth_service.dart
│   │   ├── qr_service.dart
│   │   ├── qr_token_service.dart
│   │   ├── export_service.dart
│   │   ├── sync_service.dart
│   │   └── ...
│   ├── utils/                       # Utilities
│   │   ├── validators.dart
│   │   ├── responsive.dart
│   │   └── accessibility.dart
│   └── widgets/                     # Reusable widgets
│       ├── custom_text_field.dart
│       └── state_widgets.dart
├── test/                            # Unit & Widget tests
│   ├── models/
│   ├── utils/
│   └── widgets/
├── integration_test/                # Integration tests
│   └── app_flow_test.dart
├── android/                         # Android configuration
├── ios/                             # iOS configuration
├── web/                             # Web configuration
├── windows/                         # Windows configuration
├── macos/                           # macOS configuration
├── linux/                           # Linux configuration
├── pubspec.yaml                     # Dependencies
└── README.md                        # This file
```

## 🛠 Công nghệ sử dụng

### Framework & Language
- **Flutter** 3.10+ - Cross-platform framework
- **Dart** 3.10+ - Programming language

### State Management
- **Provider** 6.1.1 - State management solution

### Database
- **sqflite** 2.3.0 - SQLite database for Flutter
- **path** 1.8.3 - Path manipulation utilities

### Authentication & Security
- **crypto** 3.0.3 - Cryptographic functions
- **shared_preferences** 2.2.2 - Local storage

### QR Code
- **mobile_scanner** 4.0.1 - QR code scanner
- **qr_flutter** 4.1.0 - QR code generator
- **permission_handler** 11.2.0 - Permission management

### Data Visualization
- **fl_chart** 0.66.0 - Beautiful charts and graphs

### Export & Printing
- **csv** 6.0.0 - CSV file generation (với UTF-8 BOM cho Excel)
- **pdf** 3.10.7 - PDF document generation (hỗ trợ font tiếng Việt)
- **printing** 5.12.0 - Print documents
- **path_provider** 2.1.2 - File system paths
- **share_plus** 10.1.2 - Chia sẻ file CSV/PDF

### UI & UX
- **cached_network_image** 3.3.1 - Image caching
- **shimmer** 3.0.0 - Loading shimmer effect
- **intl** 0.19.0 - Internationalization and date formatting

### Testing
- **flutter_test** - Unit and widget testing
- **integration_test** - Integration testing

## 🧪 Kiểm thử

Dự án bao gồm đầy đủ các loại kiểm thử:

### Unit Tests (44 tests)
Kiểm thử các models, utilities và business logic:

```bash
flutter test
```

### Widget Tests (15 tests)
Kiểm thử các widget và UI components:

```bash
flutter test test/widgets/
```

### Integration Tests (3 flows)
Kiểm thử end-to-end các luồng chính:

```bash
flutter test integration_test/app_flow_test.dart
```

**Tổng cộng: 62 tests** ✅

### Test Coverage

Để xem coverage report:

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 📚 Tài liệu

Dự án đi kèm với tài liệu chi tiết:

- **[DOCUMENTATION.md](DOCUMENTATION.md)** - Tài liệu kỹ thuật đầy đủ
- **[DEMO_GUIDE.md](DEMO_GUIDE.md)** - Hướng dẫn demo và video
- **[MUC_KHO.md](MUC_KHO.md)** - Tài liệu các tính năng nâng cao

## 🗄 Database Schema

Hệ thống sử dụng SQLite với 8 bảng chính:

| Bảng | Mô tả |
|------|-------|
| `users` | Thông tin người dùng và phân quyền |
| `students` | Thông tin sinh viên |
| `subjects` | Thông tin môn học |
| `attendance_sessions` | Thông tin buổi học |
| `attendance_records` | Bản ghi điểm danh |
| `qr_tokens` | Token QR Code bảo mật |
| `session_history` | Lịch sử thay đổi buổi học |
| `export_history` | Lịch sử xuất dữ liệu |

**Database Version**: 9

## 🎨 Screenshots

> 📸 Screenshots sẽ được thêm vào sau

## ⚙️ Cấu hình bổ sung

### Font PDF cho tiếng Việt

Để PDF hiển thị đúng font chữ tiếng Việt, vui lòng xem hướng dẫn chi tiết tại: [assets/fonts/README.md](assets/fonts/README.md)

**Tóm tắt nhanh:**
1. Tải `NotoSans-Regular.ttf` từ Google Fonts
2. Đặt vào `assets/fonts/NotoSans-Regular.ttf`
3. Chạy `flutter pub get` và khởi động lại app

### CSV Export

File CSV được xuất với UTF-8 BOM để tương thích với Microsoft Excel. File sẽ tự động mở đúng với tiếng Việt khi mở bằng Excel.

## 🤝 Đóng góp

Chúng tôi hoan nghênh mọi đóng góp! Vui lòng làm theo các bước sau:

1. **Fork** repository
2. **Tạo branch** cho tính năng mới (`git checkout -b feature/AmazingFeature`)
3. **Commit** các thay đổi (`git commit -m 'Add some AmazingFeature'`)
4. **Push** lên branch (`git push origin feature/AmazingFeature`)
5. **Mở Pull Request**

### Quy tắc đóng góp

- Tuân thủ code style hiện tại
- Viết tests cho các tính năng mới
- Cập nhật tài liệu khi cần thiết
- Đảm bảo tất cả tests đều pass

## 📄 Giấy phép

Dự án này được phân phối dưới giấy phép MIT. Xem file [LICENSE](LICENSE) để biết thêm chi tiết.

## 👨‍💻 Tác giả

**HuyBui** - huybm.ds@gmail.com

*Báo cáo cuối kỳ - Lập trình thiết bị di động*

---

## 📞 Liên hệ

Nếu bạn có bất kỳ câu hỏi hoặc đề xuất nào, vui lòng:

- **Email**: huybm.ds@gmail.com
- **Tác giả**: HuyBui

---

<div align="center">


Made with ❤️ using Flutter

</div>
