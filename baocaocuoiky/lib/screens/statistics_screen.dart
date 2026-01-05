import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../providers/auth_provider.dart';
import '../widgets/state_widgets.dart' as custom;

class StatisticsScreen extends StatefulWidget {
  final bool hideAppBar;
  
  const StatisticsScreen({super.key, this.hideAppBar = false});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with AutomaticKeepAliveClientMixin {
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isLoading = true;
  Map<String, int> _overallStats = {};
  bool _hasLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when screen becomes visible (when tab is selected)
    // Only refresh if we've already loaded once and the route is active
    final route = ModalRoute.of(context);
    if (_hasLoaded && route?.isCurrent == true && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadStatistics();
      });
    }
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

      if (mounted) {
        setState(() {
          _overallStats = {
            'present': totalPresent,
            'absent': totalAbsent,
            'late': totalLate,
            'excused': totalExcused,
          };
          _isLoading = false;
          _hasLoaded = true;
        });
      }
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final authProvider = context.watch<AuthProvider>();
    
    // Chỉ Admin mới được xem thống kê
    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Thống kê'),
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
                'Chỉ Admin mới có quyền xem thống kê này',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }
    
    final body = _isLoading
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
                  ],
                ),
              ),
            );
    
    if (widget.hideAppBar) {
      return body;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: body,
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

