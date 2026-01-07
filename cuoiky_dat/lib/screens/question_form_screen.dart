import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/topic.dart';
import '../database/database_helper.dart';
import '../utils/validation.dart';

class QuestionFormScreen extends StatefulWidget {
  final Question? question;

  const QuestionFormScreen({super.key, this.question});

  @override
  State<QuestionFormScreen> createState() => _QuestionFormScreenState();
}

class _QuestionFormScreenState extends State<QuestionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionTextController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final _explanationController = TextEditingController();

  int _selectedTopicId = 1;
  int _selectedDifficulty = 1;
  int _correctAnswerIndex = 0;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Topic> _topics = [];

  @override
  void initState() {
    super.initState();
    _loadTopics();
    if (widget.question != null) {
      _questionTextController.text = widget.question!.questionText;
      for (int i = 0; i < 4; i++) {
        _optionControllers[i].text = widget.question!.options[i];
      }
      _explanationController.text = widget.question?.explanation ?? '';
      _selectedTopicId = widget.question!.topicId;
      _selectedDifficulty = widget.question!.difficulty;
      _correctAnswerIndex = widget.question!.correctAnswerIndex;
    }
  }

  Future<void> _loadTopics() async {
    final topics = await _dbHelper.getAllTopics();
    setState(() {
      _topics = topics;
      if (_topics.isNotEmpty && _selectedTopicId == 1 && widget.question == null) {
        _selectedTopicId = _topics.first.id ?? 1;
      }
    });
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    _explanationController.dispose();
    super.dispose();
  }

  Future<void> _saveQuestion() async {
    if (_formKey.currentState!.validate()) {
      // Validate all options are filled
      bool allOptionsFilled = true;
      for (final controller in _optionControllers) {
        if (controller.text.trim().isEmpty) {
          allOptionsFilled = false;
          break;
        }
      }

      if (!allOptionsFilled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng điền đầy đủ 4 lựa chọn')),
        );
        return;
      }

      try {
        final question = Question(
          id: widget.question?.id,
          questionText: _questionTextController.text.trim(),
          options: _optionControllers.map((c) => c.text.trim()).toList(),
          correctAnswerIndex: _correctAnswerIndex,
          topicId: _selectedTopicId,
          explanation: _explanationController.text.trim().isEmpty
              ? null
              : _explanationController.text.trim(),
          difficulty: _selectedDifficulty,
          createdAt: widget.question?.createdAt ?? DateTime.now(),
        );

        if (widget.question == null) {
          await _dbHelper.insertQuestion(question);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã thêm câu hỏi thành công')),
            );
          }
        } else {
          await _dbHelper.updateQuestion(question);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã cập nhật câu hỏi thành công')),
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
        title: Text(widget.question == null ? 'Thêm câu hỏi' : 'Chỉnh sửa câu hỏi'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _questionTextController,
              decoration: const InputDecoration(
                labelText: 'Câu hỏi *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) => Validation.validateNotEmpty(value, 'Câu hỏi'),
            ),
            const SizedBox(height: 16),
            ..._optionControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Column(
                children: [
                  Row(
                    children: [
                      Radio<int>(
                        value: index,
                        groupValue: _correctAnswerIndex,
                        onChanged: (value) {
                          setState(() {
                            _correctAnswerIndex = value!;
                          });
                        },
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: 'Lựa chọn ${index + 1} *',
                            border: const OutlineInputBorder(),
                            suffixIcon: _correctAnswerIndex == index
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : null,
                          ),
                          validator: (value) => Validation.validateNotEmpty(value, 'Lựa chọn ${index + 1}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedTopicId,
              decoration: const InputDecoration(
                labelText: 'Chủ đề *',
                border: OutlineInputBorder(),
              ),
              items: _topics.map((topic) {
                return DropdownMenuItem(
                  value: topic.id,
                  child: Text(topic.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTopicId = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedDifficulty,
              decoration: const InputDecoration(
                labelText: 'Độ khó *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Dễ')),
                DropdownMenuItem(value: 2, child: Text('Trung bình')),
                DropdownMenuItem(value: 3, child: Text('Khó')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedDifficulty = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _explanationController,
              decoration: const InputDecoration(
                labelText: 'Giải thích (tùy chọn)',
                border: OutlineInputBorder(),
                hintText: 'Giải thích cho đáp án đúng...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveQuestion,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(widget.question == null ? 'Thêm' : 'Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }
}

