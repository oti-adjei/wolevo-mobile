# 3. Architecture

## Shape

**Feature-first, two layers per feature.** There is deliberately *no* domain or
use-case layer: models double as API DTOs and UI state.

```
lib/
  core/
    analytics/     AnalyticsClient seam, event names, nav observer
    env/           AppEnvironment, AppSecrets (--dart-define)
    logging/       AppLogger seam, console impl
    models/        Money, DestinationCountry, Retailer, Pagination
    network/       Dio client, ApiException
    observability/ starts PostHog (and Sentry, when restored)
    router/        go_router config, guards, shell, splash, AuthGate
    storage/       secure token storage
    theme/         colors, typography, dimens
    widgets/       buttons, cards, inputs, search field, locker panel,
                   retailer logos, the Wolevo mark
  features/
    <feature>/
      data/          repository interface + mock impl + models
      presentation/  screens, feature widgets, Riverpod providers
```

Features (14): `appearance`, `auth`, `calculator`, `cart`, `explore`, `home`,
`notifications`, `onboarding`, `orders`, `product`, `profile`, `ship`, `shop`,
`support`.

## The folder rule

**A feature must not import another feature's internals.** Cross-feature access
goes through the other feature's *published* repository interface or provider.

In practice there are only a few legitimate crossings, and each is deliberate:

| From | To | Why |
|---|---|---|
| `product` | `cart`'s `cartRepositoryProvider` | Add to Cart |
| `cart` | `profile`'s `savedAddressesProvider` | pick a delivery address |
| `cart`, `explore` | `auth`'s `PhoneField` | one phone input, one country list |
| everything | `core/widgets/locker_address_card.dart` | shared by Ship *and* Profile, so it lives in core |

If you find yourself importing a feature's screen or private widget, that's the
signal to promote the thing to `core/` instead.

## State — Riverpod

- `AsyncNotifier` for anything that loads.
- `Notifier` / `StateProvider` for local UI state (filters, tab selection).
- Providers live **next to the screens that use them**, in
  `presentation/<feature>_providers.dart`.

The root of all state is `sessionProvider` (`AsyncNotifier<AuthSession?>`).
`null` means logged out. Two conveniences read off it:

```dart
ref.watch(currentUserProvider)       // WolevoUser — non-nullable
ref.watch(warehouseAddressProvider)  // WarehouseAddress — non-nullable
```

Because those are non-nullable, **authenticated screens must never build while
the session is unresolved.** That is what `AuthGate` is for (below). This bit
us once already — see [Conventions & gotchas](09-conventions.md).

## Navigation — go_router

`lib/core/router/app_router.dart`. Route paths mirror the web app's URLs so
deep links map 1:1 (`AppRoutes` in `routes.dart`).

### Shell

`StatefulShellRoute.indexedStack` with **five bottom tabs**:

```
Home · Shop · Ship · Track · Account
```

Only the active tab shows its label, in a lime pill. The Account tab renders the
user's initials rather than a glyph. Each branch keeps its own navigator stack;
tapping the active tab pops that branch to its root.

### Startup order

```
/splash  →  animation plays while the stored token is restored
             ├─ signed in            → /home
             ├─ first launch         → /onboarding
             └─ returning, logged out → /  (Explore)
```

The splash waits on **both** the session restore and the first-launch flag, so a
returning user never sees the marketing page flash past.

### Public vs authenticated

Public: `/splash`, `/onboarding`, `/`, `/welcome`, `/auth/*`, `/calculator`,
`/help`, `/pricing`, `/support`.

Everything else is gated twice, on purpose:

1. **Router redirect** — bounces a logged-out user to login.
2. **`AuthGate`** — wraps every authenticated route builder and holds a spinner
   until a session exists, covering the first frame during token restore and
   the moment during logout when the session is briefly null.

### `?next=` — a deliberate improvement over the web app

The live site drops the intended destination on redirect, stranding
deep-linked users on Home after sign-in. We carry it through:

```dart
AppRoutes.loginWithNext('/shop?mode=search&q=usb+c+cable')
```

The Explore screen's search box relies on this: a logged-out visitor's search
survives the auth wall and runs once they sign in.

## Networking

`dio`, configured in `core/network/dio_client.dart`, base URL
`https://api.wolevo.com/api/v1`. An interceptor attaches the bearer token from
`flutter_secure_storage`. `mapDioError` converts failures into `ApiException`,
including per-field errors (`fieldErrors`) which the register form renders
inline.

No repository uses Dio yet — see [Data layer](05-data-layer.md).

The base URL comes from `AppEnvironment.current`, and an interceptor logs every
request as a breadcrumb and every failure as an error — **method, path and
status only, never bodies**. See
[Environments, logging & analytics](10-observability.md).

## Observability

Two more seams, same shape as the repositories: `AppLogger` and
`AnalyticsClient`. Features call the seam, never a vendor SDK. PostHog is wired
behind `AnalyticsClient`; Sentry is written but blocked on an Xcode 26 issue.
