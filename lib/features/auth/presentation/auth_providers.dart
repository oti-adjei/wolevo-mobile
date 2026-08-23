import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';
import '../data/mock_auth_repository.dart';

/// Swap this single line for a Dio-backed implementation to go live.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(ref.watch(tokenStorageProvider)),
);

/// The session is the app's root state: null means logged out, and the router
/// listens to it for its auth guard.
class SessionController extends AsyncNotifier<AuthSession?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  AnalyticsClient get _analytics => ref.read(analyticsProvider);
  AppLogger get _logger => ref.read(loggerProvider);

  /// Ties analytics and crash reports to the user.
  ///
  /// Only the opaque id and non-identifying traits are sent — never the email,
  /// phone or locker ID. The locker ID in particular maps 1:1 to a physical
  /// parcel at the warehouse, so it is treated as identifying.
  void _attachIdentity(AuthSession session) {
    _analytics.identify(
      userId: session.user.id,
      traits: {
        'destination_country': session.user.destinationCountry.code,
        'account_type': session.user.accountType.apiValue,
        'email_verified': session.user.emailVerified,
      },
    );
    _logger.setUser(id: session.user.id);
  }

  @override
  Future<AuthSession?> build() async {
    final session = await _repo.restore();
    // A restored session is not a sign-in event, but it still needs an identity
    // attached or every event this launch is anonymous.
    if (session != null) _attachIdentity(session);
    return session;
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.login(LoginRequest(email: email, password: password)),
    );
    // Surface the failure to the caller so the form can show its banner.
    state.maybeWhen(error: (e, st) => throw e, orElse: () {});

    if (state.valueOrNull case final session?) {
      _attachIdentity(session);
      _analytics.track(AnalyticsEvents.signedIn, properties: {'method': 'password'});
    }
  }

  Future<void> register(RegisterRequest request) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.register(request));
    state.maybeWhen(error: (e, st) => throw e, orElse: () {});

    if (state.valueOrNull case final session?) {
      _attachIdentity(session);
      _analytics.track(AnalyticsEvents.signedUp, properties: {
        'method': 'password',
        'destination_country': session.user.destinationCountry.code,
        // Whether the referral programme actually drives signups is the first
        // question anyone will ask of this funnel.
        'used_referral': request.referralCode?.isNotEmpty ?? false,
      });
    }
  }

  Future<void> continueWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.continueWithGoogle());
    state.maybeWhen(error: (e, st) => throw e, orElse: () {});

    if (state.valueOrNull case final session?) {
      _attachIdentity(session);
      _analytics.track(AnalyticsEvents.signedIn, properties: {'method': 'google'});
    }
  }

  Future<void> logout() async {
    _analytics.track(AnalyticsEvents.signedOut);
    await _repo.logout();
    state = const AsyncValue.data(null);

    // Reset last: everything after this point belongs to nobody, and without it
    // the next user on this device inherits the previous person's events.
    await _analytics.reset();
    _logger.setUser(id: null);
  }

  /// Used by the verify-email sheet's "I've Already Verified" action.
  Future<bool> refreshVerification() async {
    final user = await _repo.refreshUser();
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(user: user));
    }
    return user.emailVerified;
  }

  /// Applies a locally-edited profile (name, DOB, preferences) to the session.
  void applyUser(WolevoUser user) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(user: user));
  }
}

final sessionProvider =
    AsyncNotifierProvider<SessionController, AuthSession?>(SessionController.new);

/// True once a session exists. Reads as false while the initial restore is in
/// flight, which keeps the router on the splash route.
final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(sessionProvider).valueOrNull != null,
);

/// Convenience read for screens that require a user; throws if unauthenticated,
/// which can only happen behind the router's auth guard.
final currentUserProvider = Provider<WolevoUser>(
  (ref) => ref.watch(sessionProvider).requireValue!.user,
);

final warehouseAddressProvider = Provider<WarehouseAddress>(
  (ref) => ref.watch(sessionProvider).requireValue!.warehouseAddress,
);
