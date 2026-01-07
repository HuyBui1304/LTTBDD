class Question {
  final int? id;
  final String questionText;
  final List<String> options; // 4 options
  final int correctAnswerIndex; // 0-3
  final int topicId;
  final String? explanation;
  final int difficulty; // 1 = Easy, 2 = Medium, 3 = Hard
  final DateTime createdAt;

  Question({
    this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.topicId,
    this.explanation,
    this.difficulty = 1,
    required this.createdAt,
  }) : assert(options.length == 4, 'Question must have exactly 4 options'),
       assert(correctAnswerIndex >= 0 && correctAnswerIndex < 4, 'Correct answer index must be 0-3');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionText': questionText,
      'options': options.join('|||'), // Store as delimited string
      'correctAnswerIndex': correctAnswerIndex,
      'topicId': topicId,
      'explanation': explanation,
      'difficulty': difficulty,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as int?,
      questionText: map['questionText'] as String,
      options: (map['options'] as String).split('|||'),
      correctAnswerIndex: map['correctAnswerIndex'] as int,
      topicId: map['topicId'] as int,
      explanation: map['explanation'] as String?,
      difficulty: map['difficulty'] as int? ?? 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Question copyWith({
    int? id,
    String? questionText,
    List<String>? options,
    int? correctAnswerIndex,
    int? topicId,
    String? explanation,
    int? difficulty,
    DateTime? createdAt,
  }) {
    return Question(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      topicId: topicId ?? this.topicId,
      explanation: explanation ?? this.explanation,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get difficultyText {
    switch (difficulty) {
      case 1:
        return 'Dễ';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Khó';
      default:
        return 'Dễ';
    }
  }
}

