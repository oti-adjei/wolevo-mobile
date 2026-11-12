# Wolevo — Discovery Notes

> **Trimmed for publication.** This file records the *structure* of the
> reference product — screens, field lists, API shapes and flow — because that
> is what the concept client was built against. Wolevo's own marketing and
> interface copy has been removed and is marked `"[copy omitted]"`; the three
> stylesheets originally captured alongside it are not in this repository
> either. Nothing here is Wolevo's to publish, so only the structural notes
> remain.


> **Note on identifiers.** This document was captured against a real account.
> Personal identifiers — email address, phone number, locker ID and referral
> code — have been replaced with demo values (`demo@wolevo.com`,
> `+233200000000`, `DEMO1234`, `DEMOREF1`). Everything else, including all
> product copy and API shapes, is verbatim. Wolevo's own published support
> email and phone are left as they appear on the public site.


Discovery pass over `https://www.wolevo.com` in an authenticated Chrome session (account: Demo User, Ghana, locker `DEMO1234`). No code written. Screenshots live in `discovery/shots/` (desktop = 1440×767 viewport, mobile = 500×767 viewport — 500px is the narrowest the OS window allows, and it is below the app's `--breakpoint-s: 500px`, so mobile layouts render).

**Stack observed:** Next.js App Router (RSC, `/_next/static/...`) on Vercel, Tailwind v4 (`@theme` custom properties), `react-toastify` for toasts, Sora webfont. API is a separate origin: `https://api.wolevo.com/api/v1/...` (CORS preflighted, bearer/session restored on every page load). Images proxied through `https://wolevo-image-proxy.wolevo.workers.dev/image?url=…&w=…&q=…` (Cloudflare Worker). GTM container `GTM-T7FHJ5SM`.

**What the product is:** a package-forwarding + proxy-buying service for Africa (Ghana, Nigeria). Two flows converge:
1. **Shop** US retailers (Amazon, eBay, Fashion Nova, Plug Tech, Best Buy, Sephora) inside Wolevo → cart → checkout → Wolevo buys and ships.
2. **Ship** — user gets a personal US warehouse ("locker") address in Delaware, ships to it from anywhere, registers the tracking number, Wolevo weighs/quotes/delivers.

---

## 1. Design Language

### Colors

Tailwind v4 `@theme` tokens, pulled from the compiled CSS bundles (`_next/static/css/*.css`).

| Token | Hex | Role observed |
|---|---|---|
| `--primary` | `#01FF69` | Neon green — logo mark, "In Stock", accent text on dark |
| `--primary-2` | `#CCFFE1` | Light mint tint |
| `--primary-3` | `#00993F` | Darker green (primary hover/press) |
| `--secondary` | `#0A3307` | **Deep forest green — the signature color.** Header bar, hero band, primary buttons, footer |
| `--secondary-2` | `#DDFADB` | Pale mint — selected card fill (`I'm yet to shop` card), icon chips |
| `--secondary-3` | `#125A0C` | Mid green — step-number circles, active states |
| `--secondary-5` | `#1A1A1A` | Near-black text |
| `--secondary-6` | `#F7FEF6` | Barely-green off-white surface |
| `--secondary-7` | `#D5F9D2` | Mint surface |
| `--tertiary` | `#DFFF7C` | **Lime/chartreuse — the second signature color.** Hero band on `/home`, "SHIP A PACKAGE" pill, locker-address banner, active tab pill in calculator |
| `--tertiary-2` | `#F3FFCC` | Pale lime |
| `--tertiary-3` / `-4` | `#F9FFE5` | Palest lime (info callout backgrounds) |
| `--success` | `#2EB67D` | Success green |
| `--success-2` | `#1F7A54` | Dark success |
| `--error` | `#E63946` | Delete/logout/required-asterisk red |
| `--error-2` | `#88111A` | Dark error |
| `--error-3` | `#FEF6F7` | Error surface tint |
| `--neutral` | `#1F2933` | Body text alt |
| `--neutral-1` | `#666666` | Muted text |
| `--neutral-2` | `#999999` | Placeholder |
| `--surface` | `#F2F2F2` | Page background (light gray) |
| `--surface-3` | `#EBEBEB` | |
| `--surface-4` | `#E6E6E6` | Dividers |
| `--surface-5` | `#B3B3B3` | |
| `--surface-6` | `#FAFAFA` | Card background |
| `--variant` | `#EFF2F5` | Cool gray surface |
| `--variant-2` | `#DFE5EC` | Cool border |
| `--variant-3` | `#3A4D5F` | Slate text |
| `--azure` | `#364153` | Slate |
| `--azure-2` | `#D1D5DC` | Slate border |
| `--blue` | `#0043F0` | Link blue (rare) |
| `--input-border` | `#D1D5DB` | Field border |
| `--background` | `#FFFFFF` | |

Runtime-observed body text color is `#171717`; white cards on `#FAFAFA`/white page.

**Palette in one line:** deep forest green + neon green + lime, on white/near-white surfaces, near-black text, red only for destructive.

### Typography

- **Single family: `Sora`** (self-hosted woff2, `--font-sora`), with a `Sora Fallback` metric-matched fallback. Monospace only for the referral code/link fields.
- Observed scale (size / weight / line-height):
  - Page hero H1: **48px / 700 / ~1.1**, tight tracking (`-0.75px` at 30px, so roughly `-0.025em`)
  - Section H2: **30px / 700 / 37.5px / -0.75px**
  - Section H3 (`Deals from Amazon`): **~24–30px / 700**
  - Card/section title: 18–20px / 600–700
  - Body: **16px / 400 / 24px** (dominant), secondary body **14px / 400 / 20–22.75px**
  - Meta/caption: **12px / 400 / 18px**, sometimes 12px/600 uppercase
  - Micro label (badges like `PRIMARY`, `YOU'RE HERE`): **10px / 600 / 15px**, uppercase, letter-spaced
- Eyebrow labels (`SHIPPING CALCULATOR`, `PACKAGE DETAILS`, `NAME`, `ADDRESS LINE 1`) are uppercase, small, semibold, letter-spaced — used heavily as a structural device.
- Weights in use: 400, 500, 600, 700. No italics observed.

### Radius

Tailwind defaults are in play: `--radius-sm .25rem`, `--radius-md .375rem`, `--radius-lg .5rem`, `--radius-xl .75rem`, `--radius-2xl 1rem`, `--radius-3xl 1.5rem`, `--radius-4xl 2rem`.

In practice:
- Cards / panels: **12px and 16px** (`rounded-xl` / `rounded-2xl`)
- Inputs, selects, small buttons: **6–8px**
- Pills, avatars, icon buttons, status chips, primary CTAs in hero: **fully rounded** (`9999px`)
- Search bar: split radius (`8px 0 0 8px` for the retailer selector, `0 8px 8px 0` for the submit button) — one continuous capsule made of three pieces.

### Spacing & layout

- Max content width ~1216px, centered, `32px` page gutter on desktop; `16px` on mobile.
- Card padding 20–24px; form field vertical rhythm ~24px between fields with a hairline divider between grouped fields.
- Sticky top nav, height 64px, `--secondary` (`#0A3307`) background, white/lime content.
- Grids: product grid 5-up at 1440px, 2-up at 500px. Deals rows are horizontal scrollers with a visible scrollbar track.
- Generous vertical whitespace between page sections (48–64px).

### Buttons & cards

- **Primary button:** `#0A3307` fill, white text, radius 8px (full-round in hero/nav contexts), 14–16px/500-600, no shadow. Disabled state = same shape at ~55% opacity (`Next`, `Get Estimate`, `Checkout` when blocked).
- **Secondary button:** white fill, 1px `#E6E6E6`-ish border, dark text, same radius. (`Add More Items`, `Create Shipment`, `Show all`.)
- **Accent/lime button:** `#DFFF7C` fill, dark green text, full-round pill (`Have a product link? Click to paste`, calculator tab toggle).
- **Destructive:** white fill, red border + red text (`Clear List`, `Delete`), never a solid red fill.
- **Cards:** white on light-gray page, radius 12–16px, 1px very light border, no or barely-there shadow. Selection state = mint fill (`#DDFADB`) + darker green border + a `✓ Selected` line, plus a small colored top edge on the selector cards.
- **Icon chips:** 40px rounded-square, mint (`#DDFADB`) fill, dark-green glyph.
- **Info callouts:** pale lime (`#F9FFE5`) block, no border, 💡 emoji lead-in.
- **Iconography:** Lucide-style 1.5px stroke line icons throughout.

### Mobile shell

Below ~500px the app switches to an app-like shell:
- Top bar collapses to: logo, search icon, cart, bell, account.
- **Fixed bottom tab bar: Home · Shop · Ship · Orders** (active item in green with filled icon). This is effectively the Flutter app's nav already designed.
- Product page gets a **sticky bottom action bar**: qty stepper − 1 + | `Add to Cart · $9.99` | cart button with badge.
- Profile side-nav becomes a horizontally scrollable tab strip.

---

## 2. Screens Found

Routes are Next.js App Router paths; several "screens" are query-param states of one route (`/profile?section=…`, `/shop?mode=…`).

### 2.1 `/home` — Authenticated home / storefront
*Shots: `home-desktop.jpg`, `home-desktop-categories.jpg`, `home-mobile.jpg`*

**Purpose:** logged-in landing. Personalized greeting + merchandised deal rows per retailer.

**Elements**
- Lime hero band: `Hello, Demo!` / "[copy omitted]" + carousel dots (2 slides, auto-rotating) + giant watermark wordmark.
- `Browse Top U.S Stores` — 6 retailer chips (Amazon, eBay, Fashion Nova, Plug Tech, Best Buy, Sephora), each a white pill with the retailer logo.
- Per-retailer sections, each `H3` + `Show all →`: **Deals from Amazon**, **Fashion Nova**, **Deals from eBay**, **Plug Tech**, **Sephora**, **Deals from Best Buy**. Amazon/eBay/Best Buy render horizontally scrolling product cards (image, title 2-line clamp, USD price, struck-through was-price, local ₵ price). Fashion Nova/Plug Tech/Sephora render category tiles instead (Makeup, Skincare, Hair, Fragrance, Bath & Body, Accessories…) with a gradient-overlaid image and label bottom-left.
- Global header: retailer selector + search, cart (badge 3), `Ship`, notifications bell, account menu.

**API**
- `POST /api/v1/auth/restore` — session restore, fires on every page load.
- `GET /api/v1/shop/homepage-deals` — all the deal rows in one payload.
- `GET /api/v1/user/notifications/unread-count`
- Product images via the Cloudflare image proxy.
- Next.js prefetches `/cart?_rsc=…` and `/ship?_rsc=…` (RSC payloads).

---

### 2.2 `/ship` — Ship a package (locker + shipment registration)
*Shots: `ship-desktop-top.jpg`, `ship-desktop-address-expanded.jpg`, `ship-desktop-register-step.jpg`, `ship-desktop-form-fields.jpg`, `ship-desktop-form-bottom.jpg`, `ship-desktop-someone-sending.jpg`, `ship-mobile.jpg`*

**Purpose:** the forwarding half of the product. One page, three intent modes, plus the package-registration wizard.

**Elements**
- Dark green hero: pill `SHIP A PACKAGE` + H1 "Get your US warehouse address"[copy omitted]"Three steps before you register"[copy omitted]"Getting a package from someone in the US" explainer + `Copy address to send them` and `They already shipped it →`.
  3. `Already shipped` → opens the registration wizard (below).
- **Locker address accordion** (lime bar, `YOUR US SHIPPING ADDRESS · TAX-FREE`). Expanded: a labeled table with per-field **Copy** buttons — NAME (`Wolevo <LOCKER_ID>`), ADDRESS LINE 1 (`20 Penn Mart Center`), ADDRESS LINE 2 (`PMB302`), CITY (`New Castle`), STATE (`DE (Delaware)`), ZIP (`19720`), COUNTRY (`US`), PHONE (`+1 (240) 887-5614`). Plus two warning blocks (PMB must be present; use this exact name), an `Ask on WhatsApp` link, and a "[copy omitted]" First/Last split.
- **Journey stepper** (5 steps, shown when registering): Shop & ship to locker → **Register package (YOU'RE HERE)** → We receive & weigh → Quote & pay → Delivered to you.
- **Registration form (step 2 of the wizard)** under `PACKAGE DETAILS`:
  - `Destination Country *` — select, options: Ghana (`GH`), Nigeria (`NG`)
  - `Store tracking number *` — text
  - `Total Value (USD) *` — number, `0.00`
  - `Proof of Purchase (required) *` — drag-and-drop uploader, max 3 files, 10MB each, JPG/PNG/PDF
  - `Notes` — textarea, "[copy omitted]"
  - `Next →` (disabled until valid)

**API**
- `GET /api/v1/user/notifications/unread-count` on load. The locker address itself arrives with the user/session payload (`auth/restore`), not a separate call.
- The submit endpoint for the wizard was **not** captured — see §3.

---

### 2.3 `/orders` — My Orders
*Shots: `orders-desktop-empty.jpg`, `orders-desktop-filtered.jpg`, `orders-mobile.jpg`*

**Purpose:** unified list of purchases and forwarded shipments.

**Elements**
- H1 `My Orders` / "Track all your orders in one place"[copy omitted]"Search by order ID, tracking…" + `Search` button + `Filter` toggle (shows a count badge, e.g. `Filters (1)`, when active).
- Status chip row: **All · Pending · Purchased · Shipped · Delivered · Cancelled**; selecting one sets `?status=PENDING` and adds a `× Clear all filters (1)` control.
- Empty states: "[copy omitted]" + `Start Shopping`; filtered empty: "No matching orders" + `Clear Filters`.

**API**
- `GET /api/v1/user/fulfillments?status=PENDING&pagination.pageNumber=1&pagination.pageSize=20` — note the `pagination.*` dotted query convention (looks gRPC-gateway generated). Omitting `status` for "All".

**Not reached:** a populated list, and therefore the order-detail / tracking-timeline screen. This account has zero orders.

---

### 2.4 `/cart` — Order Summary (2-step checkout)
*Shots: `cart-desktop-items.jpg`, `cart-desktop-delivery.jpg`, `cart-mobile.jpg`*

**Purpose:** review basket, then delivery details, then hand off to payment.

**Step 1 — Items**
- Horizontal stepper: `1 Items` → `2 Delivery`.
- Items panel grouped **by retailer** (`Amazon (3 items)` with retailer logo). Each row: thumbnail, title, USD price, ₵ local price, `− qty +` stepper, red trash icon.
- Panel actions: `Clear List` (red outline), `+ Add More Items`.
- **Cost Summary** sidebar (sticky): Subtotal, `Retailer Shipping — Calculated at checkout`, `Shipping to Ghana — Calculated at checkout`, `Estimated Total $187.68+`, a pale-lime note about currency conversion, `Continue`, `Add More Items`.

**Step 2 — Delivery**
- Country select (`Ghana`, "Showing addresses in Ghana") + `Delivery Address` select populated from saved addresses (`8 Bia Rd, Accra, Greater Accra, Ghana (near Omanye Lodge)`).
- `Contact Information`: phone input with country-flag prefix selector, prefilled.
- `Different receiver? (optional)` checkbox — "[copy omitted]".
- `Order Notes` textarea.
- Sidebar becomes: `← Back to Items`, `Have a promo code? ⌄` (collapsible), `Checkout` (disabled with helper text "Please select a delivery address" until an address is picked), `Having issues? WhatsApp · Email · Help`, ToS line, `Add More Items`.

**API**
- `GET /api/v1/carts/active` — returns the active cart with items, prices in USD + local currency.
- Quantity/remove/promo endpoints not captured (see §3).

---

### 2.5 `/shop` — Shop (browse / search / paste-a-link)
*Shots: `shop-desktop.jpg`, `shop-desktop-retailer-dropdown.jpg`, `shop-desktop-search-results.jpg`, `shop-desktop-paste-link.jpg`, `search-mobile.jpg`*

Three modes on one route, driven by query params.

**a) Default browse — `/shop`**
- Lime pill CTA `🔗 Have a product link? Click to paste` top-right.
- `Amazon Deals & Featured Products` — `141 items`, 5-up product grid (image, 2-line title, USD price, was-price, ₵ price).

**b) Search results — `/shop?mode=search&retailer=AMAZON&q=usb+c+cable`**
- Heading `"usb c cable"` + `× Clear` + item count (`20 items`).
- Same product grid. Retailer scope comes from the header dropdown: **Amazon · eBay · Fashion Nova · Plug Tech · Best Buy · Sephora** (Amazon marked with a green "active" dot).

**c) Paste a link — `/shop?mode=paste&retailer=AMAZON`**
- Retailer selector + `Paste Amazon product link…` field + `Get Product` button.
- Pale-lime instructions card (4 steps). Toggle back via `🔍 Search products` pill.

**API**
- `GET /api/v1/shop/search?keyword=usb+c+cable&retailer=AMAZON&page=1`

---

### 2.6 `/product?retailer=AMAZON&productId=<ASIN>` — Product detail
*Shots: `product-desktop.jpg`, `product-mobile.jpg`*

**Purpose:** retailer product rendered inside Wolevo, with landed-cost framing.

**Elements**
- Retailer badge (`Amazon`) + share button, top-right.
- Gallery: main image with `1 / 7` counter, zoom button, thumbnail strip.
- Title; spec table: Seller (`Amazon (FBA)`), Brand, Condition, Product ID (ASIN).
- **Variant pickers** driven by the retailer's own dimensions: `Size:` (6 swatch buttons + `See more (1 more)`), `Color:` (image swatches), `NumberOfItems:` (2 / 4 / 5). Selected = mint fill + green border.
- Price rail: `$9.99`, `~₵121.88`, `In Stock`, then a pale-lime landed-cost box: **Store Shipping — Free Shipping to our US Warehouse** / **To Your Door — Ship to Ghana for $2.09**.
- Quantity stepper, `Add to Cart` (primary), `View Cart (3)` (secondary).
- Trust row: Secure Transaction · Shipping Policy · Refund Policy. `We accept`: Visa, Mastercard, **Mobile Money**, **Bank Transfer**.
- Collapsible sections: `Product Highlights` (bullets), `Dimensions & Weight`.
- Mobile: sticky bottom bar with qty + `Add to Cart · $9.99` + cart badge.

**API**
- `GET /api/v1/shop/products/parse?retailer=AMAZON&productId=B088NRLMPV&destinationCountryCode=GH` — note `destinationCountryCode` drives the "Ship to Ghana for $2.09" line and the ₵ conversion.
- `GET /api/v1/carts/active`

---

### 2.7 `/profile` — Profile (5 sections via `?section=`)
*Shots: `profile-desktop.jpg`, `profile-mobile.jpg`, `profile-addresses-desktop.jpg`, `profile-referrals-desktop.jpg`, `profile-settings-desktop.jpg`, `profile-support-desktop.jpg`*

Left sidebar (desktop) / scrollable tab strip (mobile): **Profile · Addresses · Referrals · Settings · Support · Logout** (red).

**a) `?section=profile` (default)**
- `Profile Information` card, `Edit` button, initial avatar, name/email/account type.
- `Account Information` two-column read-only grid: First Name, Last Name, Email (+ green `Verified` chip, "Email cannot be changed"[copy omitted]"Used to display prices in local currency if supported"[copy omitted]"Your unique warehouse locker identifier").
- `Warehouse Address` — the same lime locker-address accordion as `/ship`.

**b) `?section=addresses`** — `Saved Addresses` + `+ Add Address`. Address card shows a lime `PRIMARY` badge, the formatted address, `Edit` / `Delete` (red). Loading state: "Loading addresses…" spinner.
  - **Add Address modal** — a 3-step in-modal flow:
    1. `Step 1: Select Country *` — full ISO country list (~250 entries), defaults to Ghana, with a `✓ Ghana` confirmation line.
    2. `Step 2: Search City *` — typeahead ("e.g., Accra, Tema, Kumasi"); results show a flag + `Accra, Greater Accra, Ghana`.
    3. After a city is picked: `Street Address (recommended)`, `Apartment, Suite, Unit (optional)`, `Label (optional)` (Home/Office/Warehouse), a recommendation callout, **`Nearest Landmark`** ("[copy omitted]" — a real Ghana/Nigeria addressing accommodation), `Set as primary address` checkbox, `Continue` / `Cancel`.
- **API:** `GET /api/v1/addresses`; `GET /api/v1/geocoding/search?query=Accra&country=GH&limit=5` (debounced on typing; preflighted OPTIONS observed).

**c) `?section=referrals`** — `Your Referral Code` card with mono code (`DEMOREF1`) + `Copy`; `Your referral link` `https://www.wolevo.com/?ref=DEMOREF1` + copy icon; `Share with Friends` (Web Share); `How it works` 3 steps ("[copy omitted]"); `Referral Activity` — "[copy omitted]"
- **API:** `GET /api/v1/user/referrals`

**d) `?section=settings`** — `Security`: Password → `Change`; Two-Factor Authentication → `Enable`. `Email Preferences`: `Promotional emails` checkbox + note that order/payment/shipment notifications can't be turned off + `Save Preferences`. `Danger Zone`: `Delete Account` (red outline).

**e) `?section=support`** — `Help Center` card → `Visit Help Center`; `Contact Support`: `support@wolevo.com`, `+233 59 639 4945`, `Chat on WhatsApp`; `Legal & Policies`: Terms of Service, Privacy Policy, Shipping Policy, Refund Policy.

---

### 2.8 `/messages` — Notifications
*Shots: `notifications-dropdown.jpg`, `messages-desktop.jpg`*

- Bell in the header opens a dropdown: `Notifications`, list or "You're all caught up"[copy omitted]"Stay updated on your orders and shipments"[copy omitted]"No unread notifications / You're all caught up!".
- **API:** `GET /api/v1/user/notifications/unread-count` (every page load); `GET /api/v1/user/notifications?pagination.pageNumber=1&pagination.pageSize=10` (on open).

---

### 2.9 `/calculator` — Shipping cost calculator
*Shots: `calculator-desktop-link.jpg`, `calculator-desktop-weight.jpg`, `calculator-desktop-result.jpg`, `calculator-mobile.jpg`*

**Purpose:** pre-purchase landed-cost estimate. Public (works logged out) but linked from the authed footer/help.

**Elements**
- Dark hero: pill `CALCULATOR`, H1 "Know your cost before you buy."[copy omitted]"Supported: Amazon, eBay, Fashion Nova, Plug Tech, Best Buy, and Sephora"[copy omitted]"Some items like electronics, fragrances, and lithium batteries may have fixed pricing due to higher import duties or special handling."[copy omitted]"Handling fees may apply at checkout.", `Get Another Quote`. (Verified: 2 lbs → Ghana = $20.00 / GHS 244.00, implying ~12.2 GHS/USD.)
- Below: three value props — Transparent Pricing / Instant Estimate / No Surprises.

**API**
- `POST /api/v1/public/shipping-estimate` — payload shape not captured verbatim; from the form it carries `{ destinationCountryCode, weight, weightUnit, dimensions?: {l,w,h,unit} }` for the weight mode and a product URL for the link mode.

---

### 2.10 Marketing / support routes (reachable while authed)
*Shots: `help-desktop.jpg`, `pricing-desktop.jpg`, `support-desktop.jpg`*

- **`/help`** — Help Center. Two cards (`Contact Us`, `Pricing Guide`) + FAQ accordions grouped by **Shopping** ("How does shopping on Wolevo work?", "Which stores can you shop from?", "How long does it take?"), **Shipping** ("Which countries do you ship to?"[copy omitted]"How We Calculate Shipping Costs"[copy omitted]"Our pricing includes full landing cost"), `How We Price Shipping` ("Most items are priced by weight"), `Shipping Method`, …
- **`/support?country=us|ghana|nigeria`** — Contact Us with three expandable office cards. Ghana: Accra, `support@wolevo.com`, `+233 59 639 4945`, WhatsApp, Mon–Sat 9am–5pm GMT. US: New Castle, Delaware. Nigeria: Lagos.
- Other links present in the footer/nav, not individually captured: `/` and `/welcome` (landing), `/about`, `/business-shipping`, `/shipping-policy`, `/refund-policy`, `/privacy`, `/terms`, `/third-party-content`.

---

## 3. API summary

Base: `https://api.wolevo.com/api/v1`

| Method | Endpoint | Trigger | Payload / params |
|---|---|---|---|
| POST | `/auth/restore` | every page load | session/refresh token from cookie; returns user + locker address |
| GET | `/shop/homepage-deals` | `/home` | — |
| GET | `/shop/search` | search submit | `keyword`, `retailer`, `page` |
| GET | `/shop/products/parse` | product page | `retailer`, `productId`, `destinationCountryCode` |
| GET | `/carts/active` | cart, product page | — |
| GET | `/user/fulfillments` | `/orders` | `status`, `pagination.pageNumber`, `pagination.pageSize` |
| GET | `/addresses` | profile → addresses | — |
| GET | `/geocoding/search` | city typeahead | `query`, `country`, `limit` |
| GET | `/user/referrals` | profile → referrals | — |
| GET | `/user/notifications/unread-count` | every page load | — |
| GET | `/user/notifications` | bell / `/messages` | `pagination.pageNumber`, `pagination.pageSize` |
| POST | `/public/shipping-estimate` | calculator | destination + weight/dims or product URL |

Conventions worth copying into the Flutter client:
- Pagination is `pagination.pageNumber` / `pagination.pageSize` (1-indexed), dotted-key query style.
- Country is ISO-2 (`GH`, `NG`) as `destinationCountryCode` / `country`.
- Retailer enum is UPPERCASE: `AMAZON`, `EBAY`, `FASHION_NOVA`(?), `PLUG_TECH`(?), `BEST_BUY`(?), `SEPHORA` — only `AMAZON` was observed verbatim.
- Order status enum is UPPERCASE: `PENDING`, `PURCHASED`, `SHIPPED`, `DELIVERED`, `CANCELLED`.
- Every response carries both USD and destination-currency amounts (₵ / GHS) — the UI never converts client-side.

---

## 4. Anything else notable

**Surprises / things worth designing around**

1. **The locker address is the product's center of gravity.** It appears on `/ship` *and* `/profile`, with per-field copy buttons, a "use this exact name"[copy omitted]"add to contacts").
2. **`Nearest Landmark` on addresses.** Explicit accommodation for Ghana/Nigeria addressing. Don't drop it in the app's address form.
3. **Local currency everywhere.** Every price is USD + ₵ side by side, computed server-side. The mobile app should never do FX itself.
4. **Mobile already has an app shell** — bottom tabs Home/Shop/Ship/Orders and a sticky product action bar. The Flutter IA is essentially pre-specified.
5. **Two payment rails beyond cards:** Mobile Money and Bank Transfer are advertised on the product page. Expect a non-card checkout branch.
6. **WhatsApp is a first-class support channel** — linked from `/ship`, profile support, cart step 2, and the footer.
7. **Business accounts exist:** profile shows `Account Type: Personal`, and there's a `/business-shipping` route.
8. **Three distinct "how did the package get to us"[copy omitted]"create shipment" form.
9. **Slow section transitions.** `/profile?section=…` sections fade in over roughly 5–10 seconds with a `Loading addresses…` style placeholder and a long opacity animation. Feels like a bug or a very slow lazy chunk; worth checking before mirroring the pattern.
10. **Search results and product pages are RSC-rendered**, so a plain reload shows the API calls but SPA navigation doesn't — Flutter will need to call `/shop/search` and `/shop/products/parse` directly, which is fine since both are plain GETs.
11. **Deals rows use a native horizontal scroller with a visible scrollbar** on desktop, not a carousel with arrows.

**States I could not reach (and why)**

- **Order detail / tracking timeline** — the account has zero orders, and `/orders` therefore never rendered a row to click into. The 5-step journey UI on `/ship` hints at what it looks like (Register → Receive & weigh → Quote & pay → Delivered).
- **Shipment registration submit** (`Next` on `/ship`) — requires a real tracking number *and* a receipt upload, and submitting would create a live shipment record. Skipped deliberately; the POST endpoint is therefore unknown.
- **Checkout / payment** — `Checkout` on cart step 2 leads to a real payment flow. Not clicked. Promo-code apply endpoint also uncaptured.
- **Add/edit/delete address writes** — modal explored up to the final `Continue`, not submitted. `Delete` on the saved address was avoided (likely a confirm dialog, and it's the account's only address).
- **Password change, 2FA enable, delete account** — all in Settings, all account-mutating; not exercised.
- **Populated notifications** — inbox is empty, so notification card/typing variants are unknown.
- **Nigeria as destination** — the account is set to Ghana; Nigeria-specific pricing/addressing not observed.
- **Logged-out / onboarding flows** (`/`, `/welcome`, signup, locker provisioning) — the session is authenticated and I didn't log out.

---

# Auth & Onboarding (logged-out pass)

Second pass, run in the same Brave profile after **logging out** of the demo account (the extension cannot drive an incognito window). A throwaway account was created with the user's approval — see §7. Screenshots in `discovery/shots/` prefixed `logout-*`, `auth-*`, `post-signup-*`, `verify-*`.

Desktop shots are 1440px wide; "mobile" shots are 606px (the narrowest the OS window would go this session) — enough to trigger the mobile nav, not the ~430px phone layout.

## 1. Landing pages: `/` and `/welcome`

*Shots: `logout-landing-desktop-hero.jpg`, `logout-landing-desktop-stats.jpg`, `logout-landing-desktop-community.jpg`, `logout-landing-mobile.jpg`, `logout-landing-mobile-menu.jpg`*

**`/` and `/welcome` render the identical page** — same hero, same sections, same components. Only the `<title>`/meta differ:
- `/` → "[copy omitted]"
- `/welcome` → "[copy omitted]"

So `/welcome` is an SEO alias, not a separate onboarding screen. Logging out redirects to `/`.

**Logged-out header** (completely different chrome from the authed app header): logo · How it works · Calculator · Countries · Get the App · `Login` (outline button) · `Start Shopping →` (dark green button, links to `/auth/register`) · country flag switcher. Nav links are in-page anchors: `/#how-it-works`, `/#shipping-calculator`, `/#delivery-locations`, `/#get-the-app`. On mobile it collapses to logo + flag + hamburger; the drawer lists the same links with Login and `Start Shopping →` stacked at the bottom.

**Country switcher** (`nav-country-switcher.jpg`): 🌍 **Global** · 🇬🇭 **Ghana** · 🇳🇬 **Nigeria**. Ghana was pre-selected (geo/IP), and it drives the whole page's copy — the hero literally says "ship your packages to **Ghana**", "Pay in **Cedis**"[copy omitted]"Shop global."** (solid) / **"Receive it"** (outlined/stroked text) / **"at `home.`"[copy omitted]"Shop from top U.S. stores or ship your packages to Ghana. **Pay in Cedis via Mobile Money (MoMo), Card, or Bank Transfer—no U.S. card required.** Whether you're an individual or a business, Wolevo helps you save on U.S. sales tax and shipping. Delivered in 7-12 days."
4. **Shop | Ship** toggle (lime active pill) + a retailer-scoped search bar — a logged-out user can type a search here, which pushes into the auth wall.
5. Phone mockups, then an infinite marquee of retailer names (AMAZON · EBAY · FASHION NOVA · PLUG TECH · BEST BUY · SEPHORA) separated by green sparkles.
6. Stats strip: **0%** "[copy omitted]" · **6+** "US stores you can shop from today" · **2+** "African countries we deliver to" · **25%** "[copy omitted]". Numbers are dark, the `%`/`+` suffix is neon green.
7. `THE WOLEVO COMMUNITY` → "Loved & trusted by the community" / "[copy omitted]" — a horizontally scrolling row of vertical video cards with play buttons and durations (1:27, 1:02, 1:12, 0:55, 1:28, 0:57), a centered featured card, a caption block (`🇬🇭 Ghana` / "How to ship from the US to Ghana" / creator handle "Bytes Unlocked"[copy omitted]"Your story starts with one order." / "[copy omitted]" / `Start shopping`.
8. `WHY WOLEVO` → "[copy omitted]"
9. `CORE PROMISE` → "[copy omitted]" with sub-cards: no US sales tax, detailed cost breakdown, fast/affordable shipping ("[copy omitted]"), "Delivery or Pickup", "[copy omitted]"
10. `HOW IT WORKS` → "Two ways to get what you love." with tabs **Shop on Wolevo** / **Ship for Me**, steps `01 Find Your Product` → `02 Pay for the Item` → `03 We Handle Everything` → `04 You Receive`.
11. `SHIPPING CALCULATOR` — the same calculator component as `/calculator`, embedded inline and fully usable logged-out.
12. `WE DELIVER TO` → "From US to Ghana."[copy omitted]"+ all other regions".
13. `THE WOLEVO APP` → "Shop. Ship. Track. Receive."[copy omitted]"Access is a right, not a Privilege."** + `Start Shopping`.

Note the delivery-time copy is inconsistent across the page: hero says **7-12 days**, the register page says **7-14 days**, the core-promise block says **7-14 days after warehouse receipt**.

Sections animate in on scroll (IntersectionObserver). Jumping `window.scrollTo` past a section leaves it blank — it only reveals on a real scroll.

## 2. Signup — `/auth/register`

*Shots: `auth-register-desktop.jpg`, `auth-register-password-rules.jpg`, `auth-register-field-errors.jpg`, `auth-register-phone-country-picker.jpg`, `auth-register-filled.jpg`, `auth-register-duplicate-account.jpg`, `auth-register-mobile.jpg`*

**One step. No wizard, no email-vs-phone choice — both are required, on the same screen.**

Reached from `Start Shopping →`, `Sign up for free` on the login page, or the `Sign Up` tab on the auth card. `/auth/login` and `/auth/register` are two tabs of the same card (`Login` | `Sign Up`), with the Wolevo wordmark above.

Header copy: **"Create Account"** / "[copy omitted]".

Fields, in order:

| Field | Type | Required | Notes |
|---|---|---|---|
| First Name | text | �myes (`*`) | no placeholder |
| Last Name | text | yes (`*`) | side-by-side with First Name on desktop, stacked on mobile |
| Email | email | yes (`*`) | no placeholder |
| Phone Number | tel | yes (`*`) | country selector (flag + chevron) prefilled 🇬🇭 `+233`; opens a searchable full-country list ("Search country…"[copy omitted]"Enter your password"[copy omitted]"Confirm your password", eye toggle |
| Referral code | text | no | behind a collapsed `🎁 Have a referral code?` disclosure; placeholder `ENTER REFERRAL CODE` (monospace, letter-spaced) |

Then `Sign Up →` (full-width dark green), an `or` divider, `Sign up with Google` (white, Google mark), and "[copy omitted]".

**Password requirements** — shown as a live checklist under the field as soon as you type:
- • At least 8 characters
- • One uppercase letter (A-Z)
- • One digit (0-9)
- • One special character (@#$%^&+=!)

**Validation copy** (client-side, inline under each field, red with a ⓘ icon):
- `This field is required` (empty First/Last name)
- `Password must be at least 8 characters`
- `Passwords do not match`

**Server-side duplicate errors** (both rendered at once, on the respective fields):
- `An account with this email already exists. Please sign in.`
- `Account exists with phone number entered`

**Notable:** no date-of-birth, no destination-country field, and **no terms-of-service checkbox** on signup (the ToS agreement line appears at checkout instead). Destination country is inferred — the new account came out with `Destination Country: Ghana` without ever being asked, presumably from the nav country switcher / phone country code.

## 3. What happens immediately after signup

*Shots: `post-signup-home.jpg`, `post-signup-profile-locker.jpg`, `verify-email-modal.jpg`, `verify-email-resent.jpg`*

Submitting valid details:

1. **Immediate auto-login.** Redirect straight to `/home`, greeting already personalized ("Hello, Test!"[copy omitted]"check your email before continuing" wall**.
2. **No onboarding tour.** No coach marks, no wizard, no empty-state walkthrough. The user lands on the same merchandised home as an established account.
3. **Locker + US address are assigned instantly.** `/profile` on the fresh account already showed `Locker ID: DEMO5678` and the full warehouse address — **identical to the other account's** (`20 Penn Mart Center`, `PMB302`, New Castle, DE 19720, `+1 (240) 887-5614`). So the Delaware address and PMB are shared infrastructure; **the locker ID is the only per-user discriminator**, which is exactly why the "use this exact name"[copy omitted]"Order updates and your final bill are sent here. Verify it so nothing gets missed."[copy omitted]"Verify your email"[copy omitted]"We've sent a verification link to your inbox. Confirming your address means order updates and your final bill reach you."*
- Grey inset: `Verification email sent to:` + the address.
- Buttons, top to bottom: **`I've Already Verified`** (mid-green fill), **`Resend Verification Email`** (dark green), **`I'll Verify Later`** (white/outline).
- Footer: *"[copy omitted]"*
- After resend, a green success block appears: **"Verification email sent!"** / "[copy omitted]"

So verification is a **link in an email**, not an OTP code, and it is entirely deferrable. The phone number is collected but appears **not** to be verified at all.

**Also:** visiting `/auth/register` or `/auth/login` while authenticated redirects to `/home`.

## 4. Login — `/auth/login`

*Shots: `auth-login-desktop.jpg`, `auth-login-validation-errors.jpg`, `auth-login-invalid-creds.jpg`, `auth-login-mobile.jpg`*

- Tabs `Login` | `Sign Up`; heading **"Welcome Back"** / "Sign in to your account".
- Fields: `Email` (placeholder "Email"), `Password` (placeholder "Password"[copy omitted]"Don't have an account? **Sign up for free**".
- **Google is the only social provider.** No Apple, no Facebook, no phone/OTP login.

**Copy:**
- Client validation: `Please enter a valid email address`, `Must be at least 8 characters` (interesting — the login form applies the 8-char rule to the *input*, not just signup).
- Failed login: a dismissible red banner above the form, `Invalid email or password` with a ⓘ icon and an `×` close button. Correctly generic — no user-enumeration.

## 5. Forgot password — `/auth/forgot-password`

*Shots: `auth-forgot-password.jpg`, `auth-forgot-password-sent.jpg`*

A dedicated route (not a modal), rendered as a centered white card:
- `← Back to Sign In`, envelope icon in a lime circle.
- **"Forgot Password?"** / "[copy omitted]".
- `Email Address` field (leading envelope icon, placeholder "Email") + `Send Reset Link`.
- "[copy omitted]".

**Success state** (same card, replaced content): check icon, **"Check Your Email"**, *"[copy omitted]"* — enumeration-safe wording — then *"[copy omitted]"* and `Back to Sign In`.

The actual reset screen (the `/auth/reset-password?token=…` side) was not reached — no reset email was opened.

## 6. Network during auth

| Method | Endpoint | When | Notes |
|---|---|---|---|
| POST | `/api/v1/auth/restore` | every page load, logged in or out | **401** when logged out, **200** when logged in. This is the session bootstrap. |
| POST | `/api/v1/auth/login` | login submit | **401** on bad credentials → "Invalid email or password". Payload from the form: `{ email, password }`. |
| POST | `/api/v1/auth/register` | signup submit | **400** on duplicate, with per-field messages. Payload from the form: `{ firstName, lastName, email, phoneNumber (E.164, e.g. +233240000000), password, confirmPassword?, referralCode? }`. |
| ? (preflighted) | `/api/v1/auth/forgot-password?email=<urlencoded>` | Send Reset Link | **email is passed as a query parameter**, not a body. |
| ? (preflighted) | `/api/v1/auth/resend-verification-email?email=<urlencoded>` | Resend Verification Email | same query-param pattern. |

Two things worth flagging for the Flutter client:
- **PII in query strings.** `forgot-password` and `resend-verification-email` put the raw email in the URL, so it lands in access logs, proxies, and browser history. Worth confirming with the backend whether a body is also accepted before mirroring this.
- Only OPTIONS preflights were observable for those two (the tool's capture window reset before the real request), so the verb is inferred, most likely POST.

## 7. Route gating when logged out

*Shot: `logout-gated-redirect-login.jpg`*

| Route | Logged out |
|---|---|
| `/`, `/welcome` | public landing |
| `/auth/login`, `/auth/register`, `/auth/forgot-password` | public |
| `/home` | → redirects to `/auth/login` |
| `/shop` | → `/auth/login` |
| `/cart` | → `/auth/login` |
| `/orders` | → `/auth/login` |
| `/ship` | → `/auth/login` |
| `/profile`, `/messages` | → `/auth/login` (same guard) |
| `/calculator` | **public** |
| `/help` | **public** |
| `/pricing` | **public** |
| `/support?country=…` | **public** |

**The redirect drops the intended destination** — it lands on a bare `/auth/login` with no `?next=` / `?redirect=` parameter, so a logged-out user deep-linked to a product or cart loses their place after signing in. Worth fixing in the app (and worth not copying).

## 8. Do the public pages differ logged-out?

*Shots: `logout-calculator.jpg`, `logout-help.jpg`, `logout-pricing.jpg`, `logout-support.jpg`*

**Content is identical to the authenticated view. Only the chrome changes:**
- Logged out: the marketing header (How it works / Calculator / Countries / Get the App / Login / Start Shopping / country flag).
- Logged in: the app header (retailer search bar, cart badge, Ship, notification bell, account menu).

The calculator is fully functional logged-out, including `POST /api/v1/public/shipping-estimate` — consistent with the `public/` path segment. `/help`, `/pricing`, `/support` are static content either way. On `/help` logged-out there is a brief grey skeleton header while the shell decides which nav to render — a small flash-of-wrong-chrome.

## 9. Notable / open items

1. **The auth wall is aggressive.** Browsing products at all requires an account — `/shop` and `/product` both bounce. The landing page's search bar is therefore a lead-gen device, not a real search. For a mobile app this means the very first screen after install is a signup form, so the signup screen carries a lot of weight.
2. **Signup is short and fast** — 6 fields, one screen, instant login. Nothing blocks on verification. Matching this in Flutter means: one-page form, live password checklist, phone field with country picker defaulting from locale, optional referral behind a disclosure.
3. **Google is the only social provider**, on both login and signup. The OAuth flow itself was not exercised (it would leave the site and hand credentials to a real Google account).
4. **Locker ID is the identity.** Assigned at signup, shared street address across users. Any app-side copy about the warehouse address must keep the "[copy omitted]" warnings intact — they are load-bearing, not boilerplate.
5. **Destination country is never asked at signup** yet ends up populated. It comes from the nav country switcher (Global/Ghana/Nigeria) and/or the phone country code. The Flutter app needs an explicit equivalent or the same inference.
6. **Copy inconsistency on delivery time**: 7-12 days (hero) vs 7-14 days (register page and core promise).
7. **Test account created — you may want to delete it.** With your approval I completed one throwaway signup on production:
   - Name: `Test Discovery`
   - Email: `demo+test@wolevo.com` (a plus-alias of your own inbox, so the verification mail landed with you, not a stranger)
   - Phone: `+233 24 000 0000`
   - Password: `Demo1234!`
   - Assigned Locker ID: `DEMO5678`
   - Email left **unverified**; two verification emails were sent to that alias (one at signup, one via Resend).
   Delete it from the backend when convenient, or via Profile → Settings → Danger Zone → Delete Account.
8. **You are logged out of your own account.** Logging out was the only way to run this pass (the extension can't drive an incognito window). You'll need to sign back in at `/auth/login` yourself — I don't have your password and won't enter one.

### States not reached
- The **password reset screen** (`/auth/reset-password?token=…`) — requires opening the emailed link.
- The **verified-email transition** — the "I've Already Verified" path and what the profile looks like right after confirming.
- **Google OAuth** on either login or signup.
- **Nigeria-scoped landing copy** (the country switcher was left on Ghana).
- **Referral-code signup** — the field was found but never submitted with a real code, so the reward mechanics are unverified.
- Whether the **phone number is ever verified** (no SMS/OTP step was observed anywhere).
