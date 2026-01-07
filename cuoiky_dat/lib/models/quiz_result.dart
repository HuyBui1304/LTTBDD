class QuizResult {
  final int? id;
  final int quizId;
  final String quizTitle;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final double score; // Percentage score (0-100)
  final int? timeSpent; // Time spent in seconds
  final Map<int, int> answers; // questionId -> selectedAnswerIndex
  final DateTime completedAt;
  final String mode; // 'fixed', 'random', 'practice'

  QuizResult({
    this.id,
    required this.quizId,
    required this.quizTitle,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.score,
    this.timeSpent,
    required this.answers,
    required this.completedAt,
    required this.mode,
  });

  Map<String, dynamic> toMap() {
    // Convert answers map to string: "questionId:answerIndex,questionId:answerIndex"
    final answersString = answers.entries
        .map((e) => '${e.key}:${e.value}')
        .join(',');
    
    return {
      'id': id,
      'quizId': quizId,
      'quizTitle': quizTitle,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'score': score,
      'timeSpent': timeSpent,
      'answers': answersString,
      'completedAt': completedAt.millisecondsSinceEpoch,
      'mode': mode,
    };
  }

  factory QuizResult.fromMap(Map<String, dynamic> map) {
    // Parse answers string back to map
    final answersString = map['answers'] as String? ?? '';
    final answers = <int, int>{};
    if (answersString.isNotEmpty) {
      for (final pair in answersString.split(',')) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          answers[int.parse(parts[0])] = int.parse(parts[1]);
        }
      }
    }

    return QuizResult(
      id: map['id'] as int?,
      quizId: map['quizId'] as int,
      quizTitle: map['quizTitle'] as String,
      totalQuestions: map['totalQuestions'] as int,
      correctAnswers: map['correctAnswers'] as int,
      wrongAnswers: map['wrongAnswers'] as int,
      score: (map['score'] as num).toDouble(),
      timeSpent: map['timeSpent'] as int?,
      answers: answers,
      completedAt: DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int),
      mode: map['mode'] as String? ?? 'random',
    );
  }

  QuizResult copyWith({
    int? id,
    int? quizId,
    String? quizTitle,
    int? totalQuestions,
    int? correctAnswers,
    int? wrongAnswers,
    double? score,
    int? timeSpent,
    Map<int, int>? answers,
    DateTime? completedAt,
    String? mode,
  }) {
    return QuizResult(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      quizTitle: quizTitle ?? this.quizTitle,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      score: score ?? this.score,
      timeSpent: timeSpent ?? this.timeSpent,
      answers: answers ?? this.answers,
      completedAt: completedAt ?? this.completedAt,
      mode: mode ?? this.mode,
    );
  }

  String get grade {
    if (score >= 90) return 'Xuất sắc';
    if (score >= 80) return 'Giỏi';
    if (score >= 70) return 'Khá';
    if (score >= 50) return 'Trung bình';
    return 'Yếu';
  }
}

