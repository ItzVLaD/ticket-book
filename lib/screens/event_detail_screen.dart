import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../generated/l10n.dart';
import '../models/event.dart';
import '../models/event_group.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/booking_service.dart';
import '../widgets/quantity_picker.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  final EventGroup? eventGroup; // Optional: for grouped events with multiple venues/dates

  const EventDetailScreen({super.key, required this.event, this.eventGroup});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _descExpanded = false;
  int? _localQuantity;
  bool _isBookingInProgress = false;
  final BookingService _bookingService = BookingService();

  // For grouped events: track selected event variation
  late Event _selectedEvent;

  @override
  void initState() {
    super.initState();
    _selectedEvent = widget.event; // Initialize with the passed event
  }

  // Venue selector widget for grouped events
  Widget _buildVenueSelector(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Event>(
          value: _selectedEvent,
          icon: Icon(Icons.expand_more, color: colorScheme.onSurfaceVariant),
          isExpanded: true,
          items:
              widget.eventGroup!.currentSchedules.map((event) {
                // Use only current events
                String displayText;
                if (event.dateFormatted.isNotEmpty && event.venue != null) {
                  displayText = '${event.dateFormatted} • ${event.venue}';
                } else if (event.dateFormatted.isNotEmpty) {
                  displayText = event.dateFormatted;
                } else if (event.venue != null) {
                  displayText = event.venue!;
                } else {
                  displayText = 'Event ${widget.eventGroup!.schedules.indexOf(event) + 1}';
                }

                return DropdownMenuItem<Event>(
                  value: event,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (event.priceRanges?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          () {
                            final p = event.priceRanges!.first;
                            if (p.min != null && p.max != null && p.min != p.max) {
                              return '${p.min} – ${p.max} ${p.currency}';
                            }
                            final single = p.min ?? p.max;
                            return '$single ${p.currency}';
                          }(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
          onChanged: (Event? newEvent) {
            if (newEvent != null) {
              setState(() {
                _selectedEvent = newEvent;
                // Reset quantity when switching events
                _localQuantity = _bookingService.getBookedQuantity(_selectedEvent);
              });
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final wishlist = context.watch<WishlistProvider>();
    final provider = context.watch<EventsProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 350,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'event_${event.id}',
                    child:
                        event.imageUrl != null
                            ? Image.network(
                              event.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Container(
                                    color: colorScheme.surfaceVariant,
                                    child: Icon(
                                      Icons.event,
                                      size: 64,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                            )
                            : Container(
                              color: colorScheme.surfaceVariant,
                              child: Icon(
                                Icons.event,
                                size: 64,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                  ),
                  // Gradient overlay for better text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.0, 0.3, 1.0],
                      ),
                    ),
                  ),
                  // Navigation and action buttons
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.transparent),
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    right: 16,
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              wishlist.isInWishlist(event.id)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: wishlist.isInWishlist(event.id) ? Colors.red : Colors.white,
                            ),
                            onPressed: () => wishlist.toggleWishlist(event.id),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.share, color: Colors.white),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(S.of(context).shareFeatureComingSoon),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event title and basic info
                    Text(
                      event.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Venue/Date Selection Dropdown for Grouped Events
                    if (widget.eventGroup != null && widget.eventGroup!.schedules.length > 1) ...[
                      _buildVenueSelector(colorScheme, theme),
                      const SizedBox(height: 16),
                    ],

                    // Date and venue info cards (now showing _selectedEvent instead of event)
                    Row(
                      children: [
                        if (_selectedEvent.dateFormatted.isNotEmpty) ...[
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: colorScheme.onPrimaryContainer,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedEvent.dateFormatted,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (_selectedEvent.venue != null && _selectedEvent.dateFormatted.isNotEmpty)
                          const SizedBox(width: 12),
                        if (_selectedEvent.venue != null) ...[
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: colorScheme.onSecondaryContainer,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedEvent.venue!,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSecondaryContainer,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Price banner (updated to use _selectedEvent)
                    if (_selectedEvent.priceRanges?.isNotEmpty == true) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.confirmation_number, color: colorScheme.onPrimary, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              () {
                                final p = _selectedEvent.priceRanges!.first;
                                if (p.min != null && p.max != null && p.min != p.max) {
                                  return '${p.min} – ${p.max} ${p.currency}';
                                }
                                final single = p.min ?? p.max;
                                return '$single ${p.currency}';
                              }(),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Live availability display (updated to use _selectedEvent)
                    StreamBuilder<QuerySnapshot>(
                      stream: _bookingService.getEventBookings(_selectedEvent.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Card(
                            elevation: 0,
                            color: colorScheme.surfaceVariant,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Loading availability...',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError || !snapshot.hasData) {
                          return _buildAvailabilityCard(100, theme, colorScheme);
                        }

                        int totalBooked = 0;
                        for (final doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          totalBooked += (data['ticketsCount'] as int? ?? 0);
                        }

                        final ticketsLeft = 100 - totalBooked;
                        return _buildAvailabilityCard(ticketsLeft, theme, colorScheme);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Description section
                    if (event.description?.trim().isNotEmpty == true) ...[
                      Text(
                        'About This Event',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              child: ConstrainedBox(
                                constraints:
                                    _descExpanded
                                        ? const BoxConstraints()
                                        : const BoxConstraints(maxHeight: 120),
                                child: Text(
                                  event.description ?? '',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurface,
                                    height: 1.6,
                                  ),
                                  softWrap: true,
                                  overflow: TextOverflow.fade,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () => setState(() => _descExpanded = !_descExpanded),
                              icon: Icon(
                                _descExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              ),
                              label: Text(
                                _descExpanded ? S.of(context).showLess : S.of(context).showMore,
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.primary,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Similar events section
                    Text(
                      S.of(context).similarEvents,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: Builder(
                        builder: (ctx) {
                          // Safely find the group, handle case where event might not be in grouped events
                          EventGroup? group;
                          try {
                            group = provider.groupedEvents.firstWhere(
                              (g) => g.schedules.any((e) => e.id == event.id),
                            );
                          } catch (e) {
                            // Event not found in grouped events (e.g., from search results)
                            group = null;
                          }

                          final similar =
                              group != null ? provider.similarEventsFor(group) : <Event>[];

                          if (similar.isEmpty) {
                            return Center(
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.event_busy,
                                      color: colorScheme.onSurfaceVariant,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No similar events',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            itemCount: similar.length,
                            itemBuilder: (_, i) {
                              final e = similar[i];
                              return Container(
                                width: 160,
                                margin: const EdgeInsets.only(right: 16),
                                child: InkWell(
                                  onTap:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EventDetailScreen(event: e),
                                        ),
                                      ),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.shadow.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(16),
                                          ),
                                          child:
                                              e.imageUrl != null
                                                  ? Image.network(
                                                    e.imageUrl!,
                                                    height: 100,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (context, error, stackTrace) => Container(
                                                          height: 100,
                                                          color: colorScheme.surfaceVariant,
                                                          child: Icon(
                                                            Icons.event,
                                                            color: colorScheme.onSurfaceVariant,
                                                          ),
                                                        ),
                                                  )
                                                  : Container(
                                                    height: 100,
                                                    color: colorScheme.surfaceVariant,
                                                    child: Icon(
                                                      Icons.event,
                                                      color: colorScheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                e.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                e.dateFormatted,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
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
                    const SizedBox(height: 120), // Space for bottom footer
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: user != null ? _buildBookingFooter(context, user) : null,
    );
  }

  Widget _buildAvailabilityCard(int ticketsLeft, ThemeData theme, ColorScheme colorScheme) {
    final isLowStock = ticketsLeft <= 10;
    final isSoldOut = ticketsLeft <= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            isSoldOut
                ? colorScheme.errorContainer
                : isLowStock
                ? colorScheme.tertiaryContainer
                : colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isSoldOut
                  ? colorScheme.error
                  : isLowStock
                  ? colorScheme.tertiary
                  : colorScheme.primary,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  isSoldOut
                      ? colorScheme.error
                      : isLowStock
                      ? colorScheme.tertiary
                      : colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isSoldOut
                  ? Icons.event_busy
                  : isLowStock
                  ? Icons.warning
                  : Icons.confirmation_number,
              color:
                  isSoldOut
                      ? colorScheme.onError
                      : isLowStock
                      ? colorScheme.onTertiary
                      : colorScheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSoldOut ? 'Sold Out' : '$ticketsLeft tickets left',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        isSoldOut
                            ? colorScheme.onErrorContainer
                            : isLowStock
                            ? colorScheme.onTertiaryContainer
                            : colorScheme.onSurface,
                  ),
                ),
                if (isLowStock && !isSoldOut)
                  Text(
                    'Hurry up! Limited tickets available',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingFooter(BuildContext context, user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<DocumentSnapshot>(
      stream: _bookingService.getUserBooking(user.uid, _selectedEvent.id),
      builder:
          (context, userBookingSnapshot) => StreamBuilder<QuerySnapshot>(
            stream: _bookingService.getEventBookings(_selectedEvent.id),
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
              }

              // Initialize _localQuantity based on current booking state
              _localQuantity ??= hasExistingBooking ? oldQty : 1;

              // Calculate max allowed quantity
              final availableToAdd = ticketsLeft + oldQty;
              final maxQuantity = availableToAdd < 10 ? availableToAdd : 10;

              // Determine CTA button state
              String ctaLabel;
              bool ctaEnabled;

              // Check if the selected event is expired
              final isEventExpired = _selectedEvent.isExpired;

              if (isEventExpired) {
                ctaLabel = 'Event Expired';
                ctaEnabled = false;
              } else if (!hasExistingBooking) {
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QuantityPicker(
                          quantity: _localQuantity!,
                          minQuantity: hasExistingBooking ? 0 : 1,
                          maxQuantity: maxQuantity,
                          onDecrement:
                              !_isBookingInProgress &&
                                      _localQuantity! > (hasExistingBooking ? 0 : 1)
                                  ? () => setState(() => _localQuantity = _localQuantity! - 1)
                                  : null,
                          onIncrement:
                              _localQuantity! < maxQuantity &&
                                      ticketsLeft > 0 &&
                                      !_isBookingInProgress
                                  ? () => setState(() => _localQuantity = _localQuantity! + 1)
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed:
                              ctaEnabled && !_isBookingInProgress
                                  ? () => _handleBookingAction()
                                  : null,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child:
                              _isBookingInProgress
                                  ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.onPrimary,
                                    ),
                                  )
                                  : Text(
                                    ctaLabel,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Future<void> _handleBookingAction() async {
    setState(() => _isBookingInProgress = true);
    try {
      final user = context.read<AuthProvider>().user!;

      // Use updateBooking method with the selected event for grouped events
      await _bookingService.updateBooking(
        user: user,
        event: _selectedEvent,
        newQty: _localQuantity!,
      );

      if (mounted) {
        String message;
        if (_localQuantity == 0) {
          message = 'Booking cancelled successfully';
        } else {
          message = 'Tickets booked successfully';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
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
