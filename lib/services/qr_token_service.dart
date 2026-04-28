import 'dart:math';
import 'package:crypto/crypto.dart';
import '../models/qr_token.dart';
import '../database/database_helper.dart';

class QrTokenService {
  static final QrTokenService instance = QrTokenService._init();
  final DatabaseHelper _db = DatabaseHelper.instance;

  QrTokenService._init();

  // Generate a unique token for a session
  Future<QrToken> generateToken({
    required int sessionId,
    int validitySeconds = 60, // Default: token expires in 60 seconds
  }) async {
    // Clean up expired tokens before generating new one (housekeeping)
    try {
      await cleanupExpiredTokens();
    } catch (e) {
      // Ignore cleanup errors, continue with token generation
    }
    
    final token = _generateRandomToken();
    final code4Digits = _generate4DigitCode();
    final now = DateTime.now();
    final expiresAt = now.add(Duration(seconds: validitySeconds));

    final qrToken = QrToken(
      token: token,
      code4Digits: code4Digits,
      sessionId: sessionId,
      createdAt: now,
      expiresAt: expiresAt,
    );

    await _db.createQrToken(qrToken.toMap());
    return qrToken;
  }
  
  // Generate 4-digit code
  String _generate4DigitCode() {
    final random = Random.secure();
    return (1000 + random.nextInt(9000)).toString(); // 1000-9999
  }
  
  // Validate by 4-digit code (find token by code, don't need sessionId)
  Future<Map<String, dynamic>> validateByCode4Digits({
    required String code4Digits,
    required int userId,
    int? sessionId, // Optional: if provided, filter by sessionId too
  }) async {
    try {
      // Try to find token by code4Digits first (faster if we don't know sessionId)
      Map<String, dynamic>? tokenMap;
      
      if (sessionId != null) {
        // If sessionId is provided, search in that session first
        final tokenMaps = await _db.getQrTokensBySession(sessionId);
        final now = DateTime.now();
        for (var tm in tokenMaps) {
          final qrToken = QrToken.fromMap(tm);
          if (qrToken.code4Digits == code4Digits && 
              !qrToken.isExpired && 
              !qrToken.isUsed &&
              qrToken.expiresAt.isAfter(now)) {
            tokenMap = tm;
            break;
          }
        }
      }
      
      // If not found and sessionId not provided, or search in all tokens
      if (tokenMap == null) {
        tokenMap = await _db.getQrTokenByCode4Digits(code4Digits);
      }
      
      if (tokenMap == null) {
        return {
          'valid': false,
          'message': 'Mã không đúng hoặc đã hết hạn',
        };
      }
      
      final qrToken = QrToken.fromMap(tokenMap);
      
      // Double-check the token is valid
      final now = DateTime.now();
      if (qrToken.isExpired || qrToken.isUsed || !qrToken.expiresAt.isAfter(now)) {
        return {
          'valid': false,
          'message': 'Mã đã hết hạn hoặc đã được sử dụng',
        };
      }
      
      // Use the token
      return await validateAndConsumeToken(
        token: qrToken.token,
        userId: userId,
      );
    } catch (e) {
      return {
        'valid': false,
        'message': 'Lỗi xác thực: $e',
      };
    }
  }
  
  // Legacy method for backward compatibility
  Future<Map<String, dynamic>> validateByCode4DigitsWithSessionId({
    required String code4Digits,
    required int sessionId,
    required int userId,
  }) async {
    return validateByCode4Digits(
      code4Digits: code4Digits,
      sessionId: sessionId,
      userId: userId,
    );
  }

  // Validate and consume a token
  Future<Map<String, dynamic>> validateAndConsumeToken({
    required String token,
    required int userId,
    String? ipAddress,
  }) async {
    try {
      final qrTokenMap = await _db.getQrTokenByToken(token);

      if (qrTokenMap == null) {
        return {
          'valid': false,
          'message': 'Mã QR không tồn tại hoặc đã hết hạn',
        };
      }

      // Convert to QrToken object
      final qrToken = QrToken.fromMap(qrTokenMap);

      // Check if expired
      if (qrToken.isExpired) {
        return {
          'valid': false,
          'message': 'Mã QR đã hết hạn (${_formatExpiry(qrToken.expiresAt)})',
        };
      }

      // Check if already used
      if (qrToken.isUsed) {
        return {
          'valid': false,
          'message': 'Mã QR đã được sử dụng trước đó',
          'usedAt': qrToken.usedAt,
          'usedBy': qrToken.usedByUserId,
        };
      }

      // Mark as used
      final updatedToken = qrToken.copyWith(
        isUsed: true,
        usedByUserId: userId,
        usedAt: DateTime.now(),
        usedFromIp: ipAddress,
      );

      await _db.updateQrToken(token, {
        'isUsed': 1,
        'usedByUserId': userId,
        'usedAt': DateTime.now().toIso8601String(),
        'usedFromIp': ipAddress,
      });

      return {
        'valid': true,
        'message': 'Mã QR hợp lệ',
        'sessionId': qrToken.sessionId,
        'token': updatedToken,
      };
    } catch (e) {
      return {
        'valid': false,
        'message': 'Lỗi xác thực: $e',
      };
    }
  }

  // Clean up expired tokens (housekeeping)
  Future<int> cleanupExpiredTokens() async {
    return await _db.deleteExpiredQrTokens();
  }

  // Get token audit log for a session
  Future<List<QrToken>> getSessionTokens(int sessionId) async {
    final tokenMaps = await _db.getQrTokensBySession(sessionId);
    return tokenMaps.map((map) => QrToken.fromMap(map)).toList();
  }

  // Check if user has already scanned this session
  Future<bool> hasUserScannedSession({
    required int userId,
    required int sessionId,
  }) async {
    final tokens = await getSessionTokens(sessionId);
    return tokens.any((t) => t.usedByUserId == userId && t.isUsed);
  }

  // Generate a cryptographically secure random token
  String _generateRandomToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    final hash = sha256.convert(values);
    return hash.toString();
  }

  String _formatExpiry(DateTime expiresAt) {
    final now = DateTime.now();
    final diff = expiresAt.difference(now);
    
    if (diff.isNegative) {
      return 'đã hết hạn';
    }
    
    if (diff.inMinutes < 1) {
      return 'còn ${diff.inSeconds} giây';
    }
    
    if (diff.inHours < 1) {
      return 'còn ${diff.inMinutes} phút';
    }
    
    return 'còn ${diff.inHours} giờ';
  }
}

