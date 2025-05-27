import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../api_keys.dart';
import '../models/event.dart';
import '../models/event_group.dart';

class TicketmasterService {
  final String apiKey = ApiKeys.ticketMaster;
  final String baseUrl = 'https://app.ticketmaster.com/discovery/v2';

  // Add timeout for better UX
  static const Duration _timeout = Duration(seconds: 10);

  Future<List<Event>> fetchEvents({String keyword = 'concert'}) async {
    try {
      final uri = Uri.parse('$baseUrl/events.json').replace(
        queryParameters: {
          'apikey': apiKey,
          'keyword': keyword,
          'size': '20', // Limit results for better performance
          'sort': 'date,asc',
        },
      );

      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if events exist in response
        final embedded = data['_embedded'];
        if (embedded == null || embedded['events'] == null) {
          return [];
        }

        final eventsJson = embedded['events'] as List;
        return eventsJson.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on HttpException {
      throw Exception('Service temporarily unavailable.');
    } catch (e) {
      throw Exception('Failed to load events: ${e.toString()}');
    }
  }

  Future<Event?> fetchEventById(String eventId) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/events/$eventId.json',
      ).replace(queryParameters: {'apikey': apiKey});

      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Event.fromJson(data as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        return null; // Event not found
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      } else {
        throw Exception('Failed to load event: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on HttpException {
      throw Exception('Service temporarily unavailable.');
    } catch (e) {
      throw Exception('Failed to load event: ${e.toString()}');
    }
  }

  // Groups raw events into EventGroup instances
  List<EventGroup> groupEvents(List<Event> raw) {
    final groupsMap = <String, List<Event>>{};
    for (var event in raw) {
      final key = event.seriesId ?? '${event.name}_${event.firstAttractionId ?? event.id}';
      groupsMap.putIfAbsent(key, () => []).add(event);
    }
    final groups = <EventGroup>[];
    groupsMap.forEach((key, list) {
      // sort schedules by date
      list.sort((a, b) {
        final da = a.date ?? DateTime(0);
        final db = b.date ?? DateTime(0);
        return da.compareTo(db);
      });
      final firstDate = list.first.date!;
      final lastDate = list.last.date!;
      // choose primary image by longest URL as proxy for resolution
      String? primaryImage;
      for (var e in list) {
        if (e.imageUrl != null &&
            (primaryImage == null || e.imageUrl!.length > primaryImage.length)) {
          primaryImage = e.imageUrl;
        }
      }
      final name = list.first.seriesName ?? list.first.name;
      groups.add(
        EventGroup(
          id: key,
          name: name,
          primaryImageUrl: primaryImage,
          firstDate: firstDate,
          lastDate: lastDate,
          schedules: list,
        ),
      );
    });
    // sort groups by firstDate
    groups.sort((a, b) => a.firstDate.compareTo(b.firstDate));
    return groups;
  }
}
