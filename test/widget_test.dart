// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickets_booking/providers/theme_mode_notifier.dart';
import 'package:tickets_booking/providers/event_provider.dart';

void main() {
  group('Ticket Booking App Tests', () {
    testWidgets('Theme switching works', (WidgetTester tester) async {
      final themeModeNotifier = ThemeModeNotifier();

      // Test initial theme mode (should be system)
      expect(themeModeNotifier.mode, ThemeMode.system);

      // Test theme switching
      themeModeNotifier.setMode(ThemeMode.dark);
      expect(themeModeNotifier.mode, ThemeMode.dark);

      themeModeNotifier.setMode(ThemeMode.light);
      expect(themeModeNotifier.mode, ThemeMode.light);
    });

    testWidgets('Event provider initializes correctly', (WidgetTester tester) async {
      final eventProvider = EventsProvider();

      // Test initial state
      expect(eventProvider.isLoading, false);
      expect(eventProvider.hasError, false);
      expect(eventProvider.events.isEmpty, true);
      expect(eventProvider.groupedEvents.isEmpty, true);
    });
  });
}
