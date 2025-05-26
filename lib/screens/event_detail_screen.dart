import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tickets_booking/models/event.dart';
import 'package:tickets_booking/providers/auth_provider.dart';
import 'package:tickets_booking/providers/wishlist_provider.dart';
import 'package:tickets_booking/services/booking_service.dart';
import 'package:tickets_booking/generated/l10n.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(event.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            event.imageUrl != null
                ? Image.network(event.imageUrl!)
                : Container(height: 200, color: Colors.grey),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.name, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 10),
                  Text(event.venue ?? 'Невідоме місце'),
                  const SizedBox(height: 10),
                  Text(
                    event.dateFormatted.isNotEmpty
                        ? event.dateFormatted
                        : S.of(context).noEventsFound,
                  ),
                  const SizedBox(height: 20),
                  Text(event.description ?? 'Немає опису'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _bookTickets(context, event);
                    },
                    child: const Text("Забронювати квитки"),
                  ),
                  Consumer<WishlistProvider>(
                    builder: (context, wishlistProvider, child) {
                      final isWishlisted = wishlistProvider.isInWishlist(event.id);
                      return ElevatedButton.icon(
                        onPressed: () {
                          wishlistProvider.toggleWishlist(event.id);
                        },
                        icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border),
                        label: Text(isWishlisted ? 'У бажаному' : 'Додати в бажане'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _bookTickets(BuildContext context, Event event) async {
    final user = context.read<AuthProvider>().user;

    if (user == null) return;

    final bookingService = BookingService();

    await bookingService.bookTickets(
      user: user,
      eventId: event.id,
      eventName: event.name,
      ticketsCount: 1,
      eventDate: event.dateFormatted,
    );

    if (context.mounted) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Бронювання"),
              content: Text("Ви успішно забронювали квиток на ${event.name}!"),
              actions: [
                TextButton(child: const Text("ОК"), onPressed: () => Navigator.pop(context)),
              ],
            ),
      );
    }
  }
}
