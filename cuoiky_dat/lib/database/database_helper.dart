import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/student.dart';
import '../models/class_schedule.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('student_notebook.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Students table
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        studentId TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        major TEXT NOT NULL,
        year INTEGER NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Class schedules table
    await db.execute('''
      CREATE TABLE class_schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        className TEXT NOT NULL,
        subject TEXT NOT NULL,
        room TEXT NOT NULL,
        teacher TEXT NOT NULL,
        dayOfWeek INTEGER NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        weekPattern TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Audit log table for operation history
    await db.execute('''
      CREATE TABLE audit_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        tableName TEXT NOT NULL,
        recordId INTEGER NOT NULL,
        data TEXT,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_students_major ON students(major)');
    await db.execute('CREATE INDEX idx_students_year ON students(year)');
    await db.execute('CREATE INDEX idx_students_createdAt ON students(createdAt)');
    await db.execute('CREATE INDEX idx_schedules_dayOfWeek ON class_schedules(dayOfWeek)');
    await db.execute('CREATE INDEX idx_schedules_subject ON class_schedules(subject)');
    await db.execute('CREATE INDEX idx_schedules_createdAt ON class_schedules(createdAt)');
    await db.execute('CREATE INDEX idx_audit_timestamp ON audit_log(timestamp)');
    await db.execute('CREATE INDEX idx_audit_table ON audit_log(tableName, recordId)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add audit_log table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS audit_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          action TEXT NOT NULL,
          tableName TEXT NOT NULL,
          recordId INTEGER NOT NULL,
          data TEXT,
          timestamp INTEGER NOT NULL
        )
      ''');

      // Add indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_students_major ON students(major)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_students_year ON students(year)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_students_createdAt ON students(createdAt)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_schedules_dayOfWeek ON class_schedules(dayOfWeek)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_schedules_subject ON class_schedules(subject)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_schedules_createdAt ON class_schedules(createdAt)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON audit_log(timestamp)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_audit_table ON audit_log(tableName, recordId)');
    }
  }

  // Audit log operations
  Future<void> _logAction(String action, String tableName, int recordId, Map<String, dynamic>? data) async {
    final db = await database;
    await db.insert('audit_log', {
      'action': action,
      'tableName': tableName,
      'recordId': recordId,
      'data': data != null ? data.toString() : null,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getAuditLogs({
    String? tableName,
    int? recordId,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await database;
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (tableName != null) {
      whereClause += ' AND tableName = ?';
      whereArgs.add(tableName);
    }
    if (recordId != null) {
      whereClause += ' AND recordId = ?';
      whereArgs.add(recordId);
    }

    return await db.query(
      'audit_log',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
  }

  // Student CRUD operations
  Future<int> insertStudent(Student student) async {
    final db = await database;
    final id = await db.insert('students', student.toMap());
    await _logAction('CREATE', 'students', id, student.toMap());
    return id;
  }

  Future<List<Student>> getAllStudents({int? limit, int offset = 0}) async {
    final db = await database;
    final maps = await db.query(
      'students',
      orderBy: 'name',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => Student.fromMap(map)).toList();
  }

  Future<int> getStudentsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM students');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Student?> getStudentById(int id) async {
    final db = await database;
    final maps = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Student.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Student>> searchStudents(String query) async {
    final db = await database;
    final maps = await db.query(
      'students',
      where: 'name LIKE ? OR studentId LIKE ? OR email LIKE ? OR major LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'name',
    );
    return maps.map((map) => Student.fromMap(map)).toList();
  }

  Future<List<Student>> filterStudentsByMajor(String major) async {
    final db = await database;
    final maps = await db.query(
      'students',
      where: 'major = ?',
      whereArgs: [major],
      orderBy: 'name',
    );
    return maps.map((map) => Student.fromMap(map)).toList();
  }

  Future<List<Student>> filterStudentsByYear(int year) async {
    final db = await database;
    final maps = await db.query(
      'students',
      where: 'year = ?',
      whereArgs: [year],
      orderBy: 'name',
    );
    return maps.map((map) => Student.fromMap(map)).toList();
  }

  Future<int> updateStudent(Student student) async {
    final db = await database;
    final result = await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
    if (result > 0 && student.id != null) {
      await _logAction('UPDATE', 'students', student.id!, student.toMap());
    }
    return result;
  }

  Future<int> deleteStudent(int id) async {
    final db = await database;
    final student = await getStudentById(id);
    final result = await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result > 0) {
      await _logAction('DELETE', 'students', id, student?.toMap());
    }
    return result;
  }

  // Class Schedule CRUD operations
  Future<int> insertClassSchedule(ClassSchedule schedule) async {
    final db = await database;
    final id = await db.insert('class_schedules', schedule.toMap());
    await _logAction('CREATE', 'class_schedules', id, schedule.toMap());
    return id;
  }

  Future<List<ClassSchedule>> getAllClassSchedules({int? limit, int offset = 0}) async {
    final db = await database;
    final maps = await db.query(
      'class_schedules',
      orderBy: 'dayOfWeek, startTime',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => ClassSchedule.fromMap(map)).toList();
  }

  Future<int> getClassSchedulesCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM class_schedules');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<ClassSchedule?> getClassScheduleById(int id) async {
    final db = await database;
    final maps = await db.query(
      'class_schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ClassSchedule.fromMap(maps.first);
    }
    return null;
  }

  Future<List<ClassSchedule>> searchClassSchedules(String query) async {
    final db = await database;
    final maps = await db.query(
      'class_schedules',
      where: 'className LIKE ? OR subject LIKE ? OR teacher LIKE ? OR room LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'dayOfWeek, startTime',
    );
    return maps.map((map) => ClassSchedule.fromMap(map)).toList();
  }

  Future<List<ClassSchedule>> filterClassSchedulesByDay(int dayOfWeek) async {
    final db = await database;
    final maps = await db.query(
      'class_schedules',
      where: 'dayOfWeek = ?',
      whereArgs: [dayOfWeek],
      orderBy: 'startTime',
    );
    return maps.map((map) => ClassSchedule.fromMap(map)).toList();
  }

  Future<List<ClassSchedule>> filterClassSchedulesBySubject(String subject) async {
    final db = await database;
    final maps = await db.query(
      'class_schedules',
      where: 'subject = ?',
      whereArgs: [subject],
      orderBy: 'dayOfWeek, startTime',
    );
    return maps.map((map) => ClassSchedule.fromMap(map)).toList();
  }

  Future<int> updateClassSchedule(ClassSchedule schedule) async {
    final db = await database;
    final result = await db.update(
      'class_schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
    if (result > 0 && schedule.id != null) {
      await _logAction('UPDATE', 'class_schedules', schedule.id!, schedule.toMap());
    }
    return result;
  }

  Future<int> deleteClassSchedule(int id) async {
    final db = await database;
    final schedule = await getClassScheduleById(id);
    final result = await db.delete(
      'class_schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result > 0) {
      await _logAction('DELETE', 'class_schedules', id, schedule?.toMap());
    }
    return result;
  }

  // Statistics queries
  Future<int> getTotalStudents() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM students');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalClassSchedules() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM class_schedules');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> getStudentsByMajor() async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT major, COUNT(*) as count FROM students GROUP BY major',
    );
    return {for (var map in maps) map['major'] as String: map['count'] as int};
  }

  Future<Map<String, int>> getStudentsByYear() async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT year, COUNT(*) as count FROM students GROUP BY year',
    );
    return {for (var map in maps) map['year'].toString(): map['count'] as int};
  }

  Future<Map<String, int>> getSchedulesByDay() async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT dayOfWeek, COUNT(*) as count FROM class_schedules GROUP BY dayOfWeek',
    );
    return {for (var map in maps) map['dayOfWeek'].toString(): map['count'] as int};
  }

  // Statistics by time period
  Future<int> getStudentsCreatedInPeriod(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM students WHERE createdAt >= ? AND createdAt <= ?',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getSchedulesCreatedInPeriod(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM class_schedules WHERE createdAt >= ? AND createdAt <= ?',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> getStudentsByMajorInPeriod(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT major, COUNT(*) as count FROM students WHERE createdAt >= ? AND createdAt <= ? GROUP BY major',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return {for (var map in maps) map['major'] as String: map['count'] as int};
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

