import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/app_user.dart';
import '../models/student.dart';
import '../database/firebase_database_service.dart';

class FirebaseAuthService {
  static final FirebaseAuthService instance = FirebaseAuthService._init();
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseDatabaseService _db = FirebaseDatabaseService.instance;
  
  AppUser? _currentUser;

  FirebaseAuthService._init();

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // Hash password (for backward compatibility with existing users)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Determine role based on email prefix
  UserRole _getRoleFromEmail(String email) {
    final emailLower = email.toLowerCase();
    if (emailLower.startsWith('admin')) {
      return UserRole.admin;
    } else if (emailLower.startsWith('teacher')) {
      return UserRole.teacher;
    } else if (emailLower.startsWith('student')) {
      return UserRole.student;
    }
    // Default to student if prefix doesn't match
    return UserRole.student;
  }

  // Listen to auth state changes
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Register with Email & Password
  Future<AppUser?> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Check if email already exists in our database
      final existingUser = await _db.getUserByEmail(email);
      if (existingUser != null) {
        throw 'Email đã tồn tại';
      }

      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw 'Tạo tài khoản thất bại';
      }

      // Update display name in Firebase Auth
      await credential.user!.updateDisplayName(displayName);

      // Determine role from email prefix
      final role = _getRoleFromEmail(email);
      
      // Create user in Firestore
      final passwordHash = _hashPassword(password); // Keep for backward compatibility
      final user = AppUser(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
        passwordHash: passwordHash,
        role: role, // Role based on email prefix
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _db.createUser(user);

      // If role is Student, automatically create Student record
      if (role == UserRole.student) {
        try {
          // Generate student ID
          final studentId = 'SV${DateTime.now().millisecondsSinceEpoch % 1000000}';
          
          final student = Student(
            studentId: studentId,
            name: displayName,
            email: email,
            phone: null,
            classCode: null,
            subjectIds: [],
          );
          
          await _db.createStudent(student);
          debugPrint('✅ Created Student record for: $email');
        } catch (e) {
          debugPrint('⚠️ Failed to create Student record: $e');
          // Don't throw error, user account is already created
        }
      }

      _currentUser = user;
      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw 'Email đã tồn tại';
      } else if (e.code == 'weak-password') {
        throw 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';
      } else if (e.code == 'invalid-email') {
        throw 'Email không hợp lệ';
      } else if (e.message?.contains('blocked') == true || 
                 e.message?.contains('unusual activity') == true ||
                 e.message?.contains('rate') == true) {
        throw 'Firebase đã tạm thời chặn thiết bị này do tạo quá nhiều tài khoản.\n\n'
              'Vui lòng đợi 15-30 phút rồi thử lại.\n\n'
              'Hoặc tạo tài khoản qua Firebase Console:\n'
              'https://console.firebase.google.com';
      }
      throw 'Đăng ký thất bại: ${e.message ?? e.code}';
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('blocked') || 
          errorMsg.contains('unusual activity') ||
          errorMsg.contains('rate')) {
        throw 'Firebase đã tạm thời chặn thiết bị này do tạo quá nhiều tài khoản.\n\n'
              'Vui lòng đợi 15-30 phút rồi thử lại.\n\n'
              'Hoặc tạo tài khoản qua Firebase Console:\n'
              'https://console.firebase.google.com';
      }
      throw 'Đăng ký thất bại: $e';
    }
  }

  // Sign in with Email & Password
  Future<AppUser?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with Firebase Auth with timeout
      // Note: Firebase Auth handles password authentication, not passwordHash
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw 'Đăng nhập timeout. Vui lòng kiểm tra kết nối mạng.';
        },
      );

      if (credential.user == null) {
        throw 'Tài khoản hoặc mật khẩu không đúng';
      }

      // Load user from Firestore with timeout
      AppUser? user;
      try {
        user = await _db.getUserByUid(credential.user!.uid).timeout(
          const Duration(seconds: 10),
        );
      } catch (e) {
        // If error or timeout loading from DB, continue with creating new user
        debugPrint('Error loading user from Firestore: $e');
        user = null;
      }

      if (user == null) {
        // User exists in Auth but not in Firestore - create it
        // Determine role from email prefix
        final role = _getRoleFromEmail(credential.user!.email ?? email);
        
        final newUser = AppUser(
          uid: credential.user!.uid,
          email: credential.user!.email ?? email,
          displayName: credential.user!.displayName ?? 'User',
          passwordHash: _hashPassword(password), // Store hash for reference (not used for auth)
          photoUrl: credential.user!.photoURL,
          role: role, // Role based on email prefix
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        
        try {
          await _db.createUser(newUser).timeout(
            const Duration(seconds: 10),
          );
          debugPrint('Created new user in Firestore: ${newUser.email}');
        } catch (e) {
          debugPrint('Error creating user in Firestore: $e');
          // Continue even if create fails - user can still login
        }
        
        _currentUser = newUser;
        
        try {
          await _db.updateUserLastLogin(newUser.uid).timeout(
            const Duration(seconds: 5),
          );
        } catch (e) {
          // Ignore update error
        }
        
        return newUser;
      }

      // User exists in both Auth and Firestore
      // Update last login
      try {
        await _db.updateUserLastLogin(user.uid).timeout(
          const Duration(seconds: 5),
        );
      } catch (e) {
        // Ignore update error
      }
      
      _currentUser = user.copyWith(lastLogin: DateTime.now());
      return _currentUser;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw 'Tài khoản hoặc mật khẩu không đúng';
      } else if (e.code == 'wrong-password') {
        throw 'Tài khoản hoặc mật khẩu không đúng';
      } else if (e.code == 'invalid-email') {
        throw 'Email không hợp lệ';
      } else if (e.code == 'unknown' || e.message?.contains('CONFIGURATION_NOT_FOUND') == true) {
        throw 'Cần cấu hình SHA fingerprint trong Firebase Console. Xem hướng dẫn trong file get_sha.sh';
      } else if (e.code == 'invalid-credential' || 
                 e.code == 'invalid-verification-code' ||
                 e.code == 'invalid-verification-id' ||
                 e.message?.contains('credential') == true ||
                 e.message?.contains('expired') == true ||
                 e.message?.contains('malformed') == true) {
        throw 'Tài khoản hoặc mật khẩu không đúng';
      }
      throw 'Tài khoản hoặc mật khẩu không đúng';
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw e.toString();
      }
      if (e.toString().contains('Sai tài khoản') || e.toString().contains('Sai mật khẩu')) {
        throw 'Tài khoản hoặc mật khẩu không đúng';
      }
      // For any other error, show generic login error message
      throw 'Tài khoản hoặc mật khẩu không đúng';
    }
  }

  // Sign in with Google (requires google_sign_in package)
  Future<AppUser?> signInWithGoogle() async {
    try {
      // Note: This is a placeholder. You'll need to add google_sign_in package
      // and implement Google Sign-In flow
      throw 'Google Sign-In chưa được cài đặt. Vui lòng thêm package google_sign_in';
    } catch (e) {
      throw 'Đăng nhập Google thất bại: $e';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      // Check if email exists in Firestore first
      final existingUser = await _db.getUserByEmail(email);
      if (existingUser == null) {
        throw 'Email không tồn tại';
      }
      
      // Send password reset email
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw 'Email không tồn tại';
      }
      throw 'Gửi email khôi phục thất bại: ${e.message}';
    } catch (e) {
      // Re-throw if it's already our custom error message
      if (e.toString().contains('Email không tồn tại')) {
        rethrow;
      }
      throw 'Gửi email khôi phục thất bại: $e';
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      throw 'Bạn chưa đăng nhập';
    }

    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw 'Không tìm thấy người dùng';
      }

      // Re-authenticate user
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      // Update password hash in database
      final newHash = _hashPassword(newPassword);
      final updatedUser = _currentUser!.copyWith(passwordHash: newHash);
      await _db.updateUser(updatedUser);
      _currentUser = updatedUser;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw 'Mật khẩu hiện tại không đúng';
      }
      throw 'Đổi mật khẩu thất bại: ${e.message}';
    } catch (e) {
      throw 'Đổi mật khẩu thất bại: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
  }

  // Load current user (call on app start)
  Future<void> loadCurrentUser(String uid) async {
    try {
      final user = await _db.getUserByUid(uid);
      if (user != null) {
        _currentUser = user;
      } else {
        // User might exist in Auth but not in Database
        final authUser = _auth.currentUser;
        if (authUser != null && authUser.uid == uid) {
          // Determine role from email prefix
          final role = _getRoleFromEmail(authUser.email ?? '');
          
          // Create user in database
          final newUser = AppUser(
            uid: authUser.uid,
            email: authUser.email ?? '',
            displayName: authUser.displayName ?? 'User',
            passwordHash: '', // Will be set on next login
            photoUrl: authUser.photoURL,
            role: role, // Role based on email prefix
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );
          await _db.createUser(newUser);
          _currentUser = newUser;
        }
      }
    } catch (e) {
      _currentUser = null;
    }
  }

  // Check if user is admin
  bool isAdmin() {
    return _currentUser?.isAdmin ?? false;
  }

  // Update user role (Admin only)
  Future<void> updateUserRole(String uid, UserRole role) async {
    if (!isAdmin()) {
      throw 'Bạn không có quyền thực hiện thao tác này';
    }

    try {
      final user = await _db.getUserByUid(uid);
      if (user == null) {
        throw 'Không tìm thấy người dùng';
      }

      final updatedUser = user.copyWith(role: role);
      await _db.updateUser(updatedUser);
    } catch (e) {
      throw 'Cập nhật vai trò thất bại: $e';
    }
  }

  // Get all users (Admin only)
  Future<List<AppUser>> getAllUsers() async {
    if (!isAdmin()) {
      throw 'Bạn không có quyền thực hiện thao tác này';
    }
    return await _db.getAllUsers();
  }

  // Delete account (current user only)
  Future<void> deleteAccount() async {
    if (_currentUser == null) return;
    
    try {
      // Delete from Firebase Auth
      await _auth.currentUser?.delete();
      
      // Delete from Firestore
      await _db.deleteUser(_currentUser!.uid);
      _currentUser = null;
    } catch (e) {
      throw 'Xóa tài khoản thất bại: $e';
    }
  }

  // Delete user from Firebase Auth (admin function)
  // Note: Firebase Auth client SDK doesn't support deleting other users.
  // To delete users from Firebase Auth, you need to use Admin SDK on the server side.
  // This method is a placeholder - actual deletion should be done via Admin SDK or manually from Console.
  Future<void> deleteUserFromAuth(String uid) async {
    // Note: Client SDK cannot delete other users from Firebase Auth.
    // User has been deleted from Firestore, but Firebase Auth account remains.
    // To fully delete, use Firebase Admin SDK or delete manually from Firebase Console.
    debugPrint('Lưu ý: User đã được xóa từ Firestore nhưng vẫn còn trong Firebase Auth.');
    debugPrint('Để xóa hoàn toàn, vui lòng sử dụng Firebase Admin SDK hoặc xóa thủ công từ Console.');
  }

  // Create admin user (for testing)
  Future<AppUser> createAdminUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw 'Tạo tài khoản thất bại';
      }

      await credential.user!.updateDisplayName(displayName);

      // Create admin user in Firestore
      final passwordHash = _hashPassword(password);
      final user = AppUser(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
        passwordHash: passwordHash,
        role: UserRole.admin,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _db.createUser(user);
      return user;
    } catch (e) {
      throw 'Tạo admin thất bại: $e';
    }
  }

  // Create user with specific role
  Future<AppUser> createUserWithRole({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      // Check if email already exists
      final existingUser = await _db.getUserByEmail(email);
      if (existingUser != null) {
        throw 'Email đã tồn tại';
      }

      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw 'Tạo tài khoản thất bại';
      }

      await credential.user!.updateDisplayName(displayName);

      // Create user in Firestore
      final passwordHash = _hashPassword(password);
      final user = AppUser(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
        passwordHash: passwordHash,
        role: role,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _db.createUser(user);

      // If role is Student, automatically create Student record
      if (role == UserRole.student) {
        try {
          // Generate student ID (could be customized)
          final studentId = 'SV${DateTime.now().millisecondsSinceEpoch % 1000000}';
          
          final student = Student(
            studentId: studentId,
            name: displayName,
            email: email,
            phone: null,
            classCode: null,
            subjectIds: [],
          );
          
          await _db.createStudent(student);
          debugPrint('✅ Created Student record for: $email');
        } catch (e) {
          debugPrint('⚠️ Failed to create Student record: $e');
          // Don't throw error, user account is already created
        }
      }

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw 'Email đã tồn tại';
      }
      throw 'Tạo người dùng thất bại: ${e.message}';
    } catch (e) {
      throw 'Tạo người dùng thất bại: $e';
    }
  }
}

