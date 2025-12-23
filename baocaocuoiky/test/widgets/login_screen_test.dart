import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baocaocuoiky/screens/login_screen.dart';
import 'package:baocaocuoiky/providers/auth_provider.dart';
import 'package:provider/provider.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('Should display all login form fields', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Act & Assert
      expect(find.text('Điểm danh QR'), findsOneWidget);
      expect(find.text('Đăng nhập để tiếp tục'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email + Password
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
    });

    testWidgets('Should validate empty email field', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Đăng nhập'));
      await tester.pump();

      // Assert
      expect(find.text('Vui lòng nhập email'), findsOneWidget);
    });

    testWidgets('Should validate invalid email format', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.tap(find.text('Đăng nhập'));
      await tester.pump();

      // Assert
      expect(find.text('Email không hợp lệ'), findsOneWidget);
    });

    testWidgets('Should toggle password visibility', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Find password field and visibility toggle
      final visibilityIcon = find.byIcon(Icons.visibility_off);
      
      // Assert - visibility toggle exists
      expect(visibilityIcon, findsOneWidget);

      // Act - tap visibility toggle
      await tester.tap(visibilityIcon);
      await tester.pump();

      // Assert - icon should change to visibility (visible mode)
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('Should navigate to register screen', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Đăng ký'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Tạo tài khoản mới'), findsOneWidget);
    });
  });
}

