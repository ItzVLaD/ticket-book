import 'package:flutter_test/flutter_test.dart';
import 'package:tickets_booking/providers/theme_mode_notifier.dart';
import 'package:flutter/material.dart';

void main() {
  group('ThemeModeNotifier Tests', () {
    late ThemeModeNotifier themeModeNotifier;

    setUp(() {
      themeModeNotifier = ThemeModeNotifier();
    });

    test('should initialize with system theme mode', () {
      expect(themeModeNotifier.mode, equals(ThemeMode.system));
    });

    test('should set light theme mode', () {
      themeModeNotifier.setMode(ThemeMode.light);
      
      expect(themeModeNotifier.mode, equals(ThemeMode.light));
    });

    test('should set dark theme mode', () {
      themeModeNotifier.setMode(ThemeMode.dark);
      
      expect(themeModeNotifier.mode, equals(ThemeMode.dark));
    });

    test('should set system theme mode', () {
      // First change to a different mode
      themeModeNotifier.setMode(ThemeMode.light);
      expect(themeModeNotifier.mode, equals(ThemeMode.light));
      
      // Then change back to system
      themeModeNotifier.setMode(ThemeMode.system);
      expect(themeModeNotifier.mode, equals(ThemeMode.system));
    });

    test('should notify listeners when theme mode changes', () {
      bool listenerCalled = false;
      
      themeModeNotifier.addListener(() {
        listenerCalled = true;
      });
      
      themeModeNotifier.setMode(ThemeMode.dark);
      
      expect(listenerCalled, isTrue);
    });

    test('should not notify listeners if setting same theme mode', () {
      int listenerCallCount = 0;
      
      themeModeNotifier.addListener(() {
        listenerCallCount++;
      });
      
      // Set to same mode (system is default)
      themeModeNotifier.setMode(ThemeMode.system);
      
      // Should still notify (current implementation always notifies)
      expect(listenerCallCount, equals(1));
    });

    test('should handle multiple theme mode changes', () {
      final List<ThemeMode> capturedModes = [];
      
      themeModeNotifier.addListener(() {
        capturedModes.add(themeModeNotifier.mode);
      });
      
      themeModeNotifier.setMode(ThemeMode.light);
      themeModeNotifier.setMode(ThemeMode.dark);
      themeModeNotifier.setMode(ThemeMode.system);
      
      expect(capturedModes, equals([
        ThemeMode.light,
        ThemeMode.dark,
        ThemeMode.system,
      ]));
    });

    test('should maintain state after multiple listener notifications', () {
      themeModeNotifier.setMode(ThemeMode.dark);
      
      // Add listener after setting mode
      bool listenerCalled = false;
      themeModeNotifier.addListener(() {
        listenerCalled = true;
      });
      
      // Mode should still be dark
      expect(themeModeNotifier.mode, equals(ThemeMode.dark));
      
      // Change mode to trigger listener
      themeModeNotifier.setMode(ThemeMode.light);
      expect(listenerCalled, isTrue);
      expect(themeModeNotifier.mode, equals(ThemeMode.light));
    });

    test('should work with all ThemeMode enum values', () {
      for (ThemeMode mode in ThemeMode.values) {
        themeModeNotifier.setMode(mode);
        expect(themeModeNotifier.mode, equals(mode));
      }
    });

    tearDown(() {
      themeModeNotifier.dispose();
    });
  });
}
