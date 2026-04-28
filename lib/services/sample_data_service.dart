import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../database/database_helper.dart';
import '../models/app_user.dart';
import '../models/subject.dart';
import '../models/student.dart';
import '../models/attendance_session.dart';

class SampleDataService {
  static final SampleDataService instance = SampleDataService._init();
  final DatabaseHelper _db = DatabaseHelper.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  SampleDataService._init();

  /// Create user in Firebase Auth and Firestore
  /// Returns the AppUser on success, null if already exists
  Future<AppUser?> _createUserInAuthAndFirestore({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      final existingUser = await _db.getUserByEmail(email);
      if (existingUser != null) {
        debugPrint('✓ User already exists in Firestore: $email');
        return existingUser;
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw 'Tạo tài khoản trong Firebase Auth thất bại';
      }

      final uid = credential.user!.uid;
      await credential.user!.updateDisplayName(displayName);

      final passwordHash = _hashPassword(password);
      final user = AppUser(
        uid: uid,
        email: email,
        displayName: displayName,
        passwordHash: passwordHash,
        role: role,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _db.createUser(user);
      debugPrint('✓ Created user in Auth and Firestore: $email (UID: $uid)');

      // Sign out so subsequent users can be created independently
      await _auth.signOut();

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // User already exists in Auth - check Firestore
        final existingUser = await _db.getUserByEmail(email);
        if (existingUser != null) {
          return existingUser;
        }
        // Auth user exists but no Firestore record - sign in to grab UID
        try {
          final authUser = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          if (authUser.user != null) {
            final uid = authUser.user!.uid;
            final passwordHash = _hashPassword(password);
            final user = AppUser(
              uid: uid,
              email: email,
              displayName: displayName,
              passwordHash: passwordHash,
              role: role,
              createdAt: DateTime.now(),
              lastLogin: DateTime.now(),
            );
            await _db.createUser(user);
            await _auth.signOut();
            debugPrint('✓ Created Firestore record for existing Auth user: $email (UID: $uid)');
            return user;
          }
        } catch (_) {
          // Sign-in failed - password likely wrong
        }
        debugPrint('⚠ User exists in Auth but cannot create Firestore record (password may be wrong): $email');
        return null;
      }
      rethrow;
    } catch (e) {
      debugPrint('❌ Error creating user: $e');
      rethrow;
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Initialize users: 1 admin, 2 teachers, 3 students
  /// Creates Auth users sequentially, then their Firestore profiles
  /// Returns the lists of teachers and students
  Future<Map<String, List<AppUser>>> initializeSampleUsers() async {
    final List<AppUser> teachers = [];
    final List<AppUser> students = [];

    try {
      debugPrint('════════════════════════════════════════');
      debugPrint('STEP 1: Create users in Firebase Auth and Firestore');
      debugPrint('════════════════════════════════════════');

      debugPrint('1.1. Creating Admin user...');
      final admin = await _createUserInAuthAndFirestore(
        email: 'admin@gmail.com',
        password: '123456',
        displayName: 'Quản trị viên',
        role: UserRole.admin,
      );
      if (admin != null) {
        debugPrint('✓ Admin: admin@gmail.com / 123456 (UID: ${admin.uid})');
      } else {
        debugPrint('⚠ Admin already exists or could not be created');
      }

      debugPrint('1.2. Creating Teacher users...');
      for (int i = 1; i <= 2; i++) {
        final email = i == 1 ? 'teacher@gmail.com' : 'teacher$i@gmail.com';
        final teacher = await _createUserInAuthAndFirestore(
          email: email,
          password: '123456',
          displayName: 'Giáo viên $i',
          role: UserRole.teacher,
        );
        if (teacher != null) {
          teachers.add(teacher);
          debugPrint('✓ Teacher $i: $email / 123456 (UID: ${teacher.uid})');
        } else {
          // Fall back to existing Firestore record
          final existing = await _db.getUserByEmail(email);
          if (existing != null) {
            teachers.add(existing);
            debugPrint('✓ Teacher $i already exists: $email');
          }
        }
      }

      debugPrint('1.3. Creating Student users...');
      for (int i = 1; i <= 3; i++) {
        final email = i == 1 ? 'student@gmail.com' : 'student$i@gmail.com';
        final student = await _createUserInAuthAndFirestore(
          email: email,
          password: '123456',
          displayName: 'Sinh viên $i',
          role: UserRole.student,
        );
        if (student != null) {
          students.add(student);
          debugPrint('✓ Student $i: $email / 123456 (UID: ${student.uid})');
        } else {
          final existing = await _db.getUserByEmail(email);
          if (existing != null) {
            students.add(existing);
            debugPrint('✓ Student $i already exists: $email');
          }
        }
      }

      debugPrint('✓ Finished creating users: 1 admin, ${teachers.length} teachers, ${students.length} students');
      return {'teachers': teachers, 'students': students};
    } catch (e) {
      debugPrint('❌ Error creating users: $e');
      return {'teachers': teachers, 'students': students};
    }
  }

  /// Initialize subjects per teacher (each teacher teaches 3 subjects, creatorId = teacher UID)
  Future<List<Subject>> initializeSampleSubjects(List<AppUser> teachers) async {
    try {
      debugPrint('════════════════════════════════════════');
      debugPrint('STEP 2: Create subjects in Firestore');
      debugPrint('════════════════════════════════════════');

      if (teachers.isEmpty) {
        debugPrint('❌ No teachers available, cannot create subjects');
        return [];
      }

      debugPrint('✓ Found ${teachers.length} teachers to assign subjects to');

      final existingSubjects = await _db.getAllSubjects();
      final existingSubjectCodes = existingSubjects.map((s) => s.subjectCode).toSet();

      // 6 sample subjects (3 per teacher)
      final sampleSubjects = [
        // Teacher 1
        {
          'subjectCode': 'LTTBDD',
          'subjectName': 'Lập trình thiết bị di động',
          'classCode': 'LTTBDD2024',
          'description': 'Môn học về lập trình ứng dụng di động',
        },
        {
          'subjectCode': 'CTDLGT',
          'subjectName': 'Cấu trúc dữ liệu và giải thuật',
          'classCode': 'CTDLGT2024',
          'description': 'Môn học về cấu trúc dữ liệu và các thuật toán',
        },
        {
          'subjectCode': 'CSDL',
          'subjectName': 'Cơ sở dữ liệu',
          'classCode': 'CSDL2024',
          'description': 'Môn học về thiết kế và quản lý cơ sở dữ liệu',
        },
        // Teacher 2
        {
          'subjectCode': 'LTW',
          'subjectName': 'Lập trình Web',
          'classCode': 'LTW2024',
          'description': 'Môn học về phát triển ứng dụng web',
        },
        {
          'subjectCode': 'MMT',
          'subjectName': 'Mạng máy tính',
          'classCode': 'MMT2024',
          'description': 'Môn học về mạng máy tính và giao thức mạng',
        },
        {
          'subjectCode': 'HTTT',
          'subjectName': 'Hệ thống thông tin',
          'classCode': 'HTTT2024',
          'description': 'Môn học về phân tích và thiết kế hệ thống thông tin',
        },
      ];

      final List<Subject> createdSubjects = [];

      for (int i = 0; i < sampleSubjects.length; i++) {
        try {
          final subjectData = sampleSubjects[i];
          final subjectCode = subjectData['subjectCode']!;

          if (existingSubjectCodes.contains(subjectCode)) {
            debugPrint('⚠ Subject $subjectCode already exists, skipping');
            final existing = existingSubjects.firstWhere(
              (s) => s.subjectCode == subjectCode,
              orElse: () => throw Exception('Subject not found'),
            );
            createdSubjects.add(existing);
            continue;
          }

          final teacherIndex = i ~/ 3; // 0-2 -> teacher 0, 3-5 -> teacher 1

          if (teacherIndex >= teachers.length) {
            debugPrint('⚠ Not enough teachers for subject ${i + 1}');
            continue;
          }

          final teacher = teachers[teacherIndex];
          final creatorId = teacher.uid;

          final subject = Subject(
            subjectCode: subjectCode,
            subjectName: subjectData['subjectName']!,
            classCode: subjectData['classCode']!,
            description: subjectData['description'],
            creatorId: creatorId,
          );

          final createdSubject = await _db.createSubject(subject);
          createdSubjects.add(createdSubject);
          debugPrint('✓ Created subject: ${subject.subjectCode} - ${subject.subjectName} (Teacher: ${teacher.displayName}, UID: $creatorId)');
        } catch (e) {
          debugPrint('⚠ Error creating subject ${i + 1}: $e');
        }
      }

      debugPrint('✓ Finished creating ${createdSubjects.length} subjects');
      return createdSubjects;
    } catch (e) {
      debugPrint('❌ Error creating subjects: $e');
      return [];
    }
  }

  /// Initialize Student records (each student enrolled in 2 subjects via subjectIds)
  Future<void> initializeSampleStudents(
    List<AppUser> studentUsers,
    List<Subject> subjects,
  ) async {
    try {
      debugPrint('════════════════════════════════════════');
      debugPrint('STEP 3: Create Student records in Firestore');
      debugPrint('════════════════════════════════════════');

      if (studentUsers.isEmpty) {
        debugPrint('⚠ No student users, skipping Student records');
        return;
      }

      if (subjects.isEmpty) {
        debugPrint('⚠ No subjects, skipping Student records');
        return;
      }

      final existingStudents = await _db.getAllStudents();
      final existingEmails = existingStudents.map((s) => s.email.toLowerCase()).toSet();

      int createdCount = 0;

      // Allocation: each student takes 2 subjects
      // Student 1: subjects 1, 2 / Student 2: 3, 4 / Student 3: 5, 6
      for (int i = 0; i < studentUsers.length && i < 3; i++) {
        final studentUser = studentUsers[i];

        if (existingEmails.contains(studentUser.email.toLowerCase())) {
          debugPrint('✓ Student record already exists for: ${studentUser.email}');
          continue;
        }

        final subjectIndex1 = i * 2;
        final subjectIndex2 = i * 2 + 1;

        if (subjectIndex1 >= subjects.length || subjectIndex2 >= subjects.length) {
          debugPrint('⚠ Not enough subjects for student ${i + 1}');
          continue;
        }

        final subject1 = subjects[subjectIndex1];
        final subject2 = subjects[subjectIndex2];

        final studentId = '${studentUser.email.split('@')[0]}_${DateTime.now().millisecondsSinceEpoch}';
        final subjectIds = [
          subject1.id.toString(),
          subject2.id.toString(),
        ];

        try {
          await _db.createStudent(Student(
            studentId: studentId,
            name: studentUser.displayName,
            email: studentUser.email,
            subjectIds: subjectIds,
          ));
          createdCount++;
          debugPrint('✓ Created Student: $studentId - ${studentUser.displayName} (Subjects: ${subject1.subjectCode}, ${subject2.subjectCode})');
        } catch (e) {
          debugPrint('⚠ Error creating Student record for ${studentUser.email}: $e');
        }
      }

      debugPrint('✓ Finished creating $createdCount Student records');
    } catch (e) {
      debugPrint('❌ Error creating Student records: $e');
    }
  }

  /// Compute the date/time for a session.
  /// First 3 sessions: 3, 2, 1 weeks ago (already completed).
  /// Remaining 6 sessions: weekly intervals starting next week (scheduled).
  /// All sessions are at 07:30.
  DateTime _calculateSessionDate(DateTime now, int sessionNum) {
    final baseDate = DateTime(now.year, now.month, now.day, 7, 30);

    if (sessionNum <= 3) {
      // First 3: already completed (3, 2, 1 weeks ago)
      final weeksAgo = 4 - sessionNum;
      return baseDate.subtract(Duration(days: weeksAgo * 7));
    } else {
      // Remaining 6: scheduled, weekly intervals starting next week
      final weeksFromNow = sessionNum - 3;
      return baseDate.add(Duration(days: weeksFromNow * 7));
    }
  }

  /// Initialize 9 sessions per subject (first 3 completed, last 6 scheduled).
  Future<void> initializeSampleSessions(List<Subject> subjects) async {
    try {
      debugPrint('════════════════════════════════════════');
      debugPrint('STEP 4: Create sessions for each subject');
      debugPrint('════════════════════════════════════════');

      if (subjects.isEmpty) {
        debugPrint('⚠ No subjects available, skipping sessions');
        return;
      }

      int createdCount = 0;
      int updatedCount = 0;

      for (final subject in subjects) {
        if (subject.id == null || subject.creatorId == null) {
          debugPrint('⚠ Subject ${subject.subjectCode} missing id or creatorId, skipping');
          continue;
        }

        for (int sessionNum = 1; sessionNum <= 9; sessionNum++) {
          try {
            final sessionCode = '${subject.subjectCode}-BUOI$sessionNum';

            final now = DateTime.now();
            final sessionDate = _calculateSessionDate(now, sessionNum);
            final isCompleted = sessionNum <= 3;

            final existingSession = await _db.getSessionByCode(sessionCode);
            if (existingSession != null) {
              // Refresh existing session with new date/status
              final updatedSession = AttendanceSession(
                id: existingSession.id,
                sessionCode: existingSession.sessionCode,
                title: existingSession.title,
                description: existingSession.description,
                subjectId: existingSession.subjectId,
                classCode: existingSession.classCode,
                sessionNumber: existingSession.sessionNumber,
                status: isCompleted ? SessionStatus.completed : SessionStatus.scheduled,
                sessionDate: sessionDate,
                creatorId: existingSession.creatorId,
              );

              await _db.updateSession(updatedSession);
              updatedCount++;
              debugPrint('✓ Updated session: $sessionCode - ${updatedSession.title} (Date: ${sessionDate.toString()}, Status: ${isCompleted ? "completed" : "scheduled"})');
              continue;
            }

            final session = AttendanceSession(
              sessionCode: sessionCode,
              title: 'Buổi $sessionNum',
              description: 'Buổi học thứ $sessionNum của môn ${subject.subjectName}',
              subjectId: subject.id!,
              classCode: subject.classCode,
              sessionNumber: sessionNum,
              status: isCompleted ? SessionStatus.completed : SessionStatus.scheduled,
              sessionDate: sessionDate,
              creatorId: subject.creatorId!,
            );

            await _db.createSession(session);
            createdCount++;
            debugPrint('✓ Created session: $sessionCode - ${session.title} (Date: ${sessionDate.toString()}, Status: ${isCompleted ? "completed" : "scheduled"})');
          } catch (e) {
            debugPrint('⚠ Error creating session $sessionNum for subject ${subject.subjectCode}: $e');
          }
        }
      }

      debugPrint('✓ Done: created $createdCount sessions, updated $updatedCount sessions');
    } catch (e) {
      debugPrint('❌ Error creating sessions: $e');
    }
  }

  /// Initialize all sample data sequentially (no delays).
  Future<void> initializeAllSampleData() async {
    try {
      debugPrint('════════════════════════════════════════');
      debugPrint('STARTING SAMPLE DATA SEED');
      debugPrint('════════════════════════════════════════');

      final usersResult = await initializeSampleUsers();
      final teachers = usersResult['teachers'] ?? [];
      final students = usersResult['students'] ?? [];

      if (teachers.isEmpty) {
        debugPrint('❌ No teachers found, aborting');
        return;
      }

      final subjects = await initializeSampleSubjects(teachers);

      if (subjects.isEmpty) {
        debugPrint('❌ No subjects available, aborting');
        return;
      }

      await initializeSampleStudents(students, subjects);

      await initializeSampleSessions(subjects);

      debugPrint('════════════════════════════════════════');
      debugPrint('✅ SAMPLE DATA SEED COMPLETE');
      debugPrint('════════════════════════════════════════');
    } catch (e) {
      debugPrint('❌ Error seeding data: $e');
      rethrow;
    }
  }

  /// Check whether sample users already exist
  Future<bool> checkSampleUsersExist() async {
    try {
      final users = await _db.getAllUsers();
      final adminExists = users.any((u) => u.email == 'admin@gmail.com');
      final teacherExists = users.any((u) => u.email.startsWith('teacher') && u.email.endsWith('@gmail.com'));
      final studentExists = users.any((u) => u.email.startsWith('student') && u.email.endsWith('@gmail.com'));
      
      return adminExists && teacherExists && studentExists;
    } catch (e) {
      return false;
    }
  }
}
