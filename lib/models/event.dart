/// Represents price range info from Ticketmaster
class PriceRange {
  const PriceRange({required this.currency, this.min, this.max});

  factory PriceRange.fromJson(Map<String, dynamic> json) => PriceRange(
    min: (json['min'] as num?)?.toDouble(),
    max: (json['max'] as num?)?.toDouble(),
    currency: json['currency'] as String? ?? 'USD',
  );

  final double? min;
  final double? max;
  final String currency;
}

class Event {
  Event({
    required this.id,
    required this.name,
    this.description,
    this.date,
    this.venue,
    this.city,
    this.imageUrl,
    this.genre,
    this.url,
    this.minPrice,
    this.maxPrice,
    this.currency,
    this.totalTickets = 100,
    this.seriesId,
    this.seriesName,
    this.firstAttractionId,
    this.priceRanges,
  });

  final String id;
  final String name;
  final String? description;
  final DateTime? date;
  final String? venue;
  final String? city;
  final String? imageUrl;
  final String? genre;
  final String? url;
  final double? minPrice;
  final double? maxPrice;
  final String? currency;
  final int totalTickets;
  final String? seriesId;
  final String? seriesName;
  final String? firstAttractionId;
  final List<PriceRange>? priceRanges;

  factory Event.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List?) ?? [];
    final imageUrl = images.isNotEmpty ? images[0]['url'] as String? : null;
    final venues = (json['_embedded']?['venues'] as List?) ?? [];
    final dateString = json['dates']?['start']?['localDate'] as String?;
    DateTime? parsedDate;
    if (dateString != null) {
      parsedDate = DateTime.tryParse(dateString);
    }
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
      totalTickets: 100,
      seriesId: seriesId,
      seriesName: seriesName,
      firstAttractionId: firstAttractionId,
      priceRanges: priceRanges,
    );
  }

  String get dateFormatted {
    if (date == null) {
      return 'Date TBA';
    }
    return '${date!.day}/${date!.month}/${date!.year}';
  }

  /// Check if the event is expired (date has passed)
  bool get isExpired {
    if (date == null) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDateOnly = DateTime(date!.year, date!.month, date!.day);
    return eventDateOnly.isBefore(today);
  }

  /// Check if the event is current (not expired)
  bool get isCurrent => !isExpired;
}
