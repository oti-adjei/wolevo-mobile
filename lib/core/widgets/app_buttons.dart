import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';

enum AppButtonSize { regular, compact }

/// Deep-green fill, white label, no shadow. Disabled keeps the same shape at
/// ~55% opacity — matching the site's disabled `Next` / `Checkout` buttons.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.expand = true,
    this.pill = false,
    this.size = AppButtonSize.regular,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool loading;
  final bool expand;
  final bool pill;
  final AppButtonSize size;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: SizedBox(
        width: expand ? double.infinity : null,
        height: size == AppButtonSize.compact ? 44 : 52,
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.secondary,
            disabledBackgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
            shape: RoundedRectangleBorder(
              borderRadius: pill ? AppRadius.rPill : AppRadius.rInput,
            ),
          ),
          child: _ButtonBody(
            label: label,
            icon: icon,
            trailingIcon: trailingIcon,
            loading: loading,
            color: Colors.white,
            size: size,
          ),
        ),
      ),
    );
  }
}

/// White fill, hairline border, dark label.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
    this.pill = false,
    this.size = AppButtonSize.regular,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool pill;
  final AppButtonSize size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expand ? double.infinity : null,
      height: size == AppButtonSize.compact ? 44 : 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.bodyText,
          side: const BorderSide(color: AppColors.surface4),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
          shape: RoundedRectangleBorder(
            borderRadius: pill ? AppRadius.rPill : AppRadius.rInput,
          ),
        ),
        child: _ButtonBody(
          label: label,
          icon: icon,
          loading: false,
          color: AppColors.bodyText,
          size: size,
        ),
      ),
    );
  }
}

/// Lime fill with dark-green label, always a full pill. Used for the site's
/// accent CTAs (`Have a product link? Click to paste`, calculator tab toggle).
class AccentButton extends StatelessWidget {
  const AccentButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = false,
    this.size = AppButtonSize.compact,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final AppButtonSize size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expand ? double.infinity : null,
      height: size == AppButtonSize.compact ? 44 : 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.tertiary,
          foregroundColor: AppColors.secondary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rPill),
        ),
        child: _ButtonBody(
          label: label,
          icon: icon,
          loading: false,
          color: AppColors.secondary,
          size: size,
        ),
      ),
    );
  }
}

/// White fill, red border, red label. The site never uses a solid red fill.
class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = false,
    this.size = AppButtonSize.compact,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final AppButtonSize size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expand ? double.infinity : null,
      height: size == AppButtonSize.compact ? 44 : 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rInput),
        ),
        child: _ButtonBody(
          label: label,
          icon: icon,
          loading: false,
          color: AppColors.error,
          size: size,
        ),
      ),
    );
  }
}

/// Plain text link styled like the site's inline actions (`Forgot password?`,
/// `Sign up for free`).
class AppTextLink extends StatelessWidget {
  const AppTextLink({
    super.key,
    required this.label,
    this.onPressed,
    this.color = AppColors.secondary,
    this.underline = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: AppRadius.rSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Text(
          label,
          style: AppText.body14Semibold.copyWith(
            color: color,
            decoration: underline ? TextDecoration.underline : null,
          ),
        ),
      ),
    );
  }
}

class _ButtonBody extends StatelessWidget {
  const _ButtonBody({
    required this.label,
    required this.loading,
    required this.color,
    required this.size,
    this.icon,
    this.trailingIcon,
  });

  final String label;
  final bool loading;
  final Color color;
  final AppButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }

    final style = size == AppButtonSize.compact ? AppText.body14Semibold : AppText.bodySemibold;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpace.sm),
        ],
        Flexible(
          child: Text(
            label,
            style: style.copyWith(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: AppSpace.sm),
          Icon(trailingIcon, size: 18, color: color),
        ],
      ],
    );
  }
}
