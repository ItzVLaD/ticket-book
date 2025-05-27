import 'package:intl/intl.dart';
import 'package:tickets_booking/models/search_filters.dart'; // if needed, else ignore

/// Represents price range info from Ticketmaster
class PriceRange {
  final double? min;
  final double? max;
  final String? currency;
  PriceRange({this.min, this.max, this.currency});
  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
    );
  }
}

class Event {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? venue;
  final DateTime? date;
  final String? seatMapUrl;
  final int totalTickets;
  final String? seriesId;
  final String? seriesName;
  final String? firstAttractionId;
  final List<PriceRange>? priceRanges;

  Event({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.venue,
    this.date,
    this.seatMapUrl,
    this.totalTickets = 100,
    this.seriesId,
    this.seriesName,
    this.firstAttractionId,
    this.priceRanges,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List?) ?? [];
    final imageUrl = images.isNotEmpty ? images[0]['url'] as String? : null;
    final venues = (json['_embedded']?['venues'] as List?) ?? [];
    final dateString = (json['dates']?['start']?['localDate'] as String?);
    DateTime? parsedDate;
    if (dateString != null) {
      parsedDate = DateTime.tryParse(dateString);
    }
    final seatMap = (json['seatmap']?['static']?['url']) as String?;
    final series = json['series'] as Map<String, dynamic>?;
    final seriesId = series?['id'] as String?;
    final seriesName = series?['name'] as String?;
    final attractions = (json['_embedded']?['attractions'] as List?) ?? [];
    final firstAttractionId = attractions.isNotEmpty ? attractions[0]['id'] as String? : null;
    final prList = (json['priceRanges'] as List?)?.cast<Map<String, dynamic>>();
    final priceRanges = prList?.map((p) => PriceRange.fromJson(p)).toList();

    return Event(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['info'] as String?,
      imageUrl: imageUrl,
      venue: venues.isNotEmpty ? venues[0]['name'] as String? : null,
      date: parsedDate,
      seatMapUrl: seatMap,
      totalTickets: 100,
      seriesId: seriesId,
      seriesName: seriesName,
      firstAttractionId: firstAttractionId,
      priceRanges: priceRanges,
    );
  }

  String get dateFormatted {
    if (date == null) return '';
    return DateFormat.yMMMd().format(date!);
  }
}
