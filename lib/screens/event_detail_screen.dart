import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tickets_booking/models/event.dart';
import 'package:tickets_booking/providers/wishlist_provider.dart';
import 'package:tickets_booking/providers/auth_provider.dart';
import 'package:tickets_booking/services/ticketmaster_service.dart';
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
  int _bookedCount = 0;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final wishlist = context.watch<WishlistProvider>();
    final isWish = wishlist.isInWishlist(event.id);
    final available = (event.totalTickets - _bookedCount).clamp(0, event.totalTickets);
    final percent = event.totalTickets > 0 ? available / event.totalTickets : 0.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            leading: BackButton(color: Theme.of(context).colorScheme.onBackground),
            actions: [
              IconButton(
                icon: Icon(isWish ? Icons.favorite : Icons.favorite_border),
                onPressed: () => wishlist.toggleWishlist(event.id),
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // TODO: integrate share plugin
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(S.of(context).shareFeatureComingSoon)));
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'event_${event.id}',
                child:
                    event.imageUrl != null
                        ? Image.network(event.imageUrl!, fit: BoxFit.cover)
                        : Container(color: Theme.of(context).colorScheme.surface),
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
                    Chip(
                      label: Text(S.of(context).priceRange),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: percent),
                    const SizedBox(height: 4),
                    Text('${available} ${S.of(context).ticketsLeft}'),
                    const SizedBox(height: 16),
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
                      child: Text(_descExpanded ? S.of(context).showLess : S.of(context).showMore),
                    ),
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
                      child: FutureBuilder<List<Event>>(
                        future: TicketmasterService().fetchEvents(keyword: event.name),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final list = snap.data!;
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final e = list[i];
                              return Padding(
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
