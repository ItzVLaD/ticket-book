import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_group.dart';
import '../screens/event_detail_screen.dart';

class HeroCarousel extends StatelessWidget {
  const HeroCarousel({
    required this.groups,
    required this.pageController,
    required this.indicator,
    super.key,
  });

  final List<EventGroup> groups;
  final PageController pageController;
  final Widget indicator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        PageView.builder(
          controller: pageController,
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => EventDetailScreen(
                          event: group.schedules.first,
                          eventGroup: group, // Pass the group for grouped events
                        ),
                  ),
                );
              },
              child: Semantics(
                label: group.name,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (group.primaryImageUrl != null)
                      Image.network(group.primaryImageUrl!, fit: BoxFit.cover)
                    else
                      Container(
                        height: 220,
                        color: theme.colorScheme.surfaceVariant,
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.all(16),
                        child: Text(group.name, style: theme.textTheme.headlineMedium),
                      ),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(color: Colors.black.withOpacity(0)),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            theme.colorScheme.surface.withAlpha((0.7 * 255).round()),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.yMMMd().format(group.firstDate),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Padding(padding: const EdgeInsets.only(bottom: 8), child: indicator),
      ],
    );
  }
}
