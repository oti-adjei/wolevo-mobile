import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/home_models.dart';
import 'product_thumb.dart';

/// The product tile used both in the Home deal carousels and in the search
/// grid: square image, 2-line clamped title, USD price, struck-through
/// was-price, and the pre-converted local price beneath.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.width});

  final DealProduct product;

  /// Carousels pin this to ~168; the search grid leaves it null and lets the
  /// grid delegate size the tile.
  final double? width;

  static const carouselWidth = 168.0;

  void _open(BuildContext context) {
    context.push(
      '${AppRoutes.product}?retailer=${product.retailer.apiValue}'
      '&productId=${product.productId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = AppCard(
      onTap: () => _open(context),
      padding: const EdgeInsets.all(AppSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: SizedBox(
              width: double.infinity,
              child: ProductThumb(
                seed: product.productId,
                retailer: product.retailer,
                imageUrl: product.imageUrl,
                radius: AppRadius.rSm,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            product.title,
            style: AppText.body14,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  product.price.usdLabel,
                  style: AppText.bodySemibold.copyWith(color: AppColors.secondary3),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (product.isDiscounted) ...[
                const SizedBox(width: AppSpace.xs),
                Flexible(
                  child: Text(
                    product.wasPrice!.usdLabel,
                    style: AppText.caption.copyWith(
                      color: AppColors.neutral2,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.neutral2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            // Server-converted — the client never applies an FX rate.
            product.price.localLabel,
            style: AppText.caption.copyWith(color: AppColors.neutral1),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (width == null) return card;
    return SizedBox(width: width, child: card);
  }
}

/// Grey stand-in shown while the feed loads. Matches the card's footprint so
/// the real content does not shift the scroll position when it arrives.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key, this.width = ProductCard.carouselWidth});

  final double width;

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: AppColors.surface3,
            borderRadius: BorderRadius.circular(4),
          ),
        );

    return SizedBox(
      width: width,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface3,
                  borderRadius: AppRadius.rSm,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            bar(width - 24, 12),
            const SizedBox(height: 6),
            bar((width - 24) * 0.6, 12),
            const SizedBox(height: AppSpace.md),
            bar(64, 14),
            const SizedBox(height: 6),
            bar(48, 10),
          ],
        ),
      ),
    );
  }
}
