import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';

/// The Wolevo wordmark. No logo asset ships with the app, so the mark is pure
/// type: lowercase, tight, dark green, with the dot in brand neon.
class WolevoWordmark extends StatelessWidget {
  const WolevoWordmark({super.key, this.fontSize = 24, this.color});

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'wolevo',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: fontSize,
            height: 1.1,
            letterSpacing: -1,
            fontWeight: FontWeight.w700,
            fontVariations: const [FontVariation('wght', 700)],
            color: color ?? AppColors.secondary,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: fontSize * 0.14, left: 2),
          child: Container(
            height: fontSize * 0.17,
            width: fontSize * 0.17,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

/// Login | Sign Up strip. `/auth/login` and `/auth/register` are two tabs of
/// one card on the web app.
class AuthTabStrip extends StatelessWidget {
  const AuthTabStrip({
    super.key,
    required this.loginSelected,
    required this.onLogin,
    required this.onSignUp,
  });

  final bool loginSelected;
  final VoidCallback onLogin;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rPill,
      ),
      child: Row(
        children: [
          Expanded(
            child: _Tab(
              label: 'Login',
              selected: loginSelected,
              onTap: onLogin,
            ),
          ),
          Expanded(
            child: _Tab(
              label: 'Sign Up',
              selected: !loginSelected,
              onTap: onSignUp,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: selected ? null : onTap,
      borderRadius: AppRadius.rPill,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.background : Colors.transparent,
          borderRadius: AppRadius.rPill,
          border: Border.all(
            color: selected ? AppColors.surface4 : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: AppText.body14Semibold.copyWith(
            color: selected ? AppColors.secondary : AppColors.neutral1,
          ),
        ),
      ),
    );
  }
}

/// The hairline `or` rule between the primary CTA and the Google button.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, this.label = 'or'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.surface4, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          child: Text(
            label,
            style: AppText.body14.copyWith(color: AppColors.neutral2),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.surface4, height: 1)),
      ],
    );
  }
}

/// White button with a drawn `G` mark — no Google asset ships with the app.
/// Google is the only social provider on both auth screens.
class GoogleAuthButton extends StatelessWidget {
  const GoogleAuthButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.bodyText,
          side: const BorderSide(color: AppColors.surface4),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rInput),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.bodyText,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _GoogleMark(),
                  const SizedBox(width: AppSpace.md),
                  Flexible(
                    child: Text(
                      label,
                      style: AppText.bodySemibold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      width: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface4),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontFamily: 'Sora',
          fontSize: 13,
          height: 1,
          fontWeight: FontWeight.w700,
          // Google's own brand blue — deliberately NOT an AppColors token, since
          // it belongs to a third party and must not drift with our palette.
          color: Color(0xFF4285F4),
        ),
      ),
    );
  }
}

/// Centered, width-capped page body used by all three auth screens, so the
/// card reads correctly on a 375px phone and on a tablet alike.
class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface6,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.gutter,
            vertical: AppSpace.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Don't have an account? **Sign up for free**" style footer line.
class AuthFooterPrompt extends StatelessWidget {
  const AuthFooterPrompt({
    super.key,
    required this.question,
    required this.action,
    required this.onTap,
  });

  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            question,
            style: AppText.body14.copyWith(color: AppColors.neutral1),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: onTap,
          borderRadius: AppRadius.rSm,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Text(
              action,
              style: AppText.body14Semibold.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
