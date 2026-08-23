import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';

/// Category filter chips from the client's Shop mockup.
///
// ASSUMPTION: the API exposes no category taxonomy — discovery only ever saw a
// keyword search and a retailer scope. Rather than invent an endpoint, these
// filter the listings already on screen by keyword. That keeps the UI honest:
// when a real category field lands on the API, swap [ShopCategory.matches] for
// the server value and nothing else changes.
enum ShopCategory {
  all('All'),
  electronics(
    'Electronics',
    keywords: [
      'tv',
      'monitor',
      'ssd',
      'drive',
      'camera',
      'speaker',
      'console',
      'playstation',
      'xbox',
      'switch',
      'router',
      'mesh',
      'tablet',
      'ipad',
    ],
  ),
  headphones(
    'Headphones',
    keywords: [
      'headphone',
      'earbud',
      'airpod',
      'beats',
      'wh-1000',
      'on-ear',
      'over-ear',
    ],
  ),
  laptops(
    'Laptops',
    keywords: [
      'laptop',
      'macbook',
      'notebook',
      'chromebook',
      'thinkpad',
      'omnibook',
    ],
  ),
  phones(
    'Phones',
    keywords: ['iphone', 'galaxy', 'pixel', 'phone', 'razr', 'smartphone'],
  ),
  accessories(
    'Accessories',
    keywords: ['cable', 'charger', 'case', 'adapter', 'mount', 'hub', 'cord'],
  );

  const ShopCategory(this.label, {this.keywords = const []});

  final String label;
  final List<String> keywords;

  /// [ShopCategory.all] matches everything; the rest match on the title.
  bool matches(String title) {
    if (this == ShopCategory.all) return true;
    final lower = title.toLowerCase();
    return keywords.any(lower.contains);
  }
}

class CategoryChipRow extends StatelessWidget {
  const CategoryChipRow({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ShopCategory selected;
  final ValueChanged<ShopCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
        itemCount: ShopCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
        itemBuilder: (context, index) {
          final category = ShopCategory.values[index];
          final isSelected = category == selected;
          return Material(
            color: isSelected ? AppColors.tertiary : AppColors.background,
            borderRadius: AppRadius.rPill,
            child: InkWell(
              borderRadius: AppRadius.rPill,
              onTap: () => onSelected(category),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.rPill,
                  border: Border.all(
                    color: isSelected ? AppColors.tertiary : AppColors.surface4,
                  ),
                ),
                child: Text(
                  category.label,
                  style: AppText.body14Medium.copyWith(
                    color: isSelected
                        ? AppColors.secondary
                        : AppColors.neutral1,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
