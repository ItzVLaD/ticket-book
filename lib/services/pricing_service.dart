import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../models/event_group.dart';

class PricingService {
  static final PricingService _instance = PricingService._internal();
  factory PricingService() => _instance;
  PricingService._internal();

  final CollectionReference _eventPricesCollection = 
      FirebaseFirestore.instance.collection('event_prices');

  /// Gets the effective price for an event, checking API first, then database, then generating new
  Future<EventPrice> getEventPrice(Event event, {EventGroup? eventGroup}) async {
    // Step 1: Check if API provides pricing
    final apiPrice = _getApiPrice(event);
    if (apiPrice != null) {
      return apiPrice;
    }

    // Step 2: Determine the ID to use for database lookup
    final priceId = eventGroup?.id ?? event.id;

    // Step 3: Check if we already have a generated price in database
    final storedPrice = await _getStoredPrice(priceId);
    if (storedPrice != null) {
      return storedPrice;
    }

    // Step 4: Generate new random price and store it
    return await _generateAndStorePrice(priceId, event);
  }

  /// Extracts price from API data if available
  EventPrice? _getApiPrice(Event event) {
    // Check priceRanges first (preferred)
    if (event.priceRanges?.isNotEmpty == true) {
      final priceRange = event.priceRanges!.first;
      final price = priceRange.min ?? priceRange.max;
      if (price != null) {
        return EventPrice(
          price: price,
          currency: priceRange.currency,
          isGenerated: false,
        );
      }
    }

    // Check minPrice/maxPrice as fallback
    if (event.minPrice != null) {
      return EventPrice(
        price: event.minPrice!,
        currency: event.currency ?? 'USD',
        isGenerated: false,
      );
    }

    if (event.maxPrice != null) {
      return EventPrice(
        price: event.maxPrice!,
        currency: event.currency ?? 'USD',
        isGenerated: false,
      );
    }

    return null;
  }

  /// Retrieves stored price from Firestore
  Future<EventPrice?> _getStoredPrice(String priceId) async {
    try {
      final doc = await _eventPricesCollection.doc(priceId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return EventPrice(
          price: (data['price'] as num).toDouble(),
          currency: data['currency'] as String,
          isGenerated: data['isGenerated'] as bool? ?? true,
        );
      }
    } catch (e) {
      // Log error but don't throw - we'll generate a new price instead
      print('Error retrieving stored price for $priceId: $e');
    }
    return null;
  }

  /// Generates random price and stores in Firestore
  Future<EventPrice> _generateAndStorePrice(String priceId, Event event) async {
    // Generate random price between $10-40
    final random = Random();
    final price = 10.0 + (random.nextDouble() * 30.0); // 10.0 to 40.0
    final roundedPrice = double.parse(price.toStringAsFixed(1));

    // Use API currency if available, otherwise USD
    final currency = event.currency ?? 'USD';

    final eventPrice = EventPrice(
      price: roundedPrice,
      currency: currency,
      isGenerated: true,
    );

    try {
      // Store in Firestore
      await _eventPricesCollection.doc(priceId).set({
        'eventId': priceId,
        'price': roundedPrice,
        'currency': currency,
        'isGenerated': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log error but still return the generated price
      print('Error storing generated price for $priceId: $e');
    }

    return eventPrice;
  }

  /// Batch method to get prices for multiple events
  Future<Map<String, EventPrice>> getEventPrices(
    List<Event> events, {
    List<EventGroup>? eventGroups,
  }) async {
    final Map<String, EventPrice> result = {};
    
    for (final event in events) {
      // Find if this event belongs to any group
      EventGroup? parentGroup;
      if (eventGroups != null) {
        try {
          parentGroup = eventGroups.firstWhere(
            (group) => group.schedules.any((e) => e.id == event.id),
          );
        } catch (e) {
          // Event not found in any group, treat as single event
          parentGroup = null;
        }
      }

      final price = await getEventPrice(event, eventGroup: parentGroup);
      result[event.id] = price;
    }

    return result;
  }
}

/// Represents the effective price for an event
class EventPrice {
  final double price;
  final String currency;
  final bool isGenerated;

  const EventPrice({
    required this.price,
    required this.currency,
    required this.isGenerated,
  });

  /// Formatted price string for display
  String get formattedPrice {
    final symbol = currency == 'USD' ? '\$' : '$currency ';
    return '$symbol${price.toStringAsFixed(1)}';
  }

  @override
  String toString() => formattedPrice;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventPrice &&
          runtimeType == other.runtimeType &&
          price == other.price &&
          currency == other.currency &&
          isGenerated == other.isGenerated;

  @override
  int get hashCode => price.hashCode ^ currency.hashCode ^ isGenerated.hashCode;
}
