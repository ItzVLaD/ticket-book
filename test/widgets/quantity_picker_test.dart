import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickets_booking/widgets/quantity_picker.dart';

void main() {
  group('QuantityPicker Widget Tests', () {
    testWidgets('should display quantity value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityPicker(
              quantity: 5,
              onDecrement: () {},
              onIncrement: () {},
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('should enable/disable buttons based on min/max limits', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityPicker(
              quantity: 1,
              minQuantity: 1,
              maxQuantity: 10,
              onDecrement: () {},
              onIncrement: () {},
            ),
          ),
        ),
      );

      final decrementButton = find.widgetWithIcon(IconButton, Icons.remove);
      final incrementButton = find.widgetWithIcon(IconButton, Icons.add);

      expect(tester.widget<IconButton>(decrementButton).onPressed, isNull); // Disabled at minimum
      expect(tester.widget<IconButton>(incrementButton).onPressed, isNotNull); // Enabled
    });

    testWidgets('should enable/disable buttons at maximum', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityPicker(
              quantity: 10,
              minQuantity: 1,
              maxQuantity: 10,
              onDecrement: () {},
              onIncrement: () {},
            ),
          ),
        ),
      );

      final decrementButton = find.widgetWithIcon(IconButton, Icons.remove);
      final incrementButton = find.widgetWithIcon(IconButton, Icons.add);

      expect(tester.widget<IconButton>(decrementButton).onPressed, isNotNull); // Enabled
      expect(tester.widget<IconButton>(incrementButton).onPressed, isNull); // Disabled at maximum
    });

    testWidgets('should call onIncrement when increment button is tapped', (WidgetTester tester) async {
      bool incrementCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityPicker(
              quantity: 5,
              minQuantity: 1,
              maxQuantity: 10,
              onDecrement: () {},
              onIncrement: () {
                incrementCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
      expect(incrementCalled, isTrue);
    });

    testWidgets('should call onDecrement when decrement button is tapped', (WidgetTester tester) async {
      bool decrementCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityPicker(
              quantity: 5,
              minQuantity: 1,
              maxQuantity: 10,
              onDecrement: () {
                decrementCalled = true;
              },
              onIncrement: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithIcon(IconButton, Icons.remove));
      expect(decrementCalled, isTrue);
    });

    testWidgets('should handle custom min and max values', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityPicker(
              quantity: 3,
              minQuantity: 2,
              maxQuantity: 5,
              onDecrement: () {},
              onIncrement: () {},
            ),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);

      final decrementButton = find.widgetWithIcon(IconButton, Icons.remove);
      final incrementButton = find.widgetWithIcon(IconButton, Icons.add);

      expect(tester.widget<IconButton>(decrementButton).onPressed, isNotNull); // Should be enabled (3 > 2)
      expect(tester.widget<IconButton>(incrementButton).onPressed, isNotNull); // Should be enabled (3 < 5)
    });

    testWidgets('should handle zero quantity', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityPicker(
              quantity: 0,
              minQuantity: 0,
              maxQuantity: 10,
              onDecrement: () {},
              onIncrement: () {},
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      final decrementButton = find.widgetWithIcon(IconButton, Icons.remove);
      expect(tester.widget<IconButton>(decrementButton).onPressed, isNull); // Disabled at minimum (0)
    });

    testWidgets('should work without callbacks', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuantityPicker(
              quantity: 5,
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.byType(IconButton), findsNWidgets(2));
    });

    testWidgets('should apply correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityPicker(
              quantity: 5,
              onDecrement: () {},
              onIncrement: () {},
            ),
          ),
        ),
      );

      final quantityText = tester.widget<Text>(find.text('5'));
      expect(quantityText.textAlign, TextAlign.center);
      expect(quantityText.style?.fontWeight, FontWeight.bold);
    });
  });
}
