import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../services/pricing_service.dart';

/// Widget that displays event pricing in detail view with banner style
class EventDetailPriceWidget extends StatelessWidget {
  final Event event;
  final bool isCompact;

  const EventDetailPriceWidget({
    super.key,
    required this.event,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final eventsProvider = context.watch<EventsProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<EventPrice>(
      future: eventsProvider.getEventPrice(event),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return isCompact 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
        }

        if (snapshot.hasError) {
          return isCompact 
              ? Text(
                  'Price available',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.confirmation_number, color: colorScheme.onSurfaceVariant, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Price available',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
        }

        final eventPrice = snapshot.data!;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eventPrice.formattedPrice,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (eventPrice.isGenerated) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 12,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Estimated',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        }

        // Banner style for detail view
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (eventPrice.isGenerated ? colorScheme.secondary : colorScheme.primary).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.confirmation_number,
                color: eventPrice.isGenerated ? colorScheme.onSecondary : colorScheme.onPrimary,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                eventPrice.formattedPrice,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: eventPrice.isGenerated ? colorScheme.onSecondary : colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (eventPrice.isGenerated) ...[
                const SizedBox(height: 4),
                Text(
                  'Estimated Price',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: (eventPrice.isGenerated ? colorScheme.onSecondary : colorScheme.onPrimary).withOpacity(0.8),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
