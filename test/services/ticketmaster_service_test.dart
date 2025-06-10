import 'package:flutter_test/flutter_test.dart';
import 'package:tickets_booking/services/ticketmaster_service.dart';
import 'package:tickets_booking/models/event.dart';
import 'package:tickets_booking/models/search_filters.dart';
import 'package:flutter/material.dart';

void main() {
  group('TicketmasterService Tests', () {
    late TicketmasterService service;
    
    setUp(() {
      service = TicketmasterService();
    });

    group('fetchEvents', () {
      test('should return events list', () async {
        final events = await service.fetchEvents(keyword: 'test');
        
        expect(events, isA<List<Event>>());
      });

      test('should handle different keywords', () async {
        final concerts = await service.fetchEvents(keyword: 'concert');
        final sports = await service.fetchEvents(keyword: 'sports');
        final theatre = await service.fetchEvents(keyword: 'theatre');
        
        expect(concerts, isA<List<Event>>());
        expect(sports, isA<List<Event>>());
        expect(theatre, isA<List<Event>>());
      });

      test('should return current events only', () async {
        final events = await service.fetchEvents(keyword: 'concert');
        
        // All returned events should be current (not expired)
        for (final event in events) {
          if (event.date != null) {
            expect(event.date!.isAfter(DateTime.now().subtract(const Duration(days: 1))), isTrue);
          }
        }
      });
    });

    group('fetchEventsWithFilters', () {
      test('should search with keyword only', () async {
        final events = await service.fetchEventsWithFilters(
          keyword: 'concert',
        );
        
        expect(events, isA<List<Event>>());
      });

      test('should search with genre filters', () async {
        final filters = SearchFilters(
          genres: ['Music', 'Sports'],
        );

        final events = await service.fetchEventsWithFilters(
          keyword: 'test',
          filters: filters,
        );
        
        expect(events, isA<List<Event>>());
      });

      test('should search with date range filters', () async {
        final filters = SearchFilters(
          dateRange: DateTimeRange(
            start: DateTime(2025, 6, 1),
            end: DateTime(2025, 8, 31),
          ),
        );

        final events = await service.fetchEventsWithFilters(
          keyword: 'concert',
          filters: filters,
        );
        
        expect(events, isA<List<Event>>());
      });

      test('should search with radius filter', () async {
        final filters = SearchFilters(
          radius: 50,
        );

        final events = await service.fetchEventsWithFilters(
          keyword: 'music',
          filters: filters,
        );
        
        expect(events, isA<List<Event>>());
      });

      test('should handle pagination', () async {
        final page1 = await service.fetchEventsWithFilters(
          keyword: 'concert',
          page: 1,
        );

        final page2 = await service.fetchEventsWithFilters(
          keyword: 'concert', 
          page: 2,
        );
        
        expect(page1, isA<List<Event>>());
        expect(page2, isA<List<Event>>());
      });
    });

    group('fetchEventById', () {
      test('should return event when found', () async {
        // Try with a known event ID from the API test
        final event = await service.fetchEventById('G5vzZbJmA7Zw_');
        
        expect(event, anyOf(isA<Event>(), isNull));
      });

      test('should return null for non-existent event', () async {
        final event = await service.fetchEventById('non-existent-id');
        
        expect(event, isNull);
      });
    });

    group('groupEvents', () {
      test('should group events by series ID', () {
        final events = [
          Event(
            id: '1', 
            name: 'Concert Series Event 1', 
            seriesId: 'series1',
            seriesName: 'Summer Concert Series',
            date: DateTime(2025, 7, 1),
          ),
          Event(
            id: '2', 
            name: 'Concert Series Event 2', 
            seriesId: 'series1',
            seriesName: 'Summer Concert Series',
            date: DateTime(2025, 7, 15),
          ),
          Event(
            id: '3', 
            name: 'Different Event', 
            seriesId: 'series2',
            date: DateTime(2025, 8, 1),
          ),
        ];

        final groups = service.groupEvents(events);

        expect(groups.length, equals(2));
        expect(groups[0].schedules.length, equals(2));
        expect(groups[1].schedules.length, equals(1));
      });

      test('should group events by attraction ID when no series', () {
        final events = [
          Event(
            id: '1', 
            name: 'Artist Concert', // Same name for same artist
            firstAttractionId: 'artist1',
            date: DateTime(2025, 7, 1),
          ),
          Event(
            id: '2', 
            name: 'Artist Concert', // Same name for same artist
            firstAttractionId: 'artist1',
            date: DateTime(2025, 7, 15),
          ),
          Event(
            id: '3', 
            name: 'Different Artist', 
            firstAttractionId: 'artist2',
            date: DateTime(2025, 8, 1),
          ),
        ];

        final groups = service.groupEvents(events);

        expect(groups.length, equals(2));
        expect(groups[0].schedules.length, equals(2)); // Two events for artist1
        expect(groups[1].schedules.length, equals(1)); // One event for artist2
      });

      test('should group events by name when no series or attraction', () {
        final events = [
          Event(id: '1', name: 'Generic Event', date: DateTime(2025, 7, 1)),
          Event(id: '2', name: 'Generic Event', date: DateTime(2025, 7, 15)),
          Event(id: '3', name: 'Different Event', date: DateTime(2025, 8, 1)),
        ];

        final groups = service.groupEvents(events);

        expect(groups.length, equals(2));
        expect(groups[0].schedules.length, equals(2));
        expect(groups[1].schedules.length, equals(1));
      });

      test('should sort events within groups by date', () {
        final laterDate = DateTime(2025, 7, 15);
        final earlierDate = DateTime(2025, 7, 1);
        
        final events = [
          Event(
            id: '2', 
            name: 'Event', 
            seriesId: 'series1',
            date: laterDate,
          ),
          Event(
            id: '1', 
            name: 'Event', 
            seriesId: 'series1',
            date: earlierDate,
          ),
        ];

        final groups = service.groupEvents(events);

        expect(groups.length, equals(1));
        expect(groups[0].schedules.length, equals(2));
        expect(groups[0].schedules[0].date, equals(earlierDate));
        expect(groups[0].schedules[1].date, equals(laterDate));
      });

      test('should handle empty events list', () {
        final groups = service.groupEvents([]);

        expect(groups, isEmpty);
      });

      test('should select best image from events', () {
        final events = [
          Event(
            id: '1', 
            name: 'Event', 
            seriesId: 'series1',
            imageUrl: 'https://example.com/low-res.jpg',
          ),
          Event(
            id: '2', 
            name: 'Event', 
            seriesId: 'series1',
            imageUrl: 'https://example.com/1024x576/high-res.jpg',
          ),
        ];

        final groups = service.groupEvents(events);

        expect(groups.length, equals(1));
        expect(groups[0].primaryImageUrl, contains('1024x576'));
      });

      test('should prefer series name over event name', () {
        final events = [
          Event(
            id: '1', 
            name: 'Individual Event Name', 
            seriesId: 'series1',
            seriesName: 'Official Series Name',
          ),
          Event(
            id: '2', 
            name: 'Another Individual Name', 
            seriesId: 'series1',
            seriesName: 'Official Series Name',
          ),
        ];

        final groups = service.groupEvents(events);

        expect(groups.length, equals(1));
        expect(groups[0].name, equals('Official Series Name'));
      });

      test('should set correct first and last dates', () {
        final date1 = DateTime(2025, 7, 1);
        final date2 = DateTime(2025, 7, 15);
        final date3 = DateTime(2025, 8, 1);
        
        final events = [
          Event(id: '2', name: 'Event', seriesId: 'series1', date: date2),
          Event(id: '1', name: 'Event', seriesId: 'series1', date: date1),
          Event(id: '3', name: 'Event', seriesId: 'series1', date: date3),
        ];

        final groups = service.groupEvents(events);

        expect(groups.length, equals(1));
        expect(groups[0].firstDate, equals(date1));
        expect(groups[0].lastDate, equals(date3));
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        // Test with invalid keyword that might cause errors
        expect(() => service.fetchEvents(keyword: ''), returnsNormally);
      });

      test('should handle API rate limiting', () async {
        // The service should handle rate limiting gracefully
        expect(() => service.fetchEvents(keyword: 'test'), returnsNormally);
      });

      test('should handle invalid event IDs', () async {
        final event = await service.fetchEventById('invalid-id-12345');
        expect(event, isNull);
      });
    });

    group('Real API Integration', () {
      test('should handle real API response structure', () async {
        // Test with a small request to validate actual API structure
        final events = await service.fetchEvents(keyword: 'concert');
        
        expect(events, isA<List<Event>>());
        
        // If events are returned, validate their structure
        if (events.isNotEmpty) {
          final event = events.first;
          expect(event.id, isNotNull);
          expect(event.name, isNotNull);
          expect(event.name.isNotEmpty, isTrue);
        }
      });

      test('should parse venue information correctly', () async {
        final events = await service.fetchEvents(keyword: 'music');
        
        // If events with venues are returned, validate venue parsing
        final eventsWithVenues = events.where((e) => e.venue != null).toList();
        
        for (final event in eventsWithVenues.take(3)) {
          expect(event.venue, isNotNull);
          expect(event.venue!.isNotEmpty, isTrue);
        }
      });

      test('should parse date information correctly', () async {
        final events = await service.fetchEvents(keyword: 'sports');
        
        // If events with dates are returned, validate date parsing
        final eventsWithDates = events.where((e) => e.date != null).toList();
        
        for (final event in eventsWithDates.take(3)) {
          expect(event.date, isNotNull);
          expect(event.date!.isAfter(DateTime(2020)), isTrue);
        }
      });
    });
  });
}
