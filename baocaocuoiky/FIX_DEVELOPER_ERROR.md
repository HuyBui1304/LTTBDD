# Hướng dẫn sửa lỗi DEVELOPER_ERROR

## Lỗi

```
E/GoogleApiManager: Failed to get service from broker.
E/GoogleApiManager: java.lang.SecurityException: Unknown calling package name 'com.google.android.gms'.
ConnectionResult{statusCode=DEVELOPER_ERROR, ...}
```

## Nguyên nhân

Lỗi này xảy ra khi **SHA-1/SHA-256 fingerprint chưa được thêm vào Firebase Console**. Firebase cần fingerprint để xác thực app.

## Giải pháp

### Bước 1: Lấy SHA Fingerprint

#### Cách 1: Dùng script (Khuyến nghị)
```bash
cd /Users/huybui/Documents/LTTBDD/baocaocuoiky
./get_sha.sh
```

#### Cách 2: Lấy thủ công
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Bạn sẽ thấy SHA-1 và SHA-256 fingerprint.

### Bước 2: Thêm SHA vào Firebase Console

1. Vào https://console.firebase.google.com
2. Chọn project: **baocaocuoiky-5851c**
3. Click vào **⚙️ Project Settings** (góc trên bên trái)
4. Scroll xuống phần **Your apps**
5. Tìm Android app: **com.example.baocaocuoiky**
6. Click **"Add fingerprint"** (hoặc icon ✏️ để edit)
7. Copy **SHA-1** từ output của script và paste vào
8. Click **"Add fingerprint"** lần nữa và thêm **SHA-256**
9. Click **"Save"**

### Bước 3: Tải lại google-services.json (Tùy chọn)

Sau khi thêm SHA, bạn có thể:
1. Click **"Download google-services.json"** trong Firebase Console
2. Thay thế file `android/app/google-services.json` hiện tại

### Bước 4: Rebuild app

```bash
flutter clean
flutter pub get
flutter run
```

## Kiểm tra

Sau khi thêm SHA và rebuild, lỗi `DEVELOPER_ERROR` sẽ biến mất.

## Lưu ý

- **Debug keystore**: SHA fingerprint ở trên là cho debug build
- **Release keystore**: Nếu build release, cần lấy SHA từ release keystore và thêm vào Firebase
- **Thời gian**: Firebase có thể mất vài phút để cập nhật cấu hình

## Nếu vẫn lỗi

1. Kiểm tra package name: `com.example.baocaocuoiky` phải khớp với Firebase Console
2. Kiểm tra google-services.json: File phải đúng và được đặt ở `android/app/google-services.json`
3. Clean và rebuild: `flutter clean && flutter pub get && flutter run`
4. Đợi vài phút: Firebase có thể cần thời gian để cập nhật

