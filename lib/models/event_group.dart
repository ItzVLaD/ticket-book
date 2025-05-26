import 'package:tickets_booking/models/event.dart';

class EventGroup {
  final String id;
  final String name;
  final String? primaryImageUrl;
  final DateTime firstDate;
  final DateTime lastDate;
  final List<Event> schedules;

  const EventGroup({
    required this.id,
    required this.name,
    required this.primaryImageUrl,
    required this.firstDate,
    required this.lastDate,
    required this.schedules,
  });
}