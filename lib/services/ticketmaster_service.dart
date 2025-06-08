// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../api_keys.dart';
import '../models/event.dart';
import '../models/event_group.dart';
import '../models/search_filters.dart';

class TicketmasterService {
  final String apiKey = ApiKeys.ticketMaster;
  final String baseUrl = 'https://app.ticketmaster.com/discovery/v2';

  // Add timeout for better UX
  static const Duration _timeout = Duration(seconds: 10);

  Future<List<Event>> fetchEvents({String keyword = 'concert'}) async {
    try {
      // Always filter for current events (from today onwards)
      final today = DateTime.now().toIso8601String().split('T')[0];

      final uri = Uri.parse('$baseUrl/events.json').replace(
        queryParameters: {
          'apikey': apiKey,
          'keyword': keyword,
          'size': '20', // Limit results for better performance
          'sort': 'date,asc',
          'localStartDateTime': '${today}T00:00:00', // Only get current events
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

  Future<List<Event>> fetchEventsWithFilters({
    String? keyword,
    SearchFilters? filters,
    int page = 1,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'apikey': apiKey,
        'size': '20',
        'page': page.toString(),
        'sort': 'date,asc',
      };

      // Add keyword if provided
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }

      // Add filters if provided
      if (filters != null) {
        // Date range filter - use proper format
        if (filters.dateRange != null) {
          final startDate = filters.dateRange!.start.toIso8601String().split('T')[0];
          final endDate = filters.dateRange!.end.toIso8601String().split('T')[0];
          queryParams['localStartDateTime'] = '${startDate}T00:00:00,${endDate}T23:59:59';
        } else {
          // Always filter for current events (from today onwards)
          final today = DateTime.now().toIso8601String().split('T')[0];
          queryParams['localStartDateTime'] = '${today}T00:00:00';
        }

        // Genre filter - map to Ticketmaster segment IDs
        if (filters.genres.isNotEmpty) {
          final segmentIds = _mapGenresToSegmentIds(filters.genres);
          if (segmentIds.isNotEmpty) {
            queryParams['segmentId'] = segmentIds.join(',');
          }
        }

        // Radius filter - only apply if specified (remove default location)
        if (filters.radius != null) {
          queryParams['radius'] = filters.radius.toString();
          queryParams['unit'] = 'km';
          // Note: This requires user location to work properly
          // For now, we'll skip location-based filtering unless user provides location
        }
      } else {
        // If no filters, still filter for current events
        final today = DateTime.now().toIso8601String().split('T')[0];
        queryParams['localStartDateTime'] = '${today}T00:00:00';
      }

      final uri = Uri.parse('$baseUrl/events.json').replace(queryParameters: queryParams);

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
      final key = _generateGroupingKey(event);
      groupsMap.putIfAbsent(key, () => []).add(event);
    }

    final groups = <EventGroup>[];
    groupsMap.forEach((key, events) {
      // Sort schedules by date, handling null dates
      events.sort((a, b) {
        final da = a.date ?? DateTime(2030); // Put events without dates at the end
        final db = b.date ?? DateTime(2030);
        return da.compareTo(db);
      });

      // Find first and last valid dates
      final eventsWithDates = events.where((e) => e.date != null).toList();
      final firstDate =
          eventsWithDates.isNotEmpty
              ? eventsWithDates.first.date!
              : DateTime.now(); // Fallback for events without dates
      final lastDate = eventsWithDates.isNotEmpty ? eventsWithDates.last.date! : firstDate;

      // Choose primary image by resolution priority (width in URL) and then by length
      String? primaryImage = _selectBestImage(events);

      // Choose the best name (prefer seriesName, then the most common name)
      final name = _selectBestName(events);

      groups.add(
        EventGroup(
          id: key,
          name: name,
          primaryImageUrl: primaryImage,
          firstDate: firstDate,
          lastDate: lastDate,
          schedules: events,
        ),
      );
    });

    // Sort groups by firstDate
    groups.sort((a, b) => a.firstDate.compareTo(b.firstDate));
    return groups;
  }

  /// Generates a consistent grouping key for events
  String _generateGroupingKey(Event event) {
    // Priority 1: Use seriesId if available (most reliable)
    if (event.seriesId != null && event.seriesId!.isNotEmpty) {
      return 'series_${event.seriesId}';
    }

    // Priority 2: Use attraction ID + normalized name for consistency
    if (event.firstAttractionId != null && event.firstAttractionId!.isNotEmpty) {
      final normalizedName = _normalizeName(event.name);
      return 'attraction_${event.firstAttractionId}_$normalizedName';
    }

    // Priority 3: Fallback to normalized name only
    final normalizedName = _normalizeName(event.name);
    return 'name_$normalizedName';
  }

  /// Normalizes event names for better grouping
  String _normalizeName(String name) =>
      name
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
          .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscores
          .trim();

  /// Selects the best image from a list of events
  String? _selectBestImage(List<Event> events) {
    String? bestImage;
    int bestScore = 0;

    for (var event in events) {
      if (event.imageUrl != null) {
        final score = _calculateImageScore(event.imageUrl!);
        if (score > bestScore) {
          bestScore = score;
          bestImage = event.imageUrl;
        }
      }
    }

    return bestImage;
  }

  /// Calculates image quality score based on URL patterns
  int _calculateImageScore(String imageUrl) {
    int score = imageUrl.length; // Base score from length

    // Bonus for higher resolution indicators in URL
    if (imageUrl.contains('1024x576')) {
      score += 1000;
    } else if (imageUrl.contains('640x360'))
      score += 800;
    else if (imageUrl.contains('480x270'))
      score += 600;
    else if (imageUrl.contains('305x225'))
      score += 400;
    else if (imageUrl.contains('205x115'))
      score += 200;

    // Bonus for HTTPS
    if (imageUrl.startsWith('https://')) score += 100;

    return score;
  }

  /// Selects the best name from a list of events
  String _selectBestName(List<Event> events) {
    // Priority 1: Use seriesName if available and consistent
    final seriesNames =
        events
            .where((e) => e.seriesName != null && e.seriesName!.isNotEmpty)
            .map((e) => e.seriesName!)
            .toSet();

    if (seriesNames.length == 1) {
      return seriesNames.first;
    }

    // Priority 2: Use the most common event name
    final nameFrequency = <String, int>{};
    for (var event in events) {
      nameFrequency[event.name] = (nameFrequency[event.name] ?? 0) + 1;
    }

    // Return the most frequent name, or first if tied
    return nameFrequency.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // Map genre names to Ticketmaster segment IDs
  List<String> _mapGenresToSegmentIds(List<String> genres) {
    final genreMap = {
      'Music': 'KZFzniwnSyZfZ7v7nJ', // Music segment ID - 61,676 events
      'Sports': 'KZFzniwnSyZfZ7v7nE', // Sports segment ID - 18,072 events
      'Arts & Theatre': 'KZFzniwnSyZfZ7v7na', // Arts & Theatre segment ID - 79,580 events
      'Film': 'KZFzniwnSyZfZ7v7nn', // Film segment ID - 559 events
      'Miscellaneous': 'KZFzniwnSyZfZ7v7n1', // Miscellaneous segment ID - 29,572 events
    };

    return genres
        .where((genre) => genreMap.containsKey(genre))
        .map((genre) => genreMap[genre]!)
        .toList();
  }
}
