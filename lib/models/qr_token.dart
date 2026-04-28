import 'package:intl/intl.dart';

class QrToken {
  final int? id;
  final String token;
  final String code4Digits; // Mã 4 số để nhập thủ công
  final int sessionId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isUsed;
  final int? usedByUserId;
  final DateTime? usedAt;
  final String? usedFromIp;

  QrToken({
    this.id,
    required this.token,
    required this.code4Digits,
    required this.sessionId,
    DateTime? createdAt,
    required this.expiresAt,
    this.isUsed = false,
    this.usedByUserId,
    this.usedAt,
    this.usedFromIp,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isUsed && !isExpired;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'token': token,
      'code4Digits': code4Digits,
      'sessionId': sessionId,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isUsed': isUsed ? 1 : 0,
      'usedByUserId': usedByUserId,
      'usedAt': usedAt?.toIso8601String(),
      'usedFromIp': usedFromIp,
    };
  }

  factory QrToken.fromMap(Map<String, dynamic> map) {
    return QrToken(
      id: map['id'] as int?,
      token: map['token'] as String,
      code4Digits: map['code4Digits'] as String? ?? '',
      sessionId: map['sessionId'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      expiresAt: DateTime.parse(map['expiresAt'] as String),
      isUsed: (map['isUsed'] as int) == 1,
      usedByUserId: map['usedByUserId'] as int?,
      usedAt: map['usedAt'] != null
          ? DateTime.parse(map['usedAt'] as String)
          : null,
      usedFromIp: map['usedFromIp'] as String?,
    );
  }

  QrToken copyWith({
    int? id,
    String? token,
    String? code4Digits,
    int? sessionId,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isUsed,
    int? usedByUserId,
    DateTime? usedAt,
    String? usedFromIp,
  }) {
    return QrToken(
      id: id ?? this.id,
      token: token ?? this.token,
      code4Digits: code4Digits ?? this.code4Digits,
      sessionId: sessionId ?? this.sessionId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isUsed: isUsed ?? this.isUsed,
      usedByUserId: usedByUserId ?? this.usedByUserId,
      usedAt: usedAt ?? this.usedAt,
      usedFromIp: usedFromIp ?? this.usedFromIp,
    );
  }

  @override
  String toString() {
    return 'QrToken{id: $id, token: $token, sessionId: $sessionId, isValid: $isValid, expiresAt: ${DateFormat('dd/MM/yyyy HH:mm').format(expiresAt)}}';
  }
}

