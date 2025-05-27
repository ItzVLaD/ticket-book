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
}
