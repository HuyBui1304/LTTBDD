import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baocaocuoiky/widgets/custom_text_field.dart';

void main() {
  group('CustomTextField Widget Tests', () {
    testWidgets('Should display label and hint text', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: TextEditingController(),
              label: 'Test Label',
              hint: 'Test Hint',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Label'), findsOneWidget);
      expect(find.text('Test Hint'), findsOneWidget);
    });

    testWidgets('Should display prefix icon', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: TextEditingController(),
              label: 'Email',
              prefixIcon: Icons.email,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('Should call validator on validation', (WidgetTester tester) async {
      // Arrange
      bool validatorCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: TextEditingController(),
              label: 'Test',
              validator: (value) {
                validatorCalled = true;
                return 'Error message';
              },
            ),
          ),
        ),
      );

      // Act
      final formFieldFinder = find.byType(TextFormField);
      final formField = tester.widget<TextFormField>(formFieldFinder);
      formField.validator!('test');

      // Assert
      expect(validatorCalled, isTrue);
    });

    testWidgets('Should update controller text on input', (WidgetTester tester) async {
      // Arrange
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: controller,
              label: 'Test',
            ),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextFormField), 'Test Input');

      // Assert
      expect(controller.text, equals('Test Input'));
    });

    testWidgets('Should support different keyboard types', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: TextEditingController(),
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ),
      );

      // Assert - Check that CustomTextField widget exists
      expect(find.byType(CustomTextField), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });
  });
}

