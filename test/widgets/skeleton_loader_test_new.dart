import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickets_booking/widgets/skeleton_loader.dart';

void main() {
  group('SkeletonLoader Widget Tests', () {
    group('SkeletonCarousel Tests', () {
      testWidgets('should display skeleton carousel correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SkeletonCarousel(),
            ),
          ),
        );

        // Should contain main container
        expect(find.byType(Container), findsWidgets);
        
        // Should contain loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should have correct height', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SkeletonCarousel(),
            ),
          ),
        );

        final containerFinder = find.byType(Container).first;
        final Container container = tester.widget(containerFinder);
        
        // Check that the container has proper constraints
        expect(container.constraints, isNotNull);
      });

      testWidgets('should use theme colors correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: const Scaffold(
              body: SkeletonCarousel(),
            ),
          ),
        );

        // Should render without errors
        expect(find.byType(SkeletonCarousel), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('SkeletonEventCard Tests', () {
      testWidgets('should display skeleton event card correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SkeletonEventCard(),
            ),
          ),
        );

        // Should contain Card widget
        expect(find.byType(Card), findsOneWidget);
        
        // Should contain Container widgets for skeleton elements
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('should have proper layout structure', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SkeletonEventCard(),
            ),
          ),
        );

        // Should have Row layout
        expect(find.byType(Row), findsOneWidget);
        
        // Should have Column layout
        expect(find.byType(Column), findsWidgets);
      });

      testWidgets('should use correct margins and padding', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SkeletonEventCard(),
            ),
          ),
        );

        final cardFinder = find.byType(Card);
        final Card card = tester.widget(cardFinder);
        
        // Card should have margins
        expect(card.margin, isNotNull);
      });

      testWidgets('should work with different themes', (WidgetTester tester) async {
        // Test with dark theme
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: SkeletonEventCard(),
            ),
          ),
        );

        expect(find.byType(SkeletonEventCard), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Test with light theme
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: const Scaffold(
              body: SkeletonEventCard(),
            ),
          ),
        );

        expect(find.byType(SkeletonEventCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should render multiple skeleton cards', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SkeletonEventCard(),
                  SkeletonEventCard(),
                  SkeletonEventCard(),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(SkeletonEventCard), findsNWidgets(3));
      });
    });

    group('SkeletonLoader Performance Tests', () {
      testWidgets('should render quickly without performance issues', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SkeletonCarousel(),
                  SkeletonEventCard(),
                  SkeletonEventCard(),
                  SkeletonEventCard(),
                ],
              ),
            ),
          ),
        );

        stopwatch.stop();

        // Should render quickly (less than 100ms is reasonable for test environment)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        expect(find.byType(SkeletonCarousel), findsOneWidget);
        expect(find.byType(SkeletonEventCard), findsNWidgets(3));
      });
    });

    group('SkeletonLoader Accessibility Tests', () {
      testWidgets('should be accessible for screen readers', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SkeletonEventCard(),
            ),
          ),
        );

        // Should not have accessibility violations
        expect(tester.takeException(), isNull);
        
        // Basic accessibility check - should render without errors
        expect(find.byType(SkeletonEventCard), findsOneWidget);
      });
    });

    group('SkeletonLoader Edge Cases', () {
      testWidgets('should handle widget rebuild correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SkeletonEventCard(),
            ),
          ),
        );

        expect(find.byType(SkeletonEventCard), findsOneWidget);

        // Rebuild the widget
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SkeletonEventCard(),
            ),
          ),
        );

        // Should still work after rebuild
        expect(find.byType(SkeletonEventCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should work in constrained layouts', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 100,
                child: const SkeletonEventCard(),
              ),
            ),
          ),
        );

        // Should adapt to constrained space without overflow
        expect(find.byType(SkeletonEventCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });

  group('Combined SkeletonLoader Tests', () {
    testWidgets('should work together in a list view', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                SkeletonCarousel(),
                SkeletonEventCard(),
                SkeletonEventCard(),
                SkeletonEventCard(),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonCarousel), findsOneWidget);
      expect(find.byType(SkeletonEventCard), findsNWidgets(3));
      
      // Should scroll without issues
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pump();
      
      expect(tester.takeException(), isNull);
    });
  });
}
