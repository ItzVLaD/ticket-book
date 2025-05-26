import 'dart:convert';
import 'package:http/http.dart' as http;

import '../api_keys.dart';
import '../models/event.dart';

class TicketmasterService {
  final String apiKey = ApiKeys.ticketMaster;
  final String baseUrl = 'https://app.ticketmaster.com/discovery/v2/';

  Future<List<Event>> fetchEvents({String keyword = 'concert'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/events.json?apikey=$apiKey&keyword=$keyword'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final eventsJson = data['_embedded']['events'] as List;
      return eventsJson.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Не вдалося завантажити події');
    }
  }
}
