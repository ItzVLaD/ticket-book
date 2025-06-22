import 'package:flutter/material.dart';
import 'package:tickets_booking/models/event.dart';
import 'event_price_widget.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final String? heroTagSuffix; // Add suffix to make hero tags unique

  const EventCard({super.key, required this.event, required this.onTap, this.heroTagSuffix});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Create unique hero tag based on context
    final heroTag =
        heroTagSuffix != null ? 'event_${event.id}_$heroTagSuffix' : 'event_${event.id}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Event Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Hero(
                    tag: heroTag, // Use unique hero tag
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child:
                          event.imageUrl != null
                              ? Image.network(
                                event.imageUrl!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.event,
                                        color: colorScheme.primary,
                                        size: 32,
                                      ),
                                    ),
                              )
                              : Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(Icons.event, color: colorScheme.primary, size: 32),
                              ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Event Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Name
                      Text(
                        event.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Date
                      if (event.dateFormatted.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: colorScheme.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                event.dateFormatted,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],

                      // Venue and City
                      if (event.venue != null || event.city != null) ...[
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: colorScheme.secondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                [event.venue, event.city].where((s) => s != null && s.isNotEmpty).join(', '),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],

                      // Price
                      EventPriceWidget(event: event),
                      const SizedBox(height: 4),

                      // Genre
                      if (event.genre != null && event.genre!.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.music_note, size: 14, color: colorScheme.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                event.genre!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Arrow Icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
