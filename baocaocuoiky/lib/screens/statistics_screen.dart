import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import '../widgets/state_widgets.dart' as custom;

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isLoading = true;
  Map<String, int> _overallStats = {};
  List<Map<String, dynamic>> _sessionsWithStats = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await _db.getAllSessions();
      final sessionsWithStats = <Map<String, dynamic>>[];
      int totalPresent = 0, totalAbsent = 0, totalLate = 0, totalExcused = 0;

      for (final session in sessions) {
        final stats = await _db.getSessionStats(session.id!);
        sessionsWithStats.add({
          'session': session,
          'stats': stats,
        });

        totalPresent += stats['present'] ?? 0;
        totalAbsent += stats['absent'] ?? 0;
        totalLate += stats['late'] ?? 0;
        totalExcused += stats['excused'] ?? 0;
      }

      setState(() {
        _overallStats = {
          'present': totalPresent,
          'absent': totalAbsent,
          'late': totalLate,
          'excused': totalExcused,
        };
        _sessionsWithStats = sessionsWithStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              // TODO: Export functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const custom.LoadingWidget(message: 'Đang tải thống kê...')
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall Stats Cards
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
                            title: 'Có mặt',
                            value: '${_overallStats['present'] ?? 0}',
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Vắng',
                            value: '${_overallStats['absent'] ?? 0}',
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Muộn',
                            value: '${_overallStats['late'] ?? 0}',
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Có phép',
                            value: '${_overallStats['excused'] ?? 0}',
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Pie Chart
                    if (_overallStats.values.any((v) => v > 0)) ...[
                      Text(
                        'Biểu đồ tổng hợp',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            height: 300,
                            child: PieChart(
                              PieChartData(
                                sections: _buildPieChartSections(),
                                sectionsSpace: 2,
                                centerSpaceRadius: 60,
                                startDegreeOffset: -90,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Bar Chart - Sessions
                    if (_sessionsWithStats.isNotEmpty) ...[
                      Text(
                        'Thống kê theo buổi học',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            height: 300,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: _getMaxYValue().toDouble(),
                                barTouchData: BarTouchData(enabled: true),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() >= _sessionsWithStats.length) {
                                          return const Text('');
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            'S${value.toInt() + 1}',
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: _buildBarChartData(),
                                gridData: const FlGridData(show: true),
                              ),
                            ),
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

  List<PieChartSectionData> _buildPieChartSections() {
    final present = _overallStats['present'] ?? 0;
    final absent = _overallStats['absent'] ?? 0;
    final late = _overallStats['late'] ?? 0;
    final excused = _overallStats['excused'] ?? 0;
    final total = present + absent + late + excused;

    if (total == 0) return [];

    return [
      PieChartSectionData(
        color: Colors.green,
        value: present.toDouble(),
        title: '$present',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: absent.toDouble(),
        title: '$absent',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: late.toDouble(),
        title: '$late',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.blue,
        value: excused.toDouble(),
        title: '$excused',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  List<BarChartGroupData> _buildBarChartData() {
    return List.generate(_sessionsWithStats.length, (index) {
      final stats = _sessionsWithStats[index]['stats'] as Map<String, int>;
      final present = (stats['present'] ?? 0).toDouble();
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: present,
            color: Colors.green,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  int _getMaxYValue() {
    int max = 0;
    for (final item in _sessionsWithStats) {
      final stats = item['stats'] as Map<String, int>;
      final present = stats['present'] ?? 0;
      if (present > max) max = present;
    }
    return (max * 1.2).ceil(); // Add 20% padding
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
        padding: const EdgeInsets.all(16.0),
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

