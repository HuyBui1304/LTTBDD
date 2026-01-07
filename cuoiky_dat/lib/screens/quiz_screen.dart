import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../database/database_helper.dart';
import '../services/auth_service.dart';
import 'quiz_taking_screen.dart';
import 'quiz_result_screen.dart';
import 'quiz_form_screen.dart';
import '../widgets/skeleton_loader.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AuthService _authService = AuthService();
  List<Quiz> _quizzes = [];
  bool _isLoading = true;
  String _error = '';
  
  bool get _isAdmin => _authService.isAdmin;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final quizzes = await _dbHelper.getAllQuizzes();
      setState(() {
        _quizzes = quizzes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải đề thi: $e';
        _isLoading = false;
      });
    }
  }

  List<Quiz> get _filteredQuizzes {
    if (_searchQuery.isEmpty) return _quizzes;
    return _quizzes.where((quiz) {
      return quiz.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          quiz.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _deleteQuiz(Quiz quiz) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa đề thi "${quiz.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbHelper.deleteQuiz(quiz.id!);
        _loadQuizzes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa đề thi thành công')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đề thi'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm đề thi...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Quizzes list
          Expanded(
            child: _isLoading && _quizzes.isEmpty
                ? ListView.builder(
                    itemCount: 5,
                    itemBuilder: (context, index) => const SkeletonListTile(),
                  )
                : _error.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_error, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadQuizzes,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _filteredQuizzes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Không tìm thấy đề thi nào'
                                      : 'Chưa có đề thi nào',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadQuizzes,
                            child: ListView.builder(
                              itemCount: _filteredQuizzes.length,
                              itemBuilder: (context, index) {
                                final quiz = _filteredQuizzes[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      child: const Icon(Icons.quiz, color: Colors.white),
                                    ),
                                    title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(quiz.description),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.help_outline, size: 16, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text('${quiz.questionCount} câu hỏi'),
                                            if (quiz.timeLimit != null) ...[
                                              const SizedBox(width: 16),
                                              Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Text('${quiz.timeLimit} phút'),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Chip(
                                          label: Text(quiz.mode == 'fixed' ? 'Cố định' : quiz.mode == 'random' ? 'Ngẫu nhiên' : 'Luyện tập'),
                                          labelStyle: const TextStyle(fontSize: 12),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'start') {
                                          _startQuiz(quiz);
                                        } else if (value == 'edit' && _isAdmin) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => QuizFormScreen(quiz: quiz),
                                            ),
                                          ).then((result) {
                                            if (result == true) {
                                              _loadQuizzes();
                                            }
                                          });
                                        } else if (value == 'results') {
                                          _viewResults(quiz);
                                        } else if (value == 'delete' && _isAdmin) {
                                          _deleteQuiz(quiz);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(value: 'start', child: Text('Bắt đầu làm bài')),
                                        if (_isAdmin) const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                                        const PopupMenuItem(value: 'results', child: Text('Xem kết quả')),
                                        if (_isAdmin) const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                                      ],
                                    ),
                                    onTap: () => _startQuiz(quiz),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuizFormScreen()),
                );
                if (result == true) {
                  _loadQuizzes();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _startQuiz(Quiz quiz) async {
    // Get questions for quiz
    List<Question> questions = [];
    
    if (quiz.mode == 'fixed' && quiz.topicIds != null) {
      // Get questions from specific topics
      for (final topicId in quiz.topicIds!) {
        final topicQuestions = await _dbHelper.getQuestionsByTopic(topicId);
        questions.addAll(topicQuestions);
      }
    } else {
      // Get random questions
      questions = await _dbHelper.getRandomQuestions(
        topicId: quiz.topicIds?.isNotEmpty == true ? quiz.topicIds!.first : null,
        count: quiz.questionCount,
      );
    }

    if (questions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có câu hỏi nào trong đề thi này')),
        );
      }
      return;
    }

    // Limit to questionCount
    if (questions.length > quiz.questionCount) {
      questions = questions.take(quiz.questionCount).toList();
    }

    // Shuffle if needed
    if (quiz.shuffleQuestions) {
      questions.shuffle();
    }

    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizTakingScreen(
            quiz: quiz,
            questions: questions,
          ),
        ),
      );

      if (result is QuizResult) {
        // Show result screen
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizResultScreen(result: result),
            ),
          );
        }
        _loadQuizzes();
      }
    }
  }

  Future<void> _viewResults(Quiz quiz) async {
    final results = await _dbHelper.getQuizResultsByQuizId(quiz.id!);
    if (results.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa có kết quả nào cho đề thi này')),
        );
      }
      return;
    }

    // Show latest result
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultScreen(result: results.first),
        ),
      );
    }
  }
}

