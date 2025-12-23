import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Network service với error recovery và retry mechanism
class NetworkService {
  static final NetworkService instance = NetworkService._init();
  
  NetworkService._init();

  /// Check if device has internet connection
  Future<bool> hasConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Simulate cloud API call với retry mechanism
  Future<T> callWithRetry<T>({
    required Future<T> Function() apiCall,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        // Check connection before attempting
        if (attempt > 0) {
          final hasConn = await hasConnection();
          if (!hasConn) {
            throw NetworkException(
              'Không có kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.',
              type: NetworkExceptionType.noConnection,
            );
          }
        }

        // Attempt API call
        return await apiCall();
      } catch (e) {
        attempt++;
        
        // Check if should retry
        if (shouldRetry != null && !shouldRetry(e)) {
          rethrow;
        }

        // Check if max retries reached
        if (attempt >= maxRetries) {
          if (e is NetworkException) {
            rethrow;
          }
          throw NetworkException(
            'Không thể kết nối sau $maxRetries lần thử. Vui lòng thử lại sau.',
            originalError: e,
            type: NetworkExceptionType.maxRetriesExceeded,
          );
        }

        // Exponential backoff
        debugPrint('Retry attempt $attempt/$maxRetries after ${delay.inSeconds}s');
        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }

    throw NetworkException(
      'Unexpected error in retry mechanism',
      type: NetworkExceptionType.unknown,
    );
  }

  /// Upload data to cloud (simulated)
  Future<Map<String, dynamic>> uploadToCloud(Map<String, dynamic> data) async {
    return await callWithRetry(
      apiCall: () async {
        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Simulate occasional failures (10% chance)
        if (DateTime.now().millisecond % 10 == 0) {
          throw NetworkException(
            'Lỗi kết nối đến server. Vui lòng thử lại.',
            type: NetworkExceptionType.serverError,
          );
        }

        // Simulate successful upload
        return {
          'success': true,
          'uploadedAt': DateTime.now().toIso8601String(),
          'message': 'Đồng bộ thành công',
        };
      },
      shouldRetry: (error) {
        // Retry on network errors, not on validation errors
        if (error is NetworkException) {
          return error.type != NetworkExceptionType.validationError;
        }
        return true;
      },
    );
  }

  /// Download data from cloud (simulated)
  Future<Map<String, dynamic>> downloadFromCloud() async {
    return await callWithRetry(
      apiCall: () async {
        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Simulate occasional failures (10% chance)
        if (DateTime.now().millisecond % 10 == 0) {
          throw NetworkException(
            'Lỗi kết nối đến server. Vui lòng thử lại.',
            type: NetworkExceptionType.serverError,
          );
        }

        // Return empty data (in real app, this would fetch from API)
        return {
          'success': true,
          'data': {},
          'downloadedAt': DateTime.now().toIso8601String(),
        };
      },
    );
  }
}

/// Network exception types
enum NetworkExceptionType {
  noConnection,
  serverError,
  timeout,
  maxRetriesExceeded,
  validationError,
  unknown,
}

/// Custom network exception
class NetworkException implements Exception {
  final String message;
  final NetworkExceptionType type;
  final dynamic originalError;
  final StackTrace? stackTrace;

  NetworkException(
    this.message, {
    required this.type,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'NetworkException: $message (type: $type)';
  }

  bool get isRetryable {
    return type == NetworkExceptionType.serverError ||
        type == NetworkExceptionType.timeout ||
        type == NetworkExceptionType.noConnection;
  }
}

