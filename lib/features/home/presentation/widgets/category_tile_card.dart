import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/home_models.dart';
import 'product_thumb.dart';

/// A department tile from a category row (Fashion Nova / Plug Tech / Sephora):
/// image with a dark gradient wash and the label bottom-left.
class CategoryTileCard extends StatelessWidget {
  const CategoryTileCard({super.key, required this.tile});

  final CategoryTile tile;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.rCard,
      // ASSUMPTION: category tiles deep-link into Shop scoped to the retailer.
      // The web app's tile target was not captured, and Shop has no category
      // filter yet, so the label rides along as a query param for later.
      onTap: () => context.push(
        '${AppRoutes.shop}?retailer=${tile.retailer.apiValue}'
        '&category=${Uri.encodeComponent(tile.label)}',
      ),
      child: ClipRRect(
        borderRadius: AppRadius.rCard,
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ProductThumb(
                seed: '${tile.retailer.apiValue}-${tile.label}',
                retailer: tile.retailer,
                imageUrl: tile.imageUrl,
                radius: BorderRadius.zero,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC0A3307)],
                    stops: [0.35, 1],
                  ),
                ),
              ),
              Positioned(
                left: AppSpace.md,
                right: AppSpace.md,
                bottom: AppSpace.md,
                child: Text(
                  tile.label,
                  style: AppText.cardTitleMedium.copyWith(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
