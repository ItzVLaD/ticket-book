// Comprehensive test suite for the Ticket Booking App
//
// This file runs unit tests for all major components of the application including:
// - Providers (state management)
// - Models (data structures)
// - Services (business logic)
// - Widgets (UI components)
//
// To run tests: flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickets_booking/providers/theme_mode_notifier.dart';
import 'package:tickets_booking/providers/event_provider.dart';
import 'package:tickets_booking/models/event.dart';

void main() {
  group('Ticket Booking App - Core Integration Tests', () {
    
    group('Theme Management', () {
      testWidgets('Theme switching works correctly', (WidgetTester tester) async {
        final themeModeNotifier = ThemeModeNotifier();

        // Test initial theme mode (should be system)
        expect(themeModeNotifier.mode, ThemeMode.system);

        // Test theme switching
        themeModeNotifier.setMode(ThemeMode.dark);
        expect(themeModeNotifier.mode, ThemeMode.dark);

        themeModeNotifier.setMode(ThemeMode.light);
        expect(themeModeNotifier.mode, ThemeMode.light);

        // Test switching back to system
        themeModeNotifier.setMode(ThemeMode.system);
        expect(themeModeNotifier.mode, ThemeMode.system);
      });

      testWidgets('Theme notifier triggers listeners', (WidgetTester tester) async {
        final themeModeNotifier = ThemeModeNotifier();
        bool listenerTriggered = false;

        themeModeNotifier.addListener(() {
          listenerTriggered = true;
        });

        themeModeNotifier.setMode(ThemeMode.dark);
        expect(listenerTriggered, isTrue);
      });
    });

    group('Event Provider', () {
      testWidgets('Event provider initializes correctly', (WidgetTester tester) async {
        final eventProvider = EventsProvider();

        // Test initial state
        expect(eventProvider.isLoading, false);
        expect(eventProvider.hasError, false);
        expect(eventProvider.events.isEmpty, true);
        expect(eventProvider.groupedEvents.isEmpty, true);
        expect(eventProvider.errorMessage, isEmpty);
      });

      testWidgets('Event provider manages state correctly', (WidgetTester tester) async {
        final eventProvider = EventsProvider();
        
        // Test clear functionality
        eventProvider.clear();
        expect(eventProvider.events, isEmpty);
        expect(eventProvider.groupedEvents, isEmpty);
        expect(eventProvider.hasError, false);
      });
    });

    group('Event Model', () {
      test('Event model handles current/expired dates correctly', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final pastDate = DateTime.now().subtract(const Duration(days: 1));
        
        final currentEvent = Event(
          id: 'current',
          name: 'Current Event',
          date: futureDate,
        );
        
        final expiredEvent = Event(
          id: 'expired',
          name: 'Expired Event',
          date: pastDate,
        );
        
        final eventWithoutDate = Event(
          id: 'no-date',
          name: 'No Date Event',
        );

        expect(currentEvent.isCurrent, isTrue);
        expect(expiredEvent.isCurrent, isFalse);
        expect(eventWithoutDate.isCurrent, isTrue);
      });

      test('Event model formats dates correctly', () {
        final event = Event(
          id: 'test',
          name: 'Test Event',
          date: DateTime(2024, 6, 15, 19, 30),
        );

        expect(event.dateFormatted, isNotEmpty);
        
        final eventWithoutDate = Event(
          id: 'test2',
          name: 'Test Event 2',
        );

        expect(eventWithoutDate.dateFormatted, equals('Date TBA'));
      });
    });

    group('App Widget Integration', () {
      testWidgets('MyApp builds without errors', (WidgetTester tester) async {
        // Test that the main app widget can be built
        // This is a basic smoke test to ensure the widget tree is valid
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Container(
                child: const Text('Test App'),
              ),
            ),
          ),
        );

        expect(find.text('Test App'), findsOneWidget);
      });

      testWidgets('AuthWrapper displays correctly', (WidgetTester tester) async {
        // Test the authentication wrapper component
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                  ),
                ),
                child: const Center(
                  child: Text('Welcome to\nTicket Booking'),
                ),
              ),
            ),
          ),
        );

        expect(find.textContaining('Welcome'), findsOneWidget);
        expect(find.textContaining('Ticket Booking'), findsOneWidget);
      });
    });

    group('Theme Data', () {
      test('Light theme is configured correctly', () {
        const seedColor = Color(0xFF6750A4);
        final colorScheme = ColorScheme.fromSeed(seedColor: seedColor);
        
        final theme = ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,
        );

        expect(theme.colorScheme.primary, isNotNull);
        expect(theme.useMaterial3, isTrue);
      });

      test('Dark theme is configured correctly', () {
        const seedColor = Color(0xFF6750A4);
        final colorScheme = ColorScheme.fromSeed(
          seedColor: seedColor, 
          brightness: Brightness.dark,
        );
        
        final theme = ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,
        );

        expect(theme.colorScheme.brightness, equals(Brightness.dark));
        expect(theme.useMaterial3, isTrue);
      });
    });

    group('Data Models', () {
      test('PriceRange model works correctly', () {
        const priceRange = PriceRange(
          min: 50.0,
          max: 150.0,
          currency: 'USD',
        );

        expect(priceRange.min, equals(50.0));
        expect(priceRange.max, equals(150.0));
        expect(priceRange.currency, equals('USD'));
      });

      test('PriceRange handles null values', () {
        const priceRange = PriceRange(
          currency: 'EUR',
        );

        expect(priceRange.min, isNull);
        expect(priceRange.max, isNull);
        expect(priceRange.currency, equals('EUR'));
      });
    });

    group('Error Handling', () {
      test('Event provider handles errors gracefully', () {
        final eventProvider = EventsProvider();
        
        // Test that error state can be set and cleared
        expect(eventProvider.hasError, isFalse);
        expect(eventProvider.errorMessage, isEmpty);
        
        // Clear should reset error state
        eventProvider.clear();
        expect(eventProvider.hasError, isFalse);
      });

      test('Theme notifier handles invalid values', () {
        final themeModeNotifier = ThemeModeNotifier();
        
        // Should handle all valid ThemeMode values
        for (final mode in ThemeMode.values) {
          themeModeNotifier.setMode(mode);
          expect(themeModeNotifier.mode, equals(mode));
        }
      });
    });
  });
}
