import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../../data/home_models.dart';
import 'category_tile_card.dart';
import 'product_card.dart';

/// Renders one row of the Home feed: a `SectionHeader` with `Show all →` plus
/// either a horizontal product carousel or a 2-column grid of category tiles.
class HomeSectionView extends StatelessWidget {
  const HomeSectionView({super.key, required this.section});

  final HomeSection section;

  @override
  Widget build(BuildContext context) {
    if (section.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
          child: SectionHeader(
            title: section.title,
            actionLabel: 'Show all',
            onAction: () => context.push(
              '${AppRoutes.shop}?retailer=${section.retailer.apiValue}',
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        switch (section.kind) {
          HomeSectionKind.products => DealCarousel(products: section.products),
          HomeSectionKind.categories => CategoryGrid(tiles: section.categories),
        },
      ],
    );
  }
}

/// Horizontally scrolling deal row. Cards are a fixed 168 wide so a 375px
/// phone always shows a partial third card, signalling that the row scrolls.
class DealCarousel extends StatelessWidget {
  const DealCarousel({super.key, required this.products});

  final List<DealProduct> products;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 288,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpace.md),
        itemBuilder: (context, index) => ProductCard(
          product: products[index],
          width: ProductCard.carouselWidth,
        ),
      ),
    );
  }
}

/// Loading stand-in for a deal row.
class DealCarouselSkeleton extends StatelessWidget {
  const DealCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 288,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpace.md),
        itemBuilder: (_, _) => const ProductCardSkeleton(),
      ),
    );
  }
}

/// 2-column category grid. Phone-first: three-up would crush the labels below
/// 400px, so the tiles stay two-up at every supported width.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key, required this.tiles});

  final List<CategoryTile> tiles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: tiles.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpace.md,
          crossAxisSpacing: AppSpace.md,
          childAspectRatio: 4 / 3,
        ),
        itemBuilder: (context, index) => CategoryTileCard(tile: tiles[index]),
      ),
    );
  }
}
