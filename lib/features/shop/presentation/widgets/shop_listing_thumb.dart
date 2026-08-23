import 'package:flutter/material.dart';

import '../../../../core/models/retailer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';

/// Shop-grid imagery.
///
/// The live API serves product images through a Cloudflare image proxy, but
/// this build has no bundled assets and no reachable product URLs, so the
/// thumbnail falls back to a deterministic tinted panel carrying the retailer's
/// initial — the same visual language Home uses for its deal carousels.
///
// ASSUMPTION: the tint is derived from a hash of the product id purely so a
// given listing looks the same on every rebuild and across shop, search and
// the product gallery. Swap the body for an Image.network once the proxy is
// reachable; the [imageUrl] path below is already wired for that.
class ShopListingThumb extends StatelessWidget {
  const ShopListingThumb({
    super.key,
    required this.seed,
    required this.retailer,
    this.imageUrl = '',
    this.radius = AppRadius.rSm,
  });

  /// Stable identity for the placeholder — pass the product id.
  final String seed;
  final Retailer retailer;
  final String imageUrl;
  final BorderRadius radius;

  /// Palette the placeholder picks from, all brand tokens so a grid of them
  /// still reads as one surface.
  static const _tints = <Color>[
    AppColors.secondary2,
    AppColors.tertiary2,
    AppColors.secondary7,
    AppColors.tertiary,
    AppColors.primary2,
    AppColors.surface3,
  ];

  static Color tintFor(String seed) => _tints[stableHash(seed) % _tints.length];

  /// Deterministic, platform-independent hash — `String.hashCode` is not
  /// guaranteed stable across runs.
  static int stableHash(String value) {
    var h = 0;
    for (final unit in value.codeUnits) {
      h = (h * 31 + unit) & 0x7fffffff;
    }
    return h;
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = ShopThumbPlaceholder(seed: seed, retailer: retailer);
    return ClipRRect(
      borderRadius: radius,
      child: imageUrl.isEmpty
          ? placeholder
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : placeholder,
            ),
    );
  }
}

/// The tinted panel itself, exposed so the product gallery can reuse it at a
/// larger size.
class ShopThumbPlaceholder extends StatelessWidget {
  const ShopThumbPlaceholder({
    super.key,
    required this.seed,
    required this.retailer,
    this.showLabel = true,
  });

  final String seed;
  final Retailer retailer;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ShopListingThumb.tintFor(seed),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                retailer.label.substring(0, 1).toUpperCase(),
                style: AppText.h1.copyWith(
                  color: AppColors.secondary.withValues(alpha: 0.45),
                ),
              ),
              if (showLabel)
                Text(
                  retailer.label,
                  style: AppText.micro.copyWith(
                    color: AppColors.secondary.withValues(alpha: 0.55),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
