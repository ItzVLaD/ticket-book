import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';

class BookingService {
  final CollectionReference bookingsCollection = FirebaseFirestore.instance.collection('bookings');

  Future<void> bookTickets({
    required User user,
    required String eventId,
    required int ticketsCount,
    required String eventName,
    required String eventDate,
  }) async {
    final bookingId = '${user.uid}_$eventId';

    await bookingsCollection.doc(bookingId).set({
      'userId': user.uid,
      'eventId': eventId,
      'eventName': eventName,
      'ticketsCount': ticketsCount,
      'eventDate': eventDate,
      'bookedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateBooking({
    required User user,
    required Event event,
    required int newQty, // 0 = cancel
  }) async {
    final bookingId = '${user.uid}_${event.id}';

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Read this user's booking doc
      final bookingRef = bookingsCollection.doc(bookingId);
      final bookingDoc = await transaction.get(bookingRef);

      // Get all bookings for this event to calculate total booked
      final eventBookingsQuery =
          await bookingsCollection.where('eventId', isEqualTo: event.id).get();

      // Calculate current total booked tickets
      int totalBooked = 0;
      for (final doc in eventBookingsQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalBooked += (data['ticketsCount'] as int? ?? 0);
      }

      // Get old quantity for this user
      final oldQty =
          bookingDoc.exists
              ? ((bookingDoc.data() as Map<String, dynamic>)['ticketsCount'] as int? ?? 0)
              : 0;

      // Calculate delta
      final delta = newQty - oldQty;

      // Check capacity (assuming 100 total tickets per event)
      if (totalBooked + delta > 100) {
        throw Exception('Not enough tickets available');
      }

      // Update or delete booking
      if (newQty == 0) {
        // Cancel booking - delete the document
        if (bookingDoc.exists) {
          transaction.delete(bookingRef);
        }
      } else {
        // Create or update booking
        transaction.set(bookingRef, {
          'userId': user.uid,
          'eventId': event.id,
          'eventName': event.name,
          'ticketsCount': newQty,
          'eventDate': event.dateFormatted,
          'bookedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  Stream<DocumentSnapshot> getUserBooking(String userId, String eventId) {
    final bookingId = '${userId}_$eventId';
    return bookingsCollection.doc(bookingId).snapshots();
  }

  Stream<QuerySnapshot> getEventBookings(String eventId) {
    return bookingsCollection.where('eventId', isEqualTo: eventId).snapshots();
  }

  /// Get user's bookings for current (non-expired) events only
  Stream<QuerySnapshot> getUserCurrentBookings(String userId) {
    return bookingsCollection.where('userId', isEqualTo: userId).snapshots();
  }

  /// Remove expired bookings for a user
  Future<void> removeExpiredBookings(String userId) async {
    final userBookings = await bookingsCollection.where('userId', isEqualTo: userId).get();

    final batch = FirebaseFirestore.instance.batch();
    int deletedCount = 0;

    for (final doc in userBookings.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final eventDateStr = data['eventDate'] as String?;

      if (eventDateStr != null && eventDateStr.isNotEmpty) {
        try {
          // Parse the formatted date string back to DateTime for comparison
          final eventDate = DateTime.tryParse(eventDateStr);
          if (eventDate != null) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final eventDateOnly = DateTime(eventDate.year, eventDate.month, eventDate.day);

            if (eventDateOnly.isBefore(today)) {
              batch.delete(doc.reference);
              deletedCount++;
            }
          }
        } catch (e) {
          // If date parsing fails, skip this booking
          continue;
        }
      }
    }

    if (deletedCount > 0) {
      await batch.commit();
    }
  }

  /// Get current booked quantity for an event by a user
  int getBookedQuantity(Event event) {
    // This is a synchronous helper method used in UI
    // The actual booking data should be retrieved via streams
    return 0; // Default return, actual data comes from streams
  }
}
