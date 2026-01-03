class AttendanceSession {
  final int? id;
  final String sessionCode; // Mã buổi học (ví dụ: SES001, SES002...)
  final String title; // Tiêu đề buổi học (ví dụ: Buổi 1, Buổi 2...)
  final String? description;
  final int subjectId; // ID môn học (NEW - thay cho classCode)
  final String classCode; // Mã lớp (giữ lại cho backward compatibility)
  final int sessionNumber; // Số thứ tự buổi học (1-9)
  final DateTime? sessionDate; // Ngày học (nullable - có thể chưa set)
  final String? location; // Địa điểm
  final SessionStatus status;
  final String? creatorId; // UID của người tạo (teacher/admin)
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Display field (not stored in DB)
  final String? creatorName; // Tên người tạo
  final String? subjectName; // Tên môn học (for display)

  AttendanceSession({
    this.id,
    required this.sessionCode,
    required this.title,
    this.description,
    required this.subjectId,
    required this.classCode,
    required this.sessionNumber,
    this.sessionDate,
    this.location,
    this.status = SessionStatus.scheduled,
    this.creatorId,
    this.creatorName,
    this.subjectName,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionCode': sessionCode,
      'title': title,
      'description': description,
      'subjectId': subjectId,
      'classCode': classCode,
      'sessionNumber': sessionNumber,
      'sessionDate': sessionDate?.toIso8601String(),
      'location': location,
      'status': status.name,
      'creatorId': creatorId, // UID của creator
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Map
  factory AttendanceSession.fromMap(Map<String, dynamic> map) {
    return AttendanceSession(
      id: map['id'] as int?,
      sessionCode: map['sessionCode'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      subjectId: (map['subjectId'] as int?) ?? 0,
      classCode: map['classCode'] as String,
      sessionNumber: map['sessionNumber'] as int? ?? 1,
      sessionDate: map['sessionDate'] != null 
          ? DateTime.parse(map['sessionDate'] as String)
          : null,
      location: map['location'] as String?,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SessionStatus.scheduled,
      ),
      creatorId: map['creatorId'] as String?, // UID của creator
      creatorName: map['creatorName'] as String?,
      subjectName: map['subjectName'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // Copy with method for updates
  AttendanceSession copyWith({
    int? id,
    String? sessionCode,
    String? title,
    String? description,
    int? subjectId,
    String? classCode,
    int? sessionNumber,
    DateTime? sessionDate,
    String? location,
    SessionStatus? status,
    String? creatorId, // UID của creator
    String? creatorName,
    String? subjectName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceSession(
      id: id ?? this.id,
      sessionCode: sessionCode ?? this.sessionCode,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      classCode: classCode ?? this.classCode,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      sessionDate: sessionDate ?? this.sessionDate,
      location: location ?? this.location,
      status: status ?? this.status,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      subjectName: subjectName ?? this.subjectName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AttendanceSession{id: $id, sessionCode: $sessionCode, title: $title, status: $status}';
  }
}

enum SessionStatus {
  scheduled,  // Chưa diễn ra
  completed,  // Đã hoàn thành
}

extension SessionStatusExtension on SessionStatus {
  String get displayName {
    switch (this) {
      case SessionStatus.scheduled:
        return 'Chưa diễn ra';
      case SessionStatus.completed:
        return 'Đã hoàn thành';
    }
  }
}

