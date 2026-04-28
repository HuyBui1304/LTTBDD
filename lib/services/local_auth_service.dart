import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/app_user.dart';
import '../database/database_helper.dart';

class LocalAuthService {
  static final LocalAuthService instance = LocalAuthService._init();
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  AppUser? _currentUser;

  LocalAuthService._init();

  // Get current user
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // Hash password
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate UID
  String _generateUid() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond % 10000}';
  }

  // Register with Email & Password
  Future<AppUser?> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Check if email already exists
      final existingUser = await _db.getUserByEmail(email);
      if (existingUser != null) {
        throw 'Email đã được sử dụng';
      }

      // Create new user
      final passwordHash = _hashPassword(password);
      final user = AppUser(
        uid: _generateUid(),
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
      final user = await _db.getUserByEmail(email);
      if (user == null) {
        throw 'Email hoặc mật khẩu không đúng';
      }

      final passwordHash = _hashPassword(password);
      if (user.passwordHash != passwordHash) {
        throw 'Email hoặc mật khẩu không đúng';
      }

      // Update last login
      await _db.updateUserLastLogin(user.uid);
      _currentUser = user.copyWith(lastLogin: DateTime.now());
      return _currentUser;
    } catch (e) {
      // Don't expose internal error details
      if (e.toString().contains('Email hoặc mật khẩu không đúng')) {
        rethrow;
      }
      throw 'Email hoặc mật khẩu không đúng';
    }
  }

  // Mock Google Sign In
  Future<AppUser?> signInWithGoogle() async {
    try {
      // Simulate Google Sign In
      // In real app, this would open Google OAuth flow
      final email = 'demo.google@example.com';
      final displayName = 'Google User';

      // Check if user exists
      var user = await _db.getUserByEmail(email);
      
      if (user == null) {
        // Create new user
        user = AppUser(
          uid: _generateUid(),
          email: email,
          displayName: displayName,
          passwordHash: _hashPassword('google_oauth'), // Placeholder
          photoUrl: 'https://ui-avatars.com/api/?name=Google+User',
          role: UserRole.student,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        await _db.createUser(user);
      } else {
        // Update last login
        await _db.updateUserLastLogin(user.uid);
        user = user.copyWith(lastLogin: DateTime.now());
      }

      _currentUser = user;
      return user;
    } catch (e) {
      throw 'Đăng nhập Google thất bại: $e';
    }
  }

  // Reset password (Mock - in real app would send email)
  Future<void> resetPassword(String email) async {
    try {
      final user = await _db.getUserByEmail(email);
      if (user == null) {
        throw 'Không tìm thấy người dùng với email này';
      }

      // In real app, this would send email with reset link
      // For now, just simulate success
      await Future.delayed(const Duration(seconds: 1));
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
      final currentHash = _hashPassword(currentPassword);
      if (_currentUser!.passwordHash != currentHash) {
        throw 'Mật khẩu hiện tại không đúng';
      }

      final newHash = _hashPassword(newPassword);
      final updatedUser = _currentUser!.copyWith(passwordHash: newHash);
      await _db.updateUser(updatedUser);
      _currentUser = updatedUser;
    } catch (e) {
      throw 'Đổi mật khẩu thất bại: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    _currentUser = null;
  }

  // Load current user (call on app start)
  Future<void> loadCurrentUser(String uid) async {
    try {
      _currentUser = await _db.getUserByUid(uid);
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
      final passwordHash = _hashPassword(password);
      final user = AppUser(
        uid: _generateUid(),
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

