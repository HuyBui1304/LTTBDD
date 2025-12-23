import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baocaocuoiky/widgets/state_widgets.dart' as custom;

void main() {
  group('StateWidgets Tests', () {
    testWidgets('LoadingWidget should display CircularProgressIndicator',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: custom.LoadingWidget(message: 'Loading...'),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('EmptyWidget should display icon and message',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: custom.EmptyWidget(
              icon: Icons.inbox,
              title: 'No Data',
              message: 'Add some items',
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No Data'), findsOneWidget);
      expect(find.text('Add some items'), findsOneWidget);
    });

    testWidgets('EmptyWidget with action should display button',
        (WidgetTester tester) async {
      // Arrange
      bool buttonPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: custom.EmptyWidget(
              icon: Icons.add,
              title: 'Empty',
              message: 'Add item',
              action: ElevatedButton(
                onPressed: () {
                  buttonPressed = true;
                },
                child: const Text('Add'),
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Add'));
      await tester.pump();

      // Assert
      expect(buttonPressed, isTrue);
    });

    testWidgets('ErrorWidget should display error icon and message',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: custom.ErrorWidget(
              message: 'Something went wrong',
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Có lỗi xảy ra'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('ErrorWidget with retry should call onRetry',
        (WidgetTester tester) async {
      // Arrange
      bool retryCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: custom.ErrorWidget(
              message: 'Error',
              onRetry: () {
                retryCalled = true;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Thử lại'));
      await tester.pump();

      // Assert
      expect(retryCalled, isTrue);
    });
  });
}

