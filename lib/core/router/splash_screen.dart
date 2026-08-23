import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/onboarding/data/onboarding_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/wolevo_mark.dart';
import 'routes.dart';

/// The animated splash, shown immediately after the OS launch screen.
///
/// The native splash (flutter_native_splash) can only be a still image — iOS
/// renders a static launch storyboard and Android 12+ permits at most a brief
/// icon animation. So the handoff is staged: the OS shows the mark centred on
/// deep green, this screen opens with exactly the same mark at the same size on
/// the same background, then animates. The seam is invisible.
///
/// It also does useful work: it holds the first frame until the stored session
/// has been restored, which is what decides whether the user lands on Home or
/// on the marketing page.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// Matches the mark size the native splash renders (39% of a 768px canvas on
  /// a phone-width screen). Keep in step with tool/generate_brand_assets.py —
  /// if these two drift, the mark jumps as the OS splash hands over.
  static const markWidth = 99.0;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  late final Animation<double> _wipe = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.05, 0.55, curve: Curves.easeInOutCubic),
  );

  late final Animation<double> _dot = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.45, 0.75, curve: Curves.easeOutBack),
  );

  late final Animation<double> _wordmark = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.6, 0.95, curve: Curves.easeOut),
  );

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _leave();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Leaves only once the animation has finished AND both the session and the
  /// first-launch flag have resolved, so a returning user never sees the
  /// landing page flash past.
  void _leave() {
    if (_navigated || !mounted) return;
    final session = ref.read(sessionProvider);
    if (session.isLoading) return;

    final seenOnboarding = ref.read(hasSeenOnboardingProvider);
    if (seenOnboarding.isLoading) return;

    // maybeOf rather than of: the splash is also rendered in widget tests and
    // previews, where there is no router above it and `go` would throw.
    final router = GoRouter.maybeOf(context);
    if (router == null) return;

    _navigated = true;
    if (session.valueOrNull != null) {
      router.go(AppRoutes.home);
    } else {
      // First launch gets the carousel instead of the marketing scroll.
      router.go(
        seenOnboarding.valueOrNull == true
            ? AppRoutes.landing
            : AppRoutes.onboarding,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-check when the restore lands, in case it resolved after the animation.
    ref.listen(sessionProvider, (_, _) {
      if (_controller.isCompleted) _leave();
    });
    ref.listen(hasSeenOnboardingProvider, (_, _) {
      if (_controller.isCompleted) _leave();
    });

    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedWolevoMark(
                  width: SplashScreen.markWidth,
                  wipe: _wipe.value,
                  dot: _dot.value,
                ),
                const SizedBox(height: 20),
                Opacity(
                  opacity: _wordmark.value,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - _wordmark.value)),
                    child: Text(
                      'wolevo',
                      style: AppText.h3.copyWith(
                        color: Colors.white,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
