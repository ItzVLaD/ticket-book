import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tickets_booking/models/event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tickets_booking/providers/event_provider.dart';
import 'package:tickets_booking/providers/wishlist_provider.dart';
import 'package:tickets_booking/providers/auth_provider.dart';
import 'package:tickets_booking/services/booking_service.dart';
import 'package:tickets_booking/generated/l10n.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _descExpanded = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final wishlist = context.watch<WishlistProvider>();
    final provider = context.watch<EventsProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            automaticallyImplyLeading: false,
            actions: [],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'event_${event.id}',
                    child:
                        event.imageUrl != null
                            ? Image.network(event.imageUrl!, fit: BoxFit.cover)
                            : Container(color: Theme.of(context).colorScheme.surface),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 8,
                    child: IconButton.filledTonal(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    right: 8,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            wishlist.isInWishlist(event.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                          ),
                          onPressed: () => wishlist.toggleWishlist(event.id),
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        IconButton(
                          icon: Icon(Icons.share, color: Theme.of(context).colorScheme.onSurface),
                          onPressed: () {
                            // TODO: integrate share plugin
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(S.of(context).shareFeatureComingSoon)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.name, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    if (event.dateFormatted.isNotEmpty)
                      Text(event.dateFormatted, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    if (event.venue != null)
                      Chip(
                        avatar: const Icon(Icons.location_on, size: 20),
                        label: Text(event.venue!),
                      ),
                    const SizedBox(height: 16),
                    // Price banner
                    if (event.priceRanges?.isNotEmpty == true) ...[
                      FilledButton.tonal(
                        onPressed: () {},
                        child: Text(() {
                          final p = event.priceRanges!.first;
                          if (p.min != null && p.max != null && p.min != p.max) {
                            return '${p.min} – ${p.max} ${p.currency}';
                          }
                          final single = p.min ?? p.max;
                          return '$single ${p.currency}';
                        }()),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Tickets availability
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.doc('events/${event.id}').snapshots(),
                      builder: (context, snap) {
                        // Show unknown availability while loading
                        if (snap.connectionState == ConnectionState.waiting) {
                          return Column(
                            children: [
                              Text('Availability unknown'),
                              LinearProgressIndicator(value: 0),
                              const SizedBox(height: 16),
                            ],
                          );
                        }
                        if (snap.hasError || snap.data == null) {
                          return Column(
                            children: [
                              Text('Availability unknown'),
                              LinearProgressIndicator(value: 0),
                              const SizedBox(height: 16),
                            ],
                          );
                        }
                        final doc = snap.data!;
                        if (!doc.exists) {
                          return Column(
                            children: [
                              Text('Availability unknown'),
                              LinearProgressIndicator(value: 0),
                              const SizedBox(height: 16),
                            ],
                          );
                        }
                        // Access availableTickets safely
                        final data = doc.data() as Map<String, dynamic>?;
                        final avail = data?['availableTickets'] as int?;
                        if (avail == null) {
                          return Column(
                            children: [
                              Text('Availability unknown'),
                              LinearProgressIndicator(value: 0),
                              const SizedBox(height: 16),
                            ],
                          );
                        }
                        final total = event.totalTickets;
                        final ratio = total > 0 ? avail / total : 0.0;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(value: ratio),
                            const SizedBox(height: 4),
                            Text('$avail tickets left'),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
                    // Description with show more/less
                    if (event.description?.trim().isNotEmpty == true) ...[
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        child: ConstrainedBox(
                          constraints:
                              _descExpanded
                                  ? const BoxConstraints()
                                  : const BoxConstraints(maxHeight: 100),
                          child: Text(
                            event.description ?? '',
                            softWrap: true,
                            overflow: TextOverflow.fade,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _descExpanded = !_descExpanded),
                        child: Text(
                          _descExpanded ? S.of(context).showLess : S.of(context).showMore,
                        ),
                      ),
                    ],
                    if (event.seatMapUrl != null) ...[
                      const SizedBox(height: 16),
                      Image.network(event.seatMapUrl!),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      S.of(context).similarEvents,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(
                      height: 180,
                      child: Builder(
                        builder: (ctx) {
                          // find current group and similar events
                          final group = provider.groupedEvents.firstWhere(
                            (g) => g.schedules.any((e) => e.id == event.id),
                          );
                          final similar = provider.similarEventsFor(group);
                          if (similar.isEmpty) return Center(child: Text('No similar events'));
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: similar.length,
                            itemBuilder: (_, i) {
                              final e = similar[i];
                              return InkWell(
                                onTap:
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EventDetailScreen(event: e),
                                      ),
                                    ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SizedBox(
                                    width: 140,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        e.imageUrl != null
                                            ? Image.network(
                                              e.imageUrl!,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            )
                                            : Container(
                                              height: 80,
                                              color: Theme.of(context).colorScheme.surface,
                                            ),
                                        const SizedBox(height: 8),
                                        Text(e.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const Spacer(),
                                        Text(
                                          e.dateFormatted,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ]),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => _showBookingSheet(context),
                  child: Text(S.of(context).bookTickets),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingSheet(BuildContext context) {
    int qty = 1;
    final auth = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (c, setc) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    S.of(context).selectQuantity,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: qty > 1 ? () => setc(() => qty--) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text(qty.toString(), style: Theme.of(context).textTheme.headlineMedium),
                      IconButton(
                        onPressed: qty < 6 ? () => setc(() => qty++) : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(S.of(context).cancel),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final user = auth.user;
                            if (user == null) return;
                            await BookingService().bookTickets(
                              user: user,
                              eventId: widget.event.id,
                              ticketsCount: qty,
                              eventName: widget.event.name,
                              eventDate: widget.event.dateFormatted,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(S.of(context).bookingSuccess(widget.event.name)),
                                ),
                              );
                            }
                          },
                          child: Text(S.of(context).confirm),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
