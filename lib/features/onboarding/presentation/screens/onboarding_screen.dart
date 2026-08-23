import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/wolevo_mark.dart';
import '../../data/onboarding_content.dart';
import '../../data/onboarding_repository.dart';

/// First-launch carousel.
///
/// This replaces the marketing landing page on a first run rather than sitting
/// in front of it. The web landing is a long scroll — hero, stats, how-it-works,
/// calculator, CTA — which is a desktop pattern; four swipeable slides are its
/// native equivalent. Showing both would onboard the user twice before they can
/// do anything, so the landing is only reachable afterwards (via `Explore first`
/// or on later launches).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static final _slides = OnboardingContent.slides;

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish(String destination, {required bool completed}) async {
    ref.read(analyticsProvider).track(
      completed
          ? AnalyticsEvents.onboardingCompleted
          : AnalyticsEvents.onboardingSkipped,
      // Which slide they left on is the useful part: it says where the story
      // stops holding attention.
      properties: {'last_slide': _index + 1, 'slide_count': _slides.length},
    );
    await ref.read(onboardingRepositoryProvider).markSeen();
    ref.invalidate(hasSeenOnboardingProvider);
    if (mounted) context.go(destination);
  }

  void _next() {
    if (_isLast) {
      _finish(AppRoutes.register, completed: true);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                AppSpace.md,
                AppSpace.sm,
                0,
              ),
              child: Row(
                children: [
                  const WolevoMark(width: 34, color: AppColors.secondary),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    'wolevo',
                    style: AppText.cardTitleMedium.copyWith(
                      color: AppColors.secondary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _finish(AppRoutes.register, completed: false),
                    style: TextButton.styleFrom(foregroundColor: AppColors.neutral1),
                    child: Text('Skip', style: AppText.body14Semibold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _Slide(slide: _slides[i]),
              ),
            ),
            _Dots(count: _slides.length, index: _index),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                AppSpace.xl,
                AppSpace.gutter,
                AppSpace.lg,
              ),
              child: Column(
                children: [
                  PrimaryButton(
                    label: _isLast ? 'Create your account' : 'Next',
                    trailingIcon: Icons.arrow_forward,
                    onPressed: _next,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  if (_isLast)
                    TextButton(
                      onPressed: () => _finish(AppRoutes.login, completed: true),
                      style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
                      child: Text(
                        'I already have an account',
                        style: AppText.body14Semibold,
                      ),
                    )
                  else
                    TextButton(
                      onPressed: () => _finish(AppRoutes.landing, completed: false),
                      style: TextButton.styleFrom(foregroundColor: AppColors.neutral1),
                      child: Text('Explore first', style: AppText.body14Semibold),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.xl,
        AppSpace.gutter,
        AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // No illustration assets exist, so the visual is built from the brand
          // itself: a tinted panel carrying the section's icon.
          _SlideArt(icon: slide.icon, accent: slide.accent),
          const SizedBox(height: AppSpace.section),
          Text(
            slide.eyebrow.toUpperCase(),
            style: AppText.eyebrow.copyWith(color: AppColors.secondary3),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(slide.title, style: AppText.h2),
          const SizedBox(height: AppSpace.md),
          Text(
            slide.body,
            style: AppText.body.copyWith(color: AppColors.neutral1),
          ),
          if (slide.bullets.isNotEmpty) ...[
            const SizedBox(height: AppSpace.xl),
            for (final bullet in slide.bullets) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle,
                      size: 18,
                      color: AppColors.secondary3,
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(child: Text(bullet, style: AppText.body14)),
                ],
              ),
              const SizedBox(height: AppSpace.md),
            ],
          ],
          if (slide.stat case final stat?) ...[
            const SizedBox(height: AppSpace.md),
            AppCard(
              color: AppColors.tertiary3,
              borderColor: AppColors.tertiary2,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.md,
              ),
              child: Row(
                children: [
                  Text(
                    stat,
                    style: AppText.h3.copyWith(color: AppColors.secondary),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Text(
                      slide.statCaption ?? '',
                      style: AppText.caption.copyWith(color: AppColors.neutral),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SlideArt extends StatelessWidget {
  const _SlideArt({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: AppRadius.rCardLarge,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The mark, faint, as a watermark behind the icon.
          Positioned(
            right: -20,
            bottom: -10,
            child: Opacity(
              opacity: 0.10,
              child: WolevoMark(width: 150, color: accent),
            ),
          ),
          Container(
            height: 84,
            width: 84,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: AppRadius.rCardLarge,
            ),
            child: Icon(icon, size: 40, color: AppColors.secondary),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            width: i == index ? 22 : 6,
            decoration: BoxDecoration(
              color: i == index ? AppColors.secondary : AppColors.surface4,
              borderRadius: AppRadius.rPill,
            ),
          ),
      ],
    );
  }
}
