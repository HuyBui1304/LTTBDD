# Hướng dẫn xử lý Firebase Rate Limiting

## Vấn đề

Firebase đã chặn device của bạn do phát hiện hoạt động bất thường:
- Tạo quá nhiều users trong thời gian ngắn
- Xóa và tạo lại users nhiều lần
- Firebase coi đây là hoạt động spam/bot

## Giải pháp

### 1. Đợi để Firebase tự động mở khóa (Khuyến nghị)

**Thời gian đợi**: 10-30 phút (có thể lâu hơn tùy vào mức độ)

Firebase sẽ tự động mở khóa sau một khoảng thời gian. Trong lúc này:
- Không tạo/xóa users
- Không chạy lại app nhiều lần
- Đợi vài phút rồi thử lại

### 2. Tạo users thủ công từng cái một

Sau khi Firebase mở khóa, bạn có thể:

#### Cách 1: Tạo qua Firebase Console
1. Vào Firebase Console → Authentication → Users
2. Click "Add user"
3. Nhập email và password
4. Tạo từng user một, đợi vài giây giữa mỗi lần

#### Cách 2: Tạo qua app (chậm)
1. Đăng nhập với admin account
2. Vào "Quản lý tài khoản"
3. Click button "+" để tạo dữ liệu mẫu
4. Quá trình sẽ tự động với delay lớn (2 giây/user)

#### Cách 3: Tạo qua màn hình đăng ký
1. Dùng màn hình Register trong app
2. Tạo từng user một
3. Đợi vài giây giữa mỗi lần đăng ký

### 3. Tạo users cần thiết nhất trước

Thay vì tạo tất cả, chỉ tạo những users cần thiết:

**Tối thiểu cần có:**
- 1 Admin: `admin@gmail.com` / `admin123`
- 1-2 Teachers: `teacher@gmail.com` / `teacher123`
- 1-2 Students: `student@gmail.com` / `student123`

Sau đó có thể tạo thêm users khi cần.

## Danh sách users cần tạo

### Admin (Bắt buộc)
- Email: `admin@gmail.com`
- Password: `admin123`
- Role: Admin

### Teachers (Tùy chọn - tạo 1-5)
- `teacher@gmail.com` / `teacher123`
- `teacher2@gmail.com` / `teacher123`
- `teacher3@gmail.com` / `teacher123`
- `teacher4@gmail.com` / `teacher123`
- `teacher5@gmail.com` / `teacher123`

### Students (Tùy chọn - tạo 1-15)
- `student@gmail.com` / `student123`
- `student2@gmail.com` / `student123`
- ... (tối đa 15)

## Lưu ý quan trọng

1. **Không tạo/xóa users liên tục**: Firebase sẽ chặn lại
2. **Đợi giữa các lần tạo**: Tối thiểu 2-3 giây giữa mỗi user
3. **Không xóa users nếu không cần**: Việc xóa cũng bị tính vào rate limit
4. **Sử dụng Firebase Console**: An toàn hơn khi tạo nhiều users
5. **Tạo từng batch nhỏ**: Tạo 2-3 users, đợi 5 phút, rồi tạo tiếp

## Kiểm tra trạng thái

Nếu vẫn bị chặn, bạn sẽ thấy lỗi:
```
We have blocked all requests from this device due to unusual activity. Try again later.
```

**Giải pháp**: Đợi 15-30 phút rồi thử lại.

## Tạo users qua Firebase Console (Khuyến nghị)

1. Vào https://console.firebase.google.com
2. Chọn project của bạn
3. Vào Authentication → Users
4. Click "Add user"
5. Nhập email và password
6. Click "Add user"
7. Lặp lại cho các users khác (đợi vài giây giữa mỗi lần)

Sau khi tạo xong trong Firebase Console, users sẽ tự động có trong Firestore khi họ đăng nhập lần đầu (role sẽ được set dựa vào email prefix).

