import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';

/// White card on the light-gray page: 12–16px radius, hairline border, no
/// shadow. The workhorse container across every screen.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.cardPadding),
    this.onTap,
    this.color = AppColors.background,
    this.borderColor = AppColors.surface4,
    this.radius = AppRadius.rCard,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;
  final BorderRadius radius;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        border: Border.all(color: borderColor),
      ),
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      child: child,
    );

    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: radius, onTap: onTap, child: body),
    );
  }
}

/// A card that can be picked, mirroring the site's selectable cards: mint fill,
/// darker green border, and a `✓ Selected` line when active.
class SelectableCard extends StatelessWidget {
  const SelectableCard({
    super.key,
    required this.selected,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpace.lg),
  });

  final bool selected;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: padding,
      color: selected ? AppColors.secondary2 : AppColors.background,
      borderColor: selected ? AppColors.secondary3 : AppColors.surface4,
      radius: AppRadius.rCardLarge,
      child: child,
    );
  }
}

/// The `✓ Selected` affordance that sits at the bottom of a chosen card.
class SelectedMarker extends StatelessWidget {
  const SelectedMarker({super.key, this.label = 'Selected'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check, size: 14, color: AppColors.secondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppText.body14Semibold.copyWith(color: AppColors.secondary),
        ),
      ],
    );
  }
}

/// Mint rounded-square holding a line icon — used ahead of card titles.
class IconChip extends StatelessWidget {
  const IconChip({
    super.key,
    required this.icon,
    this.background = AppColors.secondary2,
    this.foreground = AppColors.secondary,
    this.size = 44,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.rCard,
      ),
      child: Icon(icon, size: size * 0.45, color: foreground),
    );
  }
}

/// Pale-lime informational block. The site uses these for the currency note in
/// the cart and the landed-cost box on a product.
class InfoCallout extends StatelessWidget {
  const InfoCallout({
    super.key,
    required this.child,
    this.leading = '💡',
    this.background = AppColors.tertiary3,
  });

  final Widget child;
  final String? leading;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.rCard,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            Text(leading!, style: AppText.body14),
            const SizedBox(width: AppSpace.sm),
          ],
          Expanded(
            child: DefaultTextStyle(style: AppText.body14, child: child),
          ),
        ],
      ),
    );
  }
}

/// Small uppercase badge — `PRIMARY`, `YOU'RE HERE`, status pills.
class MicroBadge extends StatelessWidget {
  const MicroBadge({
    super.key,
    required this.label,
    this.background = AppColors.tertiary,
    this.foreground = AppColors.secondary,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: AppRadius.rSm),
      child: Text(
        label.toUpperCase(),
        style: AppText.micro.copyWith(color: foreground),
      ),
    );
  }
}
