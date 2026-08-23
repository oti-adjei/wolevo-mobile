import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// One onboarding slide.
class OnboardingSlide {
  const OnboardingSlide({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
    this.bullets = const [],
    this.stat,
    this.statCaption,
  });

  final String eyebrow;
  final String title;
  final String body;
  final IconData icon;
  final Color accent;
  final List<String> bullets;

  /// Optional headline figure, drawn from the landing page's stats strip.
  final String? stat;
  final String? statCaption;
}

/// The four slides, each condensed from a section of the live landing page
/// (see discovery-notes.md § "1. Landing pages"). Nothing here is invented:
/// every headline and figure is the site's own copy.
abstract final class OnboardingContent {
  static const slides = <OnboardingSlide>[
    // The hero: "Shop global. Receive it at home."
    OnboardingSlide(
      eyebrow: 'Shop global',
      title: 'Receive it at home.',
      body:
          'Shop from top U.S. stores and have it delivered to your door in '
          'Ghana or Nigeria. Delivered in 7-14 days.',
      icon: Icons.public,
      accent: AppColors.primary,
      bullets: [
        'Amazon, eBay, Best Buy, Sephora and more',
        'Paste any product link — we buy it for you',
      ],
    ),

    // "HOW IT WORKS — Two ways to get what you love" → the Ship for Me half.
    OnboardingSlide(
      eyebrow: 'Ship for me',
      title: 'Your own US address.',
      body:
          'Get a real Delaware address the moment you sign up. Ship to it '
          'from any US store, or have family send to it.',
      icon: Icons.local_shipping_outlined,
      accent: AppColors.tertiary,
      bullets: [
        'USPS, UPS, FedEx — any carrier works',
        'Register the tracking number and we take it from there',
      ],
      stat: '0%',
      statCaption: 'US sales tax — we ship from a tax-free state',
    ),

    // "COVERAGE — Pay in Cedis" plus the product page's payment rails.
    OnboardingSlide(
      eyebrow: 'Pay your way',
      title: 'No US card needed.',
      body:
          'Pay in your own currency via Mobile Money (MoMo), card or bank '
          'transfer. No dollar account, no conversion stress.',
      icon: Icons.account_balance_wallet_outlined,
      accent: AppColors.primary,
      bullets: [
        'Mobile Money, Card or Bank Transfer',
        'Prices shown in USD and your local currency',
      ],
    ),

    // "THE WOLEVO APP — Shop. Ship. Track. Receive." plus the savings stat.
    OnboardingSlide(
      eyebrow: 'Stay in the loop',
      title: 'Track every package.',
      body:
          'Get quotes, pay, and follow each parcel from our warehouse to '
          'your door. Delivery or pickup — your choice.',
      icon: Icons.inventory_2_outlined,
      accent: AppColors.tertiary,
      stat: '25%',
      statCaption: 'Average savings vs traditional agents',
    ),
  ];
}
