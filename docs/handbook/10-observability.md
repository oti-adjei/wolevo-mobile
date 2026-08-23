# 10. Environments, logging & analytics

## Environments

Selected at **compile time** via `--dart-define`, not a bundled `.env` file — a
`.env` asset ships inside the IPA/APK and can be read by anyone who unzips it.

```bash
flutter run                                          # dev (default)
flutter run --dart-define=WOLEVO_ENV=staging
flutter build ipa --dart-define=WOLEVO_ENV=prod
```

`lib/core/env/app_environment.dart`:

| Env | API base URL | Verbose logs | Reporting |
|---|---|---|---|
| `dev` | production API † | ✅ | ❌ |
| `staging` | `staging-api.wolevo.com` | ✅ | ❌ |
| `prod` | `api.wolevo.com` | ❌ | ✅ |

† **There is no staging API yet.** Dev points at production data; change
`AppEnvironment.dev.apiBaseUrl` the moment one exists. Until then, treat dev
writes as real.

Non-production builds show a red corner ribbon (`DEV` / `STAGING`) so nobody
demos or files a bug against the wrong environment.

### Secrets

Same mechanism, never committed:

```bash
flutter build ipa \
  --dart-define=WOLEVO_ENV=prod \
  --dart-define=SENTRY_DSN=https://… \
  --dart-define=POSTHOG_API_KEY=phc_…
```

Missing keys are empty strings, and every consumer degrades to a no-op rather
than throwing — a missing key can never crash startup.

## Logging

`lib/core/logging/app_logger.dart`. **Vendor-neutral by design**: features call
`AppLogger`, never a Sentry API, exactly like they call repository interfaces
rather than Dio.

```dart
final logger = ref.read(loggerProvider);
logger.info('Package registered', context: {'tracking': id});
logger.warn('Icon switch failed', context: {'error': '$e'});
logger.error('Checkout failed', error: e, stackTrace: s);
logger.breadcrumb('Opened cart');
```

| Implementation | Used |
|---|---|
| `ConsoleLogger` | dev + staging |
| `NoopLogger` | production (until a reporter is wired), and tests |

### What is already wired

- **All Flutter framework errors** → `FlutterError.onError`
- **Engine errors** → `platformDispatcher.onError`
- **Stray async errors** → `runZonedGuarded`
- **Every HTTP request** → a breadcrumb; **every HTTP failure** → an error

> ⚠️ The Dio interceptor logs **method, path and status only — never bodies**.
> Responses carry delivery addresses, order contents and locker IDs. If you add
> logging, keep payloads out of it.

## Analytics

`lib/core/analytics/analytics.dart`. Same seam shape.

```dart
ref.read(analyticsProvider).track(
  AnalyticsEvents.packageRegistered,
  properties: {'destination': 'GH'},
);
```

Event names are **constants**, not inline strings — a typo is invisible until
someone opens a dashboard weeks later and finds a hole in a funnel.

`LoggingAnalytics` prints events to the console outside production;
`NoopAnalytics` drops them. **No events are instrumented in features yet** —
the seam exists, the call sites do not.

## Running: debug, profile, release

`--dart-define` combines with the build mode; they are independent axes.

```bash
# Debug — hot reload, assertions on, slowest
flutter run
flutter run --dart-define=WOLEVO_ENV=staging

# Profile — release-speed with the performance overlay + DevTools timeline.
# Use this for any judgement about jank. Never judge performance in debug.
flutter run --profile --dart-define=WOLEVO_ENV=staging

# Release — what ships. No hot reload, no DevTools by default.
flutter run --release --dart-define=WOLEVO_ENV=prod
```

Profile and release **cannot run on the iOS Simulator** — they need a physical
device (`flutter devices` to list). The Android emulator runs all three.

Artefacts:

```bash
flutter build apk    --release --dart-define=WOLEVO_ENV=prod
flutter build appbundle --release --dart-define=WOLEVO_ENV=prod   # Play Store
flutter build ipa    --release --dart-define=WOLEVO_ENV=prod      # App Store
```

Because reporting is gated on `env.reportingEnabled`, a **release build of the
`dev` environment still reports nothing** — mode and environment are separate
switches, and it is the environment that decides.

## Sentry — written, not installed

> ⚠️ **Sentry is currently NOT installed.** `sentry_flutter` (tried 8.14 and
> 9.26) fails to compile its iOS SDK under **Xcode 26**:
>
> ```
> Swift Compiler Error: Value of type 'SentryBinaryImageCache' has no member 'image'
> ```
>
> This is inside sentry-cocoa, not our code, and downgrading did not help. The
> package was removed so the build stays green.

Everything else is done and waiting:

- `SentryLogger implements AppLogger` — parked at
  `lib/core/logging/sentry_logger.dart.disabled`
- `Observability.start()` already has the init seam and sets `_sentryEnabled`
- `loggerProvider` already falls back to console when Sentry is off

**To restore, once Sentry ships an Xcode 26 fix:**

1. `flutter pub add sentry_flutter`
2. `mv lib/core/logging/sentry_logger.dart.disabled lib/core/logging/sentry_logger.dart`
3. In `Observability.start`, replace `_sentryEnabled = false;` with the
   `SentryFlutter.init(...)` block and set it from the DSN
4. In `loggerProvider`, return `SentryLogger(fallback: console)` when
   `Observability.sentryEnabled`

**No feature code changes** — that is the point of the seam.

When you do: keep `tracesSampleRate` well below 1.0, `sendDefaultPii = false`,
and scrub query strings in `beforeSend`. The API puts raw emails in the URL on
`forgot-password` and `resend-verification-email`; those must not reach a third
party.

**Check SPM support for any SDK you add.** This project has no CocoaPods and
deliberately builds with Swift Package Manager — a CocoaPods-only package drags
the whole toolchain back in. PostHog and Sentry both ship `Package.swift`.

## PostHog — installed

`posthog_flutter` is added and wired:

- `PostHogAnalytics implements AnalyticsClient` in
  `lib/core/analytics/posthog_analytics.dart`
- Started in `Observability.start()` when `reportingEnabled` **and**
  `POSTHOG_API_KEY` is set — so it is inert locally
- `analyticsProvider` returns it automatically; otherwise events go to the
  console

Null property values are dropped before sending, rather than arriving as the
string `"null"` and showing up as real values in dashboards.

### Instrumented funnel

Events fire from **controllers, not widgets**, wherever possible — a controller
runs once per action, a widget rebuilds.

| Event | Fired from |
|---|---|
| `onboarding_completed` / `onboarding_skipped` | `OnboardingScreen._finish` (+ which slide) |
| `signed_up` / `signed_in` / `signed_out` | `SessionController` |
| `locker_address_viewed` | `LockerAddressPanel` — on expand only |
| `locker_field_copied` | `CopyChip` — field **name** only, never the value |
| `product_searched` | `ShopQueryController.submitKeyword` — on submit, not per keystroke |
| `product_viewed` | `ProductDetailController.build` — once per load |
| `added_to_cart` | `CartController.addItem` |
| `checkout_started` | entering the delivery step, guarded against re-entry |
| `order_placed` | `CheckoutController.pay` |
| `shipping_estimated` | `CalculatorController.submit` — often pre-signup |
| `referral_shared` | intent only; the OS does not report share outcomes |
| `app_icon_changed` | `AppIconController.select` |

`identify()` runs on login, registration **and session restore** — without the
last one, every event in a returning user's session is anonymous. `reset()`
runs on logout, after the sign-out event.

Screen views come from `AnalyticsNavigatorObserver`, registered on the router,
so a new route cannot silently go untracked. Only the **path** is sent — query
strings carry search terms, product ids and the `next` destination.

### What is deliberately not sent

Email, phone, locker ID, delivery addresses, tracking numbers, cart item titles.
The locker ID maps 1:1 to a physical parcel at the warehouse, so it is treated
as identifying. Prices, country codes, retailer enums and counts are sent —
those are the numbers the funnel is actually about.

## Gaps

- **Sentry blocked on an Xcode 26 incompatibility** — production currently has
  no crash reporting
- No analytics events are fired from features yet; the seam and event names
  exist, the call sites do not
- No staging API exists
- No release/CI pipeline sets these defines automatically
