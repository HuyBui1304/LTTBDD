import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/student.dart';
import '../models/attendance_session.dart';
import '../models/attendance_record.dart';
import '../models/app_user.dart';
import '../models/subject.dart';
import 'package:crypto/crypto.dart' show sha256;

class Crypto {
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('attendance.db');
    await _seedDemoData(); // Tạo dữ liệu demo
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 9, // Version 9: Ensure qr_tokens table and checkInMethod/checkedByTeacherId columns exist
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add users table
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uid TEXT NOT NULL UNIQUE,
          email TEXT NOT NULL UNIQUE,
          displayName TEXT NOT NULL,
          passwordHash TEXT NOT NULL,
          photoUrl TEXT,
          role TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          lastLogin TEXT,
          UNIQUE(email)
        )
      ''');

      // Add QR scan history table
      await db.execute('''
        CREATE TABLE qr_scan_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          sessionId INTEGER,
          qrData TEXT NOT NULL,
          scanType TEXT NOT NULL,
          scannedAt TEXT NOT NULL,
          note TEXT,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (sessionId) REFERENCES attendance_sessions (id) ON DELETE SET NULL
        )
      ''');

      await db.execute('CREATE INDEX idx_qr_history_user ON qr_scan_history(userId)');
      await db.execute('CREATE INDEX idx_qr_history_session ON qr_scan_history(sessionId)');
    }
    
    if (oldVersion < 3) {
      // Add session_history table for workflow
      await db.execute('''
        CREATE TABLE IF NOT EXISTS session_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sessionId INTEGER NOT NULL,
          userId INTEGER NOT NULL,
          action TEXT NOT NULL,
          oldStatus TEXT,
          newStatus TEXT,
          note TEXT,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (sessionId) REFERENCES attendance_sessions (id) ON DELETE CASCADE,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_session_history_session ON session_history(sessionId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_session_history_user ON session_history(userId)');
      
      // Add workflow columns to sessions if not exist
      try {
        await db.execute('ALTER TABLE attendance_sessions ADD COLUMN approvedBy INTEGER');
        await db.execute('ALTER TABLE attendance_sessions ADD COLUMN approvedAt TEXT');
        await db.execute('ALTER TABLE attendance_sessions ADD COLUMN completedBy INTEGER');
        await db.execute('ALTER TABLE attendance_sessions ADD COLUMN completedAt TEXT');
      } catch (e) {
        // Columns might already exist, ignore
      }
    }

    if (oldVersion < 4) {
      // Add QR token table for anti-abuse
      await db.execute('''
        CREATE TABLE IF NOT EXISTS qr_tokens (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          token TEXT NOT NULL UNIQUE,
          code4Digits TEXT,
          sessionId INTEGER NOT NULL,
          createdAt TEXT NOT NULL,
          expiresAt TEXT NOT NULL,
          isUsed INTEGER NOT NULL DEFAULT 0,
          usedByUserId INTEGER,
          usedAt TEXT,
          usedFromIp TEXT,
          FOREIGN KEY (sessionId) REFERENCES attendance_sessions (id) ON DELETE CASCADE,
          FOREIGN KEY (usedByUserId) REFERENCES users (id) ON DELETE SET NULL
        )
      ''');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_qr_tokens_session ON qr_tokens(sessionId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_qr_tokens_token ON qr_tokens(token)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_qr_tokens_expires ON qr_tokens(expiresAt)');
    }

    if (oldVersion < 5) {
      // Add export history table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS export_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          userName TEXT NOT NULL,
          exportType TEXT NOT NULL,
          format TEXT NOT NULL,
          fileName TEXT,
          filePath TEXT,
          exportedAt TEXT NOT NULL,
          filters TEXT,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_export_history_user ON export_history(userId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_export_history_date ON export_history(exportedAt)');
    }

    if (oldVersion < 6) {
      // Add creatorId to attendance_sessions
      try {
        await db.execute('ALTER TABLE attendance_sessions ADD COLUMN creatorId INTEGER');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_creator ON attendance_sessions(creatorId)');
      } catch (e) {
        // Column might already exist, ignore
      }
    }

    if (oldVersion < 8) {
      // Add code4Digits to qr_tokens
      try {
        await db.execute('ALTER TABLE qr_tokens ADD COLUMN code4Digits TEXT');
      } catch (e) {
        // Column might already exist
      }
      
      // Add checkInMethod and checkedByTeacherId to attendance_records
      try {
        await db.execute('ALTER TABLE attendance_records ADD COLUMN checkInMethod TEXT DEFAULT "qrScan"');
        await db.execute('ALTER TABLE attendance_records ADD COLUMN checkedByTeacherId INTEGER');
      } catch (e) {
        // Columns might already exist
      }
    }
    
    if (oldVersion < 9) {
      // Ensure qr_tokens table exists (might not exist in older versions)
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS qr_tokens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            token TEXT NOT NULL UNIQUE,
            code4Digits TEXT,
            sessionId INTEGER NOT NULL,
            createdAt TEXT NOT NULL,
            expiresAt TEXT NOT NULL,
            isUsed INTEGER NOT NULL DEFAULT 0,
            usedByUserId INTEGER,
            usedAt TEXT,
            usedFromIp TEXT,
            FOREIGN KEY (sessionId) REFERENCES attendance_sessions (id) ON DELETE CASCADE,
            FOREIGN KEY (usedByUserId) REFERENCES users (id) ON DELETE SET NULL
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_qr_tokens_session ON qr_tokens(sessionId)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_qr_tokens_token ON qr_tokens(token)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_qr_tokens_expires ON qr_tokens(expiresAt)');
      } catch (e) {
        // Table might already exist
      }
      
      // Ensure checkInMethod and checkedByTeacherId columns exist
      try {
        await db.execute('ALTER TABLE attendance_records ADD COLUMN checkInMethod TEXT DEFAULT "qrScan"');
      } catch (e) {
        // Column might already exist
      }
      
      try {
        await db.execute('ALTER TABLE attendance_records ADD COLUMN checkedByTeacherId INTEGER');
      } catch (e) {
        // Column might already exist
      }
    }
    
    if (oldVersion < 7) {
      // Add subjects table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS subjects (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          subjectCode TEXT NOT NULL UNIQUE,
          subjectName TEXT NOT NULL,
          classCode TEXT NOT NULL,
          description TEXT,
          creatorId INTEGER,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          FOREIGN KEY (creatorId) REFERENCES users (id) ON DELETE SET NULL
        )
      ''');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_subjects_class ON subjects(classCode)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_subjects_creator ON subjects(creatorId)');

      // Add subjectId and sessionNumber to attendance_sessions
      try {
        await db.execute('ALTER TABLE attendance_sessions ADD COLUMN subjectId INTEGER');
        await db.execute('ALTER TABLE attendance_sessions ADD COLUMN sessionNumber INTEGER DEFAULT 1');
        // Make sessionDate nullable
        // SQLite doesn't support ALTER COLUMN, so we need to recreate table or keep it as is
        await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_subject ON attendance_sessions(subjectId)');
      } catch (e) {
        // Columns might already exist, ignore
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const intTypeNullable = 'INTEGER';

    // Students table
    await db.execute('''
      CREATE TABLE students (
        id $idType,
        studentId $textType,
        name $textType,
        email $textType,
        phone $textTypeNullable,
        classCode $textTypeNullable,
        createdAt $textType,
        updatedAt $textType,
        UNIQUE(studentId)
      )
    ''');

    // Subjects table
    await db.execute('''
      CREATE TABLE subjects (
        id $idType,
        subjectCode $textType,
        subjectName $textType,
        classCode $textType,
        description $textTypeNullable,
        creatorId $intTypeNullable,
        createdAt $textType,
        updatedAt $textType,
        UNIQUE(subjectCode),
        FOREIGN KEY (creatorId) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');

    // Attendance Sessions table
    await db.execute('''
      CREATE TABLE attendance_sessions (
        id $idType,
        sessionCode $textType,
        title $textType,
        description $textTypeNullable,
        subjectId $intType,
        classCode $textType,
        sessionNumber INTEGER NOT NULL DEFAULT 1,
        sessionDate $textTypeNullable,
        location $textTypeNullable,
        status $textType,
        creatorId $intTypeNullable,
        createdAt $textType,
        updatedAt $textType,
        UNIQUE(sessionCode),
        FOREIGN KEY (subjectId) REFERENCES subjects (id) ON DELETE CASCADE,
        FOREIGN KEY (creatorId) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');

    // Attendance Records table
    await db.execute('''
      CREATE TABLE attendance_records (
        id $idType,
        sessionId $intType,
        studentId $intType,
        status $textType,
        checkInTime $textType,
        note $textTypeNullable,
        checkInMethod TEXT DEFAULT "qrScan",
        checkedByTeacherId $intTypeNullable,
        createdAt $textType,
        updatedAt $textType,
        FOREIGN KEY (sessionId) REFERENCES attendance_sessions (id) ON DELETE CASCADE,
        FOREIGN KEY (studentId) REFERENCES students (id) ON DELETE CASCADE,
        FOREIGN KEY (checkedByTeacherId) REFERENCES users (id) ON DELETE SET NULL,
        UNIQUE(sessionId, studentId)
      )
    ''');

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        uid $textType,
        email $textType,
        displayName $textType,
        passwordHash $textType,
        photoUrl $textTypeNullable,
        role $textType,
        createdAt $textType,
        lastLogin $textTypeNullable,
        UNIQUE(uid),
        UNIQUE(email)
      )
    ''');

    // QR Scan History table
    await db.execute('''
      CREATE TABLE qr_scan_history (
        id $idType,
        userId $intType,
        sessionId $intType,
        qrData $textType,
        scanType $textType,
        scannedAt $textType,
        note $textTypeNullable,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (sessionId) REFERENCES attendance_sessions (id) ON DELETE SET NULL
      )
    ''');

    // QR Tokens table
    await db.execute('''
      CREATE TABLE qr_tokens (
        id $idType,
        token $textType UNIQUE,
        code4Digits TEXT,
        sessionId $intType,
        createdAt $textType,
        expiresAt $textType,
        isUsed INTEGER NOT NULL DEFAULT 0,
        usedByUserId $intTypeNullable,
        usedAt $textTypeNullable,
        usedFromIp $textTypeNullable,
        FOREIGN KEY (sessionId) REFERENCES attendance_sessions (id) ON DELETE CASCADE,
        FOREIGN KEY (usedByUserId) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_students_class ON students(classCode)');
    await db.execute('CREATE INDEX idx_subjects_class ON subjects(classCode)');
    await db.execute('CREATE INDEX idx_subjects_creator ON subjects(creatorId)');
    await db.execute('CREATE INDEX idx_sessions_subject ON attendance_sessions(subjectId)');
    await db.execute('CREATE INDEX idx_sessions_class ON attendance_sessions(classCode)');
    await db.execute('CREATE INDEX idx_records_session ON attendance_records(sessionId)');
    await db.execute('CREATE INDEX idx_records_student ON attendance_records(studentId)');
    await db.execute('CREATE INDEX idx_qr_history_user ON qr_scan_history(userId)');
    await db.execute('CREATE INDEX idx_qr_history_session ON qr_scan_history(sessionId)');
    await db.execute('CREATE INDEX idx_qr_tokens_session ON qr_tokens(sessionId)');
    await db.execute('CREATE INDEX idx_qr_tokens_token ON qr_tokens(token)');
    await db.execute('CREATE INDEX idx_qr_tokens_expires ON qr_tokens(expiresAt)');
  }

  // ========== STUDENT OPERATIONS ==========

  Future<Student> createStudent(Student student) async {
    final db = await database;
    final id = await db.insert('students', student.toMap());
    return student.copyWith(id: id);
  }

  Future<Student?> getStudent(int id) async {
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

  Future<List<Student>> getAllStudents() async {
    final db = await database;
    const orderBy = 'name ASC';
    final result = await db.query('students', orderBy: orderBy);
    return result.map((json) => Student.fromMap(json)).toList();
  }

  Future<List<Student>> searchStudents(String query) async {
    final db = await database;
    final result = await db.query(
      'students',
      where: 'name LIKE ? OR studentId LIKE ? OR email LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((json) => Student.fromMap(json)).toList();
  }

  Future<List<Student>> getStudentsByClass(String classCode) async {
    final db = await database;
    final result = await db.query(
      'students',
      where: 'classCode = ?',
      whereArgs: [classCode],
      orderBy: 'name ASC',
    );
    return result.map((json) => Student.fromMap(json)).toList();
  }

  Future<Student?> getStudentByStudentId(String studentId) async {
    final db = await database;
    final maps = await db.query(
      'students',
      where: 'studentId = ?',
      whereArgs: [studentId],
    );

    if (maps.isNotEmpty) {
      return Student.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateStudent(Student student) async {
    final db = await database;
    return db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<int> deleteStudent(int id) async {
    final db = await database;
    return await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== SUBJECT OPERATIONS ==========

  Future<Subject> createSubject(Subject subject) async {
    final db = await database;
    final id = await db.insert('subjects', subject.toMap());
    final createdSubject = subject.copyWith(id: id);
    
    // Auto-create 9 sessions for the subject
    await _createDefaultSessionsForSubject(createdSubject);
    
    return createdSubject;
  }

  // Create 9 default sessions for a subject
  Future<void> _createDefaultSessionsForSubject(Subject subject) async {
    final db = await database;
    final now = DateTime.now();
    
    for (int i = 1; i <= 9; i++) {
      final session = AttendanceSession(
        sessionCode: '${subject.subjectCode}-SES${i.toString().padLeft(3, '0')}',
        title: 'Buổi $i',
        description: 'Buổi học thứ $i của môn ${subject.subjectName}',
        subjectId: subject.id!,
        classCode: subject.classCode,
        sessionNumber: i,
        status: SessionStatus.scheduled,
        creatorId: subject.creatorId,
        createdAt: now,
        updatedAt: now,
      );
      
      await db.insert('attendance_sessions', session.toMap());
    }
  }

  Future<Subject?> getSubject(int id) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT s.*, u.displayName as creatorName
      FROM subjects s
      LEFT JOIN users u ON s.creatorId = u.id
      WHERE s.id = ?
    ''', [id]);

    if (maps.isNotEmpty) {
      return Subject.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Subject>> getAllSubjects({int? creatorId, String? classCode}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (creatorId != null) {
      whereClause = 'creatorId = ?';
      whereArgs.add(creatorId);
    }
    
    if (classCode != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += 'classCode = ?';
      whereArgs.add(classCode);
    }
    
    final result = await db.rawQuery('''
      SELECT s.*, u.displayName as creatorName
      FROM subjects s
      LEFT JOIN users u ON s.creatorId = u.id
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      ORDER BY s.subjectName ASC
    ''', whereArgs.isEmpty ? [] : whereArgs);
    
    return result.map((json) => Subject.fromMap(json)).toList();
  }

  Future<List<Subject>> getSubjectsByCreator(int creatorId) async {
    return getAllSubjects(creatorId: creatorId);
  }

  Future<List<Subject>> searchSubjects(String query) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT s.*, u.displayName as creatorName
      FROM subjects s
      LEFT JOIN users u ON s.creatorId = u.id
      WHERE s.subjectName LIKE ? OR s.subjectCode LIKE ? OR s.classCode LIKE ?
      ORDER BY s.subjectName ASC
    ''', ['%$query%', '%$query%', '%$query%']);
    return result.map((json) => Subject.fromMap(json)).toList();
  }

  Future<Subject?> getSubjectByCode(String subjectCode) async {
    final db = await database;
    final maps = await db.query(
      'subjects',
      where: 'subjectCode = ?',
      whereArgs: [subjectCode],
    );

    if (maps.isNotEmpty) {
      return Subject.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateSubject(Subject subject) async {
    final db = await database;
    return db.update(
      'subjects',
      subject.toMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  Future<int> deleteSubject(int id) async {
    final db = await database;
    // Sessions will be deleted automatically due to CASCADE
    return await db.delete(
      'subjects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get sessions by subject
  Future<List<AttendanceSession>> getSessionsBySubject(int subjectId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT s.*, u.displayName as creatorName, sub.subjectName
      FROM attendance_sessions s
      LEFT JOIN users u ON s.creatorId = u.id
      LEFT JOIN subjects sub ON s.subjectId = sub.id
      WHERE s.subjectId = ?
      ORDER BY s.sessionNumber ASC
    ''', [subjectId]);
    
    return result.map((json) => AttendanceSession.fromMap(json)).toList();
  }

  // ========== ATTENDANCE SESSION OPERATIONS ==========

  Future<AttendanceSession> createSession(AttendanceSession session) async {
    final db = await database;
    final id = await db.insert('attendance_sessions', session.toMap());
    return session.copyWith(id: id);
  }

  Future<AttendanceSession?> getSession(int id) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT s.*, u.displayName as creatorName, sub.subjectName
      FROM attendance_sessions s
      LEFT JOIN users u ON s.creatorId = u.id
      LEFT JOIN subjects sub ON s.subjectId = sub.id
      WHERE s.id = ?
    ''', [id]);

    if (maps.isNotEmpty) {
      return AttendanceSession.fromMap(maps.first);
    }
    return null;
  }

  Future<List<AttendanceSession>> getAllSessions({int? creatorId, String? classCode}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (creatorId != null) {
      whereClause = 'creatorId = ?';
      whereArgs.add(creatorId);
    }
    
    if (classCode != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += 'classCode = ?';
      whereArgs.add(classCode);
    }
    
    final result = await db.rawQuery('''
      SELECT s.*, u.displayName as creatorName
      FROM attendance_sessions s
      LEFT JOIN users u ON s.creatorId = u.id
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      ORDER BY s.sessionDate DESC
    ''', whereArgs.isEmpty ? [] : whereArgs);
    
    return result.map((json) => AttendanceSession.fromMap(json)).toList();
  }
  
  // Get sessions by creator (for Teacher)
  Future<List<AttendanceSession>> getSessionsByCreator(int creatorId) async {
    return getAllSessions(creatorId: creatorId);
  }
  
  // Get sessions by class (for Student)
  Future<List<AttendanceSession>> getSessionsByStudentClass(String classCode) async {
    return getAllSessions(classCode: classCode);
  }

  Future<List<AttendanceSession>> searchSessions(String query) async {
    final db = await database;
    final result = await db.query(
      'attendance_sessions',
      where: 'title LIKE ? OR sessionCode LIKE ? OR classCode LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'sessionDate DESC',
    );
    return result.map((json) => AttendanceSession.fromMap(json)).toList();
  }

  Future<List<AttendanceSession>> getSessionsByClass(String classCode) async {
    final db = await database;
    final result = await db.query(
      'attendance_sessions',
      where: 'classCode = ?',
      whereArgs: [classCode],
      orderBy: 'sessionDate DESC',
    );
    return result.map((json) => AttendanceSession.fromMap(json)).toList();
  }

  Future<AttendanceSession?> getSessionByCode(String sessionCode) async {
    final db = await database;
    final maps = await db.query(
      'attendance_sessions',
      where: 'sessionCode = ?',
      whereArgs: [sessionCode],
    );

    if (maps.isNotEmpty) {
      return AttendanceSession.fromMap(maps.first);
    }
    return null;
  }

  Future<List<AttendanceSession>> getSessionsByStatus(SessionStatus status) async {
    final db = await database;
    final result = await db.query(
      'attendance_sessions',
      where: 'status = ?',
      whereArgs: [status.name],
      orderBy: 'sessionDate DESC',
    );
    return result.map((json) => AttendanceSession.fromMap(json)).toList();
  }

  Future<int> updateSession(AttendanceSession session) async {
    final db = await database;
    return db.update(
      'attendance_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> deleteSession(int id) async {
    final db = await database;
    return await db.delete(
      'attendance_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== ATTENDANCE RECORD OPERATIONS ==========

  Future<AttendanceRecord> createRecord(AttendanceRecord record) async {
    final db = await database;
    final id = await db.insert('attendance_records', record.toMap());
    return record.copyWith(id: id);
  }

  Future<AttendanceRecord?> getRecord(int id) async {
    final db = await database;
    final maps = await db.query(
      'attendance_records',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return AttendanceRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<List<AttendanceRecord>> getRecordsBySession(int sessionId) async {
    final db = await database;
    try {
      final result = await db.rawQuery('''
        SELECT ar.*, s.name as studentName, s.studentId as studentCode, u.displayName as teacherName
        FROM attendance_records ar
        INNER JOIN students s ON ar.studentId = s.id
        LEFT JOIN users u ON ar.checkedByTeacherId = u.id
        WHERE ar.sessionId = ?
        ORDER BY s.name ASC
      ''', [sessionId]);
      return result.map((json) => AttendanceRecord.fromMap(json)).toList();
    } catch (e) {
      // Fallback: query without join if column doesn't exist
      try {
        final result = await db.rawQuery('''
          SELECT ar.*, s.name as studentName, s.studentId as studentCode
          FROM attendance_records ar
          INNER JOIN students s ON ar.studentId = s.id
          WHERE ar.sessionId = ?
          ORDER BY s.name ASC
        ''', [sessionId]);
        return result.map((json) => AttendanceRecord.fromMap(json)).toList();
      } catch (e2) {
        // Last fallback: simple query
        final result = await db.query(
          'attendance_records',
          where: 'sessionId = ?',
          whereArgs: [sessionId],
          orderBy: 'checkInTime ASC',
        );
        return result.map((json) => AttendanceRecord.fromMap(json)).toList();
      }
    }
  }

  Future<List<AttendanceRecord>> getRecordsByStudent(int studentId) async {
    final db = await database;
    final result = await db.query(
      'attendance_records',
      where: 'studentId = ?',
      whereArgs: [studentId],
      orderBy: 'checkInTime DESC',
    );
    return result.map((json) => AttendanceRecord.fromMap(json)).toList();
  }

  Future<AttendanceRecord?> getRecordBySessionAndStudent(
    int sessionId,
    int studentId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'attendance_records',
      where: 'sessionId = ? AND studentId = ?',
      whereArgs: [sessionId, studentId],
    );

    if (maps.isNotEmpty) {
      return AttendanceRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateRecord(AttendanceRecord record) async {
    final db = await database;
    return db.update(
      'attendance_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete(
      'attendance_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== STATISTICS ==========

  Future<Map<String, int>> getSessionStats(int sessionId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM attendance_records
      WHERE sessionId = ?
      GROUP BY status
    ''', [sessionId]);

    final stats = <String, int>{};
    for (var row in result) {
      stats[row['status'] as String] = row['count'] as int;
    }
    return stats;
  }

  Future<Map<String, dynamic>> getStudentStats(int studentId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as totalSessions,
        SUM(CASE WHEN status = 'present' THEN 1 ELSE 0 END) as present,
        SUM(CASE WHEN status = 'absent' THEN 1 ELSE 0 END) as absent,
        SUM(CASE WHEN status = 'late' THEN 1 ELSE 0 END) as late,
        SUM(CASE WHEN status = 'excused' THEN 1 ELSE 0 END) as excused
      FROM attendance_records
      WHERE studentId = ?
    ''', [studentId]);

    return result.first;
  }

  // ========== USER OPERATIONS ==========

  Future<AppUser> createUser(AppUser user) async {
    final db = await database;
    await db.insert('users', user.toMap());
    return user; // Return user as-is
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return AppUser.fromMap(maps.first);
    }
    return null;
  }

  Future<AppUser?> getUserByUid(String uid) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
    );

    if (maps.isNotEmpty) {
      return AppUser.fromMap(maps.first);
    }
    return null;
  }

  Future<List<AppUser>> getAllUsers() async {
    final db = await database;
    final result = await db.query('users', orderBy: 'displayName ASC');
    return result.map((json) => AppUser.fromMap(json)).toList();
  }

  // Get users by role
  Future<List<AppUser>> getUsersByRole(UserRole role) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: [role.name],
      orderBy: 'displayName ASC',
    );
    return result.map((json) => AppUser.fromMap(json)).toList();
  }

  Future<int> updateUser(AppUser user) async {
    final db = await database;
    return db.update(
      'users',
      user.toMap(),
      where: 'uid = ?',
      whereArgs: [user.uid],
    );
  }

  Future<int> deleteUser(String uid) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }

  Future<int> updateUserLastLogin(String uid) async {
    final db = await database;
    return db.update(
      'users',
      {'lastLogin': DateTime.now().toIso8601String()},
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }

  // ========== QR SCAN HISTORY OPERATIONS ==========

  Future<int> createQRScanHistory(Map<String, dynamic> scanData) async {
    final db = await database;
    return await db.insert('qr_scan_history', scanData);
  }

  Future<List<Map<String, dynamic>>> getQRScanHistoryByUser(int userId) async {
    final db = await database;
    return await db.query(
      'qr_scan_history',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'scannedAt DESC',
    );
  }

  // ========== SESSION HISTORY (WORKFLOW) ==========

  Future<int> createSessionHistory(Map<String, dynamic> history) async {
    final db = await database;
    return await db.insert('session_history', history);
  }

  Future<List<Map<String, dynamic>>> getSessionHistory(int sessionId) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT sh.*, u.displayName as userName, u.email as userEmail
      FROM session_history sh
      LEFT JOIN users u ON sh.userId = u.id
      WHERE sh.sessionId = ?
      ORDER BY sh.createdAt DESC
    ''', [sessionId]);
    return results;
  }

  Future<List<Map<String, dynamic>>> getUserActivities(int userId) async {
    final db = await database;
    return await db.query(
      'session_history',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
      limit: 50,
    );
  }

  Future<List<Map<String, dynamic>>> getQRScanHistoryBySession(int sessionId) async {
    final db = await database;
    return await db.query(
      'qr_scan_history',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'scannedAt DESC',
    );
  }

  // ========== EXPORT/IMPORT DATA ==========

  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    
    final students = await db.query('students');
    final subjects = await db.query('subjects');
    final sessions = await db.query('attendance_sessions');
    final records = await db.query('attendance_records');
    final users = await db.query('users');
    final qrHistory = await db.query('qr_scan_history');

    return {
      'version': 3,
      'exportedAt': DateTime.now().toIso8601String(),
      'students': students,
      'subjects': subjects,
      'sessions': sessions,
      'records': records,
      'users': users,
      'qrHistory': qrHistory,
    };
  }

  Future<String> exportDataAsJSON() async {
    final data = await exportAllData();
    return jsonEncode(data);
  }

  Future<void> importDataFromJSON(String jsonData) async {
    final db = await database;
    final data = jsonDecode(jsonData) as Map<String, dynamic>;

    // Clear existing data (optional, can be configurable)
    await db.delete('attendance_records');
    await db.delete('attendance_sessions');
    await db.delete('subjects');
    await db.delete('students');
    await db.delete('qr_scan_history');
    await db.delete('users');

    // Import students
    if (data['students'] != null) {
      for (var item in data['students'] as List) {
        await db.insert('students', item as Map<String, dynamic>);
      }
    }

    // Import sessions
    if (data['sessions'] != null) {
      for (var item in data['sessions'] as List) {
        await db.insert('attendance_sessions', item as Map<String, dynamic>);
      }
    }

    // Import records
    if (data['records'] != null) {
      for (var item in data['records'] as List) {
        await db.insert('attendance_records', item as Map<String, dynamic>);
      }
    }

    // Import users
    if (data['users'] != null) {
      for (var item in data['users'] as List) {
        await db.insert('users', item as Map<String, dynamic>);
      }
    }

    // Import QR history
    if (data['qrHistory'] != null) {
      for (var item in data['qrHistory'] as List) {
        await db.insert('qr_scan_history', item as Map<String, dynamic>);
      }
    }
  }

  // ========== UTILITY ==========

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'attendance.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  // Seed demo data
  bool _hasSeeded = false;

  Future<void> _seedDemoData() async {
    if (_hasSeeded) return;

    final db = _database;
    if (db == null) return;

    // Check if already has users
    final users = await db.query('users');
    if (users.isNotEmpty) {
      _hasSeeded = true;
      return;
    }

    final crypto = Crypto();
    final now = DateTime.now().toIso8601String();

    // ========== CREATE USERS ==========
    
    // Admin 1
    await db.insert('users', {
      'uid': 'admin-001',
      'email': 'admin1@gmail.com',
      'displayName': 'Nguyễn Văn Admin',
      'passwordHash': crypto.hashPassword('123'),
      'role': 'admin',
      'createdAt': now,
    });
    
    // Admin 2
    await db.insert('users', {
      'uid': 'admin-002',
      'email': 'admin2@gmail.com',
      'displayName': 'Trần Thị Admin',
      'passwordHash': crypto.hashPassword('123'),
      'role': 'admin',
      'createdAt': now,
    });

    // ========== CREATE 3 TEACHERS ==========
    final teacher1Id = await db.insert('users', {
      'uid': 'teacher-001',
      'email': 'teacher1@gmail.com',
      'displayName': 'Nguyễn Thị Lan',
      'passwordHash': crypto.hashPassword('123'),
      'role': 'teacher',
      'createdAt': now,
    });
    
    final teacher2Id = await db.insert('users', {
      'uid': 'teacher-002',
      'email': 'teacher2@gmail.com',
      'displayName': 'Trần Văn Minh',
      'passwordHash': crypto.hashPassword('123'),
      'role': 'teacher',
      'createdAt': now,
    });
    
    final teacher3Id = await db.insert('users', {
      'uid': 'teacher-003',
      'email': 'teacher3@gmail.com',
      'displayName': 'Lê Thị Hương',
      'passwordHash': crypto.hashPassword('123'),
      'role': 'teacher',
      'createdAt': now,
    });

    // ========== CREATE 30 STUDENTS ==========
    await db.insert('users', {
      'uid': 'student-001',
      'email': 'student1@gmail.com',
      'displayName': 'Nguyễn Văn A',
      'passwordHash': crypto.hashPassword('123'),
      'role': 'student',
      'createdAt': now,
    });

    await db.insert('users', {
      'uid': 'student-002',
      'email': 'student2@gmail.com',
      'displayName': 'Trần Thị B',
      'passwordHash': crypto.hashPassword('123'),
      'role': 'student',
      'createdAt': now,
    });
    
    await db.insert('users', {
      'uid': 'student-003',
      'email': 'student3@gmail.com',
      'displayName': 'Lê Văn C',
      'passwordHash': crypto.hashPassword('123'),
      'role': 'student',
      'createdAt': now,
    });
    
    await db.insert('users', {
      'uid': 'student-004',
      'email': 'student4@gmail.com',
      'displayName': 'Phạm Thị D',
      'passwordHash': crypto.hashPassword('123'),
      'role': 'student',
      'createdAt': now,
    });
    
    await db.insert('users', {
      'uid': 'student-005',
      'email': 'student5@gmail.com',
      'displayName': 'Hoàng Văn E',
      'passwordHash': crypto.hashPassword('123'),
      'role': 'student',
      'createdAt': now,
    });
    
    await db.insert('users', {
      'uid': 'student-006',
      'email': 'student6@gmail.com',
      'displayName': 'Vũ Thị F',
      'passwordHash': crypto.hashPassword('123'),
      'role': 'student',
      'createdAt': now,
    });
    
    await db.insert('users', {
      'uid': 'student-007',
      'email': 'student7@gmail.com',
      'displayName': 'Đỗ Văn G',
      'passwordHash': crypto.hashPassword('123'),
      'role': 'student',
      'createdAt': now,
    });
    
    await db.insert('users', {
      'uid': 'student-008',
      'email': 'student8@gmail.com',
      'displayName': 'Bùi Thị H',
      'passwordHash': crypto.hashPassword('123'),
      'role': 'student',
      'createdAt': now,
    });
    
    await db.insert('users', {
      'uid': 'student-009',
      'email': 'student9@gmail.com',
      'displayName': 'Đặng Văn I',
      'passwordHash': crypto.hashPassword('123'),
      'role': 'student',
      'createdAt': now,
    });
    
    await db.insert('users', {
      'uid': 'student-010',
      'email': 'student10@gmail.com',
      'displayName': 'Ngô Thị K',
      'passwordHash': crypto.hashPassword('123'),
      'role': 'student',
      'createdAt': now,
    });
    
    // Thêm 20 học sinh nữa
    for (int i = 11; i <= 30; i++) {
      final hoList = ['Nguyễn', 'Trần', 'Lê', 'Phạm', 'Hoàng', 'Vũ', 'Đỗ', 'Bùi', 'Đặng', 'Ngô'];
      final demList = ['Văn', 'Thị'];
      final tenList = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U'];
      
      final ho = hoList[(i - 1) % hoList.length];
      final dem = demList[(i - 1) % demList.length];
      final ten = tenList[(i - 11) % tenList.length];
      final name = '$ho $dem $ten';
      
      await db.insert('users', {
        'uid': 'student-${i.toString().padLeft(3, '0')}',
        'email': 'student$i@gmail.com',
        'displayName': name,
        'passwordHash': crypto.hashPassword('123'),
        'role': 'student',
        'createdAt': now,
      });
    }

    // ========== CREATE 30 STUDENTS (nhiều lớp) ==========
    // Lớp 1: LTTBDD2024
    final student1Id = await db.insert('students', {
      'studentId': 'SV001',
      'name': 'Nguyễn Văn A',
      'email': 'student1@gmail.com',
      'phone': '0901234567',
      'classCode': 'LTTBDD2024',
      'createdAt': now,
      'updatedAt': now,
    });

    final student2Id = await db.insert('students', {
      'studentId': 'SV002',
      'name': 'Trần Thị B',
      'email': 'student2@gmail.com',
      'phone': '0901234568',
      'classCode': 'LTTBDD2024',
      'createdAt': now,
      'updatedAt': now,
    });

    final student3Id = await db.insert('students', {
      'studentId': 'SV003',
      'name': 'Lê Văn C',
      'email': 'student3@gmail.com',
      'phone': '0901234569',
      'classCode': 'LTTBDD2024',
      'createdAt': now,
      'updatedAt': now,
    });
    
    final student4Id = await db.insert('students', {
      'studentId': 'SV004',
      'name': 'Phạm Thị D',
      'email': 'student4@gmail.com',
      'phone': '0901234570',
      'classCode': 'LTTBDD2024',
      'createdAt': now,
      'updatedAt': now,
    });
    
    // Lớp 2: WEB2024
    final student5Id = await db.insert('students', {
      'studentId': 'SV005',
      'name': 'Hoàng Văn E',
      'email': 'student5@gmail.com',
      'phone': '0901234571',
      'classCode': 'WEB2024',
      'createdAt': now,
      'updatedAt': now,
    });
    
    final student6Id = await db.insert('students', {
      'studentId': 'SV006',
      'name': 'Vũ Thị F',
      'email': 'student6@gmail.com',
      'phone': '0901234572',
      'classCode': 'WEB2024',
      'createdAt': now,
      'updatedAt': now,
    });
    
    // Lớp 3: AI2024
    final student7Id = await db.insert('students', {
      'studentId': 'SV007',
      'name': 'Đỗ Văn G',
      'email': 'student7@gmail.com',
      'phone': '0901234573',
      'classCode': 'AI2024',
      'createdAt': now,
      'updatedAt': now,
    });
    
    final student8Id = await db.insert('students', {
      'studentId': 'SV008',
      'name': 'Bùi Thị H',
      'email': 'student8@gmail.com',
      'phone': '0901234574',
      'classCode': 'AI2024',
      'createdAt': now,
      'updatedAt': now,
    });
    
    // Lớp 4: CNPM2024
    final student9Id = await db.insert('students', {
      'studentId': 'SV009',
      'name': 'Đặng Văn I',
      'email': 'student9@gmail.com',
      'phone': '0901234575',
      'classCode': 'CNPM2024',
      'createdAt': now,
      'updatedAt': now,
    });
    
    final student10Id = await db.insert('students', {
      'studentId': 'SV010',
      'name': 'Ngô Thị K',
      'email': 'student10@gmail.com',
      'phone': '0901234576',
      'classCode': 'CNPM2024',
      'createdAt': now,
      'updatedAt': now,
    });
    
    // Thêm 20 học sinh nữa (SV011-SV030)
    final classCodes = ['LTTBDD2024', 'WEB2024', 'AI2024', 'CNPM2024', 'CSDL2024', 'MANG2024', 'KTMT2024', 'TTNT2024'];
    for (int i = 11; i <= 30; i++) {
      final hoList = ['Nguyễn', 'Trần', 'Lê', 'Phạm', 'Hoàng', 'Vũ', 'Đỗ', 'Bùi', 'Đặng', 'Ngô'];
      final demList = ['Văn', 'Thị'];
      final tenList = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U'];
      
      final ho = hoList[(i - 1) % hoList.length];
      final dem = demList[(i - 1) % demList.length];
      final ten = tenList[(i - 11) % tenList.length];
      final name = '$ho $dem $ten';
      final classCode = classCodes[(i - 11) % classCodes.length];
      
      await db.insert('students', {
        'studentId': 'SV${i.toString().padLeft(3, '0')}',
        'name': name,
        'email': 'student$i@gmail.com',
        'phone': '0901234${(570 + i).toString().padLeft(3, '0')}',
        'classCode': classCode,
        'createdAt': now,
        'updatedAt': now,
      });
    }

    // ========== CREATE SUBJECTS (Nhiều lớp học phần cho giáo viên) ==========
    // Giáo viên 1
    final subject1 = Subject(
      subjectCode: 'LTTBDD2024',
      subjectName: 'Lập trình thiết bị di động',
      classCode: 'LTTBDD2024',
      creatorId: teacher1Id,
      createdAt: DateTime.parse(now),
      updatedAt: DateTime.parse(now),
    );
    final subject1Result = await createSubject(subject1);
    
    // Giáo viên 2
    final subject2 = Subject(
      subjectCode: 'WEB2024',
      subjectName: 'Lập trình Web',
      classCode: 'WEB2024',
      creatorId: teacher2Id,
      createdAt: DateTime.parse(now),
      updatedAt: DateTime.parse(now),
    );
    final subject2Result = await createSubject(subject2);
    
    // Giáo viên 3
    final subject3 = Subject(
      subjectCode: 'AI2024',
      subjectName: 'Trí tuệ nhân tạo',
      classCode: 'AI2024',
      creatorId: teacher3Id,
      createdAt: DateTime.parse(now),
      updatedAt: DateTime.parse(now),
    );
    final subject3Result = await createSubject(subject3);
    
    // Giáo viên 1 - Thêm nhiều lớp (5 lớp)
    final subject4 = Subject(
      subjectCode: 'CNPM2024',
      subjectName: 'Công nghệ phần mềm',
      classCode: 'CNPM2024',
      creatorId: teacher1Id,
      createdAt: DateTime.parse(now),
      updatedAt: DateTime.parse(now),
    );
    final subject4Result = await createSubject(subject4);
    
    final subject5 = Subject(
      subjectCode: 'CSDL2024',
      subjectName: 'Cơ sở dữ liệu',
      classCode: 'CSDL2024',
      creatorId: teacher1Id,
      createdAt: DateTime.parse(now),
      updatedAt: DateTime.parse(now),
    );
    final subject5Result = await createSubject(subject5);
    
    final subject6 = Subject(
      subjectCode: 'MANG2024',
      subjectName: 'Mạng máy tính',
      classCode: 'MANG2024',
      creatorId: teacher1Id,
      createdAt: DateTime.parse(now),
      updatedAt: DateTime.parse(now),
    );
    final subject6Result = await createSubject(subject6);
    
    final subject7 = Subject(
      subjectCode: 'KTMT2024',
      subjectName: 'Kiến trúc máy tính',
      classCode: 'KTMT2024',
      creatorId: teacher1Id,
      createdAt: DateTime.parse(now),
      updatedAt: DateTime.parse(now),
    );
    final subject7Result = await createSubject(subject7);
    
    // Giáo viên 2 - Thêm lớp
    final subject8 = Subject(
      subjectCode: 'TTNT2024',
      subjectName: 'Xử lý tín hiệu số',
      classCode: 'TTNT2024',
      creatorId: teacher2Id,
      createdAt: DateTime.parse(now),
      updatedAt: DateTime.parse(now),
    );
    final subject8Result = await createSubject(subject8);
    
    // Giáo viên 3 - Thêm lớp
    final subject9 = Subject(
      subjectCode: 'MMT2024',
      subjectName: 'Mật mã học',
      classCode: 'MMT2024',
      creatorId: teacher3Id,
      createdAt: DateTime.parse(now),
      updatedAt: DateTime.parse(now),
    );
    final subject9Result = await createSubject(subject9);
    
    final subject10 = Subject(
      subjectCode: 'LT2024',
      subjectName: 'Lý thuyết đồ thị',
      classCode: 'LT2024',
      creatorId: teacher3Id,
      createdAt: DateTime.parse(now),
      updatedAt: DateTime.parse(now),
    );
    final subject10Result = await createSubject(subject10);
    
    // ========== UPDATE SESSIONS (Thiết lập ngày và trạng thái) ==========
    // Sessions đã được tự động tạo bởi createSubject
    // Cập nhật sessionDate và status để có 3 trạng thái: đã hoàn thành, đang diễn ra, sắp tới
    
    final nowDateTime = DateTime.now();
    
    // Subject 1 (LTTBDD2024) - Giáo viên 1
    final sessions1 = await getSessionsBySubject(subject1Result.id!);
    if (sessions1.length >= 9) {
      // Buổi 1-2: Đã hoàn thành (2 ngày trước và hôm qua)
      await updateSession(sessions1[0].copyWith(
        sessionDate: nowDateTime.subtract(const Duration(days: 2)),
        status: SessionStatus.completed,
        location: 'Phòng A101',
      ));
      await updateSession(sessions1[1].copyWith(
        sessionDate: nowDateTime.subtract(const Duration(days: 1)),
        status: SessionStatus.completed,
        location: 'Phòng A101',
      ));
      
      // Buổi 3: Chưa diễn ra (hôm nay)
      await updateSession(sessions1[2].copyWith(
        sessionDate: nowDateTime,
        status: SessionStatus.scheduled,
        location: 'Phòng A101',
      ));
      
      // Buổi 4-9: Sắp tới (các ngày tới)
      for (int i = 3; i < 9; i++) {
        await updateSession(sessions1[i].copyWith(
          sessionDate: nowDateTime.add(Duration(days: i - 2)),
          status: SessionStatus.scheduled,
          location: 'Phòng A101',
        ));
      }
    }
    
    // Subject 2 (WEB2024) - Giáo viên 2
    final sessions2 = await getSessionsBySubject(subject2Result.id!);
    if (sessions2.length >= 9) {
      // Buổi 1: Đã hoàn thành
      await updateSession(sessions2[0].copyWith(
        sessionDate: nowDateTime.subtract(const Duration(days: 3)),
        status: SessionStatus.completed,
        location: 'Phòng B201',
      ));
      
      // Buổi 2: Chưa diễn ra
      await updateSession(sessions2[1].copyWith(
        sessionDate: nowDateTime,
        status: SessionStatus.scheduled,
        location: 'Phòng B201',
      ));
      
      // Buổi 3-9: Sắp tới
      for (int i = 2; i < 9; i++) {
        await updateSession(sessions2[i].copyWith(
          sessionDate: nowDateTime.add(Duration(days: i - 1)),
          status: SessionStatus.scheduled,
          location: 'Phòng B201',
        ));
      }
    }
    
    // Subject 3-10: Tất cả sắp tới
    final subjectsToInit = [
      (subject3Result.id!, 'Phòng C301'),
      (subject4Result.id!, 'Phòng D401'),
      (subject5Result.id!, 'Phòng E501'),
      (subject6Result.id!, 'Phòng F601'),
      (subject7Result.id!, 'Phòng G701'),
      (subject8Result.id!, 'Phòng H801'),
      (subject9Result.id!, 'Phòng I901'),
      (subject10Result.id!, 'Phòng J1001'),
    ];
    
    for (var (subjectId, location) in subjectsToInit) {
      final sessions = await getSessionsBySubject(subjectId);
      for (int i = 0; i < sessions.length && i < 9; i++) {
        await updateSession(sessions[i].copyWith(
          sessionDate: nowDateTime.add(Duration(days: i + 1)),
          status: SessionStatus.scheduled,
          location: location,
        ));
      }
    }
    
    // Lấy sessions để tạo attendance records
    final updatedSessions1 = await getSessionsBySubject(subject1Result.id!);
    final session1Id = updatedSessions1.isNotEmpty ? updatedSessions1[0].id : null;
    final session2Id = updatedSessions1.length > 1 ? updatedSessions1[1].id : null;
    final session3Id = updatedSessions1.length > 2 ? updatedSessions1[2].id : null;
    
    // Comment out phần tạo sessions thủ công (đã không cần nữa)
    /*
    final session1Id = await db.insert('attendance_sessions', {
      'sessionCode': 'SES001',
      'title': 'Lập trình thiết bị di động - Buổi 1',
      'description': 'Giới thiệu Flutter và Dart',
      'subjectId': subjectId.id!,
      'classCode': 'LTTBDD2024',
      'sessionNumber': 1,
      'sessionDate': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'location': 'Phòng A101',
      'status': 'completed',
      'creatorId': teacherId,
      'createdAt': now,
      'updatedAt': now,
    });

    final session2Id = await db.insert('attendance_sessions', {
      'sessionCode': 'SES002',
      'title': 'Lập trình thiết bị di động - Buổi 2',
      'description': 'Widget và State Management',
      'classCode': 'LTTBDD2024',
      'sessionDate': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'location': 'Phòng A101',
      'status': 'completed',
      'creatorId': teacherId,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('attendance_sessions', {
      'sessionCode': 'SES003',
      'title': 'Lập trình thiết bị di động - Buổi 3',
      'description': 'Local Database với SQLite',
      'classCode': 'LTTBDD2024',
      'sessionDate': DateTime.now().toIso8601String(),
      'location': 'Phòng A101',
      'status': 'scheduled',
      'creatorId': teacherId,
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('attendance_sessions', {
      'sessionCode': 'SES004',
      'title': 'Lập trình thiết bị di động - Buổi 4',
      'description': 'QR Code và Camera',
      'classCode': 'LTTBDD2024',
      'sessionDate': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'location': 'Phòng A101',
      'status': 'scheduled',
      'creatorId': teacherId,
      'createdAt': now,
      'updatedAt': now,
    });
    */

    // ========== CREATE ATTENDANCE RECORDS ==========
    // Chỉ tạo records nếu có sessions (chỉ cho các buổi đã hoàn thành)
    if (session1Id != null && session2Id != null) {
      // Session 1 - Buổi đã hoàn thành, đã điểm danh (LTTBDD2024)
      // Student 1-4 trong lớp LTTBDD2024
      await db.insert('attendance_records', {
        'sessionId': session1Id,
        'studentId': student1Id,
      'status': 'present',
      'checkInTime': DateTime.now().subtract(const Duration(days: 2, hours: -2)).toIso8601String(),
      'note': 'Điểm danh đầy đủ',
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('attendance_records', {
      'sessionId': session1Id,
      'studentId': student2Id,
      'status': 'present',
      'checkInTime': DateTime.now().subtract(const Duration(days: 2, hours: -2)).toIso8601String(),
      'note': 'Điểm danh đầy đủ',
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('attendance_records', {
      'sessionId': session1Id,
      'studentId': student3Id,
      'status': 'late',
      'checkInTime': DateTime.now().subtract(const Duration(days: 2, hours: -1)).toIso8601String(),
      'note': 'Đi muộn 30 phút',
      'createdAt': now,
      'updatedAt': now,
    });

    // Session 2 - Buổi đã qua, đã điểm danh
    await db.insert('attendance_records', {
      'sessionId': session2Id,
      'studentId': student1Id,
      'status': 'present',
      'checkInTime': DateTime.now().subtract(const Duration(days: 1, hours: -2)).toIso8601String(),
      'note': 'Điểm danh đầy đủ',
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('attendance_records', {
      'sessionId': session2Id,
      'studentId': student2Id,
      'status': 'present',
      'checkInTime': DateTime.now().subtract(const Duration(days: 1, hours: -2)).toIso8601String(),
      'note': 'Điểm danh đầy đủ',
      'createdAt': now,
      'updatedAt': now,
    });

    await db.insert('attendance_records', {
      'sessionId': session2Id,
      'studentId': student4Id,
      'status': 'absent',
      'checkInTime': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'note': 'Vắng không lý do',
      'createdAt': now,
      'updatedAt': now,
      });
    }

    _hasSeeded = true;
    print('');
    print('✅ ==========================================');
    print('   DEMO DATA CREATED!');
    print('==========================================');
    print('📧 Admin 1: admin1@gmail.com / 123');
    print('📧 Admin 2: admin2@gmail.com / 123');
    print('👨‍🏫 Teacher 1-3: teacher1@gmail.com - teacher3@gmail.com / 123');
    print('👨‍🎓 Student 1-30: student1@gmail.com - student30@gmail.com / 123');
    print('');
    print('📚 Đã tạo:');
    print('   - 2 admin');
    print('   - 3 giáo viên (Teacher 1 có 5 lớp, Teacher 2 có 2 lớp, Teacher 3 có 3 lớp)');
    print('   - 30 học sinh (nhiều lớp)');
    print('   - 10 lớp học phần (subjects)');
    print('   - Nhiều buổi học với 3 trạng thái: đã hoàn thành, đang diễn ra, sắp tới');
    print('   - Một số bản ghi điểm danh mẫu');
    print('==========================================');
    print('');
  }

  // ============================================
  // QR Token CRUD Operations (Anti-abuse)
  // ============================================

  Future<int> createQrToken(Map<String, dynamic> qrToken) async {
    final db = await database;
    return await db.insert('qr_tokens', qrToken);
  }

  Future<Map<String, dynamic>?> getQrTokenByToken(String token) async {
    final db = await database;
    final results = await db.query(
      'qr_tokens',
      where: 'token = ?',
      whereArgs: [token],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getQrTokensBySession(int sessionId) async {
    final db = await database;
    return await db.query(
      'qr_tokens',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> updateQrToken(Map<String, dynamic> qrToken) async {
    final db = await database;
    return await db.update(
      'qr_tokens',
      qrToken,
      where: 'id = ?',
      whereArgs: [qrToken['id']],
    );
  }

  Future<int> deleteExpiredQrTokens() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.delete(
      'qr_tokens',
      where: 'expiresAt < ? AND isUsed = 0',
      whereArgs: [now],
    );
  }

  Future<int> deleteQrToken(int id) async {
    final db = await database;
    return await db.delete(
      'qr_tokens',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================
  // Export History CRUD Operations
  // ============================================

  Future<int> createExportHistory(Map<String, dynamic> exportHistory) async {
    final db = await database;
    return await db.insert('export_history', exportHistory);
  }

  Future<List<Map<String, dynamic>>> getExportHistoryByUser(int userId, {int limit = 50}) async {
    final db = await database;
    return await db.query(
      'export_history',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'exportedAt DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getAllExportHistory({int limit = 100}) async {
    final db = await database;
    return await db.query(
      'export_history',
      orderBy: 'exportedAt DESC',
      limit: limit,
    );
  }

  Future<int> deleteExportHistory(int id) async {
    final db = await database;
    return await db.delete(
      'export_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

