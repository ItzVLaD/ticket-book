import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tickets_booking/providers/auth_provider.dart';
import 'package:tickets_booking/providers/wishlist_provider.dart';
import 'package:tickets_booking/providers/theme_mode_notifier.dart';
import 'package:tickets_booking/generated/l10n.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Center(child: Text('User not found'));
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar.medium(
          pinned: true,
          expandedHeight: 200,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
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
                    radius: 40,
                    backgroundImage: NetworkImage(user.photoURL ?? ''),
                  ),
                  const SizedBox(height: 8),
                  Text(user.displayName ?? 'No Name', style: Theme.of(context).textTheme.titleLarge),
                  Text(user.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(child: _StatCard(label: 'Bookings', icon: Icons.book_online, stream: FirebaseFirestore.instance.collection('bookings').where('userId', isEqualTo: user.uid).snapshots(), countField: null)),
                const SizedBox(width: 16),
                Expanded(child: _WishlistCountCard()),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(S.of(context).yourBookings, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        _BookingsSection(userId: user.uid),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Divider(),
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: Text(S.of(context).theme),
                trailing: Consumer<ThemeModeNotifier>(
                  builder: (context, theme, _) => DropdownButton<ThemeMode>(
                    value: theme.mode,
                    items: ThemeMode.values.map((mode) => DropdownMenuItem(
                          value: mode,
                          child: Text(mode.name.capitalize()),
                        )).toList(),
                    onChanged: (mode) { if (mode != null) context.read<ThemeModeNotifier>().setMode(mode); },
                    underline: const SizedBox.shrink(),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(S.of(context).logout),
                onTap: () => context.read<AuthProvider>().signOut(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Stream<QuerySnapshot> stream;
  final String? countField;
  const _StatCard({required this.label, required this.icon, required this.stream, this.countField});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snap) {
            final count = snap.hasData ? snap.data!.docs.length : 0;
            return Row(
              children: [Icon(icon, size: 32), const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$count', style: Theme.of(context).textTheme.headlineMedium), Text(label)]),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WishlistCountCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<WishlistProvider>(builder: (context, wish, _) {
          return Row(
            children: [Icon(Icons.favorite, size: 32), const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${wish.wishlist.length}', style: Theme.of(context).textTheme.headlineMedium), Text(S.of(context).wishlist)]),
            ],
          );
        }),
      ),
    );
  }
}

class _BookingsSection extends StatelessWidget {
  final String userId;
  const _BookingsSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('bookedAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(child: const Center(child: CircularProgressIndicator()));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return SliverToBoxAdapter(child: Center(child: Text(S.of(context).noBookings)));
        }
        // group by month-year
        final Map<String, List<QueryDocumentSnapshot>> groups = {};
        for (var doc in docs) {
          final date = (doc['bookedAt'] as Timestamp).toDate();
          final key = DateFormat.yMMMM().format(date);
          groups.putIfAbsent(key, () => []).add(doc);
        }
        return SliverAnimatedList(
          initialItemCount: groups.length,
          itemBuilder: (context, index, animation) {
            final month = groups.keys.elementAt(index);
            final items = groups[month]!;
            return FadeTransition(
              opacity: animation,
              child: ExpansionTile(
                title: Text(month),
                children: items.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(data['eventName'] ?? ''),
                    subtitle: Text('${data['ticketsCount']} × ${data['eventDate']}'),
                    onLongPress: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(S.of(context).cancelBooking),
                          content: Text(S.of(context).confirmCancel),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(S.of(context).no)),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(S.of(context).yes)),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await doc.reference.delete();
                      }
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}

extension StringExt on String {
  String capitalize() => isEmpty ? '' : this[0].toUpperCase() + substring(1);
}
