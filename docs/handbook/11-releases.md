# 11. CI & releases

## What runs on GitHub

| Workflow | Trigger | Does |
|---|---|---|
| `ci.yml` | push to `main`, every PR, manual | `flutter analyze`, `dart format --set-exit-if-changed`, `flutter test` |
| `release.yml` | tag `v*`, manual | builds an Android APK and attaches it to the release |

Both pin **Flutter 3.44.8**. Bump it there and in
[Getting started](01-getting-started.md) together, or CI and local drift apart.

CI runs on a clean checkout with **no secrets and no `--dart-define`**. That is
deliberate: it proves a new contributor can clone and get green without any
setup. It also means CI exercises the `dev` environment, where reporting is off.

## Cutting a release

```bash
git tag v0.1.0-dev
git push --tags
```

The tag builds the APK and publishes a release with generated notes. Tags
containing `-dev` or `-beta` are marked **pre-release** automatically.

To build an APK without tagging, run the **Release** workflow manually from the
Actions tab and pick an environment (`dev` / `staging` / `prod`).

## Android build notes

**`compileSdk = 37`** is pinned in `android/app/build.gradle.kts` rather than
tracking `flutter.compileSdkVersion` (36), because `flutter_secure_storage`
compiles against 37 and the AAR metadata check fails otherwise. `compileSdk` is
backward compatible — this does not raise the minimum supported device.

**Release APKs are signed with the debug key.** `android/app/build.gradle.kts`
still carries Flutter's template `signingConfig = signingConfigs.getByName("debug")`.
That is fine for sideloading to testers and is why the release workflow needs no
secrets. **A Play Store build needs real signing** — a keystore, a
`key.properties`, and the keystore held as a GitHub secret rather than committed
(`*.jks` and `key.properties` are already gitignored).

**Size:** a debug APK is ~155 MB (every ABI plus debug symbols); the release APK
is ~59 MB. The workflow builds release for that reason. `--split-per-abi` would
cut it further if download size starts to matter.

## iOS

Not automated. It needs a paid Apple Developer account, signing certificates and
a provisioning profile, none of which exist yet. Locally:

```bash
flutter build ipa --release --dart-define=WOLEVO_ENV=prod
```

Remember iOS deployment target is **14.0** (see
[Getting started](01-getting-started.md)) and this project uses **Swift Package
Manager, not CocoaPods**.

## Known warning

The Android build prints:

```
Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): posthog_flutter
Future versions of Flutter will fail to build if your app uses plugins that apply KGP.
```

Not fatal today, but it **will** break on a future Flutter. Watch for a
`posthog_flutter` release that migrates to built-in Kotlin.

## Gaps

- No iOS pipeline, no TestFlight
- No Play Store signing or upload
- No version bumping — `pubspec.yaml` stays at `0.1.0+1` regardless of tag
- No code coverage reporting
