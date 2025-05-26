import 'package:intl/intl.dart';

class Event {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? venue;
  final DateTime? date;

  Event({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.venue,
    this.date,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List?) ?? [];
    final imageUrl = images.isNotEmpty ? images[0]['url'] as String? : null;
    final venues = (json['_embedded']?['venues'] as List?) ?? [];
    final dateString = (json['dates']?['start']?['localDate'] as String?) ;
    DateTime? parsedDate;
    if (dateString != null) {
      parsedDate = DateTime.tryParse(dateString);
    }
    return Event(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['info'] as String?,
      imageUrl: imageUrl,
      venue: venues.isNotEmpty ? venues[0]['name'] as String? : null,
      date: parsedDate,
    );
  }

  String get dateFormatted {
    if (date == null) return '';
    return DateFormat.yMMMd().format(date!);
  }
}