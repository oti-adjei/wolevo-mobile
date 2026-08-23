import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/order_models.dart';
import 'order_status_badge.dart';

/// One row in the unified list of purchases and forwarded shipments.
///
/// Reference + status badge on the top line, source (retailer or
/// `Forwarded shipment`) and item count beneath, then the created date against
/// the USD + local total, with a chevron into the detail screen.
class FulfillmentCard extends StatelessWidget {
  const FulfillmentCard({super.key, required this.fulfillment, this.onTap});

  final Fulfillment fulfillment;
  final VoidCallback? onTap;

  /// `12 Aug 2026` — the site writes dates long-form, not numerically.
  static final _dateFormat = DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final f = fulfillment;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        f.reference,
                        style: AppText.cardTitleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    OrderStatusBadge(status: f.status),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      f.kind == FulfillmentKind.shipment
                          ? Icons.local_shipping_outlined
                          : Icons.shopping_bag_outlined,
                      size: 14,
                      color: AppColors.neutral1,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        f.sourceLabel,
                        style: AppText.body14.copyWith(color: AppColors.neutral1),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '  ·  ${f.itemCount} ${f.itemCount == 1 ? 'item' : 'items'}',
                      style: AppText.body14.copyWith(color: AppColors.neutral1),
                    ),
                  ],
                ),
                if (f.trackingNumber != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tracking ${f.trackingNumber}',
                    style: AppText.caption.copyWith(color: AppColors.neutral2),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpace.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        _dateFormat.format(f.createdAt),
                        style: AppText.caption.copyWith(color: AppColors.neutral1),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(f.total.usdLabel, style: AppText.bodySemibold),
                        Text(
                          f.total.localLabel,
                          style: AppText.caption.copyWith(color: AppColors.neutral1),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: AppSpace.sm, top: 2),
            child: Icon(Icons.chevron_right, size: 20, color: AppColors.neutral2),
          ),
        ],
      ),
    );
  }
}
