import 'event.dart';

class EventGroup {
  const EventGroup({
    required this.id,
    required this.name,
    required this.primaryImageUrl,
    required this.firstDate,
    required this.lastDate,
    required this.schedules,
  });

  final String id;
  final String name;
  final String? primaryImageUrl;
  final DateTime firstDate;
  final DateTime lastDate;
  final List<Event> schedules;

  // Check if this group has at least one current (non-expired) event
  bool get hasCurrentEvents {
    return schedules.any((event) => event.isCurrent);
  }

  // Get only the current (non-expired) events from this group
  List<Event> get currentSchedules {
    return schedules.where((event) => event.isCurrent).toList();
  }
}
