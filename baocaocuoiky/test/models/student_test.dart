import 'package:flutter_test/flutter_test.dart';
import 'package:baocaocuoiky/models/student.dart';

void main() {
  group('Student Model Tests', () {
    test('Student should be created with required fields', () {
      // Arrange & Act
      final student = Student(
        studentId: 'SV001',
        name: 'Nguyen Van A',
        email: 'nguyenvana@example.com',
      );

      // Assert
      expect(student.studentId, 'SV001');
      expect(student.name, 'Nguyen Van A');
      expect(student.email, 'nguyenvana@example.com');
      expect(student.id, null);
      expect(student.phone, null);
      expect(student.classCode, null);
    });

    test('Student should be created with all fields', () {
      // Arrange & Act
      final student = Student(
        id: 1,
        studentId: 'SV001',
        name: 'Nguyen Van A',
        email: 'nguyenvana@example.com',
        phone: '0123456789',
        classCode: 'IT01',
      );

      // Assert
      expect(student.id, 1);
      expect(student.studentId, 'SV001');
      expect(student.name, 'Nguyen Van A');
      expect(student.email, 'nguyenvana@example.com');
      expect(student.phone, '0123456789');
      expect(student.classCode, 'IT01');
    });

    test('Student toMap should convert to Map correctly', () {
      // Arrange
      final now = DateTime.now();
      final student = Student(
        id: 1,
        studentId: 'SV001',
        name: 'Nguyen Van A',
        email: 'nguyenvana@example.com',
        phone: '0123456789',
        classCode: 'IT01',
        createdAt: now,
        updatedAt: now,
      );

      // Act
      final map = student.toMap();

      // Assert
      expect(map['id'], 1);
      expect(map['studentId'], 'SV001');
      expect(map['name'], 'Nguyen Van A');
      expect(map['email'], 'nguyenvana@example.com');
      expect(map['phone'], '0123456789');
      expect(map['classCode'], 'IT01');
      expect(map['createdAt'], now.toIso8601String());
      expect(map['updatedAt'], now.toIso8601String());
    });

    test('Student fromMap should create Student from Map', () {
      // Arrange
      final now = DateTime.now();
      final map = {
        'id': 1,
        'studentId': 'SV001',
        'name': 'Nguyen Van A',
        'email': 'nguyenvana@example.com',
        'phone': '0123456789',
        'classCode': 'IT01',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      // Act
      final student = Student.fromMap(map);

      // Assert
      expect(student.id, 1);
      expect(student.studentId, 'SV001');
      expect(student.name, 'Nguyen Van A');
      expect(student.email, 'nguyenvana@example.com');
      expect(student.phone, '0123456789');
      expect(student.classCode, 'IT01');
      expect(student.createdAt.toIso8601String(), now.toIso8601String());
      expect(student.updatedAt.toIso8601String(), now.toIso8601String());
    });

    test('Student copyWith should update only specified fields', () {
      // Arrange
      final original = Student(
        id: 1,
        studentId: 'SV001',
        name: 'Nguyen Van A',
        email: 'nguyenvana@example.com',
        classCode: 'IT01',
      );

      // Act
      final updated = original.copyWith(
        name: 'Nguyen Van B',
        email: 'nguyenvanb@example.com',
      );

      // Assert
      expect(updated.id, 1);
      expect(updated.studentId, 'SV001');
      expect(updated.name, 'Nguyen Van B');
      expect(updated.email, 'nguyenvanb@example.com');
      expect(updated.classCode, 'IT01');
    });

    test('Student toString should return formatted string', () {
      // Arrange
      final student = Student(
        id: 1,
        studentId: 'SV001',
        name: 'Nguyen Van A',
        email: 'nguyenvana@example.com',
      );

      // Act
      final result = student.toString();

      // Assert
      expect(result, contains('Student'));
      expect(result, contains('id: 1'));
      expect(result, contains('studentId: SV001'));
      expect(result, contains('name: Nguyen Van A'));
      expect(result, contains('email: nguyenvana@example.com'));
    });
  });
}

