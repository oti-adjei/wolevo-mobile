import 'package:flutter/material.dart';

import '../../../../core/models/retailer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';

/// Product imagery placeholder.
///
/// The live API serves images through a Cloudflare image proxy, but this build
/// has no bundled assets and no reachable product URLs, so the thumbnail falls
/// back to a deterministic tinted panel carrying the retailer's initial.
///
// ASSUMPTION: the tint is derived from a hash of the product id purely so a
// given product looks the same on every rebuild and across the feed and search
// screens. Replace the whole widget body with an Image.network once the proxy
// is reachable; the [imageUrl] path below is already wired for that.
class ProductThumb extends StatelessWidget {
  const ProductThumb({
    super.key,
    required this.seed,
    required this.retailer,
    this.imageUrl = '',
    this.radius = AppRadius.rCard,
  });

  /// Stable identity for the placeholder — pass the product id or category label.
  final String seed;
  final Retailer retailer;
  final String imageUrl;
  final BorderRadius radius;

  /// Palette the placeholder picks from, all drawn from the brand tokens so a
  /// grid of them still reads as one surface.
  static const _tints = <Color>[
    AppColors.secondary2,
    AppColors.tertiary2,
    AppColors.secondary7,
    AppColors.tertiary,
    AppColors.primary2,
    AppColors.surface3,
  ];

  static Color tintFor(String seed) => _tints[_hash(seed) % _tints.length];

  /// Deterministic, platform-independent hash (String.hashCode is not
  /// guaranteed stable across runs).
  static int _hash(String value) {
    var h = 0;
    for (final unit in value.codeUnits) {
      h = (h * 31 + unit) & 0x7fffffff;
    }
    return h;
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = _Placeholder(seed: seed, retailer: retailer);
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

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.seed, required this.retailer});

  final String seed;
  final Retailer retailer;

  @override
  Widget build(BuildContext context) {
    final tint = ProductThumb.tintFor(seed);
    return Container(
      color: tint,
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
