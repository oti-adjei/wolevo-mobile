import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/ship_models.dart';

/// The three radio-like intent cards.
///
/// MOBILE ADAPTATION: the web renders these side-by-side in a 3-column grid.
/// Three cards with an icon chip, a title and a subtitle cannot survive a
/// 375px viewport in a row, so on a phone they stack vertically.
class IntentSelector extends StatelessWidget {
  const IntentSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ShipIntent selected;
  final ValueChanged<ShipIntent> onChanged;

  static IconData _iconFor(ShipIntent intent) => switch (intent) {
        ShipIntent.yetToShop => Icons.shopping_bag_outlined,
        ShipIntent.someoneSending => Icons.local_shipping_outlined,
        ShipIntent.alreadyShipped => Icons.inventory_2_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final intent in ShipIntent.values) ...[
          _IntentCard(
            intent: intent,
            selected: intent == selected,
            onTap: () => onChanged(intent),
          ),
          if (intent != ShipIntent.values.last) const SizedBox(height: AppSpace.md),
        ],
      ],
    );
  }
}

class _IntentCard extends StatelessWidget {
  const _IntentCard({
    required this.intent,
    required this.selected,
    required this.onTap,
  });

  final ShipIntent intent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SelectableCard(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          IconChip(
            icon: IntentSelector._iconFor(intent),
            background: selected ? AppColors.background : AppColors.secondary2,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(intent.title, style: AppText.cardTitleMedium),
                const SizedBox(height: 2),
                Text(
                  intent.subtitle,
                  style: AppText.body14.copyWith(color: AppColors.neutral1),
                ),
              ],
            ),
          ),
          if (selected) ...[
            const SizedBox(width: AppSpace.sm),
            const SelectedMarker(),
          ],
        ],
      ),
    );
  }
}
