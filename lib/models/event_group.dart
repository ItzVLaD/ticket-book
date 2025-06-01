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
}
