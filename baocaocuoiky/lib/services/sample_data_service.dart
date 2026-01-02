import 'package:flutter/material.dart';
import 'firebase_auth_service.dart';
import '../database/database_helper.dart';
import '../models/app_user.dart';
import '../models/subject.dart';

class SampleDataService {
  static final SampleDataService instance = SampleDataService._init();
  final FirebaseAuthService _authService = FirebaseAuthService.instance;
  final DatabaseHelper _db = DatabaseHelper.instance;

  SampleDataService._init();

  /// Helper để tạo user với retry logic
  Future<AppUser?> _createUserWithRetry({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await _authService.createUserWithRole(
          email: email,
          password: password,
          displayName: displayName,
          role: role,
        );
      } catch (e) {
        final errorMsg = e.toString();
        // Nếu user đã tồn tại, thử lấy từ database
        if (errorMsg.contains('đã được sử dụng') || errorMsg.contains('email-already-in-use')) {
          try {
            final existingUser = await _db.getUserByEmail(email);
            if (existingUser != null) {
              return existingUser;
            }
          } catch (_) {
            // Ignore
          }
          return null; // User đã tồn tại
        }
        
        // Nếu bị rate limit, đợi lâu hơn và retry
        if (errorMsg.contains('blocked') || errorMsg.contains('unusual activity') || errorMsg.contains('rate')) {
          if (attempt < maxRetries) {
            final waitTime = Duration(seconds: attempt * 5); // Exponential backoff: 5s, 10s, 15s
            debugPrint('⚠ Rate limit detected, đợi ${waitTime.inSeconds}s trước khi retry (attempt $attempt/$maxRetries)...');
            await Future.delayed(waitTime);
            continue;
          }
        }
        
        // Nếu không phải rate limit, throw error
        rethrow;
      }
    }
    return null;
  }

  /// Khởi tạo user mẫu: 1 admin, 5 teacher, 15 student
  /// Trả về danh sách teachers đã tạo để dùng cho subjects
  /// 
  /// LƯU Ý: Firebase có rate limiting. Nếu bị chặn:
  /// - Đợi 15-30 phút rồi thử lại
  /// - Hoặc tạo users thủ công qua Firebase Console
  /// - Hoặc tạo từng user một qua màn hình Register
  Future<List<AppUser>> initializeSampleUsers() async {
    final List<AppUser> teachers = [];
    try {
      debugPrint('Bắt đầu tạo user mẫu...');

      // Tạo 1 admin user với delay lớn
      try {
        final admin = await _createUserWithRetry(
          email: 'admin@gmail.com',
          password: 'admin123',
          displayName: 'Quản trị viên',
          role: UserRole.admin,
        );
        if (admin != null) {
          debugPrint('✓ Đã tạo admin user: admin@gmail.com / admin123');
        } else {
          debugPrint('✓ Admin user đã tồn tại');
        }
      } catch (e) {
        debugPrint('⚠ Lỗi khi tạo admin user: $e');
      }
      
      // Đợi trước khi tạo teachers
      await Future.delayed(const Duration(seconds: 2));

      // Tạo 5 teacher users và lưu vào danh sách
      for (int i = 1; i <= 5; i++) {
        try {
          final email = i == 1 ? 'teacher@gmail.com' : 'teacher$i@gmail.com';
          final teacher = await _createUserWithRetry(
            email: email,
            password: 'teacher123',
            displayName: 'Giáo viên $i',
            role: UserRole.teacher,
          );
          if (teacher != null) {
            teachers.add(teacher);
            debugPrint('✓ Đã tạo teacher user: $email / teacher123');
          } else {
            // Thử lấy từ database nếu đã tồn tại
            try {
              final existingUser = await _db.getUserByEmail(email);
              if (existingUser != null) {
                teachers.add(existingUser);
                debugPrint('✓ Teacher user $i đã tồn tại, sử dụng user hiện có');
              }
            } catch (_) {
              // Ignore
            }
          }
        } catch (e) {
          debugPrint('⚠ Lỗi khi tạo teacher user $i: $e');
        }
        // Delay lớn hơn giữa các teacher (1 giây)
        await Future.delayed(const Duration(seconds: 1));
      }

      // Đợi trước khi tạo students
      await Future.delayed(const Duration(seconds: 3));

      // Tạo 15 student users với delay lớn hơn
      int successCount = 0;
      for (int i = 1; i <= 15; i++) {
        try {
          final email = i == 1 ? 'student@gmail.com' : 'student$i@gmail.com';
          final student = await _createUserWithRetry(
            email: email,
            password: 'student123',
            displayName: 'Sinh viên $i',
            role: UserRole.student,
          );
          if (student != null) {
            successCount++;
          }
          if (i % 5 == 0) {
            debugPrint('✓ Đã tạo $successCount/$i student users...');
          }
        } catch (e) {
          final errorMsg = e.toString();
          if (errorMsg.contains('blocked') || errorMsg.contains('unusual activity')) {
            debugPrint('⚠ Firebase đã chặn requests. Dừng tạo students. Đã tạo: $successCount/$i');
            debugPrint('⚠ Vui lòng đợi vài phút rồi chạy lại app để tạo tiếp các students còn lại.');
            break; // Dừng lại nếu bị chặn
          }
          if (i % 5 == 0) {
            debugPrint('⚠ Một số student users có thể đã tồn tại: $e');
          }
        }
        // Delay lớn hơn giữa các student (2 giây) để tránh rate limit
        await Future.delayed(const Duration(seconds: 2));
      }

      debugPrint('Hoàn thành tạo user mẫu! (1 admin, ${teachers.length} teacher, $successCount student)');
      return teachers;
    } catch (e) {
      debugPrint('Lỗi khi tạo user mẫu: $e');
      return teachers;
    }
  }

  /// Khởi tạo dữ liệu môn học mẫu
  /// Nhận danh sách teachers từ initializeSampleUsers
  Future<void> initializeSampleSubjects(List<AppUser> teachers) async {
    try {
      debugPrint('Bắt đầu tạo môn học mẫu...');

      // Nếu không có teachers, thử lấy từ database (fallback)
      if (teachers.isEmpty) {
        debugPrint('⚠ Không có teachers từ danh sách, thử lấy từ database...');
        try {
          final allUsers = await _db.getAllUsers();
          teachers.addAll(allUsers.where((u) => u.role == UserRole.teacher));
        } catch (e) {
          debugPrint('⚠ Không thể lấy teachers từ database: $e');
        }
      }

      // Nếu vẫn không có teachers, tạo subjects với creatorId = null
      if (teachers.isEmpty) {
        debugPrint('⚠ Chưa có teacher nào, tạo môn học với creatorId = null');
      } else {
        debugPrint('✓ Tìm thấy ${teachers.length} teachers để gán môn học');
      }

      // Danh sách môn học mẫu
      final sampleSubjects = [
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
        {
          'subjectCode': 'AI',
          'subjectName': 'Trí tuệ nhân tạo',
          'classCode': 'AI2024',
          'description': 'Môn học về trí tuệ nhân tạo và machine learning',
        },
        {
          'subjectCode': 'ATTT',
          'subjectName': 'An toàn thông tin',
          'classCode': 'ATTT2024',
          'description': 'Môn học về bảo mật và an toàn thông tin',
        },
        {
          'subjectCode': 'PMUD',
          'subjectName': 'Phát triển phần mềm ứng dụng',
          'classCode': 'PMUD2024',
          'description': 'Môn học về quy trình phát triển phần mềm',
        },
        {
          'subjectCode': 'CNPM',
          'subjectName': 'Công nghệ phần mềm',
          'classCode': 'CNPM2024',
          'description': 'Môn học về công nghệ và phương pháp phát triển phần mềm',
        },
      ];

      // Kiểm tra xem đã có môn học chưa
      final existingSubjects = await _db.getAllSubjects();
      if (existingSubjects.isNotEmpty) {
        debugPrint('⚠ Đã có ${existingSubjects.length} môn học, bỏ qua tạo môn học mẫu');
        return;
      }

      // Tạo môn học và phân bổ cho các teacher
      for (int i = 0; i < sampleSubjects.length; i++) {
        try {
          final subjectData = sampleSubjects[i];
          int? creatorId;
          String? teacherName;
          
          // Nếu có teachers, phân bổ cho teacher
          if (teachers.isNotEmpty) {
            final teacherIndex = i % teachers.length; // Phân bổ đều cho các teacher
            final teacher = teachers[teacherIndex];
            creatorId = _db.uidToUserId(teacher.uid);
            teacherName = teacher.displayName;
          }

          final subject = Subject(
            subjectCode: subjectData['subjectCode']!,
            subjectName: subjectData['subjectName']!,
            classCode: subjectData['classCode']!,
            description: subjectData['description'],
            creatorId: creatorId,
          );

          await _db.createSubject(subject);
          if (teacherName != null) {
            debugPrint('✓ Đã tạo môn học: ${subject.subjectCode} - ${subject.subjectName} (Giáo viên: $teacherName)');
          } else {
            debugPrint('✓ Đã tạo môn học: ${subject.subjectCode} - ${subject.subjectName}');
          }
        } catch (e) {
          debugPrint('⚠ Lỗi khi tạo môn học ${i + 1}: $e');
        }
        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 200));
      }

      debugPrint('Hoàn thành tạo môn học mẫu! (${sampleSubjects.length} môn học)');
    } catch (e) {
      debugPrint('Lỗi khi tạo môn học mẫu: $e');
    }
  }

  /// Khởi tạo tất cả dữ liệu mẫu
  Future<void> initializeAllSampleData() async {
    // Tạo users và lấy danh sách teachers
    final teachers = await initializeSampleUsers();
    // Đợi một chút để đảm bảo users đã được tạo xong trong Firestore
    // Và để Firebase "nghỉ" sau khi tạo nhiều users
    await Future.delayed(const Duration(seconds: 5));
    // Tạo subjects với danh sách teachers đã có
    await initializeSampleSubjects(teachers);
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

