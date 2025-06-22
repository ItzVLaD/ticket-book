import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../services/pricing_service.dart';

/// Widget that displays event pricing with fallback to generated prices
class EventPriceWidget extends StatelessWidget {
  final Event event;
  final TextStyle? textStyle;
  final Color? iconColor;

  const EventPriceWidget({
    super.key,
    required this.event,
    this.textStyle,
    this.iconColor,
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
          return Row(
            children: [
              Icon(
                Icons.attach_money, 
                size: 14, 
                color: iconColor ?? colorScheme.tertiary,
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: colorScheme.primary,
                ),
              ),
            ],
          );
        }

        if (snapshot.hasError) {
          return Row(
            children: [
              Icon(
                Icons.attach_money, 
                size: 14, 
                color: iconColor ?? colorScheme.tertiary,
              ),
              const SizedBox(width: 6),
              Text(
                'Price available',
                style: textStyle ?? theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }

        final eventPrice = snapshot.data!;
        return Row(
          children: [
            Icon(
              Icons.attach_money, 
              size: 14, 
              color: iconColor ?? colorScheme.tertiary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                eventPrice.formattedPrice,
                style: textStyle ?? theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Show indicator if price is generated
            if (eventPrice.isGenerated) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: 'Estimated price',
                child: Icon(
                  Icons.info_outline,
                  size: 12,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
