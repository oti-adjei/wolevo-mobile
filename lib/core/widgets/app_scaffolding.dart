import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';
import 'app_buttons.dart';

/// Uppercase, letter-spaced label that introduces a section or a form group —
/// `PACKAGE DETAILS`, `SHIPPING CALCULATOR`, `NAME`. Used structurally all over
/// the site.
class EyebrowLabel extends StatelessWidget {
  const EyebrowLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppText.eyebrow.copyWith(color: color ?? AppColors.neutral1),
    );
  }
}

/// Section heading with an optional trailing action (`Show all →`).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.eyebrow,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                EyebrowLabel(eyebrow!),
                const SizedBox(height: AppSpace.sm),
              ],
              // cardTitle (18/700), not h3 (22/700): at display size these
              // section headings competed with the content beneath them.
              Text(title, style: AppText.cardTitle),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpace.xs),
                Text(
                  subtitle!,
                  style: AppText.body14.copyWith(color: AppColors.neutral1),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          Padding(
            padding: const EdgeInsets.only(left: AppSpace.md),
            child: TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!, style: AppText.body14Semibold),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Centered empty / zero-data state. The site pairs a short headline, a
/// supporting line and a single CTA.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.section,
          vertical: AppSpace.sectionLarge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 48, color: AppColors.surface4),
              const SizedBox(height: AppSpace.lg),
            ],
            Text(title, style: AppText.cardTitle, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: AppSpace.sm),
              Text(
                message!,
                style: AppText.body14.copyWith(color: AppColors.neutral1),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpace.xxl),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-screen failure state with a retry affordance.
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      title: 'Something went wrong',
      message: message,
      actionLabel: onRetry == null ? null : 'Try again',
      onAction: onRetry,
    );
  }
}

/// Centered spinner in brand green.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 28,
            width: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.secondary,
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: AppSpace.md),
            Text(
              label!,
              style: AppText.body14.copyWith(color: AppColors.neutral1),
            ),
          ],
        ],
      ),
    );
  }
}

/// A sheet header with a title and a close affordance, for the bottom sheets
/// that replace the web app's dropdowns and centered modals.
class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xl,
        0,
        AppSpace.sm,
        AppSpace.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.cardTitle),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppText.body14.copyWith(color: AppColors.neutral1),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close, size: 20, color: AppColors.neutral1),
          ),
        ],
      ),
    );
  }
}

/// Shows a bottom sheet using the app's standard shape and insets. Every
/// dropdown / select in the web app becomes one of these on mobile.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: builder(ctx),
    ),
  );
}
