import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the onboarding carousel has been shown.
///
/// Deliberately not in secure storage — this is a UI preference, not a secret,
/// and it should survive a logout so a returning user is never onboarded twice.
abstract interface class OnboardingRepository {
  Future<bool> hasSeenOnboarding();

  Future<void> markSeen();
}

class PrefsOnboardingRepository implements OnboardingRepository {
  static const _key = 'wolevo.onboarding.seen';

  /// Reads never throw. If the platform channel is unavailable — which happens
  /// when the binary predates the plugin, or on a platform where prefs are
  /// unsupported — the honest answer is "we don't know", and showing onboarding
  /// again is a far better failure than blocking startup.
  @override
  Future<bool> hasSeenOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Writes never throw either: failing to remember the flag means the user
  /// sees onboarding once more, which must not stop them navigating onward.
  @override
  Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {
      // Ignored by design — see above.
    }
  }
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => PrefsOnboardingRepository(),
);

/// Resolved once at startup by the splash, which decides where to route.
final hasSeenOnboardingProvider = FutureProvider<bool>(
  (ref) => ref.watch(onboardingRepositoryProvider).hasSeenOnboarding(),
);
