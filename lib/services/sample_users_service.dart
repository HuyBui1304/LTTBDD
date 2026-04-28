import 'package:flutter/material.dart';
import 'firebase_auth_service.dart';
import '../database/firebase_database_service.dart';
import '../models/app_user.dart';

class SampleUsersService {
  static final SampleUsersService instance = SampleUsersService._init();
  final FirebaseAuthService _authService = FirebaseAuthService.instance;
  final FirebaseDatabaseService _db = FirebaseDatabaseService.instance;

  SampleUsersService._init();

  /// Initialize sample users: 1 admin, 10 teachers, 50 students
  Future<void> initializeSampleUsers() async {
    try {
      debugPrint('Creating sample users...');

      try {
        await _authService.createUserWithRole(
          email: 'admin@gmail.com',
          password: 'admin123',
          displayName: 'Quản trị viên',
          role: UserRole.admin,
        );
        debugPrint('✓ Created admin user: admin@gmail.com / admin123');
      } catch (e) {
        debugPrint('⚠ Admin user may already exist: $e');
      }

      for (int i = 1; i <= 10; i++) {
        try {
          final email = i == 1 ? 'teacher@gmail.com' : 'teacher$i@gmail.com';
          await _authService.createUserWithRole(
            email: email,
            password: 'teacher123',
            displayName: 'Giáo viên $i',
            role: UserRole.teacher,
          );
          debugPrint('✓ Created teacher user: $email / teacher123');
        } catch (e) {
          debugPrint('⚠ Teacher user $i may already exist: $e');
        }
        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 200));
      }

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
            debugPrint('✓ Created $i student users...');
          }
        } catch (e) {
          if (i % 10 == 0) {
            debugPrint('⚠ Some student users may already exist: $e');
          }
        }
        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint('Finished creating sample users (1 admin, 10 teachers, 50 students)');
    } catch (e) {
      debugPrint('Error creating sample users: $e');
    }
  }

  /// Check whether sample users already exist
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

