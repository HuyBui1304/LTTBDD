import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/attendance_session.dart';

enum ReportPeriod { day, week, month }

class TimeBasedReportScreen extends StatefulWidget {
  const TimeBasedReportScreen({super.key});

  @override
  State<TimeBasedReportScreen> createState() => _TimeBasedReportScreenState();
}

class _TimeBasedReportScreenState extends State<TimeBasedReportScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  ReportPeriod _selectedPeriod = ReportPeriod.week;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  Map<String, int> _currentStats = {};
  Map<String, int> _previousStats = {};
  List<AttendanceSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final dateRange = _getDateRange();
      final previousRange = _getPreviousDateRange();

      // Get sessions in range
      final allSessions = await _db.getAllSessions();
      _sessions = allSessions.where((s) {
        return s.sessionDate != null &&
            s.sessionDate!.isAfter(dateRange.$1) &&
            s.sessionDate!.isBefore(dateRange.$2);
      }).toList();

      final previousSessions = allSessions.where((s) {
        return s.sessionDate != null &&
            s.sessionDate!.isAfter(previousRange.$1) &&
            s.sessionDate!.isBefore(previousRange.$2);
      }).toList();

      // Calculate stats
      _currentStats = await _calculateStats(_sessions);
      _previousStats = await _calculateStats(previousSessions);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  (DateTime, DateTime) _getDateRange() {
    switch (_selectedPeriod) {
      case ReportPeriod.day:
        final start = DateTime(_selectedDate.year, _selectedDate.month,
            _selectedDate.day, 0, 0, 0);
        final end = start.add(const Duration(days: 1));
        return (start, end);

      case ReportPeriod.week:
        final start = _selectedDate.subtract(
            Duration(days: _selectedDate.weekday - 1));
        final weekStart = DateTime(start.year, start.month, start.day, 0, 0, 0);
        final weekEnd = weekStart.add(const Duration(days: 7));
        return (weekStart, weekEnd);

      case ReportPeriod.month:
        final start = DateTime(_selectedDate.year, _selectedDate.month, 1);
        final end = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
        return (start, end);
    }
  }

  (DateTime, DateTime) _getPreviousDateRange() {
    switch (_selectedPeriod) {
      case ReportPeriod.day:
        final prevDate = _selectedDate.subtract(const Duration(days: 1));
        final start =
            DateTime(prevDate.year, prevDate.month, prevDate.day, 0, 0, 0);
        final end = start.add(const Duration(days: 1));
        return (start, end);

      case ReportPeriod.week:
        final prevDate = _selectedDate.subtract(const Duration(days: 7));
        final start =
            prevDate.subtract(Duration(days: prevDate.weekday - 1));
        final weekStart = DateTime(start.year, start.month, start.day, 0, 0, 0);
        final weekEnd = weekStart.add(const Duration(days: 7));
        return (weekStart, weekEnd);

      case ReportPeriod.month:
        final prevMonth = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
        final start = DateTime(prevMonth.year, prevMonth.month, 1);
        final end = DateTime(prevMonth.year, prevMonth.month + 1, 1);
        return (start, end);
    }
  }

  Future<Map<String, int>> _calculateStats(List<AttendanceSession> sessions) async {
    int totalPresent = 0, totalAbsent = 0, totalLate = 0, totalExcused = 0;

    for (final session in sessions) {
      if (session.id != null) {
        final stats = await _db.getSessionStats(session.id!);
        totalPresent += stats['present'] ?? 0;
        totalAbsent += stats['absent'] ?? 0;
        totalLate += stats['late'] ?? 0;
        totalExcused += stats['excused'] ?? 0;
      }
    }

    return {
      'sessions': sessions.length,
      'present': totalPresent,
      'absent': totalAbsent,
      'late': totalLate,
      'excused': totalExcused,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo theo thời gian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _showExportOptions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period Selector
                    _buildPeriodSelector(),
                    const SizedBox(height: 16),

                    // Date Picker
                    _buildDatePicker(),
                    const SizedBox(height: 24),

                    // Summary Cards
                    _buildSummaryCards(),
                    const SizedBox(height: 24),

                    // Comparison with previous period
                    _buildComparison(),
                    const SizedBox(height: 24),

                    // Chart
                    _buildChart(),
                    const SizedBox(height: 24),

                    // Sessions List
                    _buildSessionsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: SegmentedButton<ReportPeriod>(
                segments: const [
                  ButtonSegment(
                    value: ReportPeriod.day,
                    label: Text('Ngày'),
                    icon: Icon(Icons.today),
                  ),
                  ButtonSegment(
                    value: ReportPeriod.week,
                    label: Text('Tuần'),
                    icon: Icon(Icons.view_week),
                  ),
                  ButtonSegment(
                    value: ReportPeriod.month,
                    label: Text('Tháng'),
                    icon: Icon(Icons.calendar_month),
                  ),
                ],
                selected: {_selectedPeriod},
                onSelectionChanged: (Set<ReportPeriod> newSelection) {
                  setState(() {
                    _selectedPeriod = newSelection.first;
                    _loadReport();
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    String dateText;
    switch (_selectedPeriod) {
      case ReportPeriod.day:
        dateText = DateFormat('dd/MM/yyyy').format(_selectedDate);
        break;
      case ReportPeriod.week:
        final range = _getDateRange();
        dateText =
            '${DateFormat('dd/MM').format(range.$1)} - ${DateFormat('dd/MM/yyyy').format(range.$2.subtract(const Duration(days: 1)))}';
        break;
      case ReportPeriod.month:
        dateText = DateFormat('MMMM yyyy', 'vi_VN').format(_selectedDate);
        break;
    }

    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: Text(dateText),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  switch (_selectedPeriod) {
                    case ReportPeriod.day:
                      _selectedDate =
                          _selectedDate.subtract(const Duration(days: 1));
                      break;
                    case ReportPeriod.week:
                      _selectedDate =
                          _selectedDate.subtract(const Duration(days: 7));
                      break;
                    case ReportPeriod.month:
                      _selectedDate = DateTime(
                          _selectedDate.year, _selectedDate.month - 1, 1);
                      break;
                  }
                  _loadReport();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  switch (_selectedPeriod) {
                    case ReportPeriod.day:
                      _selectedDate =
                          _selectedDate.add(const Duration(days: 1));
                      break;
                    case ReportPeriod.week:
                      _selectedDate =
                          _selectedDate.add(const Duration(days: 7));
                      break;
                    case ReportPeriod.month:
                      _selectedDate = DateTime(
                          _selectedDate.year, _selectedDate.month + 1, 1);
                      break;
                  }
                  _loadReport();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tổng quan',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Buổi học',
                value: '${_currentStats['sessions'] ?? 0}',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Có mặt',
                value: '${_currentStats['present'] ?? 0}',
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Vắng',
                value: '${_currentStats['absent'] ?? 0}',
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Muộn',
                value: '${_currentStats['late'] ?? 0}',
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComparison() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'So sánh với kỳ trước',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildComparisonRow(
              'Buổi học',
              _currentStats['sessions'] ?? 0,
              _previousStats['sessions'] ?? 0,
            ),
            const Divider(),
            _buildComparisonRow(
              'Có mặt',
              _currentStats['present'] ?? 0,
              _previousStats['present'] ?? 0,
            ),
            const Divider(),
            _buildComparisonRow(
              'Vắng',
              _currentStats['absent'] ?? 0,
              _previousStats['absent'] ?? 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String label, int current, int previous) {
    final diff = current - previous;
    final percent =
        previous == 0 ? 0.0 : ((diff / previous) * 100);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Text('$current'),
              const SizedBox(width: 8),
              if (diff != 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: diff > 0
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        diff > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: diff > 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${percent.abs().toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: diff > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Biểu đồ điểm danh',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.green,
                      value: (_currentStats['present'] ?? 0).toDouble(),
                      title: '${_currentStats['present']}',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.red,
                      value: (_currentStats['absent'] ?? 0).toDouble(),
                      title: '${_currentStats['absent']}',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.orange,
                      value: (_currentStats['late'] ?? 0).toDouble(),
                      title: '${_currentStats['late']}',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsList() {
    if (_sessions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'Không có buổi học nào trong khoảng thời gian này',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh sách buổi học',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ..._sessions.map((session) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(session.title),
              subtitle: Text(session.sessionDate != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(session.sessionDate!)
                  : 'Chưa có ngày'),
              trailing: Text(
                session.status.displayName,
                style: TextStyle(
                  color: _getStatusColor(session.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.completed:
        return Colors.grey;
      case SessionStatus.scheduled:
        return Colors.blue;
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Xuất CSV'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Export to CSV
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đang xuất CSV...')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Xuất PDF'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Export to PDF
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đang xuất PDF...')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Chia sẻ'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Share report
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đang chia sẻ...')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

