import 'dart:async';
import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../database/database_helper.dart';

class QuizTakingScreen extends StatefulWidget {
  final Quiz quiz;
  final List<Question> questions;

  const QuizTakingScreen({
    super.key,
    required this.quiz,
    required this.questions,
  });

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  int _currentQuestionIndex = 0;
  Map<int, int> _answers = {}; // questionId -> selectedAnswerIndex
  DateTime? _startTime;
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    if (widget.quiz.timeLimit != null) {
      _remainingSeconds = widget.quiz.timeLimit! * 60;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _submitQuiz();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      _answers[widget.questions[_currentQuestionIndex].id!] = answerIndex;
    });

    if (widget.quiz.showResultImmediately) {
      // Show if correct/incorrect immediately
      final question = widget.questions[_currentQuestionIndex];
      final isCorrect = answerIndex == question.correctAnswerIndex;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCorrect ? 'Đúng!' : 'Sai! Đáp án đúng: ${question.options[question.correctAnswerIndex]}'),
          backgroundColor: isCorrect ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Auto move to next question after a delay if showing result immediately
    if (widget.quiz.showResultImmediately) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _currentQuestionIndex < widget.questions.length - 1) {
          _nextQuestion();
        }
      });
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  Future<void> _submitQuiz() async {
    _timer?.cancel();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nộp bài'),
        content: const Text('Bạn có chắc muốn nộp bài? Bạn sẽ không thể thay đổi câu trả lời sau khi nộp.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Nộp bài'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _calculateAndSaveResult();
    }
  }

  Future<void> _calculateAndSaveResult() async {
    int correctAnswers = 0;
    int wrongAnswers = 0;

    for (final question in widget.questions) {
      final selectedAnswer = _answers[question.id];
      if (selectedAnswer != null) {
        if (selectedAnswer == question.correctAnswerIndex) {
          correctAnswers++;
        } else {
          wrongAnswers++;
        }
      } else {
        wrongAnswers++; // Not answered = wrong
      }
    }

    final totalQuestions = widget.questions.length;
    final score = (correctAnswers / totalQuestions) * 100;
    final timeSpent = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : null;

    final result = QuizResult(
      quizId: widget.quiz.id!,
      quizTitle: widget.quiz.title,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      wrongAnswers: wrongAnswers,
      score: score,
      timeSpent: timeSpent,
      answers: _answers,
      completedAt: DateTime.now(),
      mode: widget.quiz.mode,
    );

    final dbHelper = DatabaseHelper.instance;
    await dbHelper.insertQuizResult(result);

    if (mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentQuestionIndex];
    final selectedAnswer = _answers[question.id];
    final progress = (_currentQuestionIndex + 1) / widget.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.quiz.timeLimit != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _formatTime(_remainingSeconds),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _remainingSeconds < 60 ? Colors.red : null,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(value: progress),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Câu ${_currentQuestionIndex + 1}/${widget.questions.length}'),
                Text('${(progress * 100).toInt()}%'),
              ],
            ),
          ),
          // Question
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.questionText,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  ...question.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = selectedAnswer == index;
                    final isCorrect = index == question.correctAnswerIndex;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isSelected
                          ? (isCorrect ? Colors.green.shade100 : Colors.red.shade100)
                          : null,
                      child: ListTile(
                        title: Text(option),
                        leading: Radio<int>(
                          value: index,
                          groupValue: selectedAnswer,
                          onChanged: (value) => _selectAnswer(value!),
                        ),
                        onTap: () => _selectAnswer(index),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Câu trước'),
                ),
                ElevatedButton.icon(
                  onPressed: _submitQuiz,
                  icon: const Icon(Icons.check),
                  label: const Text('Nộp bài'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _currentQuestionIndex < widget.questions.length - 1
                      ? _nextQuestion
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Câu sau'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

