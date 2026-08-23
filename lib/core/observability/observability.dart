import 'dart:async';

import 'package:posthog_flutter/posthog_flutter.dart';

import '../env/app_environment.dart';

/// Starts crash reporting and analytics, then runs the app.
///
/// Both SDKs are optional at runtime: with no DSN or API key configured they
/// are simply never initialised, and the providers fall back to the console
/// implementations. A missing secret can never break a build or a launch.
class Observability {
  const Observability._();

  static bool _sentryEnabled = false;
  static bool _postHogEnabled = false;

  /// True once Sentry is running. The app uses this to avoid installing its own
  /// error handlers on top of Sentry's, which would report everything twice.
  static bool get sentryEnabled => _sentryEnabled;

  static bool get postHogEnabled => _postHogEnabled;

  static Future<void> start(FutureOr<void> Function() appRunner) async {
    final env = AppEnvironment.current;

    _postHogEnabled =
        env.reportingEnabled && AppSecrets.posthogApiKey.isNotEmpty;
    if (_postHogEnabled) {
      await Posthog().setup(
        PostHogConfig(AppSecrets.posthogApiKey)
          ..host = AppSecrets.posthogHost
          // Screen views are sent explicitly through AnalyticsClient.screen so
          // the names match the route table rather than widget class names.
          ..captureApplicationLifecycleEvents = true,
      );
    }

    // Sentry is NOT installed: sentry_flutter's iOS SDK fails to compile under
    // Xcode 26 ("SentryBinaryImageCache has no member 'image'") on both 8.x and
    // 9.x. The seam, the scrubbing plan and SentryLogger are all written and
    // ready — see docs/handbook/10-observability.md for the two-step restore.
    _sentryEnabled = false;

    await appRunner();
  }

  /// When Sentry is restored, `beforeSend` must strip query strings: the API
  /// puts raw emails in the URL on `forgot-password` and
  /// `resend-verification-email`, and those must not reach a third party.
}
