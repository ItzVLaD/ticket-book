import 'dart:convert';
import 'package:http/http.dart' as http;

import '../api_keys.dart';

class TicketmasterService {
  final String apiKey = ApiKeys.ticketMaster;
  final String baseUrl = 'https://app.ticketmaster.com/discovery/v2/';

  Future<List<Event>> fetchEvents({String keyword = 'concert'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/events.json?apikey=$apiKey&keyword=$keyword'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final events = data['_embedded']['events'] as List;
      return events.map((e) => Event.fromJson(e)).toList();
    } else {
      throw Exception('Не вдалося завантажити події');
    }
  }
}

class Event {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? venue;
  final String? date;
  final int totalTickets;

  Event({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.venue,
    this.date,
    this.totalTickets = 100,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List;
    final venues = json['_embedded']['venues'] as List;
    return Event(
      id: json['id'],
      name: json['name'],
      description: json['info'],
      imageUrl: images.isNotEmpty ? images[0]['url'] : null,
      venue: venues.isNotEmpty ? venues[0]['name'] : null,
      date: json['dates']['start']['localDate'],
    );
  }
}
