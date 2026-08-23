/// Build-time environment.
///
/// Selected with `--dart-define=WOLEVO_ENV=staging`. Compile-time rather than a
/// bundled `.env` file on purpose: a `.env` asset ships inside the IPA/APK and
/// can be read by anyone who unzips it, and it can be swapped after signing.
/// `String.fromEnvironment` is baked into the binary at compile time.
///
/// ```bash
/// flutter run                                        # dev
/// flutter run --dart-define=WOLEVO_ENV=staging
/// flutter build ipa --dart-define=WOLEVO_ENV=prod
/// ```
enum AppEnvironment {
  dev(
    name: 'dev',
    apiBaseUrl: 'https://api.wolevo.com/api/v1',
    // Dev talks to production data today because there is no staging API yet;
    // swap this the moment one exists.
    label: 'DEV',
  ),
  staging(
    name: 'staging',
    apiBaseUrl: 'https://staging-api.wolevo.com/api/v1',
    label: 'STAGING',
  ),
  prod(
    name: 'prod',
    apiBaseUrl: 'https://api.wolevo.com/api/v1',
    label: null,
  );

  const AppEnvironment({
    required this.name,
    required this.apiBaseUrl,
    required this.label,
  });

  final String name;
  final String apiBaseUrl;

  /// Shown in a corner banner on non-production builds, so nobody demos
  /// staging thinking it is live. Null in production.
  final String? label;

  bool get isProd => this == AppEnvironment.prod;

  /// Verbose logging and analytics-to-console everywhere except production.
  bool get verboseLogging => !isProd;

  /// Whether crash and analytics reporting should actually transmit. Keeping
  /// this false outside production stops local noise polluting real dashboards.
  bool get reportingEnabled => isProd;

  static const _key = 'WOLEVO_ENV';

  /// The environment this binary was compiled for. Defaults to [dev].
  static final AppEnvironment current = _resolve(
    const String.fromEnvironment(_key, defaultValue: 'dev'),
  );

  static AppEnvironment _resolve(String value) => values.firstWhere(
        (e) => e.name == value.toLowerCase(),
        orElse: () => AppEnvironment.dev,
      );
}

/// Secrets are injected the same way, never committed.
///
/// ```bash
/// flutter build ipa \
///   --dart-define=WOLEVO_ENV=prod \
///   --dart-define=SENTRY_DSN=https://…
/// ```
abstract final class AppSecrets {
  /// Empty means "not configured" — the reporting layer degrades to a no-op
  /// rather than throwing, so a missing key can never crash startup.
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const posthogApiKey = String.fromEnvironment('POSTHOG_API_KEY');
  static const posthogHost = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://eu.i.posthog.com',
  );
}
