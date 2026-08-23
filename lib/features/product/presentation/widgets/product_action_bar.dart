import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';

/// The sticky bottom bar the live mobile layout uses: `− n +`, a wide
/// `Add to Cart · $9.99`, and a cart button carrying the item-count badge.
class ProductActionBar extends StatelessWidget {
  const ProductActionBar({
    super.key,
    required this.quantity,
    required this.priceLabel,
    required this.onIncrement,
    required this.onDecrement,
    required this.onAddToCart,
    required this.onOpenCart,
    this.cartCount,
    this.adding = false,
    this.enabled = true,
  });

  final int quantity;

  /// Already multiplied by [quantity] — the bar always shows what pressing the
  /// button will add.
  final String priceLabel;

  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onAddToCart;
  final VoidCallback onOpenCart;

  /// Null until the cart's count is known, which is what keeps the badge off
  /// the button on first paint.
  final int? cartCount;

  final bool adding;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.md,
            AppSpace.gutter,
            AppSpace.md,
          ),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.surface4)),
          ),
          child: Row(
            children: [
              _QuantityStepper(
                quantity: quantity,
                onIncrement: onIncrement,
                onDecrement: onDecrement,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: PrimaryButton(
                  label: 'Add to Cart · $priceLabel',
                  size: AppButtonSize.compact,
                  loading: adding,
                  onPressed: enabled && !adding ? onAddToCart : null,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              _CartButton(count: cartCount, onPressed: onOpenCart),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: AppRadius.rInput,
        border: Border.all(color: AppColors.surface4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove,
            onPressed: quantity > 1 ? onDecrement : null,
            semanticLabel: 'Decrease quantity',
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppText.body14Semibold,
            ),
          ),
          _StepButton(
            icon: Icons.add,
            onPressed: onIncrement,
            semanticLabel: 'Increase quantity',
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: AppRadius.rInput,
      child: SizedBox(
        height: 42,
        width: 36,
        child: Icon(
          icon,
          size: 18,
          semanticLabel: semanticLabel,
          color: onPressed == null ? AppColors.surface5 : AppColors.secondary5,
        ),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.count, required this.onPressed});

  final int? count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: 44,
      child: Material(
        color: AppColors.background,
        borderRadius: AppRadius.rInput,
        child: InkWell(
          borderRadius: AppRadius.rInput,
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.rInput,
              border: Border.all(color: AppColors.surface4),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 20,
                  color: AppColors.secondary5,
                ),
                if (count != null && count! > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: AppRadius.rPill,
                      ),
                      child: Text(
                        '${count! > 99 ? 99 : count}',
                        style: AppText.micro.copyWith(color: AppColors.background),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
