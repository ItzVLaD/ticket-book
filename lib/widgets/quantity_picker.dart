import 'package:flutter/material.dart';

class QuantityPicker extends StatelessWidget {
  final int quantity;
  final int minQuantity;
  final int maxQuantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const QuantityPicker({
    super.key,
    required this.quantity,
    this.minQuantity = 0,
    this.maxQuantity = 10,
    this.onDecrement,
    this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: quantity > minQuantity ? onDecrement : null,
          icon: const Icon(Icons.remove),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surfaceVariant,
            foregroundColor: colorScheme.onSurfaceVariant,
          ),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 40),
          child: Text(
            quantity.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: quantity < maxQuantity ? onIncrement : null,
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surfaceVariant,
            foregroundColor: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}