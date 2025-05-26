import 'package:flutter/material.dart';
import 'package:tickets_booking/models/event.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const EventCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      surfaceTintColor: theme.colorScheme.surfaceTint,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Hero(
                  tag: 'event_${event.id}',
                  child:
                      event.imageUrl != null
                          ? Image.network(
                            event.imageUrl!,
                            width: 100,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                          : Container(
                            width: 100,
                            height: 80,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.event, color: theme.colorScheme.onSurfaceVariant),
                          ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.dateFormatted,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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
  }
}
