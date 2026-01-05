import 'package:flutter_test/flutter_test.dart';
import 'package:cuoiky_dat/database/database_helper.dart';
import 'package:cuoiky_dat/models/student.dart';
import 'package:cuoiky_dat/models/class_schedule.dart';
import 'package:cuoiky_dat/utils/validation.dart';

void main() {
  group('Integration Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      // Clean up before each test
      final db = await dbHelper.database;
      await db.delete('students');
      await db.delete('class_schedules');
    });

    tearDown(() async {
      // Clean up after each test
      final db = await dbHelper.database;
      await db.delete('students');
      await db.delete('class_schedules');
    });

    test('Integration: Create, Read, Update, Delete Student Flow', () async {
      // Create
      final student = Student(
        name: 'Nguyen Van A',
        studentId: 'SV001',
        email: 'test@example.com',
        phone: '0123456789',
        major: 'CNTT',
        year: 2024,
        createdAt: DateTime.now(),
      );

      final id = await dbHelper.insertStudent(student);
      expect(id, isNotNull);
      expect(id, isPositive);

      // Read
      final retrieved = await dbHelper.getStudentById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Nguyen Van A'));
      expect(retrieved.studentId, equals('SV001'));

      // Update
      final updated = student.copyWith(name: 'Nguyen Van B');
      await dbHelper.updateStudent(updated.copyWith(id: id));
      
      final retrievedUpdated = await dbHelper.getStudentById(id);
      expect(retrievedUpdated!.name, equals('Nguyen Van B'));

      // Delete
      final deletedCount = await dbHelper.deleteStudent(id);
      expect(deletedCount, equals(1));

      final deleted = await dbHelper.getStudentById(id);
      expect(deleted, isNull);
    });

    test('Integration: Create, Read, Update, Delete ClassSchedule Flow', () async {
      // Create
      final schedule = ClassSchedule(
        className: 'LTHDT',
        subject: 'Lập trình hướng đối tượng',
        room: 'A101',
        teacher: 'Nguyen Van C',
        dayOfWeek: 1,
        startTime: '08:00',
        endTime: '10:00',
        weekPattern: 'All',
        createdAt: DateTime.now(),
      );

      final id = await dbHelper.insertClassSchedule(schedule);
      expect(id, isNotNull);
      expect(id, isPositive);

      // Read
      final retrieved = await dbHelper.getClassScheduleById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.className, equals('LTHDT'));
      expect(retrieved.subject, equals('Lập trình hướng đối tượng'));

      // Update
      final updated = schedule.copyWith(room: 'A102');
      await dbHelper.updateClassSchedule(updated.copyWith(id: id));
      
      final retrievedUpdated = await dbHelper.getClassScheduleById(id);
      expect(retrievedUpdated!.room, equals('A102'));

      // Delete
      final deletedCount = await dbHelper.deleteClassSchedule(id);
      expect(deletedCount, equals(1));

      final deleted = await dbHelper.getClassScheduleById(id);
      expect(deleted, isNull);
    });

    test('Integration: Search and Filter Students Flow', () async {
      // Create test data
      await dbHelper.insertStudent(Student(
        name: 'Nguyen Van A',
        studentId: 'SV001',
        email: 'a@example.com',
        phone: '0123456789',
        major: 'CNTT',
        year: 2024,
        createdAt: DateTime.now(),
      ));

      await dbHelper.insertStudent(Student(
        name: 'Tran Thi B',
        studentId: 'SV002',
        email: 'b@example.com',
        phone: '0987654321',
        major: 'Kinh te',
        year: 2023,
        createdAt: DateTime.now(),
      ));

      // Search by name
      final results = await dbHelper.searchStudents('Nguyen');
      expect(results.length, equals(1));
      expect(results.first.name, contains('Nguyen'));

      // Filter by major
      final byMajor = await dbHelper.filterStudentsByMajor('CNTT');
      expect(byMajor.length, equals(1));
      expect(byMajor.first.major, equals('CNTT'));

      // Filter by year
      final byYear = await dbHelper.filterStudentsByYear(2024);
      expect(byYear.length, equals(1));
      expect(byYear.first.year, equals(2024));
    });

    test('Integration: Validation + Database Flow', () async {
      // Test validation
      expect(Validation.validateName('Nguyen Van A'), isNull);
      expect(Validation.validateEmail('test@example.com'), isNull);
      expect(Validation.validatePhone('0123456789'), isNull);
      expect(Validation.validateStudentId('SV001'), isNull);

      // If validation passes, insert to database
      final student = Student(
        name: 'Valid Name',
        studentId: 'SV999',
        email: 'valid@example.com',
        phone: '0123456789',
        major: 'CNTT',
        year: 2024,
        createdAt: DateTime.now(),
      );

      final validationResults = [
        Validation.validateName(student.name),
        Validation.validateEmail(student.email),
        Validation.validatePhone(student.phone),
        Validation.validateStudentId(student.studentId),
      ];

      // All validations should pass
      expect(validationResults.every((r) => r == null), isTrue);

      // Insert to database
      final id = await dbHelper.insertStudent(student);
      expect(id, isPositive);

      // Verify it was inserted correctly
      final retrieved = await dbHelper.getStudentById(id);
      expect(retrieved, isNotNull);
    });
  });
}

