class Student {
  final int? id;
  final String studentId; // Mã sinh viên
  final String name;
  final String email;
  final String? phone;
  final String? classCode; // Mã lớp (deprecated, dùng subjectIds)
  final List<String>? subjectIds; // Danh sách ID môn học mà student đăng ký
  final DateTime createdAt;
  final DateTime updatedAt;

  Student({
    this.id,
    required this.studentId,
    required this.name,
    required this.email,
    this.phone,
    this.classCode, // Deprecated, dùng subjectIds
    this.subjectIds, // Danh sách ID môn học
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'name': name,
      'email': email,
      'phone': phone,
      'classCode': classCode,
      'subjectIds': subjectIds, // Danh sách ID môn học
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Map
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as int?,
      studentId: map['studentId'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      classCode: map['classCode'] as String?,
      subjectIds: map['subjectIds'] != null 
          ? List<String>.from(map['subjectIds'] as List)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // Copy with method for updates
  Student copyWith({
    int? id,
    String? studentId,
    String? name,
    String? email,
    String? phone,
    String? classCode,
    List<String>? subjectIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      classCode: classCode ?? this.classCode,
      subjectIds: subjectIds ?? this.subjectIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Student{id: $id, studentId: $studentId, name: $name, email: $email}';
  }
}

