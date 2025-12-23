import 'package:flutter_test/flutter_test.dart';
import 'package:baocaocuoiky/models/attendance_session.dart';

void main() {
  group('AttendanceSession Model Tests', () {
    test('AttendanceSession should be created with required fields', () {
      // Arrange & Act
      final session = AttendanceSession(
        sessionCode: 'SS001',
        title: 'Buổi học đầu tiên',
        subjectId: 1,
        classCode: 'IT01',
        sessionNumber: 1,
        sessionDate: DateTime(2024, 1, 15, 8, 0),
      );

      // Assert
      expect(session.sessionCode, 'SS001');
      expect(session.title, 'Buổi học đầu tiên');
      expect(session.classCode, 'IT01');
      expect(session.sessionDate, DateTime(2024, 1, 15, 8, 0));
      expect(session.status, SessionStatus.scheduled);
      expect(session.description, null);
      expect(session.location, null);
    });

    test('AttendanceSession should be created with all fields', () {
      // Arrange & Act
      final session = AttendanceSession(
        id: 1,
        sessionCode: 'SS001',
        title: 'Buổi học đầu tiên',
        description: 'Giới thiệu môn học',
        subjectId: 1,
        classCode: 'IT01',
        sessionNumber: 1,
        sessionDate: DateTime(2024, 1, 15, 8, 0),
        location: 'Phòng A101',
        status: SessionStatus.completed,
      );

      // Assert
      expect(session.id, 1);
      expect(session.sessionCode, 'SS001');
      expect(session.title, 'Buổi học đầu tiên');
      expect(session.description, 'Giới thiệu môn học');
      expect(session.classCode, 'IT01');
      expect(session.location, 'Phòng A101');
      expect(session.status, SessionStatus.completed);
    });

    test('AttendanceSession toMap should convert to Map correctly', () {
      // Arrange
      final now = DateTime.now();
      final sessionDate = DateTime(2024, 1, 15, 8, 0);
      final session = AttendanceSession(
        id: 1,
        sessionCode: 'SS001',
        title: 'Buổi học đầu tiên',
        subjectId: 1,
        classCode: 'IT01',
        sessionNumber: 1,
        sessionDate: sessionDate,
        status: SessionStatus.completed,
        createdAt: now,
        updatedAt: now,
      );

      // Act
      final map = session.toMap();

      // Assert
      expect(map['id'], 1);
      expect(map['sessionCode'], 'SS001');
      expect(map['title'], 'Buổi học đầu tiên');
      expect(map['subjectId'], 1);
      expect(map['classCode'], 'IT01');
      expect(map['sessionNumber'], 1);
      expect(map['sessionDate'], sessionDate.toIso8601String());
      expect(map['status'], 'completed');
    });

    test('AttendanceSession fromMap should create session from Map', () {
      // Arrange
      final now = DateTime.now();
      final sessionDate = DateTime(2024, 1, 15, 8, 0);
      final map = {
        'id': 1,
        'sessionCode': 'SS001',
        'title': 'Buổi học đầu tiên',
        'description': null,
        'subjectId': 1,
        'classCode': 'IT01',
        'sessionNumber': 1,
        'sessionDate': sessionDate.toIso8601String(),
        'location': null,
        'status': 'completed',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      // Act
      final session = AttendanceSession.fromMap(map);

      // Assert
      expect(session.id, 1);
      expect(session.sessionCode, 'SS001');
      expect(session.title, 'Buổi học đầu tiên');
      expect(session.status, SessionStatus.completed);
    });

    test('SessionStatus extension should return correct display name', () {
      // Assert
      expect(SessionStatus.scheduled.displayName, 'Chưa diễn ra');
      expect(SessionStatus.completed.displayName, 'Đã hoàn thành');
    });

    test('AttendanceSession copyWith should update only specified fields', () {
      // Arrange
      final original = AttendanceSession(
        id: 1,
        sessionCode: 'SS001',
        title: 'Buổi học đầu tiên',
        subjectId: 1,
        classCode: 'IT01',
        sessionNumber: 1,
        sessionDate: DateTime(2024, 1, 15, 8, 0),
        status: SessionStatus.scheduled,
      );

      // Act
      final updated = original.copyWith(
        title: 'Buổi học thứ hai',
        status: SessionStatus.completed,
      );

      // Assert
      expect(updated.id, 1);
      expect(updated.sessionCode, 'SS001');
      expect(updated.title, 'Buổi học thứ hai');
      expect(updated.classCode, 'IT01');
      expect(updated.status, SessionStatus.completed);
    });
  });
}

