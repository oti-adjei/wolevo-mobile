# 6. Screens

Route constants live in `lib/core/router/routes.dart`.

## Startup

```
/splash  →  animated mark plays while the stored token is restored
             ├─ signed in             → /home
             ├─ first launch          → /onboarding
             └─ returning, logged out → /  (Explore)
```

| Route | Screen | Feature |
|---|---|---|
| `/splash` | `SplashScreen` | `core/router` |
| `/onboarding` | `OnboardingScreen` | `onboarding` |

Onboarding is four swipeable slides, shown **once** (flag in
`shared_preferences`, survives logout). It *replaces* the marketing page on a
first run rather than sitting in front of it — showing both would onboard the
user twice before they can do anything.

## Public

| Route | Screen | Notes |
|---|---|---|
| `/` | `ExploreScreen` | hero + **Shop / Ship / Calculator** tabs |
| `/welcome` | `LandingScreen` | the full marketing scroll |
| `/auth/login` | `LoginScreen` | honours `?next=` |
| `/auth/register` | `RegisterScreen` | live password checklist |
| `/auth/forgot-password` | `ForgotPasswordScreen` | enumeration-safe copy |
| `/calculator` | `CalculatorScreen` | works logged out |
| `/help` `/pricing` `/support` | static | `support` feature |

**`/` is Explore, not the marketing page.** The long scroll is a desktop
pattern; Explore is its task-first equivalent — search, the locker pitch, and a
*working* calculator (its endpoint is genuinely public). Shop and Ship there
lead into the auth wall, but the typed search rides through as `?next=` and runs
after sign-in. The marketing scroll is kept at `/welcome`, which is the live
site's own alias for the same page.

## Bottom tabs

**Home · Shop · Ship · Track · Account**

Only the active tab shows its label, inside a lime pill — five labels do not fit
at 375pt. The Account tab renders the user's initials rather than a glyph.

| Route | Screen | Notes |
|---|---|---|
| `/home` | `HomeScreen` | flat green bar with the greeting, **Active Shipments** hero card, store tiles, deal rows |
| `/shop` | `ShopScreen` | Select Store → search → SKU entry → categories → grid |
| `/ship` | `ShipScreen` | 3 intents, locker panel, 5-step journey |
| `/orders` | `OrdersScreen` | labelled **Track**; status filters, search |
| `/account` | `AccountScreen` | hub: identity card + grouped links |

## Pushed

| Route | Screen | Notes |
|---|---|---|
| `/search` | `SearchScreen` | replaces the web header search bar |
| `/product?retailer=&productId=` | `ProductScreen` | gallery, variants, landed cost, sticky add-to-cart |
| `/cart` | `CartScreen` | two steps: Items → Delivery |
| `/cart/checkout` | `CheckoutScreen` | **inferred** |
| `/orders/:id` | `OrderDetailScreen` | **inferred** — vertical timeline |
| `/account/:section` | `ProfileSectionScreen` | profile / addresses / referrals / settings / support |
| `/account/addresses/new` | `AddAddressScreen` | full-screen 3-step flow |
| `/messages` | `MessagesScreen` | notifications |
| `/ship/register` | `RegisterPackageScreen` | package registration form |

### Account is a hub, not a tab strip

The web app kept five sections behind `/profile?section=…` with a sidebar. The
first pass reproduced that as a horizontal segmented strip, which crammed five
sections into a scrolling row and pushed most off screen. It is now a **grouped
list** (`AccountScreen`) where every destination is visible, and each opens as
its own route.

Its header card carries the user's identity and **locker ID with a copy button**
— replacing the reference mockup's "Premium Membership" banner, since Wolevo has
no premium tier and the locker ID is the thing that actually matters.

## Design provenance

Three sources, in order of authority:

1. **`discovery-notes.md`** — the live web app. Ground truth for copy, fields
   and API shapes.
2. **Client app mockups** — supplied later, and the reason Home, Shop and the
   nav were restyled. Where they conflicted with discovery, discovery won on
   *behaviour*, the mockups won on *layout*.
3. Inference, always marked in code.

Adopted from the mockups: light Shop content on white, `Select Store` logo
chips, SKU entry, category chips, the Active Shipments hero, label-on-active-tab
nav, store tiles with labels beneath, "Track" as the Orders label.

Deliberately **not** adopted:

- The **light Shop header** — the client kept the green bar; it is the brand's
  signature and matches every other screen.
- A **dark** Active Shipments card — our app bar is already dark, and two dark
  blocks stacked put the visual weight back where the mockup removed it. It is
  lime instead.
- **"Vehicles"** as a store tile — it is not a retailer in the API and nothing in
  discovery explains it. Open question with the client.

## The two inferred screens

Both carry a file-level `// INFERRED SCREEN:` banner.

**`OrderDetailScreen`** — the discovery account had zero orders, so no detail
view was reachable. Derived from the `/ship` journey stepper, the cart's
cost-summary conventions and the fulfillments status enum.

**`CheckoutScreen`** — the live Checkout button leads to a real payment flow that
was deliberately not exercised. The three rails (Card, Mobile Money, Bank
Transfer) are the ones the product page advertises. It **does not collect raw
card details** — out of scope by design; it shows a redirect explainer.

## Worth reading first

1. **`ShipScreen`** — intent switching, the shared locker panel, vertical stepper
2. **`CartScreen`** — multi-step flow in one route, bottom sheets, cross-feature reads
3. **`OrdersScreen`** — `AsyncValue` switch handling, slivers, filters, infinite scroll
