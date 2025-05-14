import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
}
