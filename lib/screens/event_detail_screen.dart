import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tickets_booking/models/event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tickets_booking/providers/event_provider.dart';
import 'package:tickets_booking/providers/wishlist_provider.dart';
import 'package:tickets_booking/providers/auth_provider.dart';
import 'package:tickets_booking/services/booking_service.dart';
import 'package:tickets_booking/widgets/quantity_picker.dart';
import 'package:tickets_booking/generated/l10n.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _descExpanded = false;
  int _localQuantity = 1;
  bool _isBookingInProgress = false;
  bool _hasInitializedQuantity = false; // Add flag to track initialization
  final BookingService _bookingService = BookingService();

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final wishlist = context.watch<WishlistProvider>();
    final provider = context.watch<EventsProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

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
                    child: event.imageUrl != null
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
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7),
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
                    // Live availability display
                    StreamBuilder<QuerySnapshot>(
                      stream: _bookingService.getEventBookings(event.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 8),
                              Text('Loading availability...'),
                            ],
                          );
                        }
                        
                        if (snapshot.hasError || !snapshot.hasData) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('100 tickets left'),
                              const SizedBox(height: 16),
                            ],
                          );
                        }

                        // Calculate total booked tickets
                        int totalBooked = 0;
                        for (final doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          totalBooked += (data['ticketsCount'] as int? ?? 0);
                        }
                        
                        final ticketsLeft = 100 - totalBooked;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$ticketsLeft tickets left'),
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
                          constraints: _descExpanded
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
                                onTap: () => Navigator.push(
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
                    const SizedBox(height: 100), // Space for bottom footer
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
      bottomSheet: user != null ? _buildBookingFooter(context, user) : null,
    );
  }

  Widget _buildBookingFooter(BuildContext context, user) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return StreamBuilder<DocumentSnapshot>(
      stream: _bookingService.getUserBooking(user.uid, widget.event.id),
      builder: (context, userBookingSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: _bookingService.getEventBookings(widget.event.id),
          builder: (context, eventBookingsSnapshot) {
            // Calculate tickets left
            int ticketsLeft = 100;
            if (eventBookingsSnapshot.hasData) {
              int totalBooked = 0;
              for (final doc in eventBookingsSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                totalBooked += (data['ticketsCount'] as int? ?? 0);
              }
              ticketsLeft = 100 - totalBooked;
            }

            // Get user's current booking
            int oldQty = 0;
            bool hasExistingBooking = false;
            if (userBookingSnapshot.hasData && userBookingSnapshot.data!.exists) {
              final data = userBookingSnapshot.data!.data() as Map<String, dynamic>;
              oldQty = data['ticketsCount'] as int? ?? 0;
              hasExistingBooking = true;
              // Initialize local quantity to current booking on first load
              if (!_hasInitializedQuantity) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    _localQuantity = oldQty;
                    _hasInitializedQuantity = true;
                  });
                });
              }
            } else if (!_hasInitializedQuantity) {
              // No existing booking, start with 1
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _localQuantity = 1;
                  _hasInitializedQuantity = true;
                });
              });
            }

            // Calculate max allowed quantity
            final availableToAdd = ticketsLeft + oldQty; // Include user's current booking
            final maxQuantity = availableToAdd < 10 ? availableToAdd : 10;

            // Determine CTA button state
            String ctaLabel;
            bool ctaEnabled;
            
            if (!hasExistingBooking) {
              if (_localQuantity == 0) {
                ctaLabel = 'Select tickets';
                ctaEnabled = false;
              } else {
                ctaLabel = 'Book tickets';
                ctaEnabled = true;
              }
            } else {
              if (_localQuantity == oldQty) {
                ctaLabel = 'Booked ✓';
                ctaEnabled = false;
              } else if (_localQuantity == 0) {
                ctaLabel = 'Cancel booking';
                ctaEnabled = true;
              } else {
                ctaLabel = 'Update booking';
                ctaEnabled = true;
              }
            }

            return Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    QuantityPicker(
                      quantity: _localQuantity,
                      minQuantity: hasExistingBooking ? 0 : 1, // Allow 0 only if user has existing booking
                      maxQuantity: maxQuantity,
                      onDecrement: !_isBookingInProgress && 
                                  _localQuantity > (hasExistingBooking ? 0 : 1)
                          ? () => setState(() => _localQuantity--)
                          : null,
                      onIncrement: _localQuantity < maxQuantity && 
                                  ticketsLeft > 0 && 
                                  !_isBookingInProgress
                          ? () => setState(() => _localQuantity++)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: ctaEnabled && !_isBookingInProgress 
                            ? () => _handleBookingAction()
                            : null,
                        child: _isBookingInProgress
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(ctaLabel),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleBookingAction() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isBookingInProgress = true);

    try {
      await _bookingService.updateBooking(
        user: user,
        event: widget.event,
        newQty: _localQuantity,
      );

      if (mounted) {
        String message;
        if (_localQuantity == 0) {
          message = 'Booking cancelled successfully';
        } else {
          message = 'Booking updated successfully';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBookingInProgress = false);
      }
    }
  }
}
