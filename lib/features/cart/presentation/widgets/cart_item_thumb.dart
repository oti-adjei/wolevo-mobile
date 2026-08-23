import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/cart_models.dart';

/// Stand-in for a product image, matching the treatment used by the orders
/// feature.
///
/// The web app serves product photos through an image proxy; no assets ship
/// with this app and nothing is available offline, so `CartItem.imageUrl` stays
/// on the model (it is part of the API shape) and is deliberately not loaded.
/// Instead: a rounded tile tinted deterministically from a hash of the title,
/// with the retailer's initial centred — same item, same colour, every time.
class CartItemThumb extends StatelessWidget {
  const CartItemThumb({super.key, required this.item, this.size = 64});

  final CartItem item;
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
    final hash =
        item.title.codeUnits.fold<int>(7, (acc, c) => (acc * 31 + c) & 0x7fffffff);
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
