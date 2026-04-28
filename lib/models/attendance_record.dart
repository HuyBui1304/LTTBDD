class AttendanceRecord {
  final int? id;
  final int sessionId;
  final int studentId;
  final AttendanceStatus status;
  final DateTime checkInTime;
  final String? note;
  final CheckInMethod checkInMethod;
  final int? checkedByTeacherId; // teacher ID for manual check-in
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields for display (not stored in DB)
  final String? studentName;
  final String? studentCode;
  final String? teacherName;

  AttendanceRecord({
    this.id,
    required this.sessionId,
    required this.studentId,
    this.status = AttendanceStatus.present,
    DateTime? checkInTime,
    this.note,
    this.checkInMethod = CheckInMethod.qrScan,
    this.checkedByTeacherId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.studentName,
    this.studentCode,
    this.teacherName,
  })  : checkInTime = checkInTime ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'studentId': studentId,
      'status': status.name,
      'checkInTime': checkInTime.toIso8601String(),
      'note': note,
      'checkInMethod': checkInMethod.name,
      'checkedByTeacherId': checkedByTeacherId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Map
  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as int?,
      sessionId: map['sessionId'] as int,
      studentId: map['studentId'] as int,
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AttendanceStatus.present,
      ),
      checkInTime: DateTime.parse(map['checkInTime'] as String),
      note: map['note'] as String?,
      checkInMethod: CheckInMethod.values.firstWhere(
        (e) => e.name == (map['checkInMethod'] as String? ?? 'qrScan'),
        orElse: () => CheckInMethod.qrScan,
      ),
      checkedByTeacherId: map['checkedByTeacherId'] as int?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      studentName: map['studentName'] as String?,
      studentCode: map['studentCode'] as String?,
      teacherName: map['teacherName'] as String?,
    );
  }

  // Copy with method for updates
  AttendanceRecord copyWith({
    int? id,
    int? sessionId,
    int? studentId,
    AttendanceStatus? status,
    DateTime? checkInTime,
    String? note,
    CheckInMethod? checkInMethod,
    int? checkedByTeacherId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? studentName,
    String? studentCode,
    String? teacherName,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      checkInTime: checkInTime ?? this.checkInTime,
      note: note ?? this.note,
      checkInMethod: checkInMethod ?? this.checkInMethod,
      checkedByTeacherId: checkedByTeacherId ?? this.checkedByTeacherId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      studentName: studentName ?? this.studentName,
      studentCode: studentCode ?? this.studentCode,
      teacherName: teacherName ?? this.teacherName,
    );
  }

  @override
  String toString() {
    return 'AttendanceRecord{id: $id, studentId: $studentId, status: $status, checkInTime: $checkInTime}';
  }
}

enum AttendanceStatus {
  present,
  absent,
  late,
  excused,
}

extension AttendanceStatusExtension on AttendanceStatus {
  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Có mặt';
      case AttendanceStatus.absent:
        return 'Vắng';
      case AttendanceStatus.late:
        return 'Muộn';
      case AttendanceStatus.excused:
        return 'Có phép';
    }
  }
}

enum CheckInMethod {
  qrScan, // QR scan
  qrCode, // 4-digit code entry
  manual, // manual teacher check-in
}

extension CheckInMethodExtension on CheckInMethod {
  String get displayName {
    switch (this) {
      case CheckInMethod.qrScan:
        return 'Quét QR';
      case CheckInMethod.qrCode:
        return 'Nhập mã';
      case CheckInMethod.manual:
        return 'Giáo viên điểm danh';
    }
  }
}

