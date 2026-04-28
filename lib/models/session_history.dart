import 'attendance_session.dart';

class SessionHistory {
  final int? id;
  final int sessionId;
  final int userId;
  final String action; // 'created', 'updated', 'approved', 'rejected', 'completed', 'cancelled'
  final SessionStatus? oldStatus;
  final SessionStatus? newStatus;
  final String? note;
  final DateTime createdAt;

  SessionHistory({
    this.id,
    required this.sessionId,
    required this.userId,
    required this.action,
    this.oldStatus,
    this.newStatus,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'userId': userId,
      'action': action,
      'oldStatus': oldStatus?.name,
      'newStatus': newStatus?.name,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SessionHistory.fromMap(Map<String, dynamic> map) {
    return SessionHistory(
      id: map['id'] as int?,
      sessionId: map['sessionId'] as int,
      userId: map['userId'] as int,
      action: map['action'] as String,
      oldStatus: map['oldStatus'] != null
          ? SessionStatus.values.byName(map['oldStatus'] as String)
          : null,
      newStatus: map['newStatus'] != null
          ? SessionStatus.values.byName(map['newStatus'] as String)
          : null,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

