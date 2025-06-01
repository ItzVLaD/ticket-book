import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../generated/l10n.dart';
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../providers/theme_mode_notifier.dart';
import '../providers/wishlist_provider.dart';
import '../services/ticketmaster_service.dart';
import 'event_detail_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleSwitchAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Switch Account'),
            content: const Text(
              'Do you want to switch to a different Google account? You will be signed out from the current account.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Switch Account'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<AuthProvider>().switchAccount();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to switch account: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      return;
    }

    // First confirmation dialog
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 8),
                const Text('Delete Account'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This action will permanently delete:'),
                const SizedBox(height: 12),
                _buildDeleteInfoItem(context, Icons.person, 'Your account profile'),
                _buildDeleteInfoItem(context, Icons.confirmation_number, 'All your bookings'),
                _buildDeleteInfoItem(context, Icons.favorite, 'Your wishlist'),
                _buildDeleteInfoItem(context, Icons.storage, 'All associated data'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This action cannot be undone!',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
    );

    if (firstConfirm != true) {
      return;
    }

    // Second confirmation dialog with email verification
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteAccountDialog(user: user),
    );

    if (secondConfirm == true && context.mounted) {
      try {
        await context.read<AuthProvider>().deleteAccount();
        // User will be automatically signed out and redirected to auth screen
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete account: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildDeleteInfoItem(BuildContext context, IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.error),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Center(child: Text('User not found'));
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar.medium(
          expandedHeight: 220,
          flexibleSpace: FlexibleSpaceBar(
            background: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child:
                        user.photoURL != null
                            ? ClipOval(
                              child: Image.network(
                                user.photoURL!,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                              ),
                            )
                            : Icon(
                              Icons.person,
                              size: 50,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName ?? 'No Name',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    user.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),

        // Statistics Cards
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Bookings',
                    icon: Icons.confirmation_number,
                    iconColor: Theme.of(context).colorScheme.primary,
                    stream:
                        FirebaseFirestore.instance
                            .collection('bookings')
                            .where('userId', isEqualTo: user.uid)
                            .snapshots(),
                    countField: null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _WishlistCountCard()),
              ],
            ),
          ),
        ),

        // Settings Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          'Settings',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Consumer<ThemeModeNotifier>(
                    builder:
                        (context, theme, _) => ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.brightness_6,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                          ),
                          title: Text(S.of(context).theme),
                          subtitle: Text('Current: ${theme.mode.name.capitalize()}'),
                          trailing: DropdownButton<ThemeMode>(
                            value: theme.mode,
                            items:
                                ThemeMode.values
                                    .map(
                                      (mode) => DropdownMenuItem(
                                        value: mode,
                                        child: Text(mode.name.capitalize()),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (mode) {
                              if (mode != null) {
                                context.read<ThemeModeNotifier>().setMode(mode);
                              }
                            },
                            underline: const SizedBox.shrink(),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                  ),
                  const Divider(height: 1),

                  // Sign Out Button
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.logout,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                        size: 20,
                      ),
                    ),
                    title: Text(S.of(context).logout),
                    subtitle: const Text('Sign out from current account'),
                    onTap: () => context.read<AuthProvider>().signOut(),
                  ),

                  const Divider(height: 1),

                  // Switch Account Button
                  Consumer<AuthProvider>(
                    builder:
                        (context, authProvider, _) => ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.switch_account,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                              size: 20,
                            ),
                          ),
                          title: const Text('Switch Account'),
                          subtitle: const Text('Sign in with a different Google account'),
                          trailing:
                              authProvider.isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                  : Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                          onTap:
                              authProvider.isLoading ? null : () => _handleSwitchAccount(context),
                        ),
                  ),

                  const Divider(height: 1),

                  // Delete Account Button
                  Consumer<AuthProvider>(
                    builder:
                        (context, authProvider, _) => ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.delete_forever,
                              color: Theme.of(context).colorScheme.onErrorContainer,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Delete Account',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: const Text('Permanently delete your account and all data'),
                          trailing:
                              authProvider.isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                  : Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.error.withOpacity(0.7),
                                  ),
                          onTap:
                              authProvider.isLoading ? null : () => _handleDeleteAccount(context),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Bookings Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  S.of(context).yourBookings,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        _BookingsSection(userId: user.uid),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.icon,
    required this.stream,
    this.iconColor,
    this.countField,
  });

  final String label;
  final IconData icon;
  final Color? iconColor;
  final Stream<QuerySnapshot> stream;
  final String? countField;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          final count = snap.hasData ? snap.data!.docs.length : 0;
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (iconColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: iconColor ?? Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$count',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _WishlistCountCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Consumer<WishlistProvider>(
        builder:
            (context, wish, _) => Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.favorite, size: 32, color: Colors.red),
                ),
                const SizedBox(height: 12),
                Text(
                  '${wish.wishlist.length}',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  S.of(context).wishlist,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
      ),
    ),
  );
}

class _BookingsSection extends StatelessWidget {
  const _BookingsSection({required this.userId});
  final String userId;

  Future<void> _navigateToEvent(BuildContext context, String eventId) async {
    try {
      // First, check if the event exists in the local cache
      final eventsProvider = context.read<EventsProvider>();
      Event? event;

      // Search in flat events list
      try {
        event = eventsProvider.events.firstWhere((e) => e.id == eventId);
      } catch (_) {
        // Not found in flat list, search in grouped events
        for (final group in eventsProvider.groupedEvents) {
          try {
            event = group.schedules.firstWhere((e) => e.id == eventId);
            break;
          } catch (_) {
            // Continue searching in other groups
          }
        }
      }

      // If found in cache, navigate directly without API call
      if (event != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailScreen(event: event!)),
        );
        return;
      }

      // Only make API call if event not found in cache
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Fetch event details from API as fallback
      final ticketmasterService = TicketmasterService();
      event = await ticketmasterService.fetchEventById(eventId);

      // Hide loading indicator
      if (context.mounted) {
        Navigator.pop(context);

        if (event != null) {
          // Navigate to event detail screen
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventDetailScreen(event: event!)),
          );
        } else {
          // Show error if event not found
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event details not available'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator and show error
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load event: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot>(
    stream:
        FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: userId)
            .orderBy('bookedAt', descending: true)
            .snapshots(),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
      }

      final docs = snap.data?.docs ?? [];
      if (docs.isEmpty) {
        return SliverToBoxAdapter(
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(S.of(context).noBookings, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Your booked events will appear here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Separate current and expired bookings
      final currentBookings = <QueryDocumentSnapshot>[];
      final expiredBookings = <QueryDocumentSnapshot>[];

      for (var doc in docs) {
        final data = doc.data()! as Map<String, dynamic>;
        final eventDateStr = data['eventDate'] as String?;

        bool isExpired = false;
        if (eventDateStr != null && eventDateStr.isNotEmpty) {
          try {
            final eventDate = DateTime.tryParse(eventDateStr);
            if (eventDate != null) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final eventDateOnly = DateTime(eventDate.year, eventDate.month, eventDate.day);
              isExpired = eventDateOnly.isBefore(today);
            }
          } catch (e) {
            // If date parsing fails, treat as current
          }
        }

        if (isExpired) {
          expiredBookings.add(doc);
        } else {
          currentBookings.add(doc);
        }
      }

      final sliverChildren = <Widget>[];

      // Current bookings section
      if (currentBookings.isNotEmpty) {
        sliverChildren.add(
          _buildBookingsGroup(
            context,
            'Current Bookings',
            currentBookings,
            Icons.event_available,
            false,
          ),
        );
      }

      // Expired bookings section
      if (expiredBookings.isNotEmpty) {
        sliverChildren.add(
          _buildBookingsGroup(context, 'Past Events', expiredBookings, Icons.history, true),
        );
      }

      return SliverList(delegate: SliverChildListDelegate(sliverChildren));
    },
  );

  Widget _buildBookingsGroup(
    BuildContext context,
    String title,
    List<QueryDocumentSnapshot> bookings,
    IconData icon,
    bool isExpired,
  ) {
    // Group by month-year
    final groups = <String, List<QueryDocumentSnapshot>>{};
    for (var doc in bookings) {
      final date = (doc['bookedAt'] as Timestamp).toDate();
      final key = DateFormat.yMMMM().format(date);
      groups.putIfAbsent(key, () => []).add(doc);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        initiallyExpanded: !isExpired, // Expand current bookings by default
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isExpired
                    ? Theme.of(context).colorScheme.surfaceVariant
                    : Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color:
                isExpired
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isExpired ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7) : null,
          ),
        ),
        subtitle: Text(
          '${bookings.length} booking${bookings.length == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        children:
            groups.entries.map((entry) {
              final month = entry.key;
              final items = entry.value;

              return ExpansionTile(
                leading: Icon(
                  Icons.calendar_month,
                  color:
                      isExpired
                          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                          : Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                title: Text(
                  month,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color:
                        isExpired ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7) : null,
                  ),
                ),
                subtitle: Text(
                  '${items.length} booking${items.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                children:
                    items.map((doc) {
                      final data = doc.data()! as Map<String, dynamic>;
                      final eventId = data['eventId'] as String;
                      final eventName = data['eventName'] as String? ?? 'Unknown Event';
                      final ticketsCount = data['ticketsCount'] as int? ?? 0;
                      final eventDate = data['eventDate'] as String? ?? '';

                      return ListTile(
                        onTap: isExpired ? null : () => _navigateToEvent(context, eventId),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                isExpired
                                    ? Theme.of(context).colorScheme.surfaceVariant
                                    : Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isExpired ? Icons.event_busy : Icons.event,
                            color:
                                isExpired
                                    ? Theme.of(context).colorScheme.onSurfaceVariant
                                    : Theme.of(context).colorScheme.onSecondaryContainer,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          eventName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                isExpired
                                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                    : null,
                            decoration: isExpired ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '$ticketsCount ticket${ticketsCount == 1 ? '' : 's'}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color:
                                        isExpired
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.onSurface.withOpacity(0.5)
                                            : Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (isExpired) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'EXPIRED',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onErrorContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (eventDate.isNotEmpty)
                              Text(
                                eventDate,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                          ],
                        ),
                        trailing:
                            !isExpired
                                ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ],
                                )
                                : null,
                        onLongPress:
                            !isExpired
                                ? () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (_) => AlertDialog(
                                          title: Text(S.of(context).cancelBooking),
                                          content: Text(S.of(context).confirmCancel),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: Text(S.of(context).no),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    Theme.of(context).colorScheme.error,
                                              ),
                                              child: Text(S.of(context).yes),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (confirm == true) {
                                    await doc.reference.delete();
                                  }
                                }
                                : null,
                      );
                    }).toList(),
              );
            }).toList(),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.user});

  final User user;

  @override
  _DeleteAccountDialogState createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isConfirmationValid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Final Confirmation'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Please confirm that you want to delete the account for:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage:
                    widget.user.photoURL != null ? NetworkImage(widget.user.photoURL!) : null,
                child: widget.user.photoURL == null ? const Icon(Icons.person, size: 16) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.displayName ?? 'No Name',
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      widget.user.email ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Type "DELETE" to confirm:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Type DELETE here',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (value) {
            setState(() {
              _isConfirmationValid = value.trim().toUpperCase() == 'DELETE';
            });
          },
        ),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
      FilledButton(
        onPressed: _isConfirmationValid ? () => Navigator.of(context).pop(true) : null,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        child: const Text('Delete Account'),
      ),
    ],
  );
}

extension StringExt on String {
  String capitalize() => isEmpty ? '' : this[0].toUpperCase() + substring(1);
}
