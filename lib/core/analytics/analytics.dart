import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../observability/observability.dart';
import 'posthog_analytics.dart';
import '../logging/app_logger.dart';

/// Product analytics seam — the shape PostHog (or any other tool) plugs into.
///
/// Features call this, never a vendor SDK, for the same reason repositories are
/// interfaces: swapping the backend must not touch feature code.
abstract interface class AnalyticsClient {
  void track(String event, {Map<String, Object?> properties});

  /// Ties events to a user. Call with null on logout.
  void identify({String? userId, Map<String, Object?> traits});

  /// Screen views. go_router can drive this from one observer rather than
  /// every screen remembering to fire it.
  void screen(String name, {Map<String, Object?> properties});

  /// Clears the identity and any queued events — call on logout, so the next
  /// user's events are not attributed to the previous one.
  Future<void> reset();
}

/// Event names.
///
/// Constants rather than inline strings: a typo in an event name is invisible
/// until someone opens a dashboard weeks later and finds a funnel with a hole
/// in it. Keep them `snake_case` and past-tense.
abstract final class AnalyticsEvents {
  // Onboarding & auth
  static const onboardingCompleted = 'onboarding_completed';
  static const onboardingSkipped = 'onboarding_skipped';
  static const signedUp = 'signed_up';
  static const signedIn = 'signed_in';
  static const signedOut = 'signed_out';

  // The forwarding flow — the funnel that matters most commercially
  static const lockerAddressViewed = 'locker_address_viewed';
  static const lockerFieldCopied = 'locker_field_copied';
  static const packageRegistered = 'package_registered';

  // The shopping flow
  static const productSearched = 'product_searched';
  static const productViewed = 'product_viewed';
  static const addedToCart = 'added_to_cart';
  static const checkoutStarted = 'checkout_started';
  static const orderPlaced = 'order_placed';

  // Supporting
  static const shippingEstimated = 'shipping_estimated';
  static const referralShared = 'referral_shared';
  static const appIconChanged = 'app_icon_changed';
}

/// Writes events to the log instead of sending them. The default outside
/// production, so the event stream can be eyeballed during development without
/// polluting real dashboards.
class LoggingAnalytics implements AnalyticsClient {
  const LoggingAnalytics(this._logger);

  final AppLogger _logger;

  @override
  void track(String event, {Map<String, Object?> properties = const {}}) {
    _logger.breadcrumb('📊 $event', data: properties);
  }

  @override
  void identify({String? userId, Map<String, Object?> traits = const {}}) {
    _logger.debug('📊 identify ${userId ?? 'anonymous'}', context: traits);
  }

  @override
  void screen(String name, {Map<String, Object?> properties = const {}}) {
    _logger.breadcrumb('📊 screen $name', data: properties);
  }

  @override
  Future<void> reset() async => _logger.debug('📊 analytics reset');
}

/// Drops everything. Used in tests, and in production until PostHog is wired.
class NoopAnalytics implements AnalyticsClient {
  const NoopAnalytics();

  @override
  void track(String event, {Map<String, Object?> properties = const {}}) {}

  @override
  void identify({String? userId, Map<String, Object?> traits = const {}}) {}

  @override
  void screen(String name, {Map<String, Object?> properties = const {}}) {}

  @override
  Future<void> reset() async {}
}

final analyticsProvider = Provider<AnalyticsClient>((ref) {
  // PostHog only when it actually started — see Observability.start. Otherwise
  // events go to the console, so the stream is still inspectable locally.
  if (Observability.postHogEnabled) return const PostHogAnalytics();
  return LoggingAnalytics(ref.watch(loggerProvider));
});
