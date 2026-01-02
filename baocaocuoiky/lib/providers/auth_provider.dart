import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../services/firebase_auth_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService.instance;
  
  AppUser? _currentUser;
  bool _isLoading = false;
  bool _isInitializing = true; // Separate flag for app init
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isTeacher => _currentUser?.isTeacher ?? false;
  bool get isStudent => _currentUser?.isStudent ?? false;

  AuthProvider() {
    _init();
  }

  void _init() async {
    // Load saved session on app start
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUid = prefs.getString('user_uid');
      if (savedUid != null) {
        // Add timeout to prevent hanging
        await loadCurrentUser(savedUid).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            _error = 'Không thể tải thông tin người dùng. Vui lòng thử lại.';
            _currentUser = null;
          },
        );
      }
    } catch (e) {
      _error = e.toString();
      _currentUser = null;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> loadCurrentUser(String uid) async {
    try {
      await _authService.loadCurrentUser(uid);
      _currentUser = _authService.currentUser;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _saveSession(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_uid', uid);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_uid');
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _currentUser = await _authService.registerWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (_currentUser != null) {
        await _saveSession(_currentUser!.uid);
      }

      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Add overall timeout to prevent infinite loading
      _currentUser = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw 'Đăng nhập timeout. Vui lòng thử lại.';
        },
      );

      if (_currentUser != null) {
        await _saveSession(_currentUser!.uid);
      }

      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _currentUser = await _authService.signInWithGoogle();

      if (_currentUser != null) {
        await _saveSession(_currentUser!.uid);
      }

      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.resetPassword(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();
      await _clearSession();
      _currentUser = null;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

