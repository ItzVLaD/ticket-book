import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tickets_booking/providers/event_provider.dart';
import 'package:tickets_booking/providers/wishlist_provider.dart';
import 'package:tickets_booking/models/event.dart';
import 'package:tickets_booking/screens/event_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHome;
  
  const WishlistScreen({super.key, this.onNavigateToHome});

  @override
  WishlistScreenState createState() => WishlistScreenState();
}

class WishlistScreenState extends State<WishlistScreen> {
  List<Event> _items = []; // Initialize with empty list instead of late
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

    final ids = wishProvider.wishlist;
    final all = eventsProvider.events;
    _items = all.where((e) => ids.contains(e.id)).toList();
    setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    final wishProvider = context.read<WishlistProvider>();
    final eventsProvider = context.read<EventsProvider>();

    // Refresh both wishlist and events
    await Future.wait([wishProvider.loadWishlist(), eventsProvider.refresh()]);

    final ids = wishProvider.wishlist;
    final all = eventsProvider.events;
    setState(() {
      _items = all.where((e) => ids.contains(e.id)).toList();
    });
  }

  void _removeItem(int index) {
    final removed = _items.removeAt(index);
    context.read<WishlistProvider>().toggleWishlist(removed.id);
  }

  Widget _buildItem(Event event, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Dismissible(
        key: ValueKey(event.id),
        direction: DismissDirection.startToEnd,
        onDismissed: (_) => _removeItem(index),
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
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
              );
            },
          );
        },
        background: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete, color: Colors.white, size: 28),
              const SizedBox(height: 4),
              Text(
                'Remove',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Event Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      event.imageUrl != null
                          ? Image.network(
                            event.imageUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.event,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  size: 32,
                                ),
                              );
                            },
                          )
                          : Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.event,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 32,
                            ),
                          ),
                ),
                const SizedBox(width: 16),

                // Event Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (event.venue != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.venue!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.dateFormatted,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Favorite Icon and Arrow
                Column(
                  children: [
                    Icon(Icons.favorite, color: Theme.of(context).colorScheme.error, size: 24),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        elevation: 0,
        actions: [
          if (_items.isNotEmpty)
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
              : _items.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final event = _items[index];
                    return _buildItem(event, index);
                  },
                ),
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Start exploring events and add your favorites here!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
}
