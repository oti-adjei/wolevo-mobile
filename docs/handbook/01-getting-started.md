# 1. Getting started

## Toolchain

Flutter **3.44.8** / Dart 3.12.2.

**fvm is optional.** Any install of 3.44.8 works — if `flutter --version`
already reports it, nothing else is needed and you can ignore the `PATH` lines
throughout this handbook.

The machine this was built on uses fvm, hence:

```bash
export PATH="$HOME/fvm/versions/3.44.8/bin:$PATH"   # only if you use fvm
flutter --version
```

`.fvm/` and `.fvmrc` are gitignored, so the choice is per-developer rather than
imposed by the repo. The rest of this handbook assumes `flutter` is on your
PATH, however it got there.

## Run it

```bash
flutter pub get
flutter run
```

The app runs entirely on mock data — no backend, no API keys, no `.env`.

### Demo credentials

| Field | Value |
|---|---|
| Email | `demo@wolevo.com` |
| Password | `Demo1234!` |

Registering a new account also works and behaves like the real site: you are
signed in immediately, a locker ID is generated on the spot, and email
verification is left pending but never blocks you.

Promo code `WOLEVO10` applies 10% in the cart.

## Build modes

Mode and environment are independent axes:

```bash
flutter run                                   # debug, dev
flutter run --profile --dart-define=WOLEVO_ENV=staging
flutter run --release --dart-define=WOLEVO_ENV=prod
```

Profile and release **cannot run on the iOS Simulator** — physical device only.
Full detail in [Environments, logging & analytics](10-observability.md).

## Verify

Both must be clean before you push:

```bash
flutter analyze      # expect: No issues found!
flutter test         # expect: 27 tests, All tests passed!
```

## Platform notes

**iOS minimum is 14.0**, not Flutter's default 13.0, because `file_picker`'s
darwin package requires it. It is set in
`ios/Runner.xcodeproj/project.pbxproj` (three build configs).

If you ever see:

```
The package product 'file-picker-darwin' requires minimum platform version 14.0
for the iOS platform, but this target supports 13.0
```

…the project setting is fine but the **generated Swift package is stale**.
`ios/Flutter/ephemeral/` pins the iOS version at generation time and is not
regenerated when the setting changes. Fix:

```bash
rm -rf ios/Flutter/ephemeral
flutter run
```

**After adding any plugin, do a full stop and re-run.** Hot restart only
reloads Dart; a new platform channel needs the native binary rebuilt. The
symptom is a `PlatformException(channel-error, Unable to establish connection
on channel: ...)`.

## Dependencies

| Package | Why |
|---|---|
| `flutter_riverpod` | state |
| `go_router` | navigation |
| `dio` | HTTP (no repository uses it yet) |
| `flutter_secure_storage` | session tokens |
| `shared_preferences` | non-secret prefs (onboarding flag, app icon choice) |
| `flutter_svg` | retailer logos supplied as SVG |
| `file_picker` | proof-of-purchase upload — **this is what forces iOS 14** |
| `share_plus` / `url_launcher` | referral sharing, tel/mailto/WhatsApp |
| `intl` | date and currency formatting |
| `posthog_flutter` | analytics (inert without a key) |
| `flutter_native_splash` / `flutter_launcher_icons` | dev-only generators |

**There is no CocoaPods in this project** — everything builds with Swift Package
Manager. Check any new iOS-touching package ships a `Package.swift` before
adding it; see [Conventions & gotchas](09-conventions.md).

## Regenerating assets

Brand art (splash, app icons) is generated from a traced vector, not from
hand-exported files:

```bash
python3 tool/generate_brand_assets.py    # requires Pillow
dart run flutter_native_splash:create
dart run flutter_launcher_icons
```

See [Brand assets](07-brand-assets.md) for why.
