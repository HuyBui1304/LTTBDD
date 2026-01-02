import 'package:flutter/material.dart';
import 'firebase_auth_service.dart';
import '../database/firebase_database_service.dart';
import '../models/app_user.dart';

class SampleUsersService {
  static final SampleUsersService instance = SampleUsersService._init();
  final FirebaseAuthService _authService = FirebaseAuthService.instance;
  final FirebaseDatabaseService _db = FirebaseDatabaseService.instance;

  SampleUsersService._init();

  /// Khởi tạo user mẫu: 1 admin, 10 teacher, 50 student
  Future<void> initializeSampleUsers() async {
    try {
      debugPrint('Bắt đầu tạo user mẫu...');

      // Tạo 1 admin user
      try {
        await _authService.createUserWithRole(
          email: 'admin@gmail.com',
          password: 'admin123',
          displayName: 'Quản trị viên',
          role: UserRole.admin,
        );
        debugPrint('✓ Đã tạo admin user: admin@gmail.com / admin123');
      } catch (e) {
        debugPrint('⚠ Admin user có thể đã tồn tại: $e');
      }

      // Tạo 10 teacher users
      for (int i = 1; i <= 10; i++) {
        try {
          final email = i == 1 ? 'teacher@gmail.com' : 'teacher$i@gmail.com';
          await _authService.createUserWithRole(
            email: email,
            password: 'teacher123',
            displayName: 'Giáo viên $i',
            role: UserRole.teacher,
          );
          debugPrint('✓ Đã tạo teacher user: $email / teacher123');
        } catch (e) {
          debugPrint('⚠ Teacher user $i có thể đã tồn tại: $e');
        }
        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Tạo 50 student users
      for (int i = 1; i <= 50; i++) {
        try {
          final email = i == 1 ? 'student@gmail.com' : 'student$i@gmail.com';
          await _authService.createUserWithRole(
            email: email,
            password: 'student123',
            displayName: 'Sinh viên $i',
            role: UserRole.student,
          );
          if (i % 10 == 0) {
            debugPrint('✓ Đã tạo $i student users...');
          }
        } catch (e) {
          if (i % 10 == 0) {
            debugPrint('⚠ Một số student users có thể đã tồn tại: $e');
          }
        }
        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint('Hoàn thành tạo user mẫu! (1 admin, 10 teacher, 50 student)');
    } catch (e) {
      debugPrint('Lỗi khi tạo user mẫu: $e');
    }
  }

  /// Kiểm tra xem user mẫu đã tồn tại chưa
  Future<bool> checkSampleUsersExist() async {
    try {
      final users = await _db.getAllUsers();
      final adminExists = users.any((u) => u.email == 'admin@example.com');
      final teacherExists = users.any((u) => u.email == 'teacher@example.com');
      final studentExists = users.any((u) => u.email == 'student@example.com');
      
      return adminExists && teacherExists && studentExists;
    } catch (e) {
      return false;
    }
  }
}

