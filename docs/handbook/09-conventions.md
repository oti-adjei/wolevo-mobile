# 9. Conventions & gotchas

## House rules

1. **Tokens only.** No hardcoded colours, sizes or radii in widgets. One
   documented exception (Google's brand blue).
2. **Copy is quoted, not paraphrased.** Check `discovery-notes.md` before
   changing user-facing text.
3. **Mark your guesses.** `// ASSUMPTION:` for a decision, `// INFERRED SCREEN:`
   for a whole screen. A future reader must be able to tell observation from
   invention.
4. **Phone-first.** 375–430px. No side-by-side layouts that crush; dropdowns
   become bottom sheets; modals become routes.
5. **Never convert currency client-side.** `Money` carries both amounts.
6. **Features don't import each other's internals** — only published
   repositories/providers.
7. **Comment the *why*, not the *what*.** Especially where the app deliberately
   diverges from the web.

## Gotchas we already hit

Each of these cost real time. They're documented so they only cost it once.

### `requireValue` on a loading session

`currentUserProvider` is non-nullable. Authenticated screens must not build
before the session resolves — during token restore, or the instant during
logout when it's briefly null. **`AuthGate` wraps every authenticated route**
for exactly this. If you add a route, wrap it.

### Sliver header extent must match its child

`SliverPersistentHeaderDelegate.minExtent`/`maxExtent` have to equal the child's
real height or Flutter asserts and the screen dies. Explore's tab bar declares
`58` = tab height 42 + 8 padding top/bottom.

### A collapsing `SliverAppBar` will overflow your hero

As the bar collapses, the flexible space shrinks below its content height. Both
hero screens wrap content in `FittedBox(fit: BoxFit.scaleDown)`.

### Adding a plugin needs a full restart

Hot restart reloads Dart only. A new platform channel needs the native binary
rebuilt, or you get `PlatformException(channel-error, ...)`.

### The stale ephemeral Swift package

`ios/Flutter/ephemeral/` pins the iOS deployment target at generation time and
is **not** regenerated when you change the project setting. `rm -rf` it.

### `SafeArea` on tab roots

Tab-root screens have no app bar, so a coloured hero must own the status-bar
inset itself (`SafeArea(bottom: false)`). Ship shipped without it once and the
pill sat under the notch.

### Prefs calls must not throw

`PrefsOnboardingRepository` swallows errors on both read and write. A failed
write used to be awaited *before* `context.go(...)`, which swallowed the button
tap entirely — the failure looked like "the button does nothing".

### CocoaPods, once invited, does not leave

Adding a CocoaPods-only plugin makes Flutter write an `ios/Podfile` — and that
file **forces the CocoaPods build path even after the plugin is removed**. If a
build suddenly demands `pod`, delete `ios/Podfile`, `ios/Podfile.lock`,
`ios/Pods/` and `ios/Flutter/ephemeral/`.

Check any new iOS-touching package ships a `Package.swift` before adding it.
`flutter_svg` and `shared_preferences` are pure Dart or SPM-ready; the dynamic
app-icon plugins were not, which is why icon switching is a ~60-line method
channel in `AppDelegate.swift` / `MainActivity.kt` instead.

### A finder that matches nothing fails oddly

`scrollUntilVisible` with `.first` on an empty finder throws `Bad state: No
element` rather than a useful failure. Prefer an explicit
`tester.drag(find.byType(ListView).first, …)`.

### `Wrap`, not `Row`, for display type

At 26px, "Receive it at home." doesn't fit one line on a 390pt phone. Any
headline with an inline highlight block needs to be able to reflow.

## Known divergences from the live web app

Deliberate, and each commented in code:

| Divergence | Why |
|---|---|
| `?next=` preserved through the auth wall | the site drops it, stranding deep links |
| `/` is Explore; the marketing scroll moved to `/welcome` | the long scroll is a desktop pattern; `/welcome` is the site's own alias for the same page |
| Account is a bottom tab, not a header avatar | the header duplicated a nav destination |
| Profile sidebar → hub + per-section routes | the segmented strip hid most sections off-screen |
| Onboarding replaces the landing page on first run | otherwise the user is onboarded twice |
| Delivery time stated as 7-14 days | the site's own hero contradicts its body copy |
| `/` is Explore; marketing moved to `/welcome` | the long scroll is a desktop pattern, and `/welcome` is the site's own alias for it |
| Orders labelled **Track** | the client's mockups; the route stays `/orders` |
| Shop keeps the green header | the mockups drew it light, the client kept the brand bar |

## Open questions for the client

- **"Vehicles"** appears as a store tile in the mockups but is not a retailer in
  the API and appears nowhere in discovery. Car importing? Not built.
- **Fashion Nova logo** was not supplied; that tile falls back to a wordmark.
- Category chips on Shop filter **client-side** — the API has no category
  taxonomy. Swap `ShopCategory.matches` for a server field when one exists.

## Open items

- The two inferred screens need review against the real API once it's available
- **Sentry is blocked** on an Xcode 26 incompatibility — no crash reporting in
  production yet (see [Observability](10-observability.md))
- `forgot-password` / `resend-verification-email` put email in the query string
  — confirm with backend whether a body is accepted
- Google OAuth is stubbed; the real flow was never exercised
- Nigeria-specific pricing and copy is untested — discovery ran on a Ghana account
- No golden tests
