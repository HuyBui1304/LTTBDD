import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../models/topic.dart';
import '../database/database_helper.dart';
import '../utils/validation.dart';

class QuizFormScreen extends StatefulWidget {
  final Quiz? quiz;

  const QuizFormScreen({super.key, this.quiz});

  @override
  State<QuizFormScreen> createState() => _QuizFormScreenState();
}

class _QuizFormScreenState extends State<QuizFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _questionCountController = TextEditingController();
  final _timeLimitController = TextEditingController();

  String _selectedMode = 'random';
  bool _shuffleQuestions = true;
  bool _showResultImmediately = false;
  List<int> _selectedTopicIds = [];

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Topic> _topics = [];

  @override
  void initState() {
    super.initState();
    _loadTopics();
    if (widget.quiz != null) {
      _titleController.text = widget.quiz!.title;
      _descriptionController.text = widget.quiz!.description;
      _questionCountController.text = widget.quiz!.questionCount.toString();
      if (widget.quiz!.timeLimit != null) {
        _timeLimitController.text = widget.quiz!.timeLimit.toString();
      }
      _selectedMode = widget.quiz!.mode;
      _shuffleQuestions = widget.quiz!.shuffleQuestions;
      _showResultImmediately = widget.quiz!.showResultImmediately;
      _selectedTopicIds = widget.quiz!.topicIds ?? [];
    }
  }

  Future<void> _loadTopics() async {
    final topics = await _dbHelper.getAllTopics();
    setState(() {
      _topics = topics;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _questionCountController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  Future<void> _saveQuiz() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedTopicIds.isEmpty && _selectedMode == 'fixed') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ít nhất một chủ đề cho đề thi cố định')),
        );
        return;
      }

      try {
        final questionCount = int.parse(_questionCountController.text);
        if (questionCount <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Số câu hỏi phải lớn hơn 0')),
          );
          return;
        }

        final quiz = Quiz(
          id: widget.quiz?.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          timeLimit: _timeLimitController.text.trim().isEmpty
              ? null
              : int.tryParse(_timeLimitController.text.trim()),
          questionCount: questionCount,
          topicIds: _selectedTopicIds.isEmpty ? null : _selectedTopicIds,
          mode: _selectedMode,
          shuffleQuestions: _shuffleQuestions,
          showResultImmediately: _showResultImmediately,
          createdAt: widget.quiz?.createdAt ?? DateTime.now(),
        );

        if (widget.quiz == null) {
          await _dbHelper.insertQuiz(quiz);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã thêm đề thi thành công')),
            );
          }
        } else {
          await _dbHelper.updateQuiz(quiz);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã cập nhật đề thi thành công')),
            );
          }
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz == null ? 'Tạo đề thi' : 'Chỉnh sửa đề thi'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề đề thi *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => Validation.validateNotEmpty(value, 'Tiêu đề'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _questionCountController,
                    decoration: const InputDecoration(
                      labelText: 'Số câu hỏi *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập số câu hỏi';
                      }
                      final count = int.tryParse(value);
                      if (count == null || count <= 0) {
                        return 'Số câu hỏi phải là số dương';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _timeLimitController,
                    decoration: const InputDecoration(
                      labelText: 'Thời gian (phút)',
                      border: OutlineInputBorder(),
                      hintText: 'Để trống = không giới hạn',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMode,
              decoration: const InputDecoration(
                labelText: 'Chế độ *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'random', child: Text('Ngẫu nhiên')),
                DropdownMenuItem(value: 'fixed', child: Text('Cố định')),
                DropdownMenuItem(value: 'practice', child: Text('Luyện tập')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedMode = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            // Topic selection
            const Text(
              'Chọn chủ đề (tùy chọn):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_topics.isEmpty)
              const Text(
                'Chưa có chủ đề nào. Vui lòng thêm chủ đề trước.',
                style: TextStyle(color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _topics.map((topic) {
                  final isSelected = _selectedTopicIds.contains(topic.id);
                  return FilterChip(
                    label: Text(topic.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTopicIds.add(topic.id!);
                        } else {
                          _selectedTopicIds.remove(topic.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Xáo trộn câu hỏi'),
              value: _shuffleQuestions,
              onChanged: (value) {
                setState(() {
                  _shuffleQuestions = value ?? true;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Hiển thị kết quả ngay sau mỗi câu'),
              subtitle: const Text('(Chỉ áp dụng cho chế độ luyện tập)'),
              value: _showResultImmediately,
              onChanged: (value) {
                setState(() {
                  _showResultImmediately = value ?? false;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveQuiz,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(widget.quiz == null ? 'Tạo đề thi' : 'Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }
}

