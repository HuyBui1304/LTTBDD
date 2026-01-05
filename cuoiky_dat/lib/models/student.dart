class Student {
  final int? id;
  final String name;
  final String studentId;
  final String email;
  final String phone;
  final String major;
  final int year;
  final DateTime createdAt;

  Student({
    this.id,
    required this.name,
    required this.studentId,
    required this.email,
    required this.phone,
    required this.major,
    required this.year,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'studentId': studentId,
      'email': email,
      'phone': phone,
      'major': major,
      'year': year,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as int?,
      name: map['name'] as String,
      studentId: map['studentId'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      major: map['major'] as String,
      year: map['year'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Student copyWith({
    int? id,
    String? name,
    String? studentId,
    String? email,
    String? phone,
    String? major,
    int? year,
    DateTime? createdAt,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      studentId: studentId ?? this.studentId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      major: major ?? this.major,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

