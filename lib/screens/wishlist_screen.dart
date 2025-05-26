import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tickets_booking/providers/event_provider.dart';
import 'package:tickets_booking/providers/wishlist_provider.dart';
import 'package:tickets_booking/models/event.dart';
import 'package:tickets_booking/screens/event_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  WishlistScreenState createState() => WishlistScreenState();
}

class WishlistScreenState extends State<WishlistScreen> {
  late List<Event> _items;
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
    await wishProvider.loadWishlist();
    final ids = wishProvider.wishlist;
    final all = eventsProvider.events;
    _items = all.where((e) => ids.contains(e.id)).toList();
    setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    final wishProvider = context.read<WishlistProvider>();
    final eventsProvider = context.read<EventsProvider>();
    await wishProvider.loadWishlist();
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
    return GestureDetector(
      onLongPress: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Dismissible(
          key: ValueKey(event.id),
          direction: DismissDirection.startToEnd,
          onDismissed: (_) => _removeItem(index),
          background: Container(
            color: Theme.of(context).colorScheme.error,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: ListTile(
            leading:
                event.imageUrl != null
                    ? Image.network(event.imageUrl!, width: 60, fit: BoxFit.cover)
                    : Container(
                      width: 60,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
            title: Text(event.name),
            subtitle: Text(event.venue ?? ''),
            trailing: Text('\$${event.dateFormatted}'),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 80,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(50),
                    ),
                    const SizedBox(height: 16),
                    Text('Your wishlist is empty', style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final event = _items[index];
                    return _buildItem(event, index);
                  },
                ),
              ),
    );
  }
}
