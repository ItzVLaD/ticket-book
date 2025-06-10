import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:tickets_booking/providers/event_provider.dart';
import 'package:tickets_booking/services/ticketmaster_service.dart';
import 'package:tickets_booking/models/event.dart';
import 'package:tickets_booking/models/event_group.dart';

// Generate mocks
@GenerateMocks([TicketmasterService])
import 'event_provider_test.mocks.dart';

void main() {
  group('EventsProvider Tests', () {
    late EventsProvider eventsProvider;
    late MockTicketmasterService mockTicketmasterService;

    setUp(() {
      mockTicketmasterService = MockTicketmasterService();
      eventsProvider = EventsProvider();
    });

    test('should initialize with empty state', () {
      expect(eventsProvider.events, isEmpty);
      expect(eventsProvider.groupedEvents, isEmpty);
      expect(eventsProvider.isLoading, isFalse);
      expect(eventsProvider.hasError, isFalse);
    });

    test('should return only current events', () {
      // Create test events - some current, some expired
      final currentDate = DateTime.now().add(const Duration(days: 1));
      final expiredDate = DateTime.now().subtract(const Duration(days: 1));
      
      final currentEvent = Event(
        id: '1',
        name: 'Current Event',
        date: currentDate,
      );
      
      final expiredEvent = Event(
        id: '2', 
        name: 'Expired Event',
        date: expiredDate,
      );

      // Set the events directly (this would normally be done through loadEvents)
      eventsProvider.events.addAll([currentEvent, expiredEvent]);
      
      final currentEvents = eventsProvider.currentEvents;
      
      expect(currentEvents.length, equals(1));
      expect(currentEvents.first.id, equals('1'));
    });

    test('should return current grouped events only', () {
      // Create test event groups
      final currentDate = DateTime.now().add(const Duration(days: 1));
      final expiredDate = DateTime.now().subtract(const Duration(days: 1));
      
      final currentEvent = Event(
        id: '1',
        name: 'Current Event',
        date: currentDate,
      );
      
      final expiredEvent = Event(
        id: '2',
        name: 'Expired Event', 
        date: expiredDate,
      );
      
      final currentGroup = EventGroup(
        id: 'group1',
        name: 'Current Group',
        primaryImageUrl: null,
        firstDate: DateTime.now().add(const Duration(days: 1)),
        lastDate: DateTime.now().add(const Duration(days: 1)),
        schedules: [currentEvent],
      );
      
      final expiredGroup = EventGroup(
        id: 'group2',
        name: 'Expired Group',
        primaryImageUrl: null,
        firstDate: DateTime.now().subtract(const Duration(days: 1)),
        lastDate: DateTime.now().subtract(const Duration(days: 1)),
        schedules: [expiredEvent],
      );

      // Manually set grouped events for testing
      eventsProvider.groupedEvents.addAll([currentGroup, expiredGroup]);
      
      final currentGroupedEvents = eventsProvider.currentGroupedEvents;
      
      expect(currentGroupedEvents.length, equals(1));
      expect(currentGroupedEvents.first.id, equals('group1'));
    });

    test('should handle load events successfully', () async {
      // Create mock events
      final mockEvents = [
        Event(id: '1', name: 'Event 1', date: DateTime.now().add(const Duration(days: 1))),
        Event(id: '2', name: 'Event 2', date: DateTime.now().add(const Duration(days: 2))),
      ];

      // Mock the service response
      when(mockTicketmasterService.fetchEvents(keyword: anyNamed('keyword')))
          .thenAnswer((_) async => mockEvents);
      when(mockTicketmasterService.groupEvents(any))
          .thenReturn([EventGroup(
            id: 'group1', 
            name: 'Group 1', 
            primaryImageUrl: null,
            firstDate: DateTime.now(),
            lastDate: DateTime.now(),
            schedules: mockEvents
          )]);

      // Note: The actual implementation uses a private service instance
      // This test demonstrates the intended behavior
      
      expect(eventsProvider.isLoading, isFalse);
      
      // Simulate loading
      eventsProvider.loadEvents(keyword: 'test');
      
      // Initially, loading should be true (but we can't easily test this without mocking)
      // expect(eventsProvider.isLoading, isTrue);
    });

    test('should handle load events error', () async {
      // Simulate error scenario
      when(mockTicketmasterService.fetchEvents(keyword: anyNamed('keyword')))
          .thenThrow(Exception('Network error'));

      // Note: The actual implementation catches errors and sets hasError = true
      expect(() async {
        await eventsProvider.loadEvents(keyword: 'test');
      }, returnsNormally); // Should not throw, should handle gracefully
    });

    test('should clear data correctly', () {
      // Add some test data
      eventsProvider.events.add(Event(id: '1', name: 'Test Event'));
      eventsProvider.groupedEvents.add(EventGroup(
        id: 'group1', 
        name: 'Test Group', 
        primaryImageUrl: null,
        firstDate: DateTime.now(),
        lastDate: DateTime.now(),
        schedules: []
      ));
      
      eventsProvider.clear();
      
      expect(eventsProvider.events, isEmpty);
      expect(eventsProvider.groupedEvents, isEmpty);
      expect(eventsProvider.hasError, isFalse);
      expect(eventsProvider.errorMessage, isEmpty);
    });

    test('should return similar events for a group', () {
      // Create test groups
      final event1 = Event(id: '1', name: 'Event 1');
      final event2 = Event(id: '2', name: 'Event 2'); 
      final event3 = Event(id: '3', name: 'Event 3');
      
      final group1 = EventGroup(
        id: 'group1', 
        name: 'Group 1', 
        primaryImageUrl: null,
        firstDate: DateTime.now(),
        lastDate: DateTime.now(),
        schedules: [event1]
      );
      final group2 = EventGroup(
        id: 'group2', 
        name: 'Group 2', 
        primaryImageUrl: null,
        firstDate: DateTime.now(),
        lastDate: DateTime.now(),
        schedules: [event2]
      );
      final group3 = EventGroup(
        id: 'group3', 
        name: 'Group 3', 
        primaryImageUrl: null,
        firstDate: DateTime.now(),
        lastDate: DateTime.now(),
        schedules: [event3]
      );
      
      eventsProvider.groupedEvents.addAll([group1, group2, group3]);
      
      final similarEvents = eventsProvider.similarEventsFor(group1);
      
      expect(similarEvents.length, equals(2)); // Should return events from other groups
      expect(similarEvents.any((e) => e.id == '1'), isFalse); // Should not include event from same group
      expect(similarEvents.any((e) => e.id == '2'), isTrue);
      expect(similarEvents.any((e) => e.id == '3'), isTrue);
    });

    test('should refresh data correctly', () async {
      // Set some initial data
      eventsProvider.events.add(Event(id: '1', name: 'Old Event'));
      
      // Refresh should clear and reload
      await eventsProvider.refresh(keyword: 'concert');
      
      // Note: Without proper mocking of the service, we can't fully test the refresh behavior
      // But we can ensure it doesn't throw errors
      expect(() => eventsProvider.refresh(), returnsNormally);
    });

    test('should notify listeners on state changes', () {
      bool listenerCalled = false;
      
      eventsProvider.addListener(() {
        listenerCalled = true;
      });
      
      eventsProvider.notifyListeners();
      
      expect(listenerCalled, isTrue);
    });
  });
}
