import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'time_based_report_screen.dart';
import 'statistics_screen.dart';
import 'export_screen.dart';

/// Màn hình tổng hợp Báo cáo & Thống kê & Xuất dữ liệu (chỉ dành cho Admin)
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    // Chỉ Admin mới được xem
    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Báo cáo & Thống kê'),
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
                'Chỉ Admin mới có quyền xem báo cáo và thống kê',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Báo cáo & Thống kê'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Báo cáo', icon: Icon(Icons.bar_chart)),
              Tab(text: 'Thống kê', icon: Icon(Icons.pie_chart)),
              Tab(text: 'Xuất dữ liệu', icon: Icon(Icons.download)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TimeBasedReportScreen(hideAppBar: true),
            StatisticsScreen(hideAppBar: true),
            ExportScreen(hideAppBar: true),
          ],
        ),
      ),
    );
  }
}

