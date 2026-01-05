import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cuoiky_dat/screens/home_screen.dart';
import 'package:cuoiky_dat/screens/students_screen.dart';
import 'package:cuoiky_dat/screens/schedule_screen.dart';
import 'package:cuoiky_dat/screens/statistics_screen.dart';
import 'package:cuoiky_dat/services/theme_service.dart';

void main() {
  group('Widget Tests', () {
    testWidgets('HomeScreen displays correctly', (WidgetTester tester) async {
      final themeService = ThemeService();
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(themeService: themeService),
        ),
      );

      expect(find.text('Sổ tay sinh viên & Lịch học'), findsOneWidget);
      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Sinh viên'), findsOneWidget);
      expect(find.text('Lịch học'), findsOneWidget);
      expect(find.text('Thống kê'), findsOneWidget);
    });

    testWidgets('HomeScreen navigation works', (WidgetTester tester) async {
      final themeService = ThemeService();
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(themeService: themeService),
        ),
      );

      // Tap on Students tab
      await tester.tap(find.text('Sinh viên'));
      await tester.pumpAndSettle();

      // Should show students screen
      expect(find.text('Danh sách sinh viên'), findsOneWidget);

      // Tap on Schedule tab
      await tester.tap(find.text('Lịch học'));
      await tester.pumpAndSettle();

      // Should show schedule screen
      expect(find.text('Lịch học'), findsOneWidget);
    });

    testWidgets('StudentsScreen displays loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StudentsScreen(),
        ),
      );

      // Initially should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('StudentsScreen shows empty state when no students', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StudentsScreen(),
        ),
      );

      // Wait for loading to finish
      await tester.pumpAndSettle();

      // Should show empty state message
      expect(find.text('Chưa có sinh viên nào'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('ScheduleScreen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScheduleScreen(),
        ),
      );

      expect(find.text('Lịch học'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Search field
    });

    testWidgets('StatisticsScreen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StatisticsScreen(),
        ),
      );

      expect(find.text('Thống kê'), findsOneWidget);
    });

    testWidgets('Theme toggle button exists in HomePage', (WidgetTester tester) async {
      final themeService = ThemeService();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomePage(themeService: themeService),
          ),
        ),
      );

      // Should have theme toggle button
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    });

    testWidgets('FloatingActionButton exists in StudentsScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StudentsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should have FAB for adding student
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('Search field exists in StudentsScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StudentsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should have search TextField
      expect(find.byType(TextField), findsWidgets);
      expect(find.text('Tìm kiếm theo tên, mã SV, email, ngành...'), findsOneWidget);
    });
  });
}
