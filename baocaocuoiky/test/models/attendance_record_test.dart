import 'package:flutter_test/flutter_test.dart';
import 'package:baocaocuoiky/models/attendance_record.dart';

void main() {
  group('AttendanceRecord Model Tests', () {
    test('AttendanceRecord should be created with required fields', () {
      // Arrange & Act
      final record = AttendanceRecord(
        sessionId: 1,
        studentId: 1,
      );

      // Assert
      expect(record.sessionId, 1);
      expect(record.studentId, 1);
      expect(record.status, AttendanceStatus.present);
      expect(record.note, null);
      expect(record.id, null);
    });

    test('AttendanceRecord should be created with all fields', () {
      // Arrange
      final checkInTime = DateTime(2024, 1, 15, 8, 5);

      // Act
      final record = AttendanceRecord(
        id: 1,
        sessionId: 1,
        studentId: 1,
        status: AttendanceStatus.late,
        checkInTime: checkInTime,
        note: 'Đến muộn do kẹt xe',
        studentName: 'Nguyen Van A',
        studentCode: 'SV001',
      );

      // Assert
      expect(record.id, 1);
      expect(record.sessionId, 1);
      expect(record.studentId, 1);
      expect(record.status, AttendanceStatus.late);
      expect(record.checkInTime, checkInTime);
      expect(record.note, 'Đến muộn do kẹt xe');
      expect(record.studentName, 'Nguyen Van A');
      expect(record.studentCode, 'SV001');
    });

    test('AttendanceRecord toMap should convert to Map correctly', () {
      // Arrange
      final now = DateTime.now();
      final checkInTime = DateTime(2024, 1, 15, 8, 5);
      final record = AttendanceRecord(
        id: 1,
        sessionId: 1,
        studentId: 1,
        status: AttendanceStatus.late,
        checkInTime: checkInTime,
        note: 'Đến muộn',
        createdAt: now,
        updatedAt: now,
      );

      // Act
      final map = record.toMap();

      // Assert
      expect(map['id'], 1);
      expect(map['sessionId'], 1);
      expect(map['studentId'], 1);
      expect(map['status'], 'late');
      expect(map['checkInTime'], checkInTime.toIso8601String());
      expect(map['note'], 'Đến muộn');
    });

    test('AttendanceRecord fromMap should create record from Map', () {
      // Arrange
      final now = DateTime.now();
      final checkInTime = DateTime(2024, 1, 15, 8, 5);
      final map = {
        'id': 1,
        'sessionId': 1,
        'studentId': 1,
        'status': 'late',
        'checkInTime': checkInTime.toIso8601String(),
        'note': 'Đến muộn',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'studentName': 'Nguyen Van A',
        'studentCode': 'SV001',
      };

      // Act
      final record = AttendanceRecord.fromMap(map);

      // Assert
      expect(record.id, 1);
      expect(record.sessionId, 1);
      expect(record.studentId, 1);
      expect(record.status, AttendanceStatus.late);
      expect(record.note, 'Đến muộn');
      expect(record.studentName, 'Nguyen Van A');
      expect(record.studentCode, 'SV001');
    });

    test('AttendanceStatus extension should return correct display name', () {
      // Assert
      expect(AttendanceStatus.present.displayName, 'Có mặt');
      expect(AttendanceStatus.absent.displayName, 'Vắng');
      expect(AttendanceStatus.late.displayName, 'Muộn');
      expect(AttendanceStatus.excused.displayName, 'Có phép');
    });

    test('AttendanceRecord copyWith should update only specified fields', () {
      // Arrange
      final original = AttendanceRecord(
        id: 1,
        sessionId: 1,
        studentId: 1,
        status: AttendanceStatus.present,
        note: 'Đúng giờ',
      );

      // Act
      final updated = original.copyWith(
        status: AttendanceStatus.late,
        note: 'Đến muộn 5 phút',
      );

      // Assert
      expect(updated.id, 1);
      expect(updated.sessionId, 1);
      expect(updated.studentId, 1);
      expect(updated.status, AttendanceStatus.late);
      expect(updated.note, 'Đến muộn 5 phút');
    });
  });
}

