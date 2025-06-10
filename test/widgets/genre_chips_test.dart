import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickets_booking/widgets/genre_chips.dart';

void main() {
  group('GenreChips Widget Tests', () {
    final testGenres = ['Music', 'Sports', 'Arts & Theatre', 'Film', 'Miscellaneous'];

    testWidgets('should display all genre chips', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenreChips(
              genres: testGenres,
              selected: 'Music',
              onSelected: (genre) {},
            ),
          ),
        ),
      );

      for (final genre in testGenres) {
        expect(find.text(genre), findsOneWidget);
      }
      expect(find.byType(ChoiceChip), findsNWidgets(testGenres.length));
    });

    testWidgets('should highlight selected genre', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenreChips(
              genres: testGenres,
              selected: 'Sports',
              onSelected: (genre) {},
            ),
          ),
        ),
      );

      final choiceChips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
      
      // Find the Sports chip and verify it's selected
      final sportsChip = choiceChips.firstWhere(
        (chip) => (chip.label as Text).data == 'Sports',
      );
      expect(sportsChip.selected, isTrue);

      // Verify other chips are not selected
      final musicChip = choiceChips.firstWhere(
        (chip) => (chip.label as Text).data == 'Music',
      );
      expect(musicChip.selected, isFalse);
    });

    testWidgets('should call onSelected when chip is tapped', (WidgetTester tester) async {
      String? selectedGenre;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenreChips(
              genres: testGenres,
              selected: 'Music',
              onSelected: (genre) {
                selectedGenre = genre;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sports'));
      expect(selectedGenre, equals('Sports'));
    });

    testWidgets('should handle no selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenreChips(
              genres: testGenres,
              selected: null,
              onSelected: (genre) {},
            ),
          ),
        ),
      );

      final choiceChips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
      
      // Verify no chips are selected
      for (final chip in choiceChips) {
        expect(chip.selected, isFalse);
      }
    });

    testWidgets('should be scrollable horizontally', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenreChips(
              genres: testGenres,
              selected: 'Music',
              onSelected: (genre) {},
            ),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      
      final scrollView = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
      expect(scrollView.scrollDirection, equals(Axis.horizontal));
    });

    testWidgets('should handle empty genre list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenreChips(
              genres: const [],
              selected: null,
              onSelected: (genre) {},
            ),
          ),
        ),
      );

      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should handle single genre', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenreChips(
              genres: const ['Music'],
              selected: 'Music',
              onSelected: (genre) {},
            ),
          ),
        ),
      );

      expect(find.text('Music'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsOneWidget);
      
      final chip = tester.widget<ChoiceChip>(find.byType(ChoiceChip));
      expect(chip.selected, isTrue);
    });

    testWidgets('should apply correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenreChips(
              genres: testGenres,
              selected: 'Music',
              onSelected: (genre) {},
            ),
          ),
        ),
      );

      final scrollView = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
      expect(scrollView.padding, const EdgeInsets.symmetric(horizontal: 16, vertical: 8));
    });

    testWidgets('should allow reselecting same genre', (WidgetTester tester) async {
      String? selectedGenre;
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenreChips(
              genres: testGenres,
              selected: 'Music',
              onSelected: (genre) {
                selectedGenre = genre;
                callCount++;
              },
            ),
          ),
        ),
      );

      // Tap the already selected Music chip
      await tester.tap(find.text('Music'));
      expect(selectedGenre, equals('Music'));
      expect(callCount, equals(1));
    });
  });
}
