import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/quiz_result.dart';
import '../models/question.dart';
import '../database/database_helper.dart';

class QuizResultScreen extends StatefulWidget {
  final QuizResult result;

  const QuizResultScreen({super.key, required this.result});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Map<int, Question> _questions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    for (final questionId in widget.result.answers.keys) {
      final question = await _dbHelper.getQuestionById(questionId);
      if (question != null) {
        _questions[questionId] = question;
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  String _formatTime(int? seconds) {
    if (seconds == null) return 'N/A';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}ph ${secs}giây';
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả bài thi'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary card
                  Card(
                    color: _getScoreColor(result.score),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            '${result.score.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            result.grade,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('Đúng', result.correctAnswers.toString(), Colors.green),
                              _buildStatItem('Sai', result.wrongAnswers.toString(), Colors.red),
                              _buildStatItem('Tổng', result.totalQuestions.toString(), Colors.blue),
                            ],
                          ),
                          if (result.timeSpent != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Thời gian: ${_formatTime(result.timeSpent)}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Hoàn thành: ${dateFormat.format(result.completedAt)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Detailed results
                  const Text(
                    'Chi tiết từng câu',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...result.answers.entries.map((entry) {
                    final questionId = entry.key;
                    final selectedAnswer = entry.value;
                    final question = _questions[questionId];
                    
                    if (question == null) return const SizedBox.shrink();

                    final isCorrect = selectedAnswer == question.correctAnswerIndex;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isCorrect ? Icons.check_circle : Icons.cancel,
                                  color: isCorrect ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    question.questionText,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...question.options.asMap().entries.map((optEntry) {
                              final index = optEntry.key;
                              final option = optEntry.value;
                              final isSelected = selectedAnswer == index;
                              final isCorrectAnswer = index == question.correctAnswerIndex;

                              Color? backgroundColor;
                              IconData? icon;
                              Color? iconColor;

                              if (isCorrectAnswer) {
                                backgroundColor = Colors.green.shade100;
                                icon = Icons.check;
                                iconColor = Colors.green;
                              } else if (isSelected) {
                                backgroundColor = Colors.red.shade100;
                                icon = Icons.close;
                                iconColor = Colors.red;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected || isCorrectAnswer
                                        ? (isCorrectAnswer ? Colors.green : Colors.red)
                                        : Colors.grey.shade300,
                                    width: isSelected || isCorrectAnswer ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    if (icon != null) ...[
                                      Icon(icon, color: iconColor, size: 20),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(child: Text(option)),
                                    if (isCorrectAnswer)
                                      const Text(
                                        'Đáp án đúng',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    if (isSelected && !isCorrectAnswer)
                                      const Text(
                                        'Bạn chọn',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                            if (question.explanation != null && question.explanation!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        question.explanation!,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.blue;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}

