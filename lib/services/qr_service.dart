import 'dart:convert';
import '../models/attendance_session.dart';

class QRService {
  static final QRService instance = QRService._init();
  
  QRService._init();

  // Generate QR data for attendance session
  String generateSessionQRData(AttendanceSession session) {
    final data = {
      'type': 'attendance_session',
      'sessionId': session.id,
      'sessionCode': session.sessionCode,
      'title': session.title,
      'classCode': session.classCode,
      'sessionDate': session.sessionDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'timestamp': DateTime.now().toIso8601String(),
    };
    return jsonEncode(data);
  }

  // Parse QR data
  Map<String, dynamic>? parseQRData(String qrData) {
    try {
      final data = jsonDecode(qrData) as Map<String, dynamic>;
      // Support attendance_token, attendance_session, and student QR types
      if (data['type'] == 'attendance_token' || 
          data['type'] == 'attendance_session' || 
          data['type'] == 'student') {
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Validate QR code (check if not expired, etc.)
  bool validateQRCode(Map<String, dynamic> qrData, {Duration? validDuration}) {
    try {
      final timestamp = DateTime.parse(qrData['timestamp'] as String);
      final now = DateTime.now();
      
      // Default valid duration: 24 hours
      final duration = validDuration ?? const Duration(hours: 24);
      
      return now.difference(timestamp) < duration;
    } catch (e) {
      return false;
    }
  }

  // Generate student QR data (for identification)
  String generateStudentQRData(int studentId, String studentCode) {
    final data = {
      'type': 'student',
      'studentId': studentId,
      'studentCode': studentCode,
      'timestamp': DateTime.now().toIso8601String(),
    };
    return jsonEncode(data);
  }
}

