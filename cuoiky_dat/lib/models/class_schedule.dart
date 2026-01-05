class ClassSchedule {
  final int? id;
  final String className;
  final String subject;
  final String room;
  final String teacher;
  final int dayOfWeek; // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
  final String startTime; // Format: "HH:mm"
  final String endTime; // Format: "HH:mm"
  final String weekPattern; // "All", "Odd", "Even"
  final DateTime createdAt;

  ClassSchedule({
    this.id,
    required this.className,
    required this.subject,
    required this.room,
    required this.teacher,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.weekPattern,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'className': className,
      'subject': subject,
      'room': room,
      'teacher': teacher,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'weekPattern': weekPattern,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ClassSchedule.fromMap(Map<String, dynamic> map) {
    return ClassSchedule(
      id: map['id'] as int?,
      className: map['className'] as String,
      subject: map['subject'] as String,
      room: map['room'] as String,
      teacher: map['teacher'] as String,
      dayOfWeek: map['dayOfWeek'] as int,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      weekPattern: map['weekPattern'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  ClassSchedule copyWith({
    int? id,
    String? className,
    String? subject,
    String? room,
    String? teacher,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? weekPattern,
    DateTime? createdAt,
  }) {
    return ClassSchedule(
      id: id ?? this.id,
      className: className ?? this.className,
      subject: subject ?? this.subject,
      room: room ?? this.room,
      teacher: teacher ?? this.teacher,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      weekPattern: weekPattern ?? this.weekPattern,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get dayName {
    const days = ['Chủ Nhật', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7'];
    return days[dayOfWeek];
  }
}

