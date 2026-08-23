import 'package:posthog_flutter/posthog_flutter.dart';

import 'analytics.dart';

/// Sends product analytics to PostHog.
///
/// Written against [AnalyticsClient] so no feature knows PostHog exists.
///
/// PostHog's Dart API takes `Map<String, Object>` — non-nullable values — while
/// the seam allows nulls for convenience at call sites. Nulls are dropped here
/// rather than being sent as the string "null", which would otherwise show up
/// as a real property value in dashboards.
class PostHogAnalytics implements AnalyticsClient {
  const PostHogAnalytics();

  @override
  void track(String event, {Map<String, Object?> properties = const {}}) {
    Posthog().capture(
      eventName: event,
      properties: _clean(properties),
    );
  }

  @override
  void identify({String? userId, Map<String, Object?> traits = const {}}) {
    if (userId == null) {
      // No id means "no longer a known user" — reset rather than identify, or
      // the next session inherits the previous person's events.
      reset();
      return;
    }
    Posthog().identify(
      userId: userId,
      userProperties: _clean(traits),
    );
  }

  @override
  void screen(String name, {Map<String, Object?> properties = const {}}) {
    Posthog().screen(
      screenName: name,
      properties: _clean(properties),
    );
  }

  @override
  Future<void> reset() => Posthog().reset();

  Map<String, Object>? _clean(Map<String, Object?> input) {
    final cleaned = <String, Object>{
      for (final entry in input.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
    return cleaned.isEmpty ? null : cleaned;
  }
}
