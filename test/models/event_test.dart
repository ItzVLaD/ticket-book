import 'package:flutter_test/flutter_test.dart';
import 'package:tickets_booking/models/event.dart';

void main() {
  group('Event Model Tests', () {
    group('Event Creation', () {
      test('should create event with required parameters', () {
        final event = Event(
          id: 'test-id',
          name: 'Test Event',
        );

        expect(event.id, equals('test-id'));
        expect(event.name, equals('Test Event'));
        expect(event.description, isNull);
        expect(event.date, isNull);
        expect(event.venue, isNull);
        expect(event.city, isNull);
        expect(event.imageUrl, isNull);
        expect(event.genre, isNull);
        expect(event.url, isNull);
        expect(event.totalTickets, equals(100));
      });

      test('should create event with all optional parameters', () {
        final testDate = DateTime(2024, 12, 25, 20, 0);
        final event = Event(
          id: 'full-event',
          name: 'Full Event',
          description: 'A complete event description',
          date: testDate,
          venue: 'Test Venue',
          city: 'Test City',
          imageUrl: 'https://example.com/image.jpg',
          genre: 'Rock',
          url: 'https://example.com/event',
          minPrice: 50.0,
          maxPrice: 150.0,
          currency: 'USD',
          totalTickets: 200,
          seriesId: 'series-1',
          seriesName: 'Concert Series',
          firstAttractionId: 'artist-1',
          category: 'Music',
          latitude: 40.7128,
          longitude: -74.0060,
        );

        expect(event.id, equals('full-event'));
        expect(event.name, equals('Full Event'));
        expect(event.description, equals('A complete event description'));
        expect(event.date, equals(testDate));
        expect(event.venue, equals('Test Venue'));
        expect(event.city, equals('Test City'));
        expect(event.imageUrl, equals('https://example.com/image.jpg'));
        expect(event.genre, equals('Rock'));
        expect(event.url, equals('https://example.com/event'));
        expect(event.minPrice, equals(50.0));
        expect(event.maxPrice, equals(150.0));
        expect(event.currency, equals('USD'));
        expect(event.totalTickets, equals(200));
        expect(event.seriesId, equals('series-1'));
        expect(event.seriesName, equals('Concert Series'));
        expect(event.firstAttractionId, equals('artist-1'));
        expect(event.category, equals('Music'));
        expect(event.latitude, equals(40.7128));
        expect(event.longitude, equals(-74.0060));
      });
    });

    group('Date Formatting', () {
      test('should format date correctly', () {
        final event = Event(
          id: 'date-test',
          name: 'Date Test Event',
          date: DateTime(2024, 6, 15, 19, 30),
        );

        expect(event.dateFormatted, equals('15/6/2024'));
      });

      test('should return "Date TBA" when no date is provided', () {
        final event = Event(
          id: 'no-date',
          name: 'No Date Event',
        );

        expect(event.dateFormatted, equals('Date TBA'));
      });

      test('should handle different date formats', () {
        final newYearEvent = Event(
          id: 'new-year',
          name: 'New Year Event',
          date: DateTime(2025, 1, 1, 0, 0),
        );

        expect(newYearEvent.dateFormatted, equals('1/1/2025'));

        final christmasEvent = Event(
          id: 'christmas',
          name: 'Christmas Event',
          date: DateTime(2024, 12, 25, 18, 0),
        );

        expect(christmasEvent.dateFormatted, equals('25/12/2024'));
      });
    });

    group('Event Status', () {
      test('should correctly identify current (non-expired) events', () {
        final futureEvent = Event(
          id: 'future',
          name: 'Future Event',
          date: DateTime.now().add(const Duration(days: 1)),
        );

        expect(futureEvent.isCurrent, isTrue);
        expect(futureEvent.isExpired, isFalse);
      });

      test('should correctly identify expired events', () {
        final pastEvent = Event(
          id: 'past',
          name: 'Past Event',
          date: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(pastEvent.isCurrent, isFalse);
        expect(pastEvent.isExpired, isTrue);
      });

      test('should treat events without date as current', () {
        final noDateEvent = Event(
          id: 'no-date',
          name: 'No Date Event',
        );

        expect(noDateEvent.isCurrent, isTrue);
        expect(noDateEvent.isExpired, isFalse);
      });

      test('should handle today\'s events correctly', () {
        final todayEvent = Event(
          id: 'today',
          name: 'Today Event',
          date: DateTime.now(),
        );

        // Today's events should be considered current
        expect(todayEvent.isCurrent, isTrue);
        expect(todayEvent.isExpired, isFalse);
      });
    });

    group('JSON Serialization', () {
      test('should create event from basic JSON', () {
        final json = {
          'id': 'json-event',
          'name': 'JSON Event',
          'info': 'Event description',
          'url': 'https://example.com/event',
        };

        final event = Event.fromJson(json);

        expect(event.id, equals('json-event'));
        expect(event.name, equals('JSON Event'));
        expect(event.description, equals('Event description'));
        expect(event.url, equals('https://example.com/event'));
      });

      test('should handle complex JSON with nested data', () {
        final json = {
          'id': 'complex-event',
          'name': 'Complex Event',
          'dates': {
            'start': {
              'localDate': '2024-12-25',
            },
          },
          'images': [
            {'url': 'https://example.com/image1.jpg'},
            {'url': 'https://example.com/image2.jpg'},
          ],
          '_embedded': {
            'venues': [
              {
                'name': 'Test Venue',
                'city': {'name': 'Test City'},
                'state': {'name': 'Test State'},
                'country': {'name': 'Test Country'},
                'location': {
                  'latitude': '40.7128',
                  'longitude': '-74.0060',
                },
              },
            ],
            'attractions': [
              {'id': 'attraction-1'},
            ],
          },
          'classifications': [
            {
              'segment': {'name': 'Music'},
              'genre': {'name': 'Rock'},
            },
          ],
          'priceRanges': [
            {
              'min': 50.0,
              'max': 150.0,
              'currency': 'USD',
            },
          ],
          'series': {
            'id': 'series-1',
            'name': 'Concert Series',
          },
        };

        final event = Event.fromJson(json);

        expect(event.id, equals('complex-event'));
        expect(event.name, equals('Complex Event'));
        expect(event.venue, equals('Test Venue'));
        expect(event.city, contains('Test City'));
        expect(event.imageUrl, equals('https://example.com/image1.jpg'));
        expect(event.category, equals('Music'));
        expect(event.genre, equals('Rock'));
        expect(event.latitude, equals(40.7128));
        expect(event.longitude, equals(-74.0060));
        expect(event.seriesId, equals('series-1'));
        expect(event.seriesName, equals('Concert Series'));
        expect(event.firstAttractionId, equals('attraction-1'));
        expect(event.priceRanges?.length, equals(1));
        expect(event.priceRanges?.first.min, equals(50.0));
        expect(event.priceRanges?.first.max, equals(150.0));
        expect(event.priceRanges?.first.currency, equals('USD'));
      });

      test('should handle JSON with missing fields gracefully', () {
        final json = {
          'id': 'minimal-event',
          'name': 'Minimal Event',
          // Missing most optional fields
        };

        final event = Event.fromJson(json);

        expect(event.id, equals('minimal-event'));
        expect(event.name, equals('Minimal Event'));
        expect(event.description, isNull);
        expect(event.date, isNull);
        expect(event.venue, isNull);
        expect(event.imageUrl, isNull);
        expect(event.priceRanges, isNull);
      });
    });

    group('Price Range Model', () {
      test('should create price range with all parameters', () {
        final priceRange = PriceRange(
          min: 25.0,
          max: 75.0,
          currency: 'EUR',
        );

        expect(priceRange.min, equals(25.0));
        expect(priceRange.max, equals(75.0));
        expect(priceRange.currency, equals('EUR'));
      });

      test('should create price range from JSON', () {
        final json = {
          'min': 30.0,
          'max': 100.0,
          'currency': 'GBP',
        };

        final priceRange = PriceRange.fromJson(json);

        expect(priceRange.min, equals(30.0));
        expect(priceRange.max, equals(100.0));
        expect(priceRange.currency, equals('GBP'));
      });

      test('should handle missing values in price range JSON', () {
        final json = {
          'currency': 'USD',
          // Missing min and max
        };

        final priceRange = PriceRange.fromJson(json);

        expect(priceRange.min, isNull);
        expect(priceRange.max, isNull);
        expect(priceRange.currency, equals('USD'));
      });

      test('should default to USD currency when not specified', () {
        final json = {
          'min': 50.0,
          'max': 150.0,
          // Missing currency
        };

        final priceRange = PriceRange.fromJson(json);

        expect(priceRange.currency, equals('USD'));
      });
    });

    group('Edge Cases', () {
      test('should handle very long event names', () {
        final longName = 'A' * 1000; // 1000 character name
        final event = Event(
          id: 'long-name',
          name: longName,
        );

        expect(event.name, equals(longName));
        expect(event.name.length, equals(1000));
      });

      test('should handle special characters in event name', () {
        final event = Event(
          id: 'special',
          name: 'Event with émojis 🎵 and 特殊字符',
        );

        expect(event.name, contains('émojis'));
        expect(event.name, contains('🎵'));
        expect(event.name, contains('特殊字符'));
      });

      test('should handle extreme dates', () {
        final veryFutureEvent = Event(
          id: 'far-future',
          name: 'Far Future Event',
          date: DateTime(2100, 1, 1),
        );

        expect(veryFutureEvent.isCurrent, isTrue);
        expect(veryFutureEvent.dateFormatted, equals('1/1/2100'));

        final veryPastEvent = Event(
          id: 'far-past',
          name: 'Far Past Event',
          date: DateTime(1900, 1, 1),
        );

        expect(veryPastEvent.isExpired, isTrue);
        expect(veryPastEvent.dateFormatted, equals('1/1/1900'));
      });

      test('should handle invalid coordinate values', () {
        final event = Event(
          id: 'invalid-coords',
          name: 'Invalid Coordinates Event',
          latitude: 999.0, // Invalid latitude
          longitude: -999.0, // Invalid longitude
        );

        expect(event.latitude, equals(999.0));
        expect(event.longitude, equals(-999.0));
        // Note: The model doesn't validate coordinates, but stores them as provided
      });
    });
  });
}
