# 📝 Tóm tắt Thay đổi Cấu trúc Dữ liệu

## ✅ Đã hoàn thành

### 1. Model Changes
- ✅ Tạo model `Subject` (Môn học) - `lib/models/subject.dart`
- ✅ Cập nhật model `AttendanceSession`:
  - Thêm `subjectId` (int, required)
  - Thêm `sessionNumber` (int, 1-9)
  - `sessionDate` giờ nullable (có thể chưa set ngày)
  - Thêm `subjectName` (display field)

### 2. Database Schema Changes
- ✅ Tăng version lên 7
- ✅ Thêm bảng `subjects` với các trường:
  - id, subjectCode (unique), subjectName, classCode
  - description, creatorId, createdAt, updatedAt
- ✅ Cập nhật bảng `attendance_sessions`:
  - Thêm `subjectId` (FK → subjects)
  - Thêm `sessionNumber` (1-9)
  - `sessionDate` giờ nullable
- ✅ Thêm indexes: idx_subjects_class, idx_subjects_creator, idx_sessions_subject

### 3. Database Operations
- ✅ CRUD cho Subject:
  - `createSubject()` - tự động tạo 9 buổi học
  - `getSubject()`, `getAllSubjects()`, `getSubjectsByCreator()`
  - `searchSubjects()`, `getSubjectByCode()`
  - `updateSubject()`, `deleteSubject()` (CASCADE delete sessions)
- ✅ `getSessionsBySubject()` - lấy danh sách buổi học theo môn
- ✅ Cập nhật `getSession()` để join với subjects table

### 4. Auto-create Sessions
- ✅ Khi tạo Subject mới → tự động tạo 9 buổi học:
  - Session code: `{subjectCode}-SES001` đến `{subjectCode}-SES009`
  - Title: "Buổi 1" đến "Buổi 9"
  - sessionNumber: 1 đến 9
  - Status: scheduled (mặc định)

---

## ⏳ Cần làm tiếp

### 1. UI Screens
- [ ] Tạo `SubjectsScreen` (thay cho SessionsScreen):
  - Hiển thị danh sách "Lớp học phần" (Subjects)
  - Có nút "Tạo lớp học phần mới"
  - Click vào Subject → mở SubjectDetailScreen

- [ ] Tạo `SubjectDetailScreen`:
  - Hiển thị 9 buổi học của môn học
  - Mỗi buổi học có:
    - Số thứ tự (Buổi 1, Buổi 2...)
    - Trạng thái
    - Ngày học (nếu đã set)
    - Nút "Tạo mã điểm danh" (thay vì tạo buổi học mới)

### 2. Update Existing Screens
- [ ] Thay đổi HomeScreen: "Buổi học" → "Lớp học phần"
- [ ] Update navigation từ SessionsScreen → SubjectsScreen
- [ ] Update các màn hình khác sử dụng sessions

### 3. QR Generation Logic
- [ ] Thay đổi: Không tạo buổi học mới
- [ ] Bấm vào buổi học → "Tạo mã điểm danh"
- [ ] Generate QR cho session đã tồn tại (không tạo mới)

### 4. Migration & Testing
- [ ] Test database migration từ version 6 → 7
- [ ] Test createSubject với auto-create 9 sessions
- [ ] Test các CRUD operations

---

## 📋 Cấu trúc mới

```
Lớp học phần (Subject)
  └── Môn học (Subject)
      └── Buổi 1 (Session 1)
      └── Buổi 2 (Session 2)
      └── ...
      └── Buổi 9 (Session 9)
```

**Flow mới:**
1. Teacher tạo "Lớp học phần" (Subject) → Tự động tạo 9 buổi học
2. Click vào Subject → Hiển thị 9 buổi học
3. Click vào buổi học → Bấm "Tạo mã điểm danh" → Generate QR

**Thay đổi so với cũ:**
- ❌ Cũ: Tạo từng buổi học riêng lẻ
- ✅ Mới: Tạo Subject → Auto 9 buổi học → Chỉ cần tạo QR khi cần

---

## 🔧 Files đã thay đổi

1. `lib/models/subject.dart` - NEW
2. `lib/models/attendance_session.dart` - UPDATED
3. `lib/database/database_helper.dart` - UPDATED (version 7, thêm subjects table, CRUD operations)

## 📁 Files cần tạo/cập nhật

1. `lib/screens/subjects_screen.dart` - NEW (thay cho sessions_screen.dart)
2. `lib/screens/subject_detail_screen.dart` - NEW
3. `lib/screens/home_screen.dart` - UPDATE (đổi "Buổi học" → "Lớp học phần")
4. Các screens khác sử dụng sessions - UPDATE

---

**Note**: Thay đổi này khá lớn, cần test kỹ database migration và các tính năng liên quan.

