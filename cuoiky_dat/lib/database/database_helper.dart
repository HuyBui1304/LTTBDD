import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/student.dart';
import '../models/class_schedule.dart';
import '../models/topic.dart';
import '../models/question.dart';
import '../models/quiz.dart';
import '../models/quiz_result.dart';
import '../models/user_progress.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('lms_quiz.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'user',
        createdAt INTEGER NOT NULL,
        lastLoginAt INTEGER
      )
    ''');

    await db.execute('CREATE INDEX idx_users_email ON users(email)');
    await db.execute('CREATE INDEX idx_users_role ON users(role)');

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

    // LMS/Quiz tables
    await _createLMSTables(db);
  }

  Future<void> _createLMSTables(Database db) async {
    // Topics table
    await db.execute('''
      CREATE TABLE topics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Questions table
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        questionText TEXT NOT NULL,
        options TEXT NOT NULL,
        correctAnswerIndex INTEGER NOT NULL,
        topicId INTEGER NOT NULL,
        explanation TEXT,
        difficulty INTEGER DEFAULT 1,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (topicId) REFERENCES topics(id)
      )
    ''');

    // Quizzes table
    await db.execute('''
      CREATE TABLE quizzes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        timeLimit INTEGER,
        questionCount INTEGER NOT NULL,
        topicIds TEXT,
        mode TEXT DEFAULT 'random',
        shuffleQuestions INTEGER DEFAULT 1,
        showResultImmediately INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Quiz results table
    await db.execute('''
      CREATE TABLE quiz_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quizId INTEGER NOT NULL,
        quizTitle TEXT NOT NULL,
        totalQuestions INTEGER NOT NULL,
        correctAnswers INTEGER NOT NULL,
        wrongAnswers INTEGER NOT NULL,
        score REAL NOT NULL,
        timeSpent INTEGER,
        answers TEXT NOT NULL,
        completedAt INTEGER NOT NULL,
        mode TEXT DEFAULT 'random',
        FOREIGN KEY (quizId) REFERENCES quizzes(id)
      )
    ''');

    // User progress table
    await db.execute('''
      CREATE TABLE user_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topicId INTEGER NOT NULL,
        topicName TEXT NOT NULL,
        totalQuestions INTEGER DEFAULT 0,
        correctAnswers INTEGER DEFAULT 0,
        wrongAnswers INTEGER DEFAULT 0,
        averageScore REAL DEFAULT 0,
        lastPracticedAt INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY (topicId) REFERENCES topics(id)
      )
    ''');

    // Create indexes for LMS tables
    await db.execute('CREATE INDEX idx_questions_topicId ON questions(topicId)');
    await db.execute('CREATE INDEX idx_questions_difficulty ON questions(difficulty)');
    await db.execute('CREATE INDEX idx_quiz_results_quizId ON quiz_results(quizId)');
    await db.execute('CREATE INDEX idx_quiz_results_completedAt ON quiz_results(completedAt)');
    await db.execute('CREATE INDEX idx_user_progress_topicId ON user_progress(topicId)');
    await db.execute('CREATE INDEX idx_user_progress_lastPracticedAt ON user_progress(lastPracticedAt)');
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
    if (oldVersion < 3) {
      // Add LMS tables
      await _createLMSTables(db);
    }
    if (oldVersion < 4) {
      // Add users table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          name TEXT NOT NULL,
          role TEXT NOT NULL DEFAULT 'user',
          createdAt INTEGER NOT NULL,
          lastLoginAt INTEGER
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_users_role ON users(role)');
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

  // ========== LMS/Quiz CRUD Operations ==========

  // Topic CRUD operations
  Future<int> insertTopic(Topic topic) async {
    final db = await database;
    final id = await db.insert('topics', topic.toMap());
    await _logAction('CREATE', 'topics', id, topic.toMap());
    return id;
  }

  Future<List<Topic>> getAllTopics({int? limit, int offset = 0}) async {
    final db = await database;
    final maps = await db.query(
      'topics',
      orderBy: 'name',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => Topic.fromMap(map)).toList();
  }

  Future<Topic?> getTopicById(int id) async {
    final db = await database;
    final maps = await db.query('topics', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Topic.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTopic(Topic topic) async {
    final db = await database;
    final result = await db.update('topics', topic.toMap(), where: 'id = ?', whereArgs: [topic.id]);
    if (result > 0 && topic.id != null) {
      await _logAction('UPDATE', 'topics', topic.id!, topic.toMap());
    }
    return result;
  }

  Future<int> deleteTopic(int id) async {
    final db = await database;
    final topic = await getTopicById(id);
    final result = await db.delete('topics', where: 'id = ?', whereArgs: [id]);
    if (result > 0) {
      await _logAction('DELETE', 'topics', id, topic?.toMap());
    }
    return result;
  }

  // Question CRUD operations
  Future<int> insertQuestion(Question question) async {
    final db = await database;
    final id = await db.insert('questions', question.toMap());
    await _logAction('CREATE', 'questions', id, question.toMap());
    return id;
  }

  Future<List<Question>> getAllQuestions({int? limit, int offset = 0}) async {
    final db = await database;
    final maps = await db.query('questions', orderBy: 'createdAt DESC', limit: limit, offset: offset);
    return maps.map((map) => Question.fromMap(map)).toList();
  }

  Future<List<Question>> getQuestionsByTopic(int topicId, {int? limit}) async {
    final db = await database;
    final maps = await db.query(
      'questions',
      where: 'topicId = ?',
      whereArgs: [topicId],
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return maps.map((map) => Question.fromMap(map)).toList();
  }

  Future<List<Question>> getRandomQuestions({
    int? topicId,
    int? difficulty,
    int count = 10,
  }) async {
    final db = await database;
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (topicId != null) {
      whereClause += ' AND topicId = ?';
      whereArgs.add(topicId);
    }
    if (difficulty != null) {
      whereClause += ' AND difficulty = ?';
      whereArgs.add(difficulty);
    }

    final maps = await db.query(
      'questions',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'RANDOM()',
      limit: count,
    );
    return maps.map((map) => Question.fromMap(map)).toList();
  }

  Future<Question?> getQuestionById(int id) async {
    final db = await database;
    final maps = await db.query('questions', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Question.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateQuestion(Question question) async {
    final db = await database;
    final result = await db.update('questions', question.toMap(), where: 'id = ?', whereArgs: [question.id]);
    if (result > 0 && question.id != null) {
      await _logAction('UPDATE', 'questions', question.id!, question.toMap());
    }
    return result;
  }

  Future<int> deleteQuestion(int id) async {
    final db = await database;
    final question = await getQuestionById(id);
    final result = await db.delete('questions', where: 'id = ?', whereArgs: [id]);
    if (result > 0) {
      await _logAction('DELETE', 'questions', id, question?.toMap());
    }
    return result;
  }

  Future<int> getQuestionsCount({int? topicId}) async {
    final db = await database;
    if (topicId != null) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM questions WHERE topicId = ?', [topicId]);
      return Sqflite.firstIntValue(result) ?? 0;
    }
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM questions');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Quiz CRUD operations
  Future<int> insertQuiz(Quiz quiz) async {
    final db = await database;
    final id = await db.insert('quizzes', quiz.toMap());
    await _logAction('CREATE', 'quizzes', id, quiz.toMap());
    return id;
  }

  Future<List<Quiz>> getAllQuizzes({int? limit, int offset = 0}) async {
    final db = await database;
    final maps = await db.query('quizzes', orderBy: 'createdAt DESC', limit: limit, offset: offset);
    return maps.map((map) => Quiz.fromMap(map)).toList();
  }

  Future<Quiz?> getQuizById(int id) async {
    final db = await database;
    final maps = await db.query('quizzes', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Quiz.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateQuiz(Quiz quiz) async {
    final db = await database;
    final result = await db.update('quizzes', quiz.toMap(), where: 'id = ?', whereArgs: [quiz.id]);
    if (result > 0 && quiz.id != null) {
      await _logAction('UPDATE', 'quizzes', quiz.id!, quiz.toMap());
    }
    return result;
  }

  Future<int> deleteQuiz(int id) async {
    final db = await database;
    final quiz = await getQuizById(id);
    final result = await db.delete('quizzes', where: 'id = ?', whereArgs: [id]);
    if (result > 0) {
      await _logAction('DELETE', 'quizzes', id, quiz?.toMap());
    }
    return result;
  }

  // Quiz Result CRUD operations
  Future<int> insertQuizResult(QuizResult result) async {
    final db = await database;
    final id = await db.insert('quiz_results', result.toMap());
    await _logAction('CREATE', 'quiz_results', id, result.toMap());
    
    // Update user progress
    await _updateUserProgress(result);
    
    return id;
  }

  Future<void> _updateUserProgress(QuizResult result) async {
    // Get questions from result to determine topics
    final questions = <int, Question>{};
    for (final questionId in result.answers.keys) {
      final question = await getQuestionById(questionId);
      if (question != null) {
        questions[questionId] = question;
      }
    }

    // Group by topic and update progress
    final topicStats = <int, Map<String, int>>{};
    for (final entry in result.answers.entries) {
      final question = questions[entry.key];
      if (question != null) {
        final topicId = question.topicId;
        if (!topicStats.containsKey(topicId)) {
          topicStats[topicId] = {'correct': 0, 'wrong': 0};
        }
        if (entry.value == question.correctAnswerIndex) {
          topicStats[topicId]!['correct'] = topicStats[topicId]!['correct']! + 1;
        } else {
          topicStats[topicId]!['wrong'] = topicStats[topicId]!['wrong']! + 1;
        }
      }
    }

    // Update or create user progress for each topic
    for (final entry in topicStats.entries) {
      final topicId = entry.key;
      final stats = entry.value;
      final topic = await getTopicById(topicId);
      if (topic != null) {
        await _upsertUserProgress(
          topicId: topicId,
          topicName: topic.name,
          correctAnswers: stats['correct']!,
          wrongAnswers: stats['wrong']!,
        );
      }
    }
  }

  Future<void> _upsertUserProgress({
    required int topicId,
    required String topicName,
    required int correctAnswers,
    required int wrongAnswers,
  }) async {
    final db = await database;
    final existing = await db.query(
      'user_progress',
      where: 'topicId = ?',
      whereArgs: [topicId],
    );

    final now = DateTime.now();
    final total = correctAnswers + wrongAnswers;
    final score = total > 0 ? (correctAnswers / total) * 100 : 0.0;

    if (existing.isNotEmpty) {
      final current = UserProgress.fromMap(existing.first);
      final newTotal = current.totalQuestions + total;
      final newCorrect = current.correctAnswers + correctAnswers;
      final newWrong = current.wrongAnswers + wrongAnswers;
      final newAvg = newTotal > 0 ? ((current.averageScore * current.totalQuestions + score * total) / newTotal) : current.averageScore;

      await db.update(
        'user_progress',
        {
          'totalQuestions': newTotal,
          'correctAnswers': newCorrect,
          'wrongAnswers': newWrong,
          'averageScore': newAvg,
          'lastPracticedAt': now.millisecondsSinceEpoch,
          'updatedAt': now.millisecondsSinceEpoch,
        },
        where: 'topicId = ?',
        whereArgs: [topicId],
      );
    } else {
      await db.insert('user_progress', {
        'topicId': topicId,
        'topicName': topicName,
        'totalQuestions': total,
        'correctAnswers': correctAnswers,
        'wrongAnswers': wrongAnswers,
        'averageScore': score,
        'lastPracticedAt': now.millisecondsSinceEpoch,
        'createdAt': now.millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      });
    }
  }

  Future<List<QuizResult>> getAllQuizResults({int? limit, int offset = 0}) async {
    final db = await database;
    final maps = await db.query(
      'quiz_results',
      orderBy: 'completedAt DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => QuizResult.fromMap(map)).toList();
  }

  Future<List<QuizResult>> getQuizResultsByQuizId(int quizId) async {
    final db = await database;
    final maps = await db.query(
      'quiz_results',
      where: 'quizId = ?',
      whereArgs: [quizId],
      orderBy: 'completedAt DESC',
    );
    return maps.map((map) => QuizResult.fromMap(map)).toList();
  }

  Future<QuizResult?> getQuizResultById(int id) async {
    final db = await database;
    final maps = await db.query('quiz_results', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return QuizResult.fromMap(maps.first);
    }
    return null;
  }

  // User Progress operations
  Future<List<UserProgress>> getAllUserProgress() async {
    final db = await database;
    final maps = await db.query('user_progress', orderBy: 'lastPracticedAt DESC');
    return maps.map((map) => UserProgress.fromMap(map)).toList();
  }

  Future<UserProgress?> getUserProgressByTopicId(int topicId) async {
    final db = await database;
    final maps = await db.query('user_progress', where: 'topicId = ?', whereArgs: [topicId]);
    if (maps.isNotEmpty) {
      return UserProgress.fromMap(maps.first);
    }
    return null;
  }

  // Statistics for LMS
  Future<Map<String, int>> getQuestionsCountByTopic() async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT topicId, COUNT(*) as count FROM questions GROUP BY topicId',
    );
    return {for (var map in maps) map['topicId'].toString(): map['count'] as int};
  }

  Future<Map<String, int>> getQuestionsByDifficulty() async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT difficulty, COUNT(*) as count FROM questions GROUP BY difficulty',
    );
    return {for (var map in maps) map['difficulty'].toString(): map['count'] as int};
  }

  Future<double> getAverageQuizScore() async {
    final db = await database;
    final result = await db.rawQuery('SELECT AVG(score) as avg FROM quiz_results');
    return (result.first['avg'] as num?)?.toDouble() ?? 0.0;
  }

  // User CRUD operations
  Future<int> insertUser(User user) async {
    final db = await database;
    final id = await db.insert('users', user.toMap());
    await _logAction('CREATE', 'users', id, user.toMap());
    return id;
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users', orderBy: 'createdAt DESC');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    final count = await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
    await _logAction('UPDATE', 'users', user.id!, user.toMap());
    return count;
  }

  Future<int> updateUserLastLogin(int userId) async {
    final db = await database;
    return await db.update(
      'users',
      {'lastLoginAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateUserPassword(int userId, String hashedPassword) async {
    final db = await database;
    return await db.update(
      'users',
      {'password': hashedPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    final count = await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _logAction('DELETE', 'users', id, null);
    return count;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

