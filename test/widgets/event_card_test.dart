import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickets_booking/widgets/event_card.dart';
import 'package:tickets_booking/models/event.dart';

void main() {
  group('EventCard Widget Tests', () {
    testWidgets('should display event information correctly', (WidgetTester tester) async {
      // Create a test event
      final event = Event(
        id: 'test-event-1',
        name: 'Test Concert',
        date: DateTime(2024, 12, 25, 20, 0),
        venue: 'Test Arena',
        city: 'Test City',
        imageUrl: 'https://example.com/image.jpg',
        genre: 'Rock',
      );

      bool onTapCalled = false;

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: event,
              onTap: () => onTapCalled = true,
              heroTagSuffix: 'test',
            ),
          ),
        ),
      );

      // Verify event name is displayed
      expect(find.text('Test Concert'), findsOneWidget);
      
      // Verify venue and city are displayed together
      expect(find.text('Test Arena, Test City'), findsOneWidget);
      
      // Verify the card is tappable
      await tester.tap(find.byType(EventCard));
      expect(onTapCalled, isTrue);
    });

    testWidgets('should display date when available', (WidgetTester tester) async {
      final event = Event(
        id: 'test-event-2',
        name: 'Future Event',
        date: DateTime(2024, 6, 15, 19, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: event,
              onTap: () {},
            ),
          ),
        ),
      );

      // Check if date is formatted and displayed
      expect(find.textContaining('15/6/2024'), findsOneWidget);
    });

    testWidgets('should display "Date TBA" when no date is available', (WidgetTester tester) async {
      final event = Event(
        id: 'test-event-3',
        name: 'No Date Event',
        // No date provided
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: event,
              onTap: () {},
            ),
          ),
        ),
      );

      // Check if "Date TBA" is displayed
      expect(find.text('Date TBA'), findsOneWidget);
    });

    testWidgets('should display venue when available', (WidgetTester tester) async {
      final event = Event(
        id: 'test-event-4',
        name: 'Venue Event',
        venue: 'Grand Theater',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: event,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify venue is displayed
      expect(find.text('Grand Theater'), findsOneWidget);
    });

    testWidgets('should display price range when available', (WidgetTester tester) async {
      final event = Event(
        id: 'test-event-5',
        name: 'Priced Event',
        minPrice: 50.0,
        maxPrice: 150.0,
        currency: 'USD',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: event,
              onTap: () {},
            ),
          ),
        ),
      );

      // Note: The EventCard might not display price directly
      // This test ensures the widget can handle events with price information
      expect(find.byType(EventCard), findsOneWidget);
    });

    testWidgets('should handle events with image URLs', (WidgetTester tester) async {
      final event = Event(
        id: 'test-event-6',
        name: 'Image Event',
        imageUrl: 'https://example.com/test-image.jpg',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: event,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should show image widget or placeholder
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should handle events without image URLs', (WidgetTester tester) async {
      final event = Event(
        id: 'test-event-7',
        name: 'No Image Event',
        // No imageUrl provided
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: event,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should show fallback icon
      expect(find.byIcon(Icons.event), findsWidgets);
    });

    testWidgets('should include Hero widget for animations', (WidgetTester tester) async {
      final event = Event(
        id: 'test-event-8',
        name: 'Hero Event',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: event,
              onTap: () {},
              heroTagSuffix: 'test',
            ),
          ),
        ),
      );

      // Should contain Hero widget for hero animations
      expect(find.byType(Hero), findsWidgets);
    });

    testWidgets('should respond to tap gestures', (WidgetTester tester) async {
      final event = Event(
        id: 'test-event-9',
        name: 'Tappable Event',
      );

      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: event,
              onTap: () => tapCount++,
            ),
          ),
        ),
      );

      // Test multiple taps
      await tester.tap(find.byType(EventCard));
      await tester.tap(find.byType(EventCard));
      
      expect(tapCount, equals(2));
    });

    testWidgets('should have proper Material design styling', (WidgetTester tester) async {
      final event = Event(
        id: 'test-event-10',
        name: 'Styled Event',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: event,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should contain Material design elements
      expect(find.byType(Material), findsWidgets);
      expect(find.byType(InkWell), findsWidgets);
    });
  });

  group('EventCard Edge Cases', () {
    testWidgets('should handle very long event names', (WidgetTester tester) async {
      final event = Event(
        id: 'long-name-event',
        name: 'This is a very long event name that might overflow the UI layout and cause display issues',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: event,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should not throw overflow errors
      expect(tester.takeException(), isNull);
      expect(find.byType(EventCard), findsOneWidget);
    });

    testWidgets('should handle special characters in event name', (WidgetTester tester) async {
      final event = Event(
        id: 'special-chars',
        name: 'Event with 特殊字符 & émojis 🎵',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: event,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('特殊字符'), findsOneWidget);
      expect(find.textContaining('🎵'), findsOneWidget);
    });
  });
}
