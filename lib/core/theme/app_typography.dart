import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Sora is shipped as a variable font, so every style declares both a
/// [FontWeight] (for Flutter's own resolution) and a matching `wght`
/// [FontVariation] (so the variable axis actually moves).
TextStyle _sora({
  required double size,
  required int weight,
  required double height,
  double letterSpacing = 0,
  Color color = AppColors.bodyText,
}) {
  return TextStyle(
    fontFamily: 'Sora',
    fontSize: size,
    height: height / size,
    letterSpacing: letterSpacing,
    color: color,
    fontWeight: FontWeight.values[(weight ~/ 100) - 1],
    fontVariations: [FontVariation('wght', weight.toDouble())],
  );
}

/// The web type scale, translated to phone sizes. Display sizes are stepped
/// down from the desktop values (48px H1 would overflow a 375px viewport);
/// body and below keep their exact web values.
abstract final class AppText {
  /// Web H1 is 48/700 with tight tracking. On a phone hero this lands at 34.
  static final h1 = _sora(size: 34, weight: 700, height: 40, letterSpacing: -0.85);

  /// Web H2 30/700/-0.75px.
  static final h2 = _sora(size: 26, weight: 700, height: 32, letterSpacing: -0.65);

  /// Web H3 24–30/700.
  static final h3 = _sora(size: 22, weight: 700, height: 28, letterSpacing: -0.4);

  /// Card / section titles: 18–20 / 600–700.
  static final cardTitle = _sora(size: 18, weight: 700, height: 24, letterSpacing: -0.2);
  static final cardTitleMedium = _sora(size: 16, weight: 600, height: 22);

  /// Body 16/400/24 — the dominant style on the site.
  static final body = _sora(size: 16, weight: 400, height: 24);
  static final bodyMedium = _sora(size: 16, weight: 500, height: 24);
  static final bodySemibold = _sora(size: 16, weight: 600, height: 24);

  /// Secondary body 14/400/20.
  static final body14 = _sora(size: 14, weight: 400, height: 20);
  static final body14Medium = _sora(size: 14, weight: 500, height: 20);
  static final body14Semibold = _sora(size: 14, weight: 600, height: 20);

  /// Caption 12/400/18.
  static final caption = _sora(size: 12, weight: 400, height: 18);
  static final captionSemibold = _sora(size: 12, weight: 600, height: 18);

  /// Micro label — the `PRIMARY` / `YOU'RE HERE` badges: 10/600 uppercase.
  static final micro = _sora(size: 10, weight: 600, height: 15, letterSpacing: 0.6);

  /// Eyebrow labels sit above form sections and page sections
  /// (`PACKAGE DETAILS`, `NAME`, `SHIPPING CALCULATOR`). Uppercase, small,
  /// semibold, letter-spaced — used structurally throughout the site.
  static final eyebrow = _sora(
    size: 11,
    weight: 600,
    height: 16,
    letterSpacing: 1.1,
    color: AppColors.neutral1,
  );

  /// Referral code / link fields are the only monospace on the site.
  static const mono = TextStyle(
    fontFamily: 'monospace',
    fontFamilyFallback: ['Menlo', 'Courier New'],
    fontSize: 15,
    height: 20 / 15,
    letterSpacing: 1.2,
    color: AppColors.bodyText,
  );
}
