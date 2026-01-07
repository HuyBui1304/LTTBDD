import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import '../models/topic.dart';
import '../models/user_progress.dart';
import '../services/export_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isLoading = true;
  String _error = '';

  // LMS Statistics
  int _totalQuestions = 0;
  int _totalQuizzes = 0;
  int _totalQuizResults = 0;
  Map<String, int> _questionsByTopic = {};
  Map<String, int> _questionsByDifficulty = {};
  List<UserProgress> _userProgress = [];
  double _averageScore = 0.0;
  List<Topic> _topics = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final topics = await _dbHelper.getAllTopics();
      final questionsCount = await _dbHelper.getQuestionsCount();
      final questionsByTopic = await _dbHelper.getQuestionsCountByTopic();
      final questionsByDifficulty = await _dbHelper.getQuestionsByDifficulty();
      final userProgress = await _dbHelper.getAllUserProgress();
      final averageScore = await _dbHelper.getAverageQuizScore();
      final allQuizzes = await _dbHelper.getAllQuizzes();
      final allResults = await _dbHelper.getAllQuizResults();

      setState(() {
        _topics = topics;
        _totalQuestions = questionsCount;
        _totalQuizzes = allQuizzes.length;
        _totalQuizResults = allResults.length;
        _questionsByTopic = questionsByTopic;
        _questionsByDifficulty = questionsByDifficulty;
        _userProgress = userProgress;
        _averageScore = averageScore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải thống kê: $e';
        _isLoading = false;
      });
    }
  }

  List<UserProgress> get _weakTopics {
    return _userProgress.where((p) => p.averageScore < 70).toList()
      ..sort((a, b) => a.averageScore.compareTo(b.averageScore));
  }

  List<UserProgress> get _strongTopics {
    return _userProgress.where((p) => p.averageScore >= 80).toList()
      ..sort((a, b) => b.averageScore.compareTo(a.averageScore));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê học tập'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download),
            tooltip: 'Xuất dữ liệu',
            onSelected: (value) async {
              try {
                final exportService = ExportService();
                if (value == 'csv') {
                  await exportService.exportLMSStatistics(
                    _totalQuestions,
                    _totalQuizzes,
                    _totalQuizResults,
                    _questionsByTopic,
                    _questionsByDifficulty,
                    _userProgress,
                    _averageScore,
                    _topics,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xuất CSV thành công')),
                    );
                  }
                } else if (value == 'pdf') {
                  await exportService.exportLMSStatisticsPDF(
                    _totalQuestions,
                    _totalQuizzes,
                    _totalQuizResults,
                    _questionsByTopic,
                    _questionsByDifficulty,
                    _userProgress,
                    _averageScore,
                    _topics,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xuất PDF thành công')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi xuất: $e')),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'csv', child: Row(
                children: [
                  Icon(Icons.table_chart),
                  SizedBox(width: 8),
                  Text('Xuất CSV'),
                ],
              )),
              const PopupMenuItem(value: 'pdf', child: Row(
                children: [
                  Icon(Icons.picture_as_pdf),
                  SizedBox(width: 8),
                  Text('Xuất PDF'),
                ],
              )),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        onPressed: _loadStatistics,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStatistics,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary cards
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 600;
                            return isWide
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: _buildSummaryCard(
                                          'Tổng câu hỏi',
                                          _totalQuestions.toString(),
                                          Icons.help_outline,
                                          Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildSummaryCard(
                                          'Tổng đề thi',
                                          _totalQuizzes.toString(),
                                          Icons.quiz,
                                          Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildSummaryCard(
                                          'Bài đã làm',
                                          _totalQuizResults.toString(),
                                          Icons.assignment,
                                          Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildSummaryCard(
                                          'Điểm TB',
                                          _averageScore.toStringAsFixed(1),
                                          Icons.star,
                                          Colors.purple,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildSummaryCard(
                                              'Tổng câu hỏi',
                                              _totalQuestions.toString(),
                                              Icons.help_outline,
                                        Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildSummaryCard(
                                              'Tổng đề thi',
                                              _totalQuizzes.toString(),
                                              Icons.quiz,
                                              Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildSummaryCard(
                                              'Bài đã làm',
                                              _totalQuizResults.toString(),
                                              Icons.assignment,
                                              Colors.orange,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildSummaryCard(
                                              'Điểm TB',
                                              _averageScore.toStringAsFixed(1),
                                              Icons.star,
                                              Colors.purple,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Questions by Topic chart
                        if (_questionsByTopic.isNotEmpty) ...[
                          const Text(
                            'Câu hỏi theo chủ đề',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 300,
                            child: _buildPieChart(_questionsByTopic),
                          ),
                          const SizedBox(height: 24),
                          _buildQuestionsByTopicTable(),
                          const SizedBox(height: 24),
                        ],

                        // Questions by Difficulty
                        if (_questionsByDifficulty.isNotEmpty) ...[
                          const Text(
                            'Câu hỏi theo độ khó',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 300,
                            child: _buildBarChart(_questionsByDifficulty),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // User Progress by Topic
                        if (_userProgress.isNotEmpty) ...[
                          const Text(
                            'Tiến độ học tập theo chủ đề',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildUserProgressTable(),
                          const SizedBox(height: 24),
                        ],

                        // Weak Topics - Gợi ý ôn tập
                        if (_weakTopics.isNotEmpty) ...[
                          Card(
                            color: Colors.red.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.warning, color: Colors.red.shade700),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Cần cải thiện',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Các chủ đề bạn cần ôn tập thêm:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  ..._weakTopics.take(5).map((progress) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '• ${progress.topicName}',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                          Text(
                                            '${progress.averageScore.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  if (_weakTopics.length > 5)
                                    Text(
                                      '... và ${_weakTopics.length - 5} chủ đề khác',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Strong Topics
                        if (_strongTopics.isNotEmpty) ...[
                          Card(
                            color: Colors.green.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green.shade700),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Điểm mạnh',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Các chủ đề bạn làm tốt:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  ..._strongTopics.take(5).map((progress) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '• ${progress.topicName}',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                          Text(
                                            '${progress.averageScore.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Text(
                  value,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> data) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.amber,
    ];

    int colorIndex = 0;
    final pieChartSections = data.entries.map((entry) {
      final topicId = int.tryParse(entry.key);
      final topic = _topics.firstWhere(
        (t) => t.id == topicId,
        orElse: () => Topic(id: -1, name: 'Unknown', description: '', createdAt: DateTime.now()),
      );
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: topic.name.length > 10 ? '${topic.name.substring(0, 10)}...' : topic.name,
        color: color,
        radius: 80,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: pieChartSections,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> data) {
    final maxValue = data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b);
    final colors = {
      '1': Colors.green,
      '2': Colors.orange,
      '3': Colors.red,
    };
    final labels = {
      '1': 'Dễ',
      '2': 'TB',
      '3': 'Khó',
    };

    final barGroups = data.entries.map((entry) {
      final color = colors[entry.key] ?? Colors.grey;
      return BarChartGroupData(
        x: int.parse(entry.key),
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: color,
            width: 20,
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final key = value.toInt().toString();
                return Text(labels[key] ?? key);
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        maxY: maxValue.toDouble() * 1.2,
      ),
    );
  }

  Widget _buildQuestionsByTopicTable() {
    return Card(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: Colors.grey),
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('Chủ đề', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('Số câu hỏi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
          ..._questionsByTopic.entries.map((entry) {
            final topicId = int.tryParse(entry.key);
            final topic = _topics.firstWhere(
              (t) => t.id == topicId,
              orElse: () => Topic(id: -1, name: 'Unknown', description: '', createdAt: DateTime.now()),
            );
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(topic.name),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(entry.value.toString()),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUserProgressTable() {
    return Card(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: Colors.grey),
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('Chủ đề', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('Đúng', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('Sai', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('Điểm TB', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
          ..._userProgress.map((progress) {
            final color = progress.averageScore >= 80
                ? Colors.green
                : progress.averageScore >= 50
                    ? Colors.orange
                    : Colors.red;
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(progress.topicName),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    progress.correctAnswers.toString(),
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    progress.wrongAnswers.toString(),
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${progress.averageScore.toStringAsFixed(1)}%',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
