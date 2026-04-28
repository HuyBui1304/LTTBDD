class Subject {
  final int? id;
  final String subjectCode; // subject code (e.g. LTTBDD2024)
  final String subjectName;
  final String classCode; // class section code
  final String? description;
  final String? creatorId; // UID of teacher who created/manages the subject
  final DateTime createdAt;
  final DateTime updatedAt;

  // Display field (not stored in DB)
  final String? creatorName;

  Subject({
    this.id,
    required this.subjectCode,
    required this.subjectName,
    required this.classCode,
    this.description,
    this.creatorId, // teacher UID
    this.creatorName,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'classCode': classCode,
      'description': description,
      'creatorId': creatorId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Map
  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as int?,
      subjectCode: map['subjectCode'] as String,
      subjectName: map['subjectName'] as String,
      classCode: map['classCode'] as String,
      description: map['description'] as String?,
      creatorId: map['creatorId'] as String?, // teacher UID
      creatorName: map['creatorName'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // Copy with method for updates
  Subject copyWith({
    int? id,
    String? subjectCode,
    String? subjectName,
    String? classCode,
    String? description,
    String? creatorId, // teacher UID
    String? creatorName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subject(
      id: id ?? this.id,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      classCode: classCode ?? this.classCode,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Subject{id: $id, subjectCode: $subjectCode, subjectName: $subjectName, classCode: $classCode}';
  }
}

