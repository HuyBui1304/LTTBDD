import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'network_service.dart';

/// Service để quản lý offline queue - lưu các operations khi mất mạng
class OfflineQueueService {
  static final OfflineQueueService instance = OfflineQueueService._init();
  final NetworkService _networkService = NetworkService.instance;
  
  static const String _queueKey = 'offline_queue';
  static const String _lastSyncKey = 'last_sync_time';

  OfflineQueueService._init();

  /// Add operation to offline queue
  Future<void> enqueueOperation({
    required String operation, // 'sync_upload', 'sync_download'
    required Map<String, dynamic> data,
    DateTime? timestamp,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey) ?? '[]';
      final queue = List<Map<String, dynamic>>.from(jsonDecode(queueJson));

      queue.add({
        'operation': operation,
        'data': data,
        'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
        'retryCount': 0,
      });

      await prefs.setString(_queueKey, jsonEncode(queue));
    } catch (e) {
      throw 'Lỗi lưu operation vào queue: $e';
    }
  }

  /// Get all queued operations
  Future<List<QueuedOperation>> getQueuedOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey) ?? '[]';
      final queue = List<Map<String, dynamic>>.from(jsonDecode(queueJson));

      return queue.map((item) => QueuedOperation.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Process queued operations when network is available
  Future<QueueProcessResult> processQueue() async {
    final hasConnection = await _networkService.hasConnection();
    if (!hasConnection) {
      return QueueProcessResult(
        success: false,
        message: 'Không có kết nối mạng',
        processedCount: 0,
        failedCount: 0,
      );
    }

    final operations = await getQueuedOperations();
    if (operations.isEmpty) {
      return QueueProcessResult(
        success: true,
        message: 'Không có operations nào cần xử lý',
        processedCount: 0,
        failedCount: 0,
      );
    }

    int processed = 0;
    int failed = 0;
    final errors = <String>[];

    for (final operation in operations) {
      try {
        bool success = false;

        switch (operation.operation) {
          case 'sync_upload':
            await _networkService.uploadToCloud(operation.data);
            success = true;
            break;
          case 'sync_download':
            final result = await _networkService.downloadFromCloud();
            // In real app, would import the data
            success = result['success'] == true;
            break;
          default:
            success = false;
        }

        if (success) {
          processed++;
          await removeOperation(operation);
        } else {
          failed++;
          await incrementRetryCount(operation);
        }
      } catch (e) {
        failed++;
        errors.add('${operation.operation}: $e');
        await incrementRetryCount(operation);
      }
    }

    // Update last sync time if any operations succeeded
    if (processed > 0) {
      await updateLastSyncTime();
    }

    return QueueProcessResult(
      success: processed > 0,
      message: 'Đã xử lý $processed operations, thất bại $failed',
      processedCount: processed,
      failedCount: failed,
      errors: errors,
    );
  }

  /// Remove operation from queue
  Future<void> removeOperation(QueuedOperation operation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey) ?? '[]';
      final queue = List<Map<String, dynamic>>.from(jsonDecode(queueJson));

      queue.removeWhere((item) =>
          item['timestamp'] == operation.timestamp.toIso8601String() &&
          item['operation'] == operation.operation);

      await prefs.setString(_queueKey, jsonEncode(queue));
    } catch (e) {
      // Ignore errors when removing
    }
  }

  /// Increment retry count for an operation
  Future<void> incrementRetryCount(QueuedOperation operation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey) ?? '[]';
      final queue = List<Map<String, dynamic>>.from(jsonDecode(queueJson));

      for (var item in queue) {
        if (item['timestamp'] == operation.timestamp.toIso8601String() &&
            item['operation'] == operation.operation) {
          item['retryCount'] = (item['retryCount'] ?? 0) + 1;
          break;
        }
      }

      // Remove operations with too many retries (more than 10)
      queue.removeWhere((item) => (item['retryCount'] ?? 0) > 10);

      await prefs.setString(_queueKey, jsonEncode(queue));
    } catch (e) {
      // Ignore errors
    }
  }

  /// Clear all queued operations
  Future<void> clearQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_queueKey);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncTimeStr = prefs.getString(_lastSyncKey);
      if (syncTimeStr != null) {
        return DateTime.parse(syncTimeStr);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update last sync time
  Future<void> updateLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Ignore errors
    }
  }

  /// Get queue size
  Future<int> getQueueSize() async {
    final operations = await getQueuedOperations();
    return operations.length;
  }
}

/// Represents a queued operation
class QueuedOperation {
  final String operation;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  QueuedOperation({
    required this.operation,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  factory QueuedOperation.fromMap(Map<String, dynamic> map) {
    return QueuedOperation(
      operation: map['operation'] as String,
      data: Map<String, dynamic>.from(map['data'] as Map),
      timestamp: DateTime.parse(map['timestamp'] as String),
      retryCount: map['retryCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'operation': operation,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
    };
  }
}

/// Result of processing queue
class QueueProcessResult {
  final bool success;
  final String message;
  final int processedCount;
  final int failedCount;
  final List<String> errors;

  QueueProcessResult({
    required this.success,
    required this.message,
    required this.processedCount,
    required this.failedCount,
    this.errors = const [],
  });
}

