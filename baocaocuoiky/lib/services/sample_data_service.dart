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

  /// Tạo user trong Firebase Auth và Firestore
  /// Trả về AppUser nếu thành công, null nếu đã tồn tại
  Future<AppUser?> _createUserInAuthAndFirestore({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      // Kiểm tra xem user đã tồn tại trong Firestore chưa
      final existingUser = await _db.getUserByEmail(email);
      if (existingUser != null) {
        debugPrint('✓ User đã tồn tại trong Firestore: $email');
        return existingUser;
      }

      // Tạo user trong Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw 'Tạo tài khoản trong Firebase Auth thất bại';
      }

      final uid = credential.user!.uid;
      await credential.user!.updateDisplayName(displayName);

      // Tạo user profile trong Firestore (users/{uid})
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
      debugPrint('✓ Đã tạo user trong Auth và Firestore: $email (UID: $uid)');
      
      // Sign out để không ảnh hưởng đến các user khác
      await _auth.signOut();
      
      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // User đã tồn tại trong Auth - kiểm tra Firestore
        final existingUser = await _db.getUserByEmail(email);
        if (existingUser != null) {
          return existingUser;
        }
        // User có trong Auth nhưng không có trong Firestore
        // Cố đăng nhập để lấy UID và tạo trong Firestore
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
            debugPrint('✓ Đã tạo user trong Firestore (user đã có trong Auth): $email (UID: $uid)');
            return user;
          }
        } catch (_) {
          // Không thể đăng nhập - password có thể sai
        }
        debugPrint('⚠ User có trong Auth nhưng không thể tạo trong Firestore (password có thể sai): $email');
        return null;
      }
      rethrow;
    } catch (e) {
      debugPrint('❌ Lỗi khi tạo user: $e');
      rethrow;
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Khởi tạo users: 1 admin, 2 teacher, 3 student
  /// Tạo tuần tự trong Firebase Auth, sau đó tạo profile trong Firestore
  /// Trả về danh sách teachers và students
  Future<Map<String, List<AppUser>>> initializeSampleUsers() async {
    final List<AppUser> teachers = [];
    final List<AppUser> students = [];
    
    try {
      debugPrint('════════════════════════════════════════');
      debugPrint('BƯỚC 1: Tạo users trong Firebase Auth và Firestore');
      debugPrint('════════════════════════════════════════');

      // 1. Tạo Admin
      debugPrint('1.1. Tạo Admin user...');
      final admin = await _createUserInAuthAndFirestore(
        email: 'admin@gmail.com',
        password: '123456',
        displayName: 'Quản trị viên',
        role: UserRole.admin,
      );
      if (admin != null) {
        debugPrint('✓ Admin: admin@gmail.com / 123456 (UID: ${admin.uid})');
      } else {
        debugPrint('⚠ Admin đã tồn tại hoặc không thể tạo');
      }

      // 2. Tạo 2 Teachers
      debugPrint('1.2. Tạo Teacher users...');
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
          // Thử lấy từ Firestore nếu đã tồn tại
          final existing = await _db.getUserByEmail(email);
          if (existing != null) {
            teachers.add(existing);
            debugPrint('✓ Teacher $i đã tồn tại: $email');
          }
        }
      }

      // 3. Tạo 3 Students
      debugPrint('1.3. Tạo Student users...');
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
          // Thử lấy từ Firestore nếu đã tồn tại
          final existing = await _db.getUserByEmail(email);
          if (existing != null) {
            students.add(existing);
            debugPrint('✓ Student $i đã tồn tại: $email');
          }
        }
      }

      debugPrint('✓ Hoàn thành tạo users: 1 admin, ${teachers.length} teachers, ${students.length} students');
      return {'teachers': teachers, 'students': students};
    } catch (e) {
      debugPrint('❌ Lỗi khi tạo users: $e');
      return {'teachers': teachers, 'students': students};
    }
  }

  /// Khởi tạo subjects dựa trên teachers
  /// Mỗi teacher dạy 3 môn, creatorId = UID của teacher
  Future<List<Subject>> initializeSampleSubjects(List<AppUser> teachers) async {
    try {
      debugPrint('════════════════════════════════════════');
      debugPrint('BƯỚC 2: Tạo subjects trong Firestore');
      debugPrint('════════════════════════════════════════');

      if (teachers.isEmpty) {
        debugPrint('❌ Chưa có teachers, không thể tạo subjects');
        return [];
      }

      debugPrint('✓ Tìm thấy ${teachers.length} teachers để gán môn học');

      // Lấy danh sách subjects hiện có để kiểm tra
      final existingSubjects = await _db.getAllSubjects();
      final existingSubjectCodes = existingSubjects.map((s) => s.subjectCode).toSet();

      // Danh sách 6 môn học (mỗi teacher dạy 3 môn)
      final sampleSubjects = [
        // Teacher 1 - 3 môn học
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
        // Teacher 2 - 3 môn học
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

      // Tạo môn học và phân bổ cho các teacher (mỗi teacher dạy 3 môn)
      for (int i = 0; i < sampleSubjects.length; i++) {
        try {
          final subjectData = sampleSubjects[i];
          final subjectCode = subjectData['subjectCode']!;
          
          // Kiểm tra xem subject đã tồn tại chưa
          if (existingSubjectCodes.contains(subjectCode)) {
            debugPrint('⚠ Subject $subjectCode đã tồn tại, bỏ qua');
            // Thêm vào danh sách để return
            final existing = existingSubjects.firstWhere(
              (s) => s.subjectCode == subjectCode,
              orElse: () => throw Exception('Subject not found'),
            );
            createdSubjects.add(existing);
            continue;
          }

          final teacherIndex = i ~/ 3; // 0-2 -> teacher 0, 3-5 -> teacher 1
          
          if (teacherIndex >= teachers.length) {
            debugPrint('⚠ Không đủ teachers cho môn học ${i + 1}');
            continue;
          }

          final teacher = teachers[teacherIndex];
          final creatorId = teacher.uid; // Dùng UID trực tiếp

          final subject = Subject(
            subjectCode: subjectCode,
            subjectName: subjectData['subjectName']!,
            classCode: subjectData['classCode']!,
            description: subjectData['description'],
            creatorId: creatorId, // UID của teacher
          );

          final createdSubject = await _db.createSubject(subject);
          createdSubjects.add(createdSubject);
          debugPrint('✓ Đã tạo môn học: ${subject.subjectCode} - ${subject.subjectName} (Teacher: ${teacher.displayName}, UID: $creatorId)');
        } catch (e) {
          debugPrint('⚠ Lỗi khi tạo môn học ${i + 1}: $e');
        }
      }

      debugPrint('✓ Hoàn thành tạo ${createdSubjects.length} subjects');
      return createdSubjects;
    } catch (e) {
      debugPrint('❌ Lỗi khi tạo subjects: $e');
      return [];
    }
  }

  /// Khởi tạo Student records
  /// Mỗi student học 2 môn, lưu trong subjectIds
  Future<void> initializeSampleStudents(
    List<AppUser> studentUsers,
    List<Subject> subjects,
  ) async {
    try {
      debugPrint('════════════════════════════════════════');
      debugPrint('BƯỚC 3: Tạo Student records trong Firestore');
      debugPrint('════════════════════════════════════════');

      if (studentUsers.isEmpty) {
        debugPrint('⚠ Chưa có student users, bỏ qua tạo Student records');
        return;
      }

      if (subjects.isEmpty) {
        debugPrint('⚠ Chưa có subjects, bỏ qua tạo Student records');
        return;
      }

      // Kiểm tra xem đã có student records chưa
      final existingStudents = await _db.getAllStudents();
      final existingEmails = existingStudents.map((s) => s.email.toLowerCase()).toSet();

      int createdCount = 0;

      // Phân bổ: mỗi student user học 2 môn
      // Student 1: môn 1, 2
      // Student 2: môn 3, 4
      // Student 3: môn 5, 6
      for (int i = 0; i < studentUsers.length && i < 3; i++) {
        final studentUser = studentUsers[i];
        
        // Kiểm tra xem đã có student record cho user này chưa
        if (existingEmails.contains(studentUser.email.toLowerCase())) {
          debugPrint('✓ Student record đã tồn tại cho: ${studentUser.email}');
          continue;
        }

        final subjectIndex1 = i * 2;
        final subjectIndex2 = i * 2 + 1;

        if (subjectIndex1 >= subjects.length || subjectIndex2 >= subjects.length) {
          debugPrint('⚠ Không đủ subjects cho student ${i + 1}');
          continue;
        }

        final subject1 = subjects[subjectIndex1];
        final subject2 = subjects[subjectIndex2];

        // Tạo Student record với subjectIds
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
            subjectIds: subjectIds, // Danh sách ID môn học
          ));
          createdCount++;
          debugPrint('✓ Đã tạo Student: $studentId - ${studentUser.displayName} (Môn: ${subject1.subjectCode}, ${subject2.subjectCode})');
        } catch (e) {
          debugPrint('⚠ Lỗi khi tạo Student record cho ${studentUser.email}: $e');
        }
      }

      debugPrint('✓ Hoàn thành tạo $createdCount Student records');
    } catch (e) {
      debugPrint('❌ Lỗi khi tạo Student records: $e');
    }
  }

  /// Tính toán ngày giờ cho session
  /// 3 buổi đầu: 3 tuần trước, 2 tuần trước, 1 tuần trước (đã diễn ra)
  /// 6 buổi còn lại: cách nhau 1 tuần từ hôm nay (chưa diễn ra)
  /// Tất cả đều có giờ 7h30
  DateTime _calculateSessionDate(DateTime now, int sessionNum) {
    final baseDate = DateTime(now.year, now.month, now.day, 7, 30);
    
    if (sessionNum <= 3) {
      // 3 buổi đầu: đã diễn ra (3 tuần trước, 2 tuần trước, 1 tuần trước)
      final weeksAgo = 4 - sessionNum; // sessionNum 1 -> 3 tuần trước, 2 -> 2 tuần trước, 3 -> 1 tuần trước
      return baseDate.subtract(Duration(days: weeksAgo * 7));
    } else {
      // 6 buổi còn lại: chưa diễn ra (cách nhau 1 tuần từ hôm nay)
      final weeksFromNow = sessionNum - 3; // sessionNum 4 -> 1 tuần sau, 5 -> 2 tuần sau, ...
      return baseDate.add(Duration(days: weeksFromNow * 7));
    }
  }

  /// Khởi tạo 9 buổi học cho mỗi subject
  /// Mỗi subject có 9 buổi học (Buổi 1 đến Buổi 9)
  /// 3 buổi đầu đã diễn ra, 6 buổi còn lại chưa diễn ra
  Future<void> initializeSampleSessions(List<Subject> subjects) async {
    try {
      debugPrint('════════════════════════════════════════');
      debugPrint('BƯỚC 4: Tạo buổi học (sessions) cho các môn học');
      debugPrint('════════════════════════════════════════');

      if (subjects.isEmpty) {
        debugPrint('⚠ Chưa có subjects, bỏ qua tạo sessions');
        return;
      }

      int createdCount = 0;
      int updatedCount = 0;

      // Tạo 9 buổi học cho mỗi subject (update ghi đè nếu đã có)
      for (final subject in subjects) {
        if (subject.id == null || subject.creatorId == null) {
          debugPrint('⚠ Subject ${subject.subjectCode} chưa có id hoặc creatorId, bỏ qua');
          continue;
        }

        for (int sessionNum = 1; sessionNum <= 9; sessionNum++) {
          try {
            final sessionCode = '${subject.subjectCode}-BUOI$sessionNum';
            
            // Tính toán ngày giờ cho session
            final now = DateTime.now();
            final sessionDate = _calculateSessionDate(now, sessionNum);
            final isCompleted = sessionNum <= 3; // 3 buổi đầu đã diễn ra
            
            // Kiểm tra xem session đã tồn tại chưa
            final existingSession = await _db.getSessionByCode(sessionCode);
            if (existingSession != null) {
              // Update existing session với ngày giờ mới
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
              debugPrint('✓ Đã cập nhật session: $sessionCode - ${updatedSession.title} (Date: ${sessionDate.toString()}, Status: ${isCompleted ? "completed" : "scheduled"})');
              continue;
            }

            // Tạo session mới
            final session = AttendanceSession(
              sessionCode: sessionCode,
              title: 'Buổi $sessionNum',
              description: 'Buổi học thứ $sessionNum của môn ${subject.subjectName}',
              subjectId: subject.id!,
              classCode: subject.classCode,
              sessionNumber: sessionNum,
              status: isCompleted ? SessionStatus.completed : SessionStatus.scheduled,
              sessionDate: sessionDate,
              creatorId: subject.creatorId!, // UID của teacher
            );

            await _db.createSession(session);
            createdCount++;
            debugPrint('✓ Đã tạo session: $sessionCode - ${session.title} (Date: ${sessionDate.toString()}, Status: ${isCompleted ? "completed" : "scheduled"})');
          } catch (e) {
            debugPrint('⚠ Lỗi khi tạo session ${sessionNum} cho subject ${subject.subjectCode}: $e');
          }
        }
      }
      
      debugPrint('✓ Hoàn thành: Tạo mới $createdCount sessions, cập nhật $updatedCount sessions');
    } catch (e) {
      debugPrint('❌ Lỗi khi tạo sessions: $e');
    }
  }

  /// Khởi tạo tất cả dữ liệu mẫu
  /// Chạy tuần tự bằng await, không dùng delay
  Future<void> initializeAllSampleData() async {
    try {
      debugPrint('════════════════════════════════════════');
      debugPrint('BẮT ĐẦU SEED DỮ LIỆU MẪU');
      debugPrint('════════════════════════════════════════');

      // BƯỚC 1: Tạo users trong Firebase Auth và Firestore
      final usersResult = await initializeSampleUsers();
      final teachers = usersResult['teachers'] ?? [];
      final students = usersResult['students'] ?? [];

      if (teachers.isEmpty) {
        debugPrint('❌ Không có teachers, không thể tiếp tục');
        return;
      }

      // BƯỚC 2: Tạo subjects trong Firestore
      final subjects = await initializeSampleSubjects(teachers);

      if (subjects.isEmpty) {
        debugPrint('❌ Không có subjects, không thể tiếp tục');
        return;
      }

      // BƯỚC 3: Tạo Student records trong Firestore
      await initializeSampleStudents(students, subjects);

      // BƯỚC 4: Tạo 9 buổi học cho mỗi subject
      await initializeSampleSessions(subjects);

      debugPrint('════════════════════════════════════════');
      debugPrint('✅ HOÀN THÀNH SEED DỮ LIỆU MẪU');
      debugPrint('════════════════════════════════════════');
    } catch (e) {
      debugPrint('❌ Lỗi khi seed dữ liệu: $e');
      rethrow;
    }
  }

  /// Kiểm tra xem user mẫu đã tồn tại chưa
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
