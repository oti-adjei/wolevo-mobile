import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// The landing H1's mixed treatment:
///
///   Shop global.   — solid dark
///   Receive it     — outlined (stroke-only)
///   at home.       — "at" solid, "home." on a rotated neon-green block
class HeroHeadline extends StatelessWidget {
  const HeroHeadline({super.key, this.fontSize = 38});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final base = AppText.h1.copyWith(
      fontSize: fontSize,
      height: 1.12,
      color: AppColors.secondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Shop global.', style: base),
        const SizedBox(height: 2),
        OutlinedHeroText('Receive it', style: base),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('at', style: base),
            const SizedBox(width: 10),
            Transform.rotate(
              angle: -2.5 * math.pi / 180,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: fontSize * 0.22,
                  vertical: fontSize * 0.06,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(fontSize * 0.18),
                ),
                child: Text(
                  'home.',
                  style: base.copyWith(color: AppColors.secondary),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Stroke-only text. Rendered as two layers so the glyph metrics stay identical
/// to the solid lines above and below it.
class OutlinedHeroText extends StatelessWidget {
  const OutlinedHeroText(
    this.text, {
    super.key,
    required this.style,
    this.strokeWidth = 1.6,
    this.strokeColor = AppColors.secondary,
  });

  final String text;
  final TextStyle style;
  final double strokeWidth;
  final Color strokeColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Transparent fill layer keeps the line's size and baseline honest.
        Text(text, style: style.copyWith(color: Colors.transparent)),
        Text(
          text,
          style: style.copyWith(
            color: null,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeJoin = StrokeJoin.round
              ..color = strokeColor,
          ),
        ),
      ],
    );
  }
}
