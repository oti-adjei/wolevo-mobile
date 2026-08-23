import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/order_models.dart';

/// Stand-in for a product image.
///
/// The web app serves product photos through a Cloudflare image proxy, but no
/// assets are bundled with this app and the images are not available offline —
/// so `FulfillmentItem.imageUrl` is kept on the model (it is part of the API
/// shape) and deliberately not loaded here.
///
/// Instead: a rounded tile tinted deterministically from a hash of the item
/// title, with the retailer's initial centred. Same item, same colour, every
/// time — which reads as a real thumbnail strip rather than a row of grey boxes.
class OrderItemThumb extends StatelessWidget {
  const OrderItemThumb({super.key, required this.item, this.size = 56});

  final FulfillmentItem item;
  final double size;

  /// Tints drawn from the brand palette only — never an arbitrary hex.
  static const _tints = <(Color background, Color foreground)>[
    (AppColors.secondary2, AppColors.secondary),
    (AppColors.tertiary2, AppColors.secondary3),
    (AppColors.primary2, AppColors.success2),
    (AppColors.secondary7, AppColors.secondary3),
    (AppColors.tertiary3, AppColors.secondary),
    (AppColors.surface3, AppColors.neutral),
  ];

  @override
  Widget build(BuildContext context) {
    final hash = item.title.codeUnits.fold<int>(7, (acc, c) => (acc * 31 + c) & 0x7fffffff);
    final (background, foreground) = _tints[hash % _tints.length];

    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.rCard,
        border: Border.all(color: AppColors.surface4),
      ),
      child: Text(
        item.retailer.label.substring(0, 1).toUpperCase(),
        style: AppText.cardTitle.copyWith(color: foreground, fontSize: size * 0.36),
      ),
    );
  }
}
