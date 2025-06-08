import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/wishlist_provider.dart';
import '../screens/event_detail_screen.dart';
import '../widgets/event_card.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key, this.onNavigateToHome});

  final VoidCallback? onNavigateToHome;

  @override
  WishlistScreenState createState() => WishlistScreenState();
}

class WishlistScreenState extends State<WishlistScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final wishProvider = context.read<WishlistProvider>();
    final eventsProvider = context.read<EventsProvider>();

    // Load wishlist IDs
    await wishProvider.loadWishlist();

    // Ensure events are loaded before filtering
    if (eventsProvider.events.isEmpty && !eventsProvider.isLoading) {
      await eventsProvider.loadEvents();
    }

    setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    final wishProvider = context.read<WishlistProvider>();
    final eventsProvider = context.read<EventsProvider>();

    // Refresh both wishlist and events
    await Future.wait([wishProvider.loadWishlist(), eventsProvider.refresh()]);
  }

  void _removeItem(String eventId) {
    context.read<WishlistProvider>().toggleWishlist(eventId);
  }

  @override
  Widget build(BuildContext context) => Consumer2<WishlistProvider, EventsProvider>(
    builder: (context, wishProvider, eventsProvider, child) {
      final wishlistItems = wishProvider.wishlist;
      final allEvents = eventsProvider.events;
      final filteredEvents = allEvents.where((e) => wishlistItems.contains(e.id)).toList();

      return Scaffold(
        appBar: AppBar(
          title: const Text('My Wishlist'),
          elevation: 0,
          actions: [
            if (wishlistItems.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Wishlist Tips'),
                          content: const Text(
                            '• Tap any event to view details\n'
                            '• Swipe right to remove from wishlist\n'
                            '• Pull down to refresh your wishlist',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Got it'),
                            ),
                          ],
                        ),
                  );
                },
              ),
          ],
        ),
        body:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : filteredEvents.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = filteredEvents[index];
                      return Dismissible(
                        key: ValueKey(event.id),
                        direction: DismissDirection.startToEnd,
                        onDismissed: (_) => _removeItem(event.id),
                        confirmDismiss:
                            (direction) async => showDialog(
                              context: context,
                              builder:
                                  (BuildContext context) => AlertDialog(
                                    title: const Text('Remove from Wishlist'),
                                    content: Text('Remove "${event.name}" from your wishlist?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Theme.of(context).colorScheme.error,
                                        ),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                            ),
                        background: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete, color: Colors.white, size: 28),
                              SizedBox(height: 4),
                              Text(
                                'Remove',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        child: EventCard(
                          event: event,
                          heroTagSuffix: 'wishlist', // Add unique suffix for wishlist screen
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
      );
    },
  );

  Widget _buildEmptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.error.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your wishlist is empty',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Start exploring events and add your favorites here!',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              // Navigate to home tab if callback is available, otherwise pop
              if (widget.onNavigateToHome != null) {
                widget.onNavigateToHome!();
              } else {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.explore),
            label: const Text('Explore Events'),
          ),
        ],
      ),
    ),
  );
}
