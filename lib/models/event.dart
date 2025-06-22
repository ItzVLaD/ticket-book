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
    this.category,
    this.latitude,
    this.longitude,
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
  final String? category;
  final double? latitude;
  final double? longitude;

  factory Event.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List?) ?? [];
    final imageUrl = images.isNotEmpty ? images[0]['url'] as String? : null;
    final venues = (json['_embedded']?['venues'] as List?) ?? [];

    // Extract venue and location information
    String? venueName;
    String? cityName;
    String? stateName;
    String? countryName;
    double? latitude;
    double? longitude;

    if (venues.isNotEmpty) {
      final venue = venues[0] as Map<String, dynamic>;
      venueName = venue['name'] as String?;

      // Extract coordinates
      final location = venue['location'] as Map<String, dynamic>?;
      if (location != null) {
        latitude = double.tryParse(location['latitude']?.toString() ?? '');
        longitude = double.tryParse(location['longitude']?.toString() ?? '');
      }

      // Extract city information
      final city = venue['city'] as Map<String, dynamic>?;
      if (city != null) {
        cityName = city['name'] as String?;
      }

      // Extract state information
      final state = venue['state'] as Map<String, dynamic>?;
      if (state != null) {
        stateName = state['name'] as String?;
      }

      // Extract country information
      final country = venue['country'] as Map<String, dynamic>?;
      if (country != null) {
        countryName = country['name'] as String?;
      }
    }

    // Build city string with available location info
    String? fullCityLocation;
    if (cityName != null) {
      final locationParts = <String>[cityName];
      if (stateName != null) {
        locationParts.add(stateName);
      }
      if (countryName != null) {
        locationParts.add(countryName);
      }
      fullCityLocation = locationParts.join(', ');
    }

    // Extract category and genre from classifications
    String? category;
    String? genre;
    final classifications = (json['classifications'] as List?) ?? [];
    if (classifications.isNotEmpty) {
      final primaryClassification = classifications[0] as Map<String, dynamic>;
      final segment = primaryClassification['segment'] as Map<String, dynamic>?;
      final genreData = primaryClassification['genre'] as Map<String, dynamic>?;

      category = segment?['name'] as String?;
      genre = genreData?['name'] as String?;
    }

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
      venue: venueName,
      city: fullCityLocation,
      date: parsedDate,
      totalTickets: 100,
      seriesId: seriesId,
      seriesName: seriesName,
      firstAttractionId: firstAttractionId,
      priceRanges: priceRanges,
      category: category,
      genre: genre,
      url: json['url'] as String?,
      latitude: latitude,
      longitude: longitude,
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

  /// Check if this event has pricing information from the API
  bool get hasApiPricing {
    // Check priceRanges first
    if (priceRanges?.isNotEmpty == true) {
      final priceRange = priceRanges!.first;
      if (priceRange.min != null || priceRange.max != null) {
        return true;
      }
    }
    // Check individual price fields
    return minPrice != null || maxPrice != null;
  }

  /// Get the primary currency for this event (for generating prices if needed)
  String get effectiveCurrency {
    // Try priceRanges first
    if (priceRanges?.isNotEmpty == true) {
      return priceRanges!.first.currency;
    }
    // Fall back to currency field or USD
    return currency ?? 'USD';
  }
}
