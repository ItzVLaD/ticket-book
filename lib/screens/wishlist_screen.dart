import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tickets_booking/providers/event_provider.dart';
import 'package:tickets_booking/providers/wishlist_provider.dart';
import 'package:tickets_booking/screens/event_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = context.watch<WishlistProvider>();
    final eventsProvider = context.watch<EventsProvider>();

    final wishlistedEvents =
        eventsProvider.events
            .where((event) => wishlistProvider.wishlist.contains(event.id))
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Вішліст')),
      body:
          wishlistedEvents.isEmpty
              ? const Center(child: Text("Ваш вішліст порожній"))
              : ListView.builder(
                itemCount: wishlistedEvents.length,
                itemBuilder: (_, index) {
                  final event = wishlistedEvents[index];
                  return ListTile(
                    leading:
                        event.imageUrl != null
                            ? Image.network(event.imageUrl!, width: 50, fit: BoxFit.cover)
                            : null,
                    title: Text(event.name),
                    subtitle: Text(event.venue ?? 'Невідоме місце'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
                      );
                    },
                  );
                },
              ),
    );
  }
}
