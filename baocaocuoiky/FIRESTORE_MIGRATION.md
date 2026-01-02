# Hướng dẫn chuyển đổi từ Realtime Database sang Firestore

## Tổng quan

Project đã được chuyển đổi từ Firebase Realtime Database sang Cloud Firestore.

## Những thay đổi chính

1. **Package mới**: Đã thay `firebase_database` bằng `cloud_firestore` trong `pubspec.yaml`
2. **Service mới**: `FirebaseDatabaseService` giờ sử dụng Firestore thay vì Realtime Database
3. **Realtime listeners**: `RealtimeNotificationService` đã được cập nhật để sử dụng Firestore snapshots

## Cấu trúc Collections trong Firestore

- `students` - Danh sách sinh viên
- `subjects` - Danh sách môn học
- `attendance_sessions` - Các buổi điểm danh
- `attendance_records` - Bản ghi điểm danh
- `users` - Người dùng
- `qr_tokens` - QR tokens
- `qr_scan_history` - Lịch sử quét QR
- `session_history` - Lịch sử buổi học
- `export_history` - Lịch sử xuất file

## Firestore Indexes cần thiết

Một số queries sử dụng cả `where` và `orderBy` trên các field khác nhau sẽ yêu cầu composite index. Firestore sẽ tự động hướng dẫn tạo index khi chạy query lần đầu, hoặc bạn có thể tạo thủ công trong Firebase Console.

### Các index cần tạo:

1. **attendance_sessions**
   - Collection: `attendance_sessions`
   - Fields: `creatorId` (Ascending), `createdAt` (Descending)

2. **attendance_sessions**
   - Collection: `attendance_sessions`
   - Fields: `subjectId` (Ascending), `createdAt` (Descending)

3. **attendance_sessions**
   - Collection: `attendance_sessions`
   - Fields: `classCode` (Ascending), `createdAt` (Descending)

4. **attendance_records**
   - Collection: `attendance_records`
   - Fields: `studentId` (Ascending), `checkInTime` (Descending)

5. **qr_scan_history**
   - Collection: `qr_scan_history`
   - Fields: `userId` (Ascending), `scannedAt` (Descending)

6. **session_history**
   - Collection: `session_history`
   - Fields: `sessionId` (Ascending), `createdAt` (Descending)

7. **export_history**
   - Collection: `export_history`
   - Fields: `userId` (Ascending), `exportedAt` (Descending)

## Cách tạo index

1. Vào Firebase Console → Firestore Database → Indexes
2. Click "Create Index"
3. Chọn collection và các fields theo danh sách trên
4. Hoặc khi chạy app, Firestore sẽ tự động hiển thị link để tạo index

## Lưu ý

- Tất cả dữ liệu cũ trong Realtime Database sẽ không tự động chuyển sang Firestore
- Cần migrate dữ liệu thủ công nếu có dữ liệu quan trọng
- Interface của service vẫn giữ nguyên, code hiện tại không cần thay đổi

## User mẫu

App sẽ tự động tạo user mẫu khi khởi động lần đầu:

### 1. Admin (Quản trị viên) - 1 user
- **Email**: `admin@gmail.com`
- **Password**: `admin123`
- **Quyền**: Toàn quyền quản trị

### 2. Teacher (Giáo viên) - 5 users
- **Email**: `teacher@gmail.com`, `teacher2@gmail.com`, ..., `teacher5@gmail.com`
- **Password**: `teacher123` (cho tất cả)
- **Quyền**: Tạo lớp học, QR, xuất file

### 3. Student (Sinh viên) - 15 users
- **Email**: `student@gmail.com`, `student2@gmail.com`, ..., `student15@gmail.com`
- **Password**: `student123` (cho tất cả)
- **Quyền**: Quét QR, xem lịch sử

> **Lưu ý**: 
> - Các user này sẽ được tạo tự động khi app khởi động. Nếu user đã tồn tại, app sẽ bỏ qua và không tạo lại.
> - **Phân quyền tự động**: Role được xác định dựa vào prefix của email:
>   - Email bắt đầu bằng `admin` → Quản trị viên
>   - Email bắt đầu bằng `teacher` → Giáo viên
>   - Email bắt đầu bằng `student` → Sinh viên
>   - Mặc định → Sinh viên

## Dữ liệu môn học mẫu

App sẽ tự động tạo 10 môn học mẫu khi khởi động lần đầu (sau khi đã tạo users):

1. **LTTBDD** - Lập trình thiết bị di động (LTTBDD2024)
2. **CTDLGT** - Cấu trúc dữ liệu và giải thuật (CTDLGT2024)
3. **CSDL** - Cơ sở dữ liệu (CSDL2024)
4. **LTW** - Lập trình Web (LTW2024)
5. **MMT** - Mạng máy tính (MMT2024)
6. **HTTT** - Hệ thống thông tin (HTTT2024)
7. **AI** - Trí tuệ nhân tạo (AI2024)
8. **ATTT** - An toàn thông tin (ATTT2024)
9. **PMUD** - Phát triển phần mềm ứng dụng (PMUD2024)
10. **CNPM** - Công nghệ phần mềm (CNPM2024)

> **Lưu ý**: 
> - Các môn học sẽ được phân bổ đều cho các giáo viên (teacher users)
> - Nếu đã có môn học trong database, app sẽ bỏ qua và không tạo lại
> - Mỗi môn học sẽ có creatorId là một trong các teacher đã được tạo

## Testing

Sau khi chuyển đổi, hãy test các chức năng sau:
- Đăng nhập với các user mẫu ở trên
- Tạo/đọc/cập nhật/xóa sinh viên
- Tạo/đọc/cập nhật/xóa môn học
- Tạo/đọc/cập nhật/xóa buổi điểm danh
- Tạo/đọc/cập nhật/xóa bản ghi điểm danh
- Quét QR code
- Realtime notifications

