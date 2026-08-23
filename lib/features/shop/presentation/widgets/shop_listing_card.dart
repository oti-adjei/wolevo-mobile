import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/shop_models.dart';
import 'shop_listing_thumb.dart';

/// One tile in the shop grid: square thumbnail, 2-line clamped title, USD price
/// in brand green, struck-through was-price, and the server-converted local
/// price beneath. The web app renders five of these per row on desktop; a phone
/// gets two.
class ShopListingCard extends StatelessWidget {
  const ShopListingCard({super.key, required this.listing});

  final ShopListing listing;

  void _open(BuildContext context) {
    context.push(
      '${AppRoutes.product}?retailer=${listing.retailer.apiValue}'
      '&productId=${listing.productId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => _open(context),
      padding: const EdgeInsets.all(AppSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: SizedBox(
                  width: double.infinity,
                  child: ShopListingThumb(
                    seed: listing.productId,
                    retailer: listing.retailer,
                    imageUrl: listing.imageUrl,
                  ),
                ),
              ),
              if (!listing.inStock)
                Positioned(
                  left: AppSpace.xs,
                  top: AppSpace.xs,
                  child: const MicroBadge(
                    label: 'Out of stock',
                    background: AppColors.surface3,
                    foreground: AppColors.neutral1,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            listing.title,
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
                  listing.price.usdLabel,
                  style: AppText.bodySemibold.copyWith(
                    color: AppColors.secondary3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (listing.isDiscounted) ...[
                const SizedBox(width: AppSpace.xs),
                Flexible(
                  child: Text(
                    listing.wasPrice!.usdLabel,
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
            listing.price.localLabel,
            style: AppText.caption.copyWith(color: AppColors.neutral1),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Grey stand-in shown while a page loads. Matches the card's footprint so real
/// content does not shift the scroll position when it arrives.
class ShopListingCardSkeleton extends StatelessWidget {
  const ShopListingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface3,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface3,
                borderRadius: AppRadius.rSm,
              ),
              child: SizedBox(width: double.infinity),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          bar(1, 12),
          const SizedBox(height: 6),
          bar(0.6, 12),
          const SizedBox(height: AppSpace.md),
          bar(0.45, 14),
          const SizedBox(height: 6),
          bar(0.35, 10),
        ],
      ),
    );
  }
}
