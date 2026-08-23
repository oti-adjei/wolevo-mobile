import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/product_models.dart';

/// `$9.99` / `~₵121.88` / `In Stock`, then the pale-lime landed-cost box. The
/// tilde is the site's own hedge on the converted amount.
class ProductPriceRail extends StatelessWidget {
  const ProductPriceRail({super.key, required this.product});

  final ProductDetail product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              product.price.usdLabel,
              style: AppText.h2.copyWith(color: AppColors.secondary5),
            ),
            if (product.isDiscounted) ...[
              const SizedBox(width: AppSpace.sm),
              Text(
                product.wasPrice!.usdLabel,
                style: AppText.body14.copyWith(
                  color: AppColors.neutral2,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.neutral2,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          // Server-converted — the client never applies an FX rate.
          '~${product.price.localLabel}',
          style: AppText.body14.copyWith(color: AppColors.neutral1),
        ),
        const SizedBox(height: AppSpace.md),
        Row(
          children: [
            Icon(
              product.inStock
                  ? Icons.check_circle
                  : Icons.remove_circle_outline,
              size: 16,
              color: product.inStock ? AppColors.primary3 : AppColors.neutral1,
            ),
            const SizedBox(width: 6),
            Text(
              product.inStock ? 'In Stock' : 'Out of Stock',
              style: AppText.body14Semibold.copyWith(
                color: product.inStock
                    ? AppColors.primary3
                    : AppColors.neutral1,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        LandedCostCallout(landedCost: product.landedCost),
      ],
    );
  }
}

/// The pale-lime box that frames the two shipping legs — the whole point of
/// Wolevo rendering a retailer's product inside its own shell.
class LandedCostCallout extends StatelessWidget {
  const LandedCostCallout({super.key, required this.landedCost});

  final LandedCost landedCost;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.tertiary3,
        borderRadius: AppRadius.rCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row(
            icon: Icons.store_outlined,
            label: 'Store Shipping',
            value: landedCost.storeShippingLabel,
            highlight: landedCost.shipsFreeToWarehouse,
          ),
          const SizedBox(height: AppSpace.md),
          _Row(
            icon: Icons.local_shipping_outlined,
            label: 'To Your Door',
            value: landedCost.toYourDoorLabel,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.secondary3),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppText.caption.copyWith(color: AppColors.neutral1),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppText.body14Semibold.copyWith(
                  color: highlight ? AppColors.primary3 : AppColors.secondary5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
