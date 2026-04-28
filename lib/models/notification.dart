class AppNotification {
  final String? id;
  final String title;
  final String content;
  final String? targetRole; // 'admin', 'teacher', 'student', null = all
  final String? targetUserId; // specific user UID, null = all users of role
  final String? targetClassCode; // class code, null = all classes
  final List<String>? readBy; // UIDs of users who have read this notification
  final DateTime createdAt;
  final String createdBy; // creator UID

  AppNotification({
    this.id,
    required this.title,
    required this.content,
    this.targetRole,
    this.targetUserId,
    this.targetClassCode,
    this.readBy,
    required this.createdAt,
    required this.createdBy,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? content,
    String? targetRole,
    String? targetUserId,
    String? targetClassCode,
    List<String>? readBy,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      targetRole: targetRole ?? this.targetRole,
      targetUserId: targetUserId ?? this.targetUserId,
      targetClassCode: targetClassCode ?? this.targetClassCode,
      readBy: readBy ?? this.readBy,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'targetRole': targetRole,
      'targetUserId': targetUserId,
      'targetClassCode': targetClassCode,
      'readBy': readBy,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      targetRole: map['targetRole'],
      targetUserId: map['targetUserId'],
      targetClassCode: map['targetClassCode'],
      readBy: map['readBy'] != null ? List<String>.from(map['readBy']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      createdBy: map['createdBy'] ?? '',
    );
  }
}

