import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/cart_models.dart';
import 'cart_item_thumb.dart';

/// One line of the items panel: thumbnail, 2-line title, USD price with the
/// local price beneath, a `− n +` stepper and the red trash icon.
class CartItemRow extends StatelessWidget {
  const CartItemRow({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    this.busy = false,
  });

  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  /// True while a mutation is in flight, so the stepper cannot be double-tapped.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CartItemThumb(item: item),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body14Medium,
                ),
                if (item.variantSummary case final variant?) ...[
                  const SizedBox(height: 2),
                  Text(
                    variant,
                    style: AppText.caption.copyWith(color: AppColors.neutral1),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  item.unitPrice.usdLabel,
                  style: AppText.bodySemibold.copyWith(
                    color: AppColors.secondary3,
                  ),
                ),
                Text(
                  item.unitPrice.localLabel,
                  style: AppText.caption.copyWith(color: AppColors.neutral1),
                ),
                const SizedBox(height: AppSpace.md),
                Row(
                  children: [
                    QuantityStepper(
                      quantity: item.quantity,
                      enabled: !busy,
                      onChanged: onQuantityChanged,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: busy ? null : onRemove,
                      tooltip: 'Remove item',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The `− n +` control. Minimum of 1: dropping below it is what the trash icon
/// is for, matching the web app.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.enabled = true,
    this.min = 1,
    this.max = 99,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.rInput,
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove,
            onTap: enabled && quantity > min
                ? () => onChanged(quantity - 1)
                : null,
          ),
          SizedBox(
            width: 34,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppText.body14Semibold,
            ),
          ),
          _StepButton(
            icon: Icons.add,
            onTap: enabled && quantity < max
                ? () => onChanged(quantity + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rInput,
      child: SizedBox(
        height: 36,
        width: 36,
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? AppColors.neutral2 : AppColors.bodyText,
        ),
      ),
    );
  }
}
