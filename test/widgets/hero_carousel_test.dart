import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickets_booking/models/event_group.dart';
import 'package:tickets_booking/models/event.dart';
import 'package:tickets_booking/widgets/hero_carousel.dart';

void main() {
  group('HeroCarousel Widget Tests', () {
    late List<EventGroup> testGroups;
    late PageController pageController;

    setUp(() {
      pageController = PageController();
      
      // Create test events for the groups
      final testEvent1 = Event(
        id: 'event1',
        name: 'Concert Event',
        date: DateTime(2024, 1, 1),
        venue: 'Music Hall',
        city: 'Test City',
      );
      
      final testEvent2 = Event(
        id: 'event2',  
        name: 'Theater Show',
        date: DateTime(2024, 2, 1),
        venue: 'Theater',
        city: 'Test City 2',
      );
      
      testGroups = [
        EventGroup(
          id: 'group1',
          name: 'Concert Event',
          schedules: [testEvent1],
          primaryImageUrl: null, // Avoid network issues
          firstDate: DateTime(2024, 1, 1),
          lastDate: DateTime(2024, 1, 2),
        ),
        EventGroup(
          id: 'group2',
          name: 'Theater Show',
          schedules: [testEvent2],
          primaryImageUrl: null,
          firstDate: DateTime(2024, 2, 1),
          lastDate: DateTime(2024, 2, 2),
        ),
      ];
    });

    tearDown(() {
      pageController.dispose();
    });

    testWidgets('should display carousel with PageView', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroCarousel(
              groups: testGroups,
              pageController: pageController,
              indicator: const Text('Test Indicator'),
            ),
          ),
        ),
      );

      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('Test Indicator'), findsOneWidget);
    });

    testWidgets('should handle empty groups list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroCarousel(
              groups: const [],
              pageController: pageController,
              indicator: const Text('Empty Indicator'),
            ),
          ),
        ),
      );

      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('Empty Indicator'), findsOneWidget);
    });

    testWidgets('should display event names', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroCarousel(
              groups: testGroups,
              pageController: pageController,
              indicator: const Text('Indicator'),
            ),
          ),
        ),
      );

      // Since text appears in multiple places, use findsAtLeastNWidgets
      expect(find.text('Concert Event'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Jan'), findsAtLeastNWidgets(1));
    });

    testWidgets('should show containers for layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroCarousel(
              groups: [testGroups[1]], // Single group
              pageController: pageController,
              indicator: const Text('Indicator'),
            ),
          ),
        ),
      );

      expect(find.text('Theater Show'), findsAtLeastNWidgets(1));
      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('should be interactive', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroCarousel(
              groups: testGroups,
              pageController: pageController,
              indicator: const Text('Indicator'),
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
      
      // Test that widget is interactive (without testing navigation)
      final inkWell = find.byType(InkWell);
      expect(inkWell, findsOneWidget);
    });

    testWidgets('should have semantic accessibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroCarousel(
              groups: testGroups,
              pageController: pageController,
              indicator: const Text('Indicator'),
            ),
          ),
        ),
      );

      // Check for semantics widget
      expect(find.byType(Semantics), findsAtLeastNWidgets(1));
    });

    testWidgets('should display indicator correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroCarousel(
              groups: testGroups,
              pageController: pageController,
              indicator: const Icon(Icons.circle),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.circle), findsOneWidget);
      
      // Check Stack alignment - handle multiple stacks
      final stackFinder = find.byType(Stack);
      expect(stackFinder, findsAtLeastNWidgets(1));
    });

    testWidgets('should handle visual effects', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroCarousel(
              groups: testGroups,
              pageController: pageController,
              indicator: const Text('Indicator'),
            ),
          ),
        ),
      );

      // Check for BackdropFilter
      expect(find.byType(BackdropFilter), findsOneWidget);
      
      // Check for gradient containers
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasGradient = containers.any((container) => 
        container.decoration is BoxDecoration &&
        (container.decoration as BoxDecoration).gradient != null
      );
      expect(hasGradient, isTrue);
    });

    testWidgets('should use provided PageController', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroCarousel(
              groups: testGroups,
              pageController: pageController,
              indicator: const Text('Indicator'),
            ),
          ),
        ),
      );

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller, equals(pageController));
      // PageView doesn't expose itemCount, but we can verify it has content
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('should handle single event group', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroCarousel(
              groups: [testGroups.first],
              pageController: pageController,
              indicator: const Text('Single Indicator'),
            ),
          ),
        ),
      );

      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('Concert Event'), findsAtLeastNWidgets(1));
      expect(find.text('Single Indicator'), findsOneWidget);
    });
  });
}
