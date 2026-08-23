import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/retailer.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../../../../core/widgets/retailer_logo.dart';

/// `Browse Top U.S stores`.
///
/// White tiles carrying the store logo with the label *below*, as in the
/// client's mockups. The row scrolls horizontally so every store is reachable
/// by swipe; tile width is fixed rather than flex-divided so the last tile sits
/// part-visible at the edge, which is what signals it scrolls.
class RetailerChipRow extends StatelessWidget {
  const RetailerChipRow({super.key, this.retailers = Retailer.values});

  final List<Retailer> retailers;

  static const _tileWidth = 78.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
        itemCount: retailers.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpace.md),
        itemBuilder: (context, index) {
          final retailer = retailers[index];
          return SizedBox(
            width: _tileWidth,
            child: _RetailerTile(
              retailer: retailer,
              onTap: () => context.push(
                '${AppRoutes.shop}?retailer=${retailer.apiValue}',
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RetailerTile extends StatelessWidget {
  const _RetailerTile({required this.retailer, required this.onTap});

  final Retailer retailer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: AppColors.background,
          borderRadius: AppRadius.rCard,
          child: InkWell(
            borderRadius: AppRadius.rCard,
            onTap: onTap,
            child: Container(
              height: 66,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: AppRadius.rCard,
                border: Border.all(color: AppColors.surface4),
              ),
              child: RetailerLogo(retailer: retailer),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          retailer.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(color: AppColors.neutral1),
        ),
      ],
    );
  }
}

/// Heading plus the `View All` action, on one line — the mockup's arrangement.
class BrowseStoresHeader extends StatelessWidget {
  const BrowseStoresHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        0,
        AppSpace.sm,
        AppSpace.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Browse Top U.S stores', style: AppText.cardTitle),
          ),
          TextButton(
            onPressed: () => showAllRetailersSheet(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
            child: Text('View All', style: AppText.body14Semibold),
          ),
        ],
      ),
    );
  }
}

/// Every store in one list, for `View All`.
Future<void> showAllRetailersSheet(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(title: 'Browse Top U.S stores'),
          for (final retailer in Retailer.values)
            ListTile(
              leading: SizedBox(
                width: 54,
                height: 30,
                child: RetailerLogo(retailer: retailer),
              ),
              title: Text(retailer.label, style: AppText.body),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push('${AppRoutes.shop}?retailer=${retailer.apiValue}');
              },
            ),
          const SizedBox(height: AppSpace.lg),
        ],
      ),
    ),
  );
}
