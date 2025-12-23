import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_1712/main.dart';

void main() {
  testWidgets('TabBar renders and switches tabs', (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(const MyApp());

    // Check title
    expect(find.text('Bùi Minh Huy_2286400009'), findsOneWidget);

    // Check 3 tabs exist
    expect(find.text('Cat'), findsOneWidget);
    expect(find.text('Dog'), findsOneWidget);
    expect(find.text('Rabbit'), findsOneWidget);

    // Default should show Cat asset image
    final catImage = find.byWidgetPredicate((w) {
      if (w is Image && w.image is AssetImage) {
        return (w.image as AssetImage).assetName == 'assets/cat.jpeg';
      }
      return false;
    });
    expect(catImage, findsOneWidget);

    // Tap Dog tab
    await tester.tap(find.text('Dog'));
    await tester.pumpAndSettle();

    final dogImage = find.byWidgetPredicate((w) {
      if (w is Image && w.image is AssetImage) {
        return (w.image as AssetImage).assetName == 'assets/dog.jpeg';
      }
      return false;
    });
    expect(dogImage, findsOneWidget);

    // Tap Rabbit tab
    await tester.tap(find.text('Rabbit'));
    await tester.pumpAndSettle();

    final rabbitImage = find.byWidgetPredicate((w) {
      if (w is Image && w.image is AssetImage) {
        return (w.image as AssetImage).assetName == 'assets/rabbit.jpeg';
      }
      return false;
    });
    expect(rabbitImage, findsOneWidget);
  });
}