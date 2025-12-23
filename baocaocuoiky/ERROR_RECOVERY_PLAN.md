# 🔄 Kế hoạch Phục hồi Lỗi (Error Recovery Plan)

## 📋 Tổng quan

Tài liệu này mô tả chiến lược xử lý lỗi và phục hồi khi có sự cố về mạng, API, hoặc đám mây trong ứng dụng Điểm danh QR.

---

## 🎯 Nguyên tắc Chính

1. **Graceful Degradation**: Ứng dụng vẫn hoạt động offline
2. **Automatic Retry**: Tự động thử lại với exponential backoff
3. **Queue Management**: Lưu operations vào queue khi mất mạng
4. **User Feedback**: Thông báo rõ ràng cho người dùng về trạng thái

---

## 🔧 Các Component

### 1. NetworkService (`lib/services/network_service.dart`)

**Chức năng:**
- Kiểm tra kết nối mạng
- Retry mechanism với exponential backoff
- Xử lý các loại lỗi network khác nhau

**Retry Strategy:**
- **Max retries**: 3 lần
- **Initial delay**: 1 giây
- **Backoff multiplier**: 2.0 (1s → 2s → 4s)
- **Retryable errors**: Server errors, timeouts, no connection
- **Non-retryable errors**: Validation errors

**Ví dụ:**
```dart
final result = await NetworkService.instance.callWithRetry(
  apiCall: () => uploadData(data),
  maxRetries: 3,
  shouldRetry: (error) => error is NetworkException && error.isRetryable,
);
```

### 2. OfflineQueueService (`lib/services/offline_queue_service.dart`)

**Chức năng:**
- Lưu operations vào queue khi mất mạng
- Xử lý queue khi có mạng trở lại
- Quản lý retry count (max 10 lần)
- Lưu trữ last sync time

**Queue Operations:**
- `sync_upload`: Đồng bộ lên cloud
- `sync_download`: Đồng bộ từ cloud

**Flow:**
```
1. Operation fails (no network)
2. Add to queue với timestamp
3. Background process kiểm tra network
4. Khi có network → Process queue
5. Success → Remove from queue
6. Fail → Increment retry count
7. Max retries → Remove from queue (log error)
```

### 3. SyncService (`lib/services/sync_service.dart`)

**Chức năng:**
- Đồng bộ dữ liệu với cloud
- Tích hợp với NetworkService và OfflineQueueService
- Xử lý conflict resolution

**Sync Flow:**
```
1. Check network connection
2. If offline → Queue operation
3. If online → Try sync với retry
4. On failure → Queue for later
5. Update last sync time on success
```

---

## 📊 Error Types & Handling

### NetworkException Types

| Type | Description | Retryable | Action |
|------|-------------|-----------|--------|
| `noConnection` | Không có kết nối mạng | ✅ Yes | Queue operation |
| `serverError` | Lỗi từ server (500, 502, etc.) | ✅ Yes | Retry với backoff |
| `timeout` | Request timeout | ✅ Yes | Retry với backoff |
| `maxRetriesExceeded` | Đã thử quá số lần cho phép | ❌ No | Queue hoặc show error |
| `validationError` | Lỗi validation | ❌ No | Show error immediately |
| `unknown` | Lỗi không xác định | ✅ Yes | Queue operation |

---

## 🔄 Retry Mechanism

### Exponential Backoff

```
Attempt 1: Wait 1s
Attempt 2: Wait 2s (1s * 2.0)
Attempt 3: Wait 4s (2s * 2.0)
```

**Code:**
```dart
Duration delay = initialDelay; // 1s
for (int attempt = 0; attempt < maxRetries; attempt++) {
  try {
    return await apiCall();
  } catch (e) {
    if (attempt < maxRetries - 1) {
      await Future.delayed(delay);
      delay = Duration(milliseconds: delay.inMilliseconds * 2);
    }
  }
}
```

---

## 📱 Offline Queue Management

### Adding to Queue

```dart
await OfflineQueueService.instance.enqueueOperation(
  operation: 'sync_upload',
  data: exportData,
);
```

### Processing Queue

```dart
final result = await OfflineQueueService.instance.processQueue();

if (result.success) {
  print('Processed ${result.processedCount} operations');
} else {
  print('Failed ${result.failedCount} operations');
}
```

### Queue Cleanup

- Operations với retry count > 10 sẽ bị xóa
- User có thể manually clear queue
- Queue được lưu trong SharedPreferences (persistent)

---

## 🚨 Error Recovery Scenarios

### Scenario 1: Mất mạng khi đang đồng bộ

**Flow:**
1. User nhấn "Đồng bộ"
2. Check network → ❌ No connection
3. Operation được thêm vào queue
4. Show message: "Đã lưu vào hàng đợi. Sẽ đồng bộ khi có mạng."

**Recovery:**
- Background service kiểm tra network định kỳ
- Khi có mạng → Tự động process queue
- Show notification: "Đã đồng bộ thành công"

### Scenario 2: Server error (500)

**Flow:**
1. API call → Server returns 500
2. Retry với exponential backoff (3 lần)
3. Nếu vẫn fail → Queue operation
4. Show message: "Lỗi server. Đã lưu vào hàng đợi."

**Recovery:**
- Background retry khi có mạng
- Max 10 retries trong queue
- Nếu vẫn fail → Log error, notify admin

### Scenario 3: Timeout

**Flow:**
1. API call → Timeout sau 30s
2. Retry với backoff
3. Nếu vẫn timeout → Queue

**Recovery:**
- Same as server error
- Consider increasing timeout for slow connections

### Scenario 4: Validation Error

**Flow:**
1. API call → Validation error (400)
2. ❌ Không retry (không phải network issue)
3. Show error immediately
4. User phải fix data và thử lại

---

## 🔍 Monitoring & Logging

### Metrics to Track

1. **Sync Success Rate**: % syncs thành công
2. **Average Retry Count**: Số lần retry trung bình
3. **Queue Size**: Số operations trong queue
4. **Last Sync Time**: Thời gian đồng bộ cuối cùng
5. **Network Availability**: % thời gian có mạng

### Logging

```dart
// Log sync attempts
debugPrint('Sync attempt $attempt/$maxRetries');

// Log queue operations
debugPrint('Queued operation: $operation');

// Log errors
debugPrint('Sync error: $error');
```

---

## 📋 Best Practices

1. **Always check network before API calls**
   ```dart
   final hasConnection = await NetworkService.instance.hasConnection();
   if (!hasConnection) {
     // Queue operation
   }
   ```

2. **Use retry for network operations**
   ```dart
   await NetworkService.instance.callWithRetry(apiCall: ...);
   ```

3. **Queue operations when offline**
   ```dart
   await OfflineQueueService.instance.enqueueOperation(...);
   ```

4. **Process queue on app start and network reconnect**
   ```dart
   await OfflineQueueService.instance.processQueue();
   ```

5. **Provide user feedback**
   - Show loading indicators
   - Display error messages
   - Notify when queue is processed

---

## 🧪 Testing Error Scenarios

### Unit Tests

- Test retry mechanism với different error types
- Test queue enqueue/dequeue
- Test network check

### Integration Tests

- Test sync flow với network interruption
- Test queue processing
- Test error recovery

### Manual Testing

1. Enable airplane mode → Try sync → Check queue
2. Disable airplane mode → Check auto-process queue
3. Simulate server errors → Check retry logic

---

## 📚 References

- `lib/services/network_service.dart` - Network service với retry
- `lib/services/offline_queue_service.dart` - Offline queue management
- `lib/services/sync_service.dart` - Sync service với error recovery

---

## ✅ Checklist

- [x] NetworkService với retry mechanism
- [x] OfflineQueueService để quản lý queue
- [x] Exponential backoff strategy
- [x] Error type classification
- [x] Queue processing on network reconnect
- [x] User feedback mechanisms
- [x] Documentation

---

**Version**: 1.0  
**Last Updated**: 2024

