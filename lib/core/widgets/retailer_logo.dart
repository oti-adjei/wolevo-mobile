import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/retailer.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The store's logo, from the client-supplied artwork in `assets/logos/`.
///
/// Sephora's PNG is greyscale-with-alpha, so it is tinted to the brand's deep
/// green rather than rendered as flat grey.
///
// ASSUMPTION: no Fashion Nova asset was supplied, so that one falls back to a
// styled wordmark. Drop `assets/logos/fashion_nova.*` in and add a case here.
class RetailerLogo extends StatelessWidget {
  const RetailerLogo({super.key, required this.retailer});

  final Retailer retailer;

  @override
  Widget build(BuildContext context) {
    return switch (retailer) {
      Retailer.amazon => SvgPicture.asset(
        'assets/logos/amazon.svg',
        fit: BoxFit.contain,
      ),
      Retailer.ebay => SvgPicture.asset(
        'assets/logos/ebay.svg',
        fit: BoxFit.contain,
      ),
      Retailer.bestBuy => SvgPicture.asset(
        'assets/logos/best-buy.svg',
        fit: BoxFit.contain,
      ),
      Retailer.plugTech => Image.asset(
        'assets/logos/plug_tech.webp',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => RetailerWordmark(retailer: retailer),
      ),
      Retailer.sephora => Image.asset(
        'assets/logos/Sephora.png',
        fit: BoxFit.contain,
        color: AppColors.secondary,
        errorBuilder: (_, _, _) => RetailerWordmark(retailer: retailer),
      ),
      Retailer.fashionNova => RetailerWordmark(retailer: retailer),
    };
  }
}

class RetailerWordmark extends StatelessWidget {
  const RetailerWordmark({super.key, required this.retailer});

  final Retailer retailer;

  /// Short forms — full labels wrap badly inside a 78px tile.
  String get _short => switch (retailer) {
    Retailer.amazon => 'amazon',
    Retailer.ebay => 'ebay',
    Retailer.fashionNova => 'NOVA',
    Retailer.plugTech => 'plug',
    Retailer.bestBuy => 'BEST BUY',
    Retailer.sephora => 'SEPHORA',
  };

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        _short,
        maxLines: 1,
        style: AppText.body14Semibold.copyWith(
          color: AppColors.secondary,
          letterSpacing: retailer == Retailer.sephora ? 1.2 : -0.2,
        ),
      ),
    );
  }
}
