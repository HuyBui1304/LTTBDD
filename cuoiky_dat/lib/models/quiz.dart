class Quiz {
  final int? id;
  final String title;
  final String description;
  final int? timeLimit; // Time limit in minutes, null = no limit
  final int questionCount; // Number of questions to show
  final List<int>? topicIds; // null = all topics
  final String mode; // 'fixed' (cố định), 'random' (ngẫu nhiên), 'practice' (luyện tập)
  final bool shuffleQuestions; // Shuffle question order
  final bool showResultImmediately; // Show result after each question
  final DateTime createdAt;

  Quiz({
    this.id,
    required this.title,
    required this.description,
    this.timeLimit,
    required this.questionCount,
    this.topicIds,
    this.mode = 'random',
    this.shuffleQuestions = true,
    this.showResultImmediately = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timeLimit': timeLimit,
      'questionCount': questionCount,
      'topicIds': topicIds?.join(','), // Store as comma-separated string
      'mode': mode,
      'shuffleQuestions': shuffleQuestions ? 1 : 0,
      'showResultImmediately': showResultImmediately ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      timeLimit: map['timeLimit'] as int?,
      questionCount: map['questionCount'] as int,
      topicIds: map['topicIds'] != null
          ? (map['topicIds'] as String).split(',').map((e) => int.parse(e)).toList()
          : null,
      mode: map['mode'] as String? ?? 'random',
      shuffleQuestions: (map['shuffleQuestions'] as int? ?? 1) == 1,
      showResultImmediately: (map['showResultImmediately'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Quiz copyWith({
    int? id,
    String? title,
    String? description,
    int? timeLimit,
    int? questionCount,
    List<int>? topicIds,
    String? mode,
    bool? shuffleQuestions,
    bool? showResultImmediately,
    DateTime? createdAt,
  }) {
    return Quiz(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timeLimit: timeLimit ?? this.timeLimit,
      questionCount: questionCount ?? this.questionCount,
      topicIds: topicIds ?? this.topicIds,
      mode: mode ?? this.mode,
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      showResultImmediately: showResultImmediately ?? this.showResultImmediately,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

