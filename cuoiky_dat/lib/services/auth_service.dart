import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  // Simple hash function (in production, use bcrypt or similar)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<User?> login(String email, String password) async {
    try {
      final hashedPassword = _hashPassword(password);
      final user = await _dbHelper.getUserByEmail(email);

      if (user == null) {
        return null; // User not found
      }

      if (user.password != hashedPassword) {
        return null; // Wrong password
      }

      // Update last login
      await _dbHelper.updateUserLastLogin(user.id!);

      _currentUser = user.copyWith(lastLoginAt: DateTime.now());
      return _currentUser;
    } catch (e) {
      return null;
    }
  }

  Future<User?> register(String email, String password, String name, {String role = 'user'}) async {
    try {
      // Check if user already exists
      final existingUser = await _dbHelper.getUserByEmail(email);
      if (existingUser != null) {
        throw Exception('Email đã được sử dụng');
      }

      final hashedPassword = _hashPassword(password);
      final user = User(
        email: email,
        password: hashedPassword,
        name: name,
        role: role,
        createdAt: DateTime.now(),
      );

      final id = await _dbHelper.insertUser(user);
      _currentUser = user.copyWith(id: id);
      return _currentUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (_currentUser == null) return false;

    try {
      final hashedOldPassword = _hashPassword(oldPassword);
      if (_currentUser!.password != hashedOldPassword) {
        return false; // Wrong old password
      }

      final hashedNewPassword = _hashPassword(newPassword);
      await _dbHelper.updateUserPassword(_currentUser!.id!, hashedNewPassword);
      _currentUser = _currentUser!.copyWith(password: hashedNewPassword);
      return true;
    } catch (e) {
      return false;
    }
  }
}

