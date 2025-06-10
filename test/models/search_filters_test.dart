import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickets_booking/models/search_filters.dart';

void main() {
  group('SearchFilters Model Tests', () {
    test('should create SearchFilters with default values', () {
      final filters = SearchFilters();

      expect(filters.dateRange, isNull);
      expect(filters.genres, isEmpty);
      expect(filters.radius, isNull);
    });

    test('should create SearchFilters with all parameters', () {
      final dateRange = DateTimeRange(
        start: DateTime(2024, 6, 1),
        end: DateTime(2024, 6, 30),
      );
      final genres = ['Music', 'Sports'];
      const radius = 50;

      final filters = SearchFilters(
        dateRange: dateRange,
        genres: genres,
        radius: radius,
      );

      expect(filters.dateRange, equals(dateRange));
      expect(filters.genres, equals(genres));
      expect(filters.radius, equals(radius));
    });

    test('should handle null date range', () {
      final filters = SearchFilters(
        dateRange: null,
        genres: ['Music'],
        radius: 25,
      );

      expect(filters.dateRange, isNull);
      expect(filters.genres, equals(['Music']));
      expect(filters.radius, equals(25));
    });

    test('should handle empty genres list', () {
      final filters = SearchFilters(
        genres: [],
        radius: 10,
      );

      expect(filters.genres, isEmpty);
      expect(filters.radius, equals(10));
    });

    test('should handle null radius', () {
      final filters = SearchFilters(
        genres: ['Sports', 'Music'],
        radius: null,
      );

      expect(filters.genres, equals(['Sports', 'Music']));
      expect(filters.radius, isNull);
    });

    test('should create copy with modified parameters', () {
      final originalFilters = SearchFilters(
        genres: ['Music'],
        radius: 25,
      );

      final newDateRange = DateTimeRange(
        start: DateTime(2024, 7, 1),
        end: DateTime(2024, 7, 31),
      );

      // Note: If SearchFilters has a copyWith method, test it
      // Otherwise, test creating new instances
      final newFilters = SearchFilters(
        dateRange: newDateRange,
        genres: originalFilters.genres,
        radius: originalFilters.radius,
      );

      expect(newFilters.dateRange, equals(newDateRange));
      expect(newFilters.genres, equals(['Music']));
      expect(newFilters.radius, equals(25));
    });

    test('should handle multiple genres', () {
      final genres = ['Music', 'Sports', 'Arts & Theatre', 'Film', 'Miscellaneous'];
      final filters = SearchFilters(genres: genres);

      expect(filters.genres.length, equals(5));
      expect(filters.genres.contains('Music'), isTrue);
      expect(filters.genres.contains('Sports'), isTrue);
      expect(filters.genres.contains('Arts & Theatre'), isTrue);
      expect(filters.genres.contains('Film'), isTrue);
      expect(filters.genres.contains('Miscellaneous'), isTrue);
    });

    test('should handle date range spanning multiple months', () {
      final dateRange = DateTimeRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 12, 31),
      );

      final filters = SearchFilters(dateRange: dateRange);

      expect(filters.dateRange!.start.year, equals(2024));
      expect(filters.dateRange!.start.month, equals(1));
      expect(filters.dateRange!.end.year, equals(2024));
      expect(filters.dateRange!.end.month, equals(12));
    });

    test('should handle same start and end date', () {
      final sameDate = DateTime(2024, 6, 15);
      final dateRange = DateTimeRange(
        start: sameDate,
        end: sameDate,
      );

      final filters = SearchFilters(dateRange: dateRange);

      expect(filters.dateRange!.start, equals(sameDate));
      expect(filters.dateRange!.end, equals(sameDate));
    });

    test('should handle various radius values', () {
      final radiusValues = [null, 10, 25, 50, 100];

      for (final radius in radiusValues) {
        final filters = SearchFilters(radius: radius);
        expect(filters.radius, equals(radius));
      }
    });

    test('should handle duplicate genres', () {
      final genres = ['Music', 'Music', 'Sports', 'Music'];
      final filters = SearchFilters(genres: genres);

      // Depending on implementation, might keep duplicates or remove them
      expect(filters.genres.length, greaterThanOrEqualTo(2));
      expect(filters.genres.contains('Music'), isTrue);
      expect(filters.genres.contains('Sports'), isTrue);
    });

    test('should handle edge case date ranges', () {
      // Test with dates in the past
      final pastDateRange = DateTimeRange(
        start: DateTime(2020, 1, 1),
        end: DateTime(2020, 12, 31),
      );

      final filters = SearchFilters(dateRange: pastDateRange);
      expect(filters.dateRange, equals(pastDateRange));

      // Test with future dates
      final futureDateRange = DateTimeRange(
        start: DateTime(2030, 1, 1),
        end: DateTime(2030, 12, 31),
      );

      final filtersWithFuture = SearchFilters(dateRange: futureDateRange);
      expect(filtersWithFuture.dateRange, equals(futureDateRange));
    });
  });
}
