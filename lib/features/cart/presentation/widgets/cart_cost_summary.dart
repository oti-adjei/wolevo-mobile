import 'package:flutter/material.dart';

import '../../../../core/models/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/cart_models.dart';

/// The site's `Cost Summary`.
///
/// MOBILE ADAPTATION: the web pins this as a sticky right-hand sidebar. A
/// sidebar has nowhere to live on a 375px phone, so it becomes a single-column
/// section below the items, and the sidebar's buttons move to a sticky bottom
/// bar (see [CartScreen]).
class CartCostSummary extends StatelessWidget {
  const CartCostSummary({
    super.key,
    required this.totals,
    required this.itemCount,
    required this.destinationName,
    this.promoCode,
    this.onRemovePromo,
  });

  final CartTotals totals;
  final int itemCount;
  final String destinationName;
  final String? promoCode;
  final VoidCallback? onRemovePromo;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cost Summary', style: AppText.cardTitle),
          const SizedBox(height: AppSpace.md),
          CostRow(label: 'Subtotal ($itemCount items)', value: totals.subtotal),
          const CostRow(label: 'Retailer Shipping', value: null),
          CostRow(label: 'Shipping to $destinationName', value: null),
          if (totals.discount case final discount?)
            CostRow(
              label: promoCode == null ? 'Discount' : 'Discount ($promoCode)',
              value: discount,
              negative: true,
              trailing: onRemovePromo == null
                  ? null
                  : InkWell(
                      onTap: onRemovePromo,
                      borderRadius: AppRadius.rSm,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          'Remove',
                          style: AppText.caption.copyWith(color: AppColors.neutral1),
                        ),
                      ),
                    ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpace.md),
            child: Divider(height: 1),
          ),
          CostRow(
            label: 'Estimated Total',
            value: totals.estimatedTotal,
            emphasised: true,
            // The web renders the estimate with a trailing `+` while the two
            // shipping legs are still unknown.
            suffix: totals.hasPendingCosts ? '+' : null,
          ),
        ],
      ),
    );
  }
}

/// One label/amount line. A null [value] renders the site's placeholder wording
/// for a cost the warehouse has not determined yet.
class CostRow extends StatelessWidget {
  const CostRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasised = false,
    this.negative = false,
    this.suffix,
    this.trailing,
  });

  final String label;
  final Money? value;
  final bool emphasised;
  final bool negative;
  final String? suffix;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final amount = value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: emphasised
                      ? AppText.bodySemibold
                      : AppText.body14.copyWith(color: AppColors.neutral1),
                ),
                ?trailing,
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          if (amount == null)
            Text(
              'Calculated at checkout',
              style: AppText.body14.copyWith(color: AppColors.neutral1),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${negative ? '−' : ''}${amount.usdLabel}${suffix ?? ''}',
                  style: (emphasised ? AppText.bodySemibold : AppText.body14Medium)
                      .copyWith(color: negative ? AppColors.success2 : null),
                ),
                Text(
                  '${negative ? '−' : ''}${amount.localLabel}${suffix ?? ''}',
                  style: AppText.caption.copyWith(color: AppColors.neutral1),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The pale-lime note that sits under the cost summary on the live cart.
class CartCurrencyNote extends StatelessWidget {
  const CartCurrencyNote({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoCallout(
      leading: '💡',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Note: All prices will be converted to your destination currency at checkout.'),
          SizedBox(height: 4),
          Text('Click checkout to see final pricing.'),
        ],
      ),
    );
  }
}
