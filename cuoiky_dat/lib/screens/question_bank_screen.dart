import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/topic.dart';
import '../database/database_helper.dart';
import '../services/auth_service.dart';
import 'question_form_screen.dart';
import '../widgets/skeleton_loader.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AuthService _authService = AuthService();
  List<Question> _questions = [];
  List<Topic> _topics = [];
  bool _isLoading = true;
  String _error = '';
  String _searchQuery = '';
  int? _selectedTopicId;
  int? _selectedDifficulty;
  String _sortBy = 'createdAt'; // 'createdAt', 'difficulty', 'topic'
  bool _sortAscending = false;
  
  bool get _isAdmin => _authService.isAdmin;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final questions = await _dbHelper.getAllQuestions();
      final topics = await _dbHelper.getAllTopics();
      setState(() {
        _questions = questions;
        _topics = topics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải dữ liệu: $e';
        _isLoading = false;
      });
    }
  }

  List<Question> get _filteredQuestions {
    List<Question> filtered = List.from(_questions);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((q) {
        return q.questionText.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_selectedTopicId != null) {
      filtered = filtered.where((q) => q.topicId == _selectedTopicId).toList();
    }

    if (_selectedDifficulty != null) {
      filtered = filtered.where((q) => q.difficulty == _selectedDifficulty).toList();
    }

    // Sort
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'difficulty':
          comparison = a.difficulty.compareTo(b.difficulty);
          break;
        case 'topic':
          comparison = a.topicId.compareTo(b.topicId);
          break;
        case 'createdAt':
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  Future<void> _deleteQuestion(Question question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa câu hỏi này?'),
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
        await _dbHelper.deleteQuestion(question.id!);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa câu hỏi thành công')),
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
        title: const Text('Ngân hàng câu hỏi'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Search and filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm câu hỏi...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Use single row on wide screens, stacked on narrow screens
                    if (constraints.maxWidth > 400) {
                      return Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              value: _selectedTopicId,
                              decoration: const InputDecoration(
                                labelText: 'Chủ đề',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                isDense: true,
                              ),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem<int?>(value: null, child: Text('Tất cả', overflow: TextOverflow.ellipsis)),
                                ..._topics.map((topic) {
                                  return DropdownMenuItem<int?>(
                                    value: topic.id,
                                    child: Text(
                                      topic.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedTopicId = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              value: _selectedDifficulty,
                              decoration: const InputDecoration(
                                labelText: 'Độ khó',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                isDense: true,
                              ),
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem<int?>(value: null, child: Text('Tất cả', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 1, child: Text('Dễ', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 2, child: Text('Trung bình', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 3, child: Text('Khó', overflow: TextOverflow.ellipsis)),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedDifficulty = value;
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Stack vertically on narrow screens
                      return Column(
                        children: [
                          DropdownButtonFormField<int?>(
                            value: _selectedTopicId,
                            decoration: const InputDecoration(
                              labelText: 'Chủ đề',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('Tất cả', overflow: TextOverflow.ellipsis)),
                              ..._topics.map((topic) {
                                return DropdownMenuItem<int?>(
                                  value: topic.id,
                                  child: Text(
                                    topic.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedTopicId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int?>(
                            value: _selectedDifficulty,
                            decoration: const InputDecoration(
                              labelText: 'Độ khó',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem<int?>(value: null, child: Text('Tất cả', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 1, child: Text('Dễ', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 2, child: Text('Trung bình', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 3, child: Text('Khó', overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedDifficulty = value;
                              });
                            },
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                // Sort options
                Row(
                  children: [
                    const Text('Sắp xếp: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'createdAt', child: Text('Ngày tạo')),
                          DropdownMenuItem(value: 'difficulty', child: Text('Độ khó')),
                          DropdownMenuItem(value: 'topic', child: Text('Chủ đề')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _sortBy = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                      onPressed: () {
                        setState(() {
                          _sortAscending = !_sortAscending;
                        });
                      },
                      tooltip: _sortAscending ? 'Tăng dần' : 'Giảm dần',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Questions list
          Expanded(
            child: _isLoading && _questions.isEmpty
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
                              onPressed: _loadData,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _filteredQuestions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.help_outline, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty || _selectedTopicId != null || _selectedDifficulty != null
                                      ? 'Không tìm thấy câu hỏi nào'
                                      : 'Chưa có câu hỏi nào',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.builder(
                              itemCount: _filteredQuestions.length,
                              itemBuilder: (context, index) {
                                final question = _filteredQuestions[index];
                                final topic = _topics.firstWhere(
                                  (t) => t.id == question.topicId,
                                  orElse: () => Topic(id: -1, name: 'Unknown', description: '', createdAt: DateTime.now()),
                                );

                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getDifficultyColor(question.difficulty),
                                      child: Text(
                                        question.difficulty.toString(),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    title: Text(
                                      question.questionText,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Chủ đề: ${topic.name}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Độ khó: ${question.difficultyText}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Đáp án đúng: ${question.options[question.correctAnswerIndex]}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    isThreeLine: false,
                                    dense: true,
                                    trailing: _isAdmin
                                        ? PopupMenuButton<String>(
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => QuestionFormScreen(question: question),
                                                  ),
                                                ).then((result) {
                                                  if (result == true) {
                                                    _loadData();
                                                  }
                                                });
                                              } else if (value == 'delete') {
                                                _deleteQuestion(question);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                                              const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                                            ],
                                          )
                                        : null,
                                    onTap: () {
                                      _showQuestionDetails(question, topic);
                                    },
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
                  MaterialPageRoute(builder: (context) => const QuestionFormScreen()),
                );
                if (result == true) {
                  _loadData();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showQuestionDetails(Question question, Topic topic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chi tiết câu hỏi'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Câu hỏi: ${question.questionText}'),
              const SizedBox(height: 16),
              const Text('Các lựa chọn:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...question.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isCorrect = index == question.correctAnswerIndex;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isCorrect ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(option)),
                      if (isCorrect)
                        const Text(
                          ' (Đúng)',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              Text('Chủ đề: ${topic.name}'),
              Text('Độ khó: ${question.difficultyText}'),
              if (question.explanation != null && question.explanation!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Giải thích: ${question.explanation}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          if (_isAdmin)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuestionFormScreen(question: question),
                  ),
                ).then((result) {
                  if (result == true) {
                    _loadData();
                  }
                });
              },
              child: const Text('Chỉnh sửa'),
            ),
        ],
      ),
    );
  }
}

