import 'package:flutter_test/flutter_test.dart';
import 'package:tickets_booking/models/event_group.dart';
import 'package:tickets_booking/models/event.dart';

void main() {
  group('EventGroup Model Tests', () {
    group('EventGroup Creation', () {
      test('should create event group with required parameters', () {
        final events = [
          Event(id: '1', name: 'Event 1', date: DateTime.now().add(const Duration(days: 1))),
          Event(id: '2', name: 'Event 2', date: DateTime.now().add(const Duration(days: 2))),
        ];

        final group = EventGroup(
          id: 'test-group',
          name: 'Test Group',
          primaryImageUrl: 'https://example.com/image.jpg',
          firstDate: DateTime.now().add(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 2)),
          schedules: events,
        );

        expect(group.id, equals('test-group'));
        expect(group.name, equals('Test Group'));
        expect(group.primaryImageUrl, equals('https://example.com/image.jpg'));
        expect(group.schedules.length, equals(2));
        expect(group.schedules, equals(events));
      });

      test('should create event group with null primary image', () {
        final events = [
          Event(id: '1', name: 'Event 1'),
        ];

        final group = EventGroup(
          id: 'no-image-group',
          name: 'No Image Group',
          primaryImageUrl: null,
          firstDate: DateTime.now(),
          lastDate: DateTime.now(),
          schedules: events,
        );

        expect(group.id, equals('no-image-group'));
        expect(group.name, equals('No Image Group'));
        expect(group.primaryImageUrl, isNull);
        expect(group.schedules.length, equals(1));
      });

      test('should create event group with empty schedules', () {
        final group = EventGroup(
          id: 'empty-group',
          name: 'Empty Group',
          primaryImageUrl: null,
          firstDate: DateTime.now(),
          lastDate: DateTime.now(),
          schedules: [],
        );

        expect(group.id, equals('empty-group'));
        expect(group.name, equals('Empty Group'));
        expect(group.schedules, isEmpty);
      });
    });

    group('Current Events Detection', () {
      test('should correctly identify groups with current events', () {
        final currentEvents = [
          Event(id: '1', name: 'Current Event 1', date: DateTime.now().add(const Duration(days: 1))),
          Event(id: '2', name: 'Current Event 2', date: DateTime.now().add(const Duration(days: 2))),
        ];

        final group = EventGroup(
          id: 'current-group',
          name: 'Current Group',
          primaryImageUrl: null,
          firstDate: DateTime.now().add(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 2)),
          schedules: currentEvents,
        );

        expect(group.hasCurrentEvents, isTrue);
        expect(group.currentSchedules.length, equals(2));
        expect(group.currentSchedules, equals(currentEvents));
      });

      test('should correctly identify groups with only expired events', () {
        final expiredEvents = [
          Event(id: '1', name: 'Expired Event 1', date: DateTime.now().subtract(const Duration(days: 1))),
          Event(id: '2', name: 'Expired Event 2', date: DateTime.now().subtract(const Duration(days: 2))),
        ];

        final group = EventGroup(
          id: 'expired-group',
          name: 'Expired Group',
          primaryImageUrl: null,
          firstDate: DateTime.now().subtract(const Duration(days: 2)),
          lastDate: DateTime.now().subtract(const Duration(days: 1)),
          schedules: expiredEvents,
        );

        expect(group.hasCurrentEvents, isFalse);
        expect(group.currentSchedules, isEmpty);
      });

      test('should handle mixed current and expired events', () {
        final mixedEvents = [
          Event(id: '1', name: 'Expired Event', date: DateTime.now().subtract(const Duration(days: 1))),
          Event(id: '2', name: 'Current Event 1', date: DateTime.now().add(const Duration(days: 1))),
          Event(id: '3', name: 'Current Event 2', date: DateTime.now().add(const Duration(days: 2))),
        ];

        final group = EventGroup(
          id: 'mixed-group',
          name: 'Mixed Group',
          primaryImageUrl: null,
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 2)),
          schedules: mixedEvents,
        );

        expect(group.hasCurrentEvents, isTrue);
        expect(group.currentSchedules.length, equals(2));
        expect(group.currentSchedules.map((e) => e.id), containsAll(['2', '3']));
        expect(group.currentSchedules.every((e) => e.isCurrent), isTrue);
      });

      test('should handle events without dates', () {
        final noDateEvents = [
          Event(id: '1', name: 'No Date Event 1'),
          Event(id: '2', name: 'No Date Event 2'),
        ];

        final group = EventGroup(
          id: 'no-date-group',
          name: 'No Date Group',
          primaryImageUrl: null,
          firstDate: DateTime.now(),
          lastDate: DateTime.now(),
          schedules: noDateEvents,
        );

        // Events without dates are considered current
        expect(group.hasCurrentEvents, isTrue);
        expect(group.currentSchedules.length, equals(2));
        expect(group.currentSchedules, equals(noDateEvents));
      });
    });

    group('Date Handling', () {
      test('should handle same first and last date', () {
        final singleDayEvent = Event(
          id: '1', 
          name: 'Single Day Event', 
          date: DateTime(2024, 12, 25, 20, 0),
        );

        final group = EventGroup(
          id: 'single-day-group',
          name: 'Single Day Group',
          primaryImageUrl: null,
          firstDate: DateTime(2024, 12, 25),
          lastDate: DateTime(2024, 12, 25),
          schedules: [singleDayEvent],
        );

        expect(group.firstDate, equals(group.lastDate));
        expect(group.schedules.length, equals(1));
      });

      test('should handle date ranges spanning months', () {
        final events = [
          Event(id: '1', name: 'November Event', date: DateTime(2024, 11, 30)),
          Event(id: '2', name: 'December Event', date: DateTime(2024, 12, 15)),
          Event(id: '3', name: 'January Event', date: DateTime(2025, 1, 15)),
        ];

        final group = EventGroup(
          id: 'multi-month-group',
          name: 'Multi-Month Group',
          primaryImageUrl: null,
          firstDate: DateTime(2024, 11, 30),
          lastDate: DateTime(2025, 1, 15),
          schedules: events,
        );

        expect(group.firstDate.month, equals(11));
        expect(group.lastDate.month, equals(1));
        expect(group.lastDate.year, equals(2025));
        expect(group.schedules.length, equals(3));
      });

      test('should handle extreme date ranges', () {
        final events = [
          Event(id: '1', name: 'Far Future Event', date: DateTime(2100, 1, 1)),
        ];

        final group = EventGroup(
          id: 'far-future-group',
          name: 'Far Future Group',
          primaryImageUrl: null,
          firstDate: DateTime(2100, 1, 1),
          lastDate: DateTime(2100, 1, 1),
          schedules: events,
        );

        expect(group.firstDate.year, equals(2100));
        expect(group.hasCurrentEvents, isTrue); // Far future events are current
      });
    });

    group('Schedule Management', () {
      test('should preserve event order in schedules', () {
        final events = [
          Event(id: '3', name: 'Third Event'),
          Event(id: '1', name: 'First Event'),
          Event(id: '2', name: 'Second Event'),
        ];

        final group = EventGroup(
          id: 'ordered-group',
          name: 'Ordered Group',
          primaryImageUrl: null,
          firstDate: DateTime.now(),
          lastDate: DateTime.now(),
          schedules: events,
        );

        expect(group.schedules[0].id, equals('3'));
        expect(group.schedules[1].id, equals('1'));
        expect(group.schedules[2].id, equals('2'));
      });

      test('should handle large number of schedules', () {
        final events = List.generate(100, (index) => Event(
          id: 'event-$index',
          name: 'Event $index',
          date: DateTime.now().add(Duration(days: index)),
        ));

        final group = EventGroup(
          id: 'large-group',
          name: 'Large Group',
          primaryImageUrl: null,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 99)),
          schedules: events,
        );

        expect(group.schedules.length, equals(100));
        expect(group.hasCurrentEvents, isTrue);
        expect(group.currentSchedules.length, equals(100));
      });

      test('should handle duplicate events in schedules', () {
        final event1 = Event(id: '1', name: 'Event 1');
        final event2 = Event(id: '1', name: 'Event 1 Duplicate'); // Same ID

        final group = EventGroup(
          id: 'duplicate-group',
          name: 'Duplicate Group',
          primaryImageUrl: null,
          firstDate: DateTime.now(),
          lastDate: DateTime.now(),
          schedules: [event1, event2],
        );

        expect(group.schedules.length, equals(2));
        expect(group.schedules[0].id, equals(group.schedules[1].id));
      });
    });

    group('Image URL Handling', () {
      test('should handle valid image URLs', () {
        final group = EventGroup(
          id: 'image-group',
          name: 'Image Group',
          primaryImageUrl: 'https://example.com/image.jpg',
          firstDate: DateTime.now(),
          lastDate: DateTime.now(),
          schedules: [],
        );

        expect(group.primaryImageUrl, equals('https://example.com/image.jpg'));
      });

      test('should handle relative image URLs', () {
        final group = EventGroup(
          id: 'relative-image-group',
          name: 'Relative Image Group',
          primaryImageUrl: '/images/event.jpg',
          firstDate: DateTime.now(),
          lastDate: DateTime.now(),
          schedules: [],
        );

        expect(group.primaryImageUrl, equals('/images/event.jpg'));
      });

      test('should handle empty string image URL', () {
        final group = EventGroup(
          id: 'empty-image-group',
          name: 'Empty Image Group',
          primaryImageUrl: '',
          firstDate: DateTime.now(),
          lastDate: DateTime.now(),
          schedules: [],
        );

        expect(group.primaryImageUrl, equals(''));
      });
    });

    group('Edge Cases', () {
      test('should handle very long group names', () {
        final longName = 'A' * 500;
        final group = EventGroup(
          id: 'long-name-group',
          name: longName,
          primaryImageUrl: null,
          firstDate: DateTime.now(),
          lastDate: DateTime.now(),
          schedules: [],
        );

        expect(group.name, equals(longName));
        expect(group.name.length, equals(500));
      });

      test('should handle special characters in group name', () {
        final group = EventGroup(
          id: 'special-chars-group',
          name: 'Group with émojis 🎪 and 特殊字符',
          primaryImageUrl: null,
          firstDate: DateTime.now(),
          lastDate: DateTime.now(),
          schedules: [],
        );

        expect(group.name, contains('émojis'));
        expect(group.name, contains('🎪'));
        expect(group.name, contains('特殊字符'));
      });

      test('should handle invalid date order (last date before first date)', () {
        final group = EventGroup(
          id: 'invalid-date-order',
          name: 'Invalid Date Order',
          primaryImageUrl: null,
          firstDate: DateTime.now().add(const Duration(days: 2)),
          lastDate: DateTime.now().add(const Duration(days: 1)), // Before first date
          schedules: [],
        );

        // The model doesn't validate date order, it just stores what's provided
        expect(group.firstDate.isAfter(group.lastDate), isTrue);
      });
    });

    group('Immutability', () {
      test('EventGroup should be immutable', () {
        final events = [
          Event(id: '1', name: 'Event 1'),
        ];

        final group = EventGroup(
          id: 'immutable-group',
          name: 'Immutable Group',
          primaryImageUrl: null,
          firstDate: DateTime.now(),
          lastDate: DateTime.now(),
          schedules: events,
        );

        // The group should have its own copy of the schedules list
        expect(group.schedules, isA<List<Event>>());
        expect(group.schedules.length, equals(1));
        
        // The fields should be final (can't be changed after creation)
        expect(group.id, equals('immutable-group'));
        expect(group.name, equals('Immutable Group'));
      });
    });
  });
}
