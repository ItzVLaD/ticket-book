import 'dart:convert';
import 'package:http/http.dart' as http;

import '../api_keys.dart';
import '../models/event.dart';
import '../models/event_group.dart';

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
