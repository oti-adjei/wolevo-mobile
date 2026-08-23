import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/order_models.dart';

/// The status chip row: **All · Pending · Purchased · Shipped · Delivered ·
/// Cancelled** (discovery-notes.md § 2.3). Selecting one sets `?status=…` on the
/// web; here it drives the repository call.
///
/// Selected = deep-green fill with a white label (the site uses a dark pill);
/// unselected = white with a hairline border.
class OrderStatusFilterBar extends StatelessWidget {
  const OrderStatusFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// Null is the `All` chip.
  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      child: Row(
        children: [
          _Chip(
            label: 'All',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final status in OrderStatus.values) ...[
            const SizedBox(width: AppSpace.sm),
            _Chip(
              label: status.label,
              selected: selected == status,
              onTap: () => onSelected(status),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rPill,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.secondary : AppColors.background,
            borderRadius: AppRadius.rPill,
            border: Border.all(
              color: selected ? AppColors.secondary : AppColors.surface4,
            ),
          ),
          child: Text(
            label,
            style: AppText.body14Semibold.copyWith(
              color: selected ? Colors.white : AppColors.bodyText,
            ),
          ),
        ),
      ),
    );
  }
}

/// The `× Clear all filters (1)` control the site shows underneath the chip row
/// whenever a filter is active.
class ClearFiltersButton extends StatelessWidget {
  const ClearFiltersButton({
    super.key,
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.close, size: 16),
        label: Text(
          'Clear all filters ($count)',
          style: AppText.body14Semibold,
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.neutral1,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
