# 5. Data layer

## The pattern

Every feature's `data/` folder holds three things:

```
<feature>_models.dart       models — double as API DTOs and UI state
<feature>_repository.dart   abstract interface
mock_<feature>_repository.dart  in-memory implementation
```

The interface is the contract. The UI only ever sees the interface, so the mock
and a future Dio implementation are interchangeable.

## Going live

One line per feature. For example:

```dart
// lib/features/auth/presentation/auth_providers.dart
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(ref.watch(tokenStorageProvider)),   // ← swap
);
```

becomes

```dart
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => DioAuthRepository(ref.watch(dioProvider)),
);
```

**No UI changes.** That is the whole point of the layout — if wiring the real
API forces a widget edit, the interface was wrong.

## Observed API conventions

These came from watching the live site's network traffic. Match them.

| Convention | Example |
|---|---|
| Base URL | `https://api.wolevo.com/api/v1` |
| Pagination | `pagination.pageNumber` / `pagination.pageSize`, **1-indexed**, dotted query keys |
| Country | ISO-2 as `destinationCountryCode` — `GH`, `NG` |
| Retailer enum | UPPERCASE — `AMAZON`, `EBAY`, `FASHION_NOVA`, `PLUG_TECH`, `BEST_BUY`, `SEPHORA` |
| Order status enum | UPPERCASE — `PENDING`, `PURCHASED`, `SHIPPED`, `DELIVERED`, `CANCELLED` |
| Money | every amount carries **both** `usd` and the local amount |

## Endpoint map

Confirmed by observation:

| Method | Path | Notes |
|---|---|---|
| POST | `/auth/restore` | session bootstrap; 401 when logged out |
| POST | `/auth/login` | `{ email, password }`; 401 → "Invalid email or password" |
| POST | `/auth/register` | 400 on duplicate, with per-field messages |
| ? | `/auth/forgot-password?email=` | **email in the query string** |
| ? | `/auth/resend-verification-email?email=` | same |
| GET | `/shop/homepage-deals` | Home feed |
| GET | `/shop/search?keyword=&retailer=&page=` | |
| GET | `/shop/products/parse?retailer=&productId=&destinationCountryCode=` | |
| GET | `/carts/active` | |
| GET | `/user/fulfillments?status=&pagination.*` | orders **and** forwarded shipments |
| GET | `/addresses` | |
| GET | `/geocoding/search?query=&country=&limit=` | city typeahead |
| GET | `/user/referrals` | |
| GET | `/user/notifications`, `/user/notifications/unread-count` | |
| POST | `/public/shipping-estimate` | **public** — works logged out |

> ⚠️ `forgot-password` and `resend-verification-email` put the raw email in the
> URL, so it lands in access logs and proxies. Worth confirming with the backend
> whether a body is accepted before mirroring this.

### Feature repositories

Every feature follows the pattern. Beyond the ones above:

- **`onboarding`** — `OnboardingRepository`, backed by `shared_preferences`.
  Both read and write **swallow errors**: a failed write used to be awaited
  before navigation, which swallowed the button tap entirely.
- **`appearance`** — `AppIconRepository` (platform channel, not a plugin) and
  `AppearanceRepository` (the seasonal icon campaign).

### Inferred endpoints

Never observed; modelled to match the conventions above. Each is marked
`// ASSUMPTION:` in code.

- `POST /shipments` — registering a forwarded package
- Cart mutations (add / update / remove / promo / checkout)
- `GET /app/appearance` — the seasonal app-icon campaign

## Mock data

Seeded from the real values quoted in `discovery-notes.md`, not invented:

- **Cart** — the three actual Amazon items, subtotal **$187.68**
- **Product** — the real Anker cable `B088NRLMPV`, $9.99, 7 images, its real variants
- **Shop** — 24 listings × 6 retailers
- **Calculator** — calibrated to the one captured data point: **2 lb → Ghana = $20.00 / GHS 244.00**
- **Notifications** — inbox seeded for demo purposes; the live one was empty

Mocks simulate latency (~300–800ms) so loading states are real, and hold state
in memory so add-to-cart is consistent across screens within a session.

## Images

There are no bundled product images and the real ones aren't available offline.
Each feature has a small `*Thumb` widget that renders a deterministic tinted
placeholder from a hash of the id or title, tinted **only from brand tokens**.
`imageUrl` is still on every model — it's part of the API shape — so switching
to the real Cloudflare image proxy is a widget-level change.
