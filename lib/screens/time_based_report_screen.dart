import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/attendance_session.dart';
import '../models/subject.dart';
import '../providers/auth_provider.dart';
import '../services/export_service.dart';

enum ReportPeriod { day, week, month }

class TimeBasedReportScreen extends StatefulWidget {
  final bool hideAppBar;
  
  const TimeBasedReportScreen({super.key, this.hideAppBar = false});

  @override
  State<TimeBasedReportScreen> createState() => _TimeBasedReportScreenState();
}

class _TimeBasedReportScreenState extends State<TimeBasedReportScreen> with AutomaticKeepAliveClientMixin {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ExportService _exportService = ExportService.instance;

  ReportPeriod _selectedPeriod = ReportPeriod.week;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  Map<String, int> _currentStats = {};
  Map<String, int> _previousStats = {};
  List<AttendanceSession> _sessions = [];
  
  // Subject filter
  List<Subject> _allSubjects = [];
  Subject? _selectedSubject; // null = "Toàn bộ"
  bool _hasLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    _loadReport();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when screen becomes visible (when tab is selected)
    final route = ModalRoute.of(context);
    if (_hasLoaded && route?.isCurrent == true && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadSubjects();
          _loadReport();
        }
      });
    }
  }

  Future<void> _loadSubjects() async {
    try {
      final subjects = await _db.getAllSubjects();
      if (mounted) {
        setState(() {
          _allSubjects = subjects;
          // Ensure _selectedSubject still exists in the new list
          if (_selectedSubject != null && _selectedSubject!.id != null) {
            try {
              final found = subjects.firstWhere((s) => s.id == _selectedSubject!.id);
              _selectedSubject = found; // Update to new reference
            } catch (e) {
              _selectedSubject = null; // Reset if not found
            }
          }
        });
      }
    } catch (e) {
      // Ignore error, can still use without subject filter
    }
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final dateRange = _getDateRange();
      final previousRange = _getPreviousDateRange();

      // Get sessions - filter by subject if selected
      List<AttendanceSession> allSessions;
      if (_selectedSubject != null && _selectedSubject!.id != null) {
        // Use database method to get sessions by subject
        allSessions = await _db.getSessionsBySubject(_selectedSubject!.id!);
      } else {
        // Get all sessions
        allSessions = await _db.getAllSessions();
      }
      
      // Filter by date range
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

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải báo cáo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final authProvider = context.watch<AuthProvider>();
    
    // Kiểm tra quyền nếu không phải trong tab
    if (!widget.hideAppBar && !authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Báo cáo theo thời gian'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Không có quyền truy cập',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chỉ Admin mới có quyền xem báo cáo này',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Body content
    final bodyContent = _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject Filter
                    _buildSubjectFilter(),
                    const SizedBox(height: 16),
                    
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
            );
    
    // Return with or without AppBar based on hideAppBar flag
    if (widget.hideAppBar) {
      return bodyContent;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Báo cáo theo thời gian'),
            if (_selectedSubject != null)
              Text(
                _selectedSubject!.subjectName,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadSubjects();
              _loadReport();
            },
            tooltip: 'Làm mới',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _showExportOptions,
            tooltip: 'Xuất & Chia sẻ',
          ),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildSubjectFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Môn học',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Subject?>(
              value: _selectedSubject != null && _selectedSubject!.id != null
                  ? _allSubjects.where((s) => s.id == _selectedSubject!.id).isNotEmpty
                      ? _allSubjects.firstWhere((s) => s.id == _selectedSubject!.id)
                      : null
                  : null,
              decoration: const InputDecoration(
                labelText: 'Chọn môn học',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              isExpanded: true,
              items: [
                const DropdownMenuItem<Subject?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.all_inclusive, size: 20),
                      SizedBox(width: 8),
                      Text('Toàn bộ môn học', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                ..._allSubjects.map((subject) {
                  return DropdownMenuItem<Subject?>(
                    value: subject,
                    child: Text(
                      '${subject.subjectCode} - ${subject.subjectName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ],
              onChanged: (subject) {
                setState(() {
                  _selectedSubject = subject;
                  _loadReport();
                });
              },
            ),
          ],
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
                title: 'Có phép',
                value: '${_currentStats['excused'] ?? 0}',
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Buổi học',
                value: '${_currentStats['sessions'] ?? 0}',
                color: Colors.black,
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
            const Divider(),
            _buildComparisonRow(
              'Muộn',
              _currentStats['late'] ?? 0,
              _previousStats['late'] ?? 0,
            ),
            const Divider(),
            _buildComparisonRow(
              'Có phép',
              _currentStats['excused'] ?? 0,
              _previousStats['excused'] ?? 0,
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
                    PieChartSectionData(
                      color: Colors.blue,
                      value: (_currentStats['excused'] ?? 0).toDouble(),
                      title: '${_currentStats['excused']}',
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Xuất báo cáo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: const Text('Xuất CSV'),
                subtitle: const Text('Lưu vào thiết bị'),
                onTap: () {
                  Navigator.pop(context);
                  _exportToCSV();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Xuất PDF'),
                subtitle: const Text('Lưu vào thiết bị'),
                onTap: () {
                  Navigator.pop(context);
                  _exportToPDF();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.blue),
                title: const Text('Chia sẻ CSV'),
                subtitle: const Text('Gửi qua email, WhatsApp, v.v.'),
                onTap: () {
                  Navigator.pop(context);
                  _shareReport('csv');
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.orange),
                title: const Text('Chia sẻ PDF'),
                subtitle: const Text('Gửi qua email, WhatsApp, v.v.'),
                onTap: () {
                  Navigator.pop(context);
                  _shareReport('pdf');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportToCSV() async {
    try {
      final dateRange = _getDateRange();
      final periodName = _selectedPeriod == ReportPeriod.day ? 'ngay' 
                       : _selectedPeriod == ReportPeriod.week ? 'tuan' 
                       : 'thang';
      
      await _exportService.shareTimeBasedReport(
        period: periodName,
        startDate: dateRange.$1,
        endDate: dateRange.$2,
        stats: _currentStats,
        format: 'csv',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xuất báo cáo CSV thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToPDF() async {
    try {
      final dateRange = _getDateRange();
      final periodName = _selectedPeriod == ReportPeriod.day ? 'ngay' 
                       : _selectedPeriod == ReportPeriod.week ? 'tuan' 
                       : 'thang';
      
      await _exportService.shareTimeBasedReport(
        period: periodName,
        startDate: dateRange.$1,
        endDate: dateRange.$2,
        stats: _currentStats,
        format: 'pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xuất báo cáo PDF thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareReport(String format) async {
    try {
      final dateRange = _getDateRange();
      final periodName = _selectedPeriod == ReportPeriod.day ? 'ngay' 
                       : _selectedPeriod == ReportPeriod.week ? 'tuan' 
                       : 'thang';
      
      await _exportService.shareTimeBasedReport(
        period: periodName,
        startDate: dateRange.$1,
        endDate: dateRange.$2,
        stats: _currentStats,
        format: format,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã chia sẻ báo cáo ${format.toUpperCase()} thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chia sẻ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

