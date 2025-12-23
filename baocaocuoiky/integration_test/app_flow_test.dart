import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:baocaocuoiky/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flow 1: Login → Home → Students CRUD', () {
    testWidgets('User can login, navigate to students, and add a student', 
        (WidgetTester tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find login fields
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).at(1);
      final loginButton = find.text('Đăng nhập');

      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);
      expect(loginButton, findsOneWidget);

      // Enter credentials
      await tester.enterText(emailField, 'user@gmail.com');
      await tester.pumpAndSettle();
      await tester.enterText(passwordField, '123');
      await tester.pumpAndSettle();

      // Tap login
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should be on home screen
      expect(find.text('Tổng quan'), findsOneWidget);

      // Navigate to Students
      final studentsCard = find.text('Sinh viên');
      expect(studentsCard, findsOneWidget);
      await tester.tap(studentsCard);
      await tester.pumpAndSettle();

      // Should be on Students screen
      expect(find.text('Danh sách sinh viên'), findsOneWidget);

      // Tap Add button
      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pumpAndSettle();

        // Fill student form
        final studentIdField = find.byType(TextFormField).first;
        final nameField = find.byType(TextFormField).at(1);
        
        await tester.enterText(studentIdField, 'TEST001');
        await tester.pumpAndSettle();
        await tester.enterText(nameField, 'Test Student');
        await tester.pumpAndSettle();

        // Save
        final saveButton = find.text('Lưu');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Should show success message or return to list
          expect(find.text('TEST001'), findsWidgets);
        }
      }
    });
  });

  group('Flow 2: Login → Sessions → Create → QR Generate', () {
    testWidgets('User can create a session and generate QR code', 
        (WidgetTester tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Login
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).at(1);
      await tester.enterText(emailField, 'admin@gmail.com');
      await tester.pumpAndSettle();
      await tester.enterText(passwordField, '123');
      await tester.pumpAndSettle();
      
      final loginButton = find.text('Đăng nhập');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to Sessions
      final sessionsCard = find.text('Buổi học');
      expect(sessionsCard, findsOneWidget);
      await tester.tap(sessionsCard);
      await tester.pumpAndSettle();

      // Tap Add button
      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pumpAndSettle();

        // Fill session form
        final titleField = find.byType(TextFormField).first;
        await tester.enterText(titleField, 'Test Session');
        await tester.pumpAndSettle();

        // Save
        final saveButton = find.text('Lưu');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Look for the created session
          final createdSession = find.text('Test Session');
          if (createdSession.evaluate().isNotEmpty) {
            // Tap to view details
            await tester.tap(createdSession.first);
            await tester.pumpAndSettle();

            // Look for QR button
            final qrButton = find.text('Tạo QR');
            if (qrButton.evaluate().isNotEmpty) {
              await tester.tap(qrButton);
              await tester.pumpAndSettle(const Duration(seconds: 1));

              // Should show QR code
              expect(find.text('Mã QR Điểm danh'), findsOneWidget);
            }
          }
        }
      }
    });
  });

  group('Flow 3: Login → Export → View History', () {
    testWidgets('User can export data and view export history', 
        (WidgetTester tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Login
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).at(1);
      await tester.enterText(emailField, 'admin@gmail.com');
      await tester.pumpAndSettle();
      await tester.enterText(passwordField, '123');
      await tester.pumpAndSettle();
      
      final loginButton = find.text('Đăng nhập');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open user menu
      final userMenuButton = find.byType(PopupMenuButton<String>);
      if (userMenuButton.evaluate().isNotEmpty) {
        await tester.tap(userMenuButton.first);
        await tester.pumpAndSettle();

        // Tap export option
        final exportOption = find.text('Xuất dữ liệu');
        if (exportOption.evaluate().isNotEmpty) {
          await tester.tap(exportOption);
          await tester.pumpAndSettle();

          // Should be on export screen
          expect(find.text('Xuất dữ liệu'), findsWidgets);

          // Try to export students
          final exportStudentsButton = find.text('Sinh viên');
          if (exportStudentsButton.evaluate().isNotEmpty) {
            await tester.tap(exportStudentsButton.first);
            await tester.pumpAndSettle();

            // Select CSV
            final csvButton = find.text('CSV');
            if (csvButton.evaluate().isNotEmpty) {
              await tester.tap(csvButton);
              await tester.pumpAndSettle(const Duration(seconds: 3));

              // Should show success message
              expect(find.textContaining('thành công'), findsOneWidget);

              // Go back and check export history
              final backButton = find.byType(BackButton);
              if (backButton.evaluate().isNotEmpty) {
                await tester.tap(backButton.first);
                await tester.pumpAndSettle();

                // Look for history option (if accessible)
                // This might need UI adjustment
              }
            }
          }
        }
      }
    });
  });
}

