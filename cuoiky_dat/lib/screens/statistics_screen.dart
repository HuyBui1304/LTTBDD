import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
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

  int _totalStudents = 0;
  int _totalSchedules = 0;
  Map<String, int> _studentsByMajor = {};
  Map<String, int> _studentsByYear = {};
  Map<String, int> _schedulesByDay = {};

  String _selectedPeriod = 'all'; // 'all', 'today', 'week', 'month'
  int _periodStudents = 0;
  int _periodSchedules = 0;
  int _previousPeriodStudents = 0;
  int _previousPeriodSchedules = 0;

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
      final totalStudents = await _dbHelper.getTotalStudents();
      final totalSchedules = await _dbHelper.getTotalClassSchedules();
      final studentsByMajor = await _dbHelper.getStudentsByMajor();
      final studentsByYear = await _dbHelper.getStudentsByYear();
      final schedulesByDay = await _dbHelper.getSchedulesByDay();

      // Load period statistics
      await _loadPeriodStatistics();

      setState(() {
        _totalStudents = totalStudents;
        _totalSchedules = totalSchedules;
        _studentsByMajor = studentsByMajor;
        _studentsByYear = studentsByYear;
        _schedulesByDay = schedulesByDay;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải thống kê: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPeriodStatistics() async {
    final now = DateTime.now();
    DateTime start, end, previousStart, previousEnd;

    switch (_selectedPeriod) {
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        end = now;
        previousStart = start.subtract(const Duration(days: 1));
        previousEnd = start;
        break;
      case 'week':
        final daysFromMonday = now.weekday - 1;
        start = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysFromMonday));
        end = now;
        previousStart = start.subtract(const Duration(days: 7));
        previousEnd = start;
        break;
      case 'month':
        start = DateTime(now.year, now.month, 1);
        end = now;
        final previousMonth = DateTime(now.year, now.month - 1, 1);
        previousStart = previousMonth;
        previousEnd = start;
        break;
      default: // 'all'
        return;
    }

    _periodStudents = await _dbHelper.getStudentsCreatedInPeriod(start, end);
    _periodSchedules = await _dbHelper.getSchedulesCreatedInPeriod(start, end);
    _previousPeriodStudents = await _dbHelper.getStudentsCreatedInPeriod(previousStart, previousEnd);
    _previousPeriodSchedules = await _dbHelper.getSchedulesCreatedInPeriod(previousStart, previousEnd);
  }

  void _onPeriodChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedPeriod = value;
      });
      _loadPeriodStatistics();
    }
  }

  double _calculateChange(int current, int previous) {
    if (previous == 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download),
            tooltip: 'Xuất dữ liệu',
            onSelected: (value) async {
              try {
                final exportService = ExportService();
                if (value == 'csv') {
                  await exportService.exportStatistics(
                    _totalStudents,
                    _totalSchedules,
                    _studentsByMajor,
                    _studentsByYear,
                    _schedulesByDay,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xuất CSV thành công')),
                    );
                  }
                } else if (value == 'pdf') {
                  await exportService.exportStatisticsPDF(
                    _totalStudents,
                    _totalSchedules,
                    _studentsByMajor,
                    _studentsByYear,
                    _schedulesByDay,
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
                        // Period filter
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Text('Báo cáo theo: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedPeriod,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                                      DropdownMenuItem(value: 'today', child: Text('Hôm nay')),
                                      DropdownMenuItem(value: 'week', child: Text('Tuần này')),
                                      DropdownMenuItem(value: 'month', child: Text('Tháng này')),
                                    ],
                                    onChanged: _onPeriodChanged,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Summary cards
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 600;
                            return isWide
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: _buildSummaryCard(
                                          'Tổng sinh viên',
                                          _totalStudents.toString(),
                                          Icons.people,
                                          Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildSummaryCard(
                                          'Tổng lịch học',
                                          _totalSchedules.toString(),
                                          Icons.calendar_today,
                                          Colors.green,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _buildSummaryCard(
                                        'Tổng sinh viên',
                                        _totalStudents.toString(),
                                        Icons.people,
                                        Colors.blue,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildSummaryCard(
                                        'Tổng lịch học',
                                        _totalSchedules.toString(),
                                        Icons.calendar_today,
                                        Colors.green,
                                      ),
                                    ],
                                  );
                          },
                        ),
                        
                        // Period comparison cards
                        if (_selectedPeriod != 'all') ...[
                          const SizedBox(height: 24),
                          const Text(
                            'So sánh với kỳ trước',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 600;
                              return isWide
                                  ? Row(
                                      children: [
                                        Expanded(
                                          child: _buildPeriodComparisonCard(
                                            'Sinh viên',
                                            _periodStudents,
                                            _previousPeriodStudents,
                                            Icons.people,
                                            Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildPeriodComparisonCard(
                                            'Lịch học',
                                            _periodSchedules,
                                            _previousPeriodSchedules,
                                            Icons.calendar_today,
                                            Colors.green,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        _buildPeriodComparisonCard(
                                          'Sinh viên',
                                          _periodStudents,
                                          _previousPeriodStudents,
                                          Icons.people,
                                          Colors.blue,
                                        ),
                                        const SizedBox(height: 16),
                                        _buildPeriodComparisonCard(
                                          'Lịch học',
                                          _periodSchedules,
                                          _previousPeriodSchedules,
                                          Icons.calendar_today,
                                          Colors.green,
                                        ),
                                      ],
                                    );
                            },
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Students by Major chart
                        if (_studentsByMajor.isNotEmpty) ...[
                          const Text(
                            'Sinh viên theo ngành',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 300,
                            child: _buildPieChart(_studentsByMajor),
                          ),
                          const SizedBox(height: 24),
                          _buildTable('Ngành', 'Số lượng', _studentsByMajor),
                          const SizedBox(height: 24),
                        ],

                        // Students by Year chart
                        if (_studentsByYear.isNotEmpty) ...[
                          const Text(
                            'Sinh viên theo khóa',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 300,
                            child: _buildBarChart(_studentsByYear),
                          ),
                          const SizedBox(height: 24),
                          _buildTable('Khóa', 'Số lượng', _studentsByYear),
                          const SizedBox(height: 24),
                        ],

                        // Schedules by Day
                        if (_schedulesByDay.isNotEmpty) ...[
                          const Text(
                            'Lịch học theo thứ',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildTable('Thứ', 'Số lượng', _schedulesByDay),
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

  Widget _buildPeriodComparisonCard(
    String title,
    int current,
    int previous,
    IconData icon,
    Color color,
  ) {
    final change = _calculateChange(current, previous);
    final isPositive = change >= 0;

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      current.toString(),
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isPositive ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        Text(
                          '${change.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              'Kỳ trước: $previous',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
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
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: entry.key,
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
    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
    ];

    int colorIndex = 0;
    final barGroups = data.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
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
              getTitlesWidget: (value, meta) => Text('K${value.toInt()}'),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        maxY: maxValue.toDouble() * 1.2,
      ),
    );
  }

  Widget _buildTable(String header1, String header2, Map<String, int> data) {
    final days = {'0': 'Chủ Nhật', '1': 'Thứ 2', '2': 'Thứ 3', '3': 'Thứ 4', '4': 'Thứ 5', '5': 'Thứ 6', '6': 'Thứ 7'};

    return Card(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey[200]),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(header1, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(header2, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          ...data.entries.map((entry) {
            final label = days.containsKey(entry.key) ? days[entry.key] : entry.key;
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(label ?? entry.key),
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
}

