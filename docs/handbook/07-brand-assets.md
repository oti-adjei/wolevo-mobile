# 7. Brand assets

## The mark is vector, not raster

**No plugin, no image asset.** There is no `flutter_svg` involvement in the mark
itself — it is a `CustomPainter` drawing a traced path.

The artwork supplied by the client is a 762×203 PNG in which the mark occupies
only **143×129 pixels** — far too small to upscale for a splash screen or a
1024px app icon.

Because the mark is straight-edged bars plus a circular dot, it was **traced
once** into a 21-point polygon and is now re-rasterised at whatever size is
needed. (The dot was confirmed circular: fill ratio 0.78 ≈ π/4.)

That geometry lives in **one place, used two ways**:

| File | Consumer |
|---|---|
| `tool/generate_brand_assets.py` | rasterises PNGs for the OS (splash, icons) |
| `lib/core/widgets/wolevo_mark.dart` | draws the same coordinates as a Flutter `Path` |

Both carry the same normalised coordinates, so the OS splash, the in-app
animation and the Settings icon swatches **cannot drift apart**.

```bash
python3 tool/generate_brand_assets.py     # needs Pillow
```

## Splash

A native splash **cannot be animated** — iOS renders a static launch storyboard,
Android 12+ allows only a brief icon animation. So it is a two-stage handoff:

1. **OS splash** (`flutter_native_splash`) — mark on `#0A3307`
2. **`SplashScreen`** — opens with *the same mark at the same size on the same
   background*, then animates: a diagonal wipe along the stroke angle, the dot
   popping in, the wordmark fading up

The seam is invisible because stage 2 begins identical to stage 1.

> ⚠️ `SplashScreen.markWidth` (99.0) must stay in step with the `0.39` ratio in
> `generate_brand_assets.py`. If they drift, the mark visibly jumps at handoff.
> This is the one coupling in the brand pipeline that isn't enforced by code.

Config is at the bottom of `pubspec.yaml`. Regenerate:

```bash
dart run flutter_native_splash:create
```

An inverted lockup (dark mark on a neon field) is generated too —
`splash_mark_dark.png`. Two commented lines in `pubspec.yaml` swap to it.

## App icon

```bash
dart run flutter_launcher_icons
```

Android gets a proper adaptive icon (flat `#0A3307` background + mark
foreground) so launchers can mask it to any shape. `remove_alpha_ios` is on —
iOS rejects icons with transparency.

## Seasonal / alternate icons

Users can pick an icon in **Settings → Appearance**, and Wolevo can switch it
remotely for a season.

### Variants

Defined in `ICON_VARIANTS` (Python) and `AppIconVariant` (Dart). **Only the
palette varies** — the mark itself never changes — so a seasonal icon cannot
drift off-brand.

| id | Field | Mark |
|---|---|---|
| `default` | forest | neon |
| `lime` | neon | forest |
| `midnight` | near-black | neon |
| `festive` | forest | lime |

### Adding one

1. Add a line to `ICON_VARIANTS` in `tool/generate_brand_assets.py`
2. Add a case to `AppIconVariant`
3. Run the generator — it writes iOS `AppIcon-<name>@2x/@3x.png` and Android
   `mipmap-*/ic_launcher_<name>.png` directly into the platform folders
4. Declare it natively:
   - **iOS** — a `CFBundleAlternateIcons` entry in `ios/Runner/Info.plist`
   - **Android** — an `<activity-alias>` in `AndroidManifest.xml`

### How switching works

Implemented as a **method channel in the app target** (`AppDelegate.swift` /
`MainActivity.kt`), not a plugin: every dynamic-icon package on pub is
CocoaPods-only, and this project builds with Swift Package Manager. Adding one
pulls CocoaPods into the toolchain for ~60 lines of native code.

> If a CocoaPods-only plugin is ever added, Flutter writes an `ios/Podfile`, and
> that file forces the CocoaPods build path **even after the plugin is removed**.
> Delete `ios/Podfile`, `ios/Podfile.lock`, `ios/Pods/` and `ios/Flutter/ephemeral/`.


- **iOS** — `setAlternateIconName`; `null` restores the primary icon.
- **Android** — there is no equivalent API. The swap enables one
  `activity-alias` and disables the others. **`MainActivity` deliberately
  carries no `LAUNCHER` filter** — even the default icon is an alias, because
  the plugin only enumerates aliases. Exactly one must be enabled or the app
  appears twice in the launcher.

### Known rough edges

- iOS shows an **unavoidable system alert** when the icon changes. Suppressing
  it needs private API and risks App Store review, so it is left visible.
- Android's alias swap can **relaunch the app**, and some launchers cache the
  old icon until reboot. It is noticeably jankier than iOS.
- Not all devices support it — `isSupported()` is checked and the picker
  explains itself rather than offering a dead control.

### Remote campaigns

`AppearanceRepository.currentCampaign()` (modelled as `GET /app/appearance`)
returns an `IconCampaign` with a variant and a date window.

**The app cannot install *new* artwork remotely** — both stores require icons to
be in the binary. A campaign only selects a variant that already shipped. Plan
around it: ship the season's icon ahead of time, switch it on by date.

Precedence, in `AppIconController`:

1. A **forced** campaign — for a rebrand, not a season
2. The user's **own choice**, if they ever made one
3. An ordinary campaign, if the user hasn't opted out
4. The default

A user who deliberately picked an icon never has it silently replaced.
