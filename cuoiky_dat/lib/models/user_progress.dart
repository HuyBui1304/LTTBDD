class UserProgress {
  final int? id;
  final int topicId;
  final String topicName;
  final int totalQuestions; // Total questions attempted in this topic
  final int correctAnswers; // Correct answers in this topic
  final int wrongAnswers; // Wrong answers in this topic
  final double averageScore; // Average score percentage
  final DateTime lastPracticedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProgress({
    this.id,
    required this.topicId,
    required this.topicName,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.averageScore,
    required this.lastPracticedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topicId': topicId,
      'topicName': topicName,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'averageScore': averageScore,
      'lastPracticedAt': lastPracticedAt.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      id: map['id'] as int?,
      topicId: map['topicId'] as int,
      topicName: map['topicName'] as String,
      totalQuestions: map['totalQuestions'] as int,
      correctAnswers: map['correctAnswers'] as int,
      wrongAnswers: map['wrongAnswers'] as int,
      averageScore: (map['averageScore'] as num).toDouble(),
      lastPracticedAt: DateTime.fromMillisecondsSinceEpoch(map['lastPracticedAt'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  UserProgress copyWith({
    int? id,
    int? topicId,
    String? topicName,
    int? totalQuestions,
    int? correctAnswers,
    int? wrongAnswers,
    double? averageScore,
    DateTime? lastPracticedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProgress(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      topicName: topicName ?? this.topicName,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      averageScore: averageScore ?? this.averageScore,
      lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get accuracy => totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;

  String get performanceLevel {
    if (averageScore >= 90) return 'Xuất sắc';
    if (averageScore >= 80) return 'Giỏi';
    if (averageScore >= 70) return 'Khá';
    if (averageScore >= 50) return 'Trung bình';
    return 'Cần cải thiện';
  }
}

