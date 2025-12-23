# 📱 Hệ thống Điểm danh QR - Tài liệu Triển khai

## 📂 1. CẤU TRÚC THƯ MỤC

```
baocaocuoiky/
├── lib/
│   ├── main.dart                      # Entry point
│   ├── models/                        # Data models
│   │   ├── student.dart              # Student model
│   │   ├── attendance_session.dart   # Session model  
│   │   ├── attendance_record.dart    # Record model
│   │   ├── app_user.dart            # User model
│   │   └── session_history.dart     # Workflow history model
│   │
│   ├── database/
│   │   └── database_helper.dart     # SQLite operations
│   │
│   ├── services/                    # Business logic
│   │   ├── local_auth_service.dart # Authentication
│   │   ├── qr_service.dart         # QR generation/parsing
│   │   ├── export_service.dart     # CSV/PDF export
│   │   └── sync_service.dart       # Conflict resolution
│   │
│   ├── providers/                   # State management
│   │   └── auth_provider.dart      # Auth state
│   │
│   ├── screens/                     # UI screens
│   │   ├── login_screen.dart       # Login
│   │   ├── register_screen.dart    # Register
│   │   ├── home_screen.dart        # Dashboard
│   │   ├── students_screen.dart    # Students list
│   │   ├── student_detail_screen.dart
│   │   ├── sessions_screen.dart    # Sessions list
│   │   ├── session_detail_screen.dart
│   │   ├── session_workflow_screen.dart  # Workflow
│   │   ├── qr_display_screen.dart  # QR generator
│   │   ├── qr_scanner_screen.dart  # QR scanner
│   │   ├── qr_history_screen.dart  # QR history
│   │   ├── statistics_screen.dart   # Charts
│   │   ├── time_based_report_screen.dart # Time reports
│   │   ├── export_screen.dart       # Export options
│   │   └── conflict_resolution_screen.dart # Sync conflicts
│   │
│   ├── widgets/                     # Reusable widgets
│   │   ├── state_widgets.dart      # Loading/Empty/Error
│   │   └── custom_text_field.dart  # Input field
│   │
│   └── utils/
│       └── validators.dart          # Input validation
│
├── test/                            # Tests
│   ├── models/                      # Model tests
│   ├── utils/                       # Validator tests
│   └── widgets/                     # Widget tests
│
└── pubspec.yaml                     # Dependencies
```

---

## 🗄️ 2. MÔ HÌNH DỮ LIỆU (DATABASE SCHEMA)

### 2.1. Students Table
```sql
CREATE TABLE students (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  studentId TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  classCode TEXT,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
)
```

### 2.2. Attendance Sessions Table
```sql
CREATE TABLE attendance_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sessionCode TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  description TEXT,
  classCode TEXT NOT NULL,
  sessionDate TEXT NOT NULL,
  location TEXT,
  status TEXT NOT NULL,
  approvedBy INTEGER,
  approvedAt TEXT,
  completedBy INTEGER,
  completedAt TEXT,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
)
```

### 2.3. Attendance Records Table
```sql
CREATE TABLE attendance_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sessionId INTEGER NOT NULL,
  studentId INTEGER NOT NULL,
  status TEXT NOT NULL,
  checkInTime TEXT,
  note TEXT,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  FOREIGN KEY (sessionId) REFERENCES attendance_sessions(id),
  FOREIGN KEY (studentId) REFERENCES students(id)
)
```

### 2.4. Users Table (Authentication)
```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uid TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL UNIQUE,
  displayName TEXT NOT NULL,
  passwordHash TEXT NOT NULL,
  photoUrl TEXT,
  role TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  lastLogin TEXT
)
```

### 2.5. Session History Table (Workflow)
```sql
CREATE TABLE session_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sessionId INTEGER NOT NULL,
  userId INTEGER NOT NULL,
  action TEXT NOT NULL,
  oldStatus TEXT,
  newStatus TEXT,
  note TEXT,
  createdAt TEXT NOT NULL,
  FOREIGN KEY (sessionId) REFERENCES attendance_sessions(id),
  FOREIGN KEY (userId) REFERENCES users(id)
)
```

### 2.6. QR Scan History Table
```sql
CREATE TABLE qr_scan_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  userId INTEGER NOT NULL,
  sessionId INTEGER,
  qrData TEXT NOT NULL,
  scanType TEXT NOT NULL,
  scannedAt TEXT NOT NULL,
  note TEXT,
  FOREIGN KEY (userId) REFERENCES users(id),
  FOREIGN KEY (sessionId) REFERENCES attendance_sessions(id)
)
```

---

## 🔄 3. SƠ ĐỒ LUỒNG HOẠT ĐỘNG

### 3.1. Luồng Đăng nhập
```
[Start] → Enter Email/Password 
       → Validate Input 
       → Hash Password 
       → Check Database 
       → [Success] → Save Session → Navigate to Home
       → [Fail] → Show Error Message
```

### 3.2. Luồng Workflow Duyệt Buổi học
```
[Draft] → Submit for Approval → [Pending]
       → Admin Review
       → [Approve] → [Scheduled] → [Start] → [Ongoing] → [Complete] → [Completed]
       → [Reject] → [Draft]
       → [Cancel] → [Cancelled]
```

### 3.3. Luồng Điểm danh QR
```
Teacher: Create Session → Generate QR Code → Display
Student: Open Scanner → Scan QR → Validate → Mark Attendance → Save Record
System: Log History → Update Stats → Notify
```

### 3.4. Luồng Đồng bộ với Xung đột
```
[Import Data] → Detect Conflicts 
             → [No Conflicts] → Import Directly
             → [Has Conflicts] → Show Resolution Screen
                              → User Chooses Version
                              → Apply Resolution
                              → Complete Import
```

---

## 🎯 4. KỊCH BẢN SỬ DỤNG (USE CASES)

### 4.1. UC-01: Đăng nhập hệ thống
**Actor:** User  
**Precondition:** App đã cài đặt  
**Flow:**
1. User mở app
2. Nhập email và password
3. Nhấn "Đăng nhập"
4. Hệ thống kiểm tra thông tin
5. Chuyển đến Home Screen

**Alternative:** 
- Email/Password sai → Hiển thị lỗi
- Chưa có tài khoản → Chuyển đến Register

---

### 4.2. UC-02: Tạo buổi học mới
**Actor:** Teacher/Admin  
**Precondition:** Đã đăng nhập  
**Flow:**
1. Vào màn hình "Buổi học"
2. Nhấn nút "+"
3. Điền thông tin: Tiêu đề, Mã lớp, Ngày giờ, Địa điểm
4. Nhấn "Lưu"
5. Buổi học được tạo với status = Draft
6. (Optional) Submit for Approval

---

### 4.3. UC-03: Quét QR điểm danh
**Actor:** Student  
**Precondition:** Đã có buổi học với QR code  
**Flow:**
1. Teacher hiển thị QR code buổi học
2. Student mở app → Quét QR
3. Camera mở → Đưa QR vào khung
4. Hệ thống validate QR
5. Tạo attendance record
6. Hiển thị "Điểm danh thành công"

---

### 4.4. UC-04: Xem báo cáo theo thời gian
**Actor:** Teacher/Admin  
**Precondition:** Đã có dữ liệu điểm danh  
**Flow:**
1. Vào "Báo cáo theo thời gian"
2. Chọn kỳ: Ngày/Tuần/Tháng
3. Chọn ngày cụ thể (prev/next)
4. Xem thống kê
5. So sánh với kỳ trước
6. (Optional) Xuất báo cáo

---

### 4.5. UC-05: Giải quyết xung đột đồng bộ
**Actor:** User  
**Precondition:** Import data có conflicts  
**Flow:**
1. Import file JSON
2. Hệ thống phát hiện xung đột
3. Hiển thị màn hình "Giải quyết xung đột"
4. User xem từng conflict (Local vs Remote)
5. Chọn version muốn giữ
6. Nhấn "Áp dụng"
7. Hoàn tất import

---

## 🛠️ 5. HƯỚNG DẪN TRIỂN KHAI

### 5.1. Yêu cầu Hệ thống
- Flutter SDK: ≥ 3.10.1
- Dart SDK: ≥ 3.0.0
- Android: minSdk 21 (Android 5.0+)
- iOS: 11.0+

### 5.2. Cài đặt Dependencies
```bash
flutter pub get
```

### 5.3. Chạy ứng dụng
```bash
# List devices
flutter devices

# Run on specific device
flutter run -d <device_id>

# Run in debug mode
flutter run --debug

# Run in release mode
flutter run --release
```

### 5.4. Chạy Tests
```bash
# All tests
flutter test

# Specific test file
flutter test test/models/student_test.dart

# With coverage
flutter test --coverage
```

### 5.5. Build APK/IPA
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 🔐 6. BẢO MẬT

### 6.1. Password Hashing
- Sử dụng SHA-256 để hash password
- Không lưu plain text password

### 6.2. Session Management
- SharedPreferences lưu user UID
- Auto-logout khi token expire

### 6.3. QR Code Security
- QR có timestamp để validate
- Mỗi QR chỉ dùng trong 24h
- Log lịch sử quét

---

## 📊 7. PERFORMANCE OPTIMIZATION

### 7.1. Infinite Scroll
- Load 20 items mỗi lần
- Lazy loading khi scroll xuống cuối

### 7.2. Database Indexing
- Index trên userId, sessionId
- Tối ưu query joins

### 7.3. Caching
- Cache user session
- Cache recent data

---

## 🐛 8. TROUBLESHOOTING

### 8.1. Lỗi Database
```
Error: Database locked
Fix: Close app và restart
```

### 8.2. Lỗi QR Scanner
```
Error: Camera permission denied
Fix: Settings → Permissions → Camera → Allow
```

### 8.3. Lỗi Export
```
Error: Write permission denied
Fix: Request storage permission trong AndroidManifest.xml
```

---

## 📞 9. CONTACT & SUPPORT

- Developer: [Your Name]
- Email: [Your Email]
- GitHub: [Repository URL]

---

**Version:** 1.0.0  
**Last Updated:** December 2024

