import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/app_user.dart';
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
        throw 'Email đã được sử dụng';
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

      // Create user in Realtime Database
      final passwordHash = _hashPassword(password); // Keep for backward compatibility
      final user = AppUser(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
        passwordHash: passwordHash,
        role: UserRole.student, // Default role
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _db.createUser(user);
      _currentUser = user;
      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw 'Email đã được sử dụng';
      } else if (e.code == 'weak-password') {
        throw 'Mật khẩu quá yếu';
      } else if (e.code == 'invalid-email') {
        throw 'Email không hợp lệ';
      }
      throw 'Đăng ký thất bại: ${e.message}';
    } catch (e) {
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
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw 'Đăng nhập timeout. Vui lòng kiểm tra kết nối mạng.';
        },
      );

      if (credential.user == null) {
        throw 'Đăng nhập thất bại';
      }

      // Load user from Realtime Database with timeout
      AppUser? user;
      try {
        user = await _db.getUserByUid(credential.user!.uid).timeout(
          const Duration(seconds: 10),
        );
      } catch (e) {
        // If error or timeout loading from DB, continue with creating new user
        user = null;
      }

      if (user == null) {
        // User exists in Auth but not in Database - create it
        final newUser = AppUser(
          uid: credential.user!.uid,
          email: credential.user!.email ?? email,
          displayName: credential.user!.displayName ?? 'User',
          passwordHash: _hashPassword(password),
          photoUrl: credential.user!.photoURL,
          role: UserRole.student,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        
        try {
          await _db.createUser(newUser).timeout(
            const Duration(seconds: 10),
          );
        } catch (e) {
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
        throw 'Email hoặc mật khẩu không đúng';
      } else if (e.code == 'wrong-password') {
        throw 'Email hoặc mật khẩu không đúng';
      } else if (e.code == 'invalid-email') {
        throw 'Email không hợp lệ';
      } else if (e.code == 'unknown' || e.message?.contains('CONFIGURATION_NOT_FOUND') == true) {
        throw 'Cần cấu hình SHA fingerprint trong Firebase Console. Xem hướng dẫn trong file get_sha.sh';
      }
      throw 'Đăng nhập thất bại: ${e.message}';
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw e.toString();
      }
      throw 'Đăng nhập thất bại: $e';
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
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw 'Không tìm thấy người dùng với email này';
      }
      throw 'Gửi email khôi phục thất bại: ${e.message}';
    } catch (e) {
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
          // Create user in database
          final newUser = AppUser(
            uid: authUser.uid,
            email: authUser.email ?? '',
            displayName: authUser.displayName ?? 'User',
            passwordHash: '', // Will be set on next login
            photoUrl: authUser.photoURL,
            role: UserRole.student,
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

  // Delete account
  Future<void> deleteAccount() async {
    if (_currentUser == null) return;
    
    try {
      // Delete from Firebase Auth
      await _auth.currentUser?.delete();
      
      // Delete from Realtime Database
      await _db.deleteUser(_currentUser!.uid);
      _currentUser = null;
    } catch (e) {
      throw 'Xóa tài khoản thất bại: $e';
    }
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

      // Create admin user in Realtime Database
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
}

