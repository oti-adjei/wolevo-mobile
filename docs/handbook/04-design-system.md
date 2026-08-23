# 4. Design system

All tokens live in `lib/core/theme/`. **Never hardcode a colour, size or radius
in a widget.** There is exactly one legitimate exception in the codebase —
Google's brand blue on the OAuth "G" — and it carries a comment explaining why
it must not become a token.

Check with:

```bash
grep -rn "0xFF" lib | grep -v app_colors    # expect only the Google blue
```

## Colours — `app_colors.dart`

Lifted verbatim from the web app's Tailwind `@theme` block.

| Token | Hex | Used for |
|---|---|---|
| `primary` | `#01FF69` | neon green — logo mark, "In Stock", accents on dark |
| `primary2` / `primary3` | `#CCFFE1` / `#00993F` | tint / press state |
| `secondary` | `#0A3307` | **deep forest green** — headers, primary buttons, heroes |
| `secondary2` | `#DDFADB` | mint — selected cards, icon chips |
| `secondary3` | `#125A0C` | step circles, active borders |
| `tertiary` | `#DFFF7C` | **lime** — active pills, locker banner, badges |
| `tertiary3` | `#F9FFE5` | info callout background |
| `success` / `error` | `#2EB67D` / `#E63946` | status |
| `surface` | `#F2F2F2` | page background |
| `surface4` | `#E6E6E6` | hairline borders |
| `neutral1` / `neutral2` | `#666` / `#999` | muted text / placeholder |
| `bodyText` | `#171717` | default text |

**Two signature colours**: deep forest green and lime. If a screen feels off,
it's usually because it's missing one of them.

## Typography — `app_typography.dart`

**Sora**, shipped as a variable font. Every style declares both a `FontWeight`
*and* a matching `wght` `FontVariation` — without the latter the axis doesn't
actually move.

Display sizes are stepped down from the web (48px H1 would overflow a 375px
phone); body and below keep their exact web values.

```
h1        34/700   tight tracking
h2        26/700
h3        22/700
cardTitle 18/700
body      16/400/24     ← dominant
body14    14/400/20
caption   12/400/18
micro     10/600        uppercase, letter-spaced (badges)
eyebrow   11/600        uppercase, letter-spaced (section labels)
```

**Eyebrow labels are structural**, not decoration. The web app uses them above
every form group and section (`PACKAGE DETAILS`, `NAME`, `SHIPPING CALCULATOR`).
Use `EyebrowLabel` rather than styling a `Text` yourself.

## Radius & spacing — `app_dimens.dart`

- Cards **12–16**, inputs and small buttons **6–8**, pills/avatars/CTAs **fully round**
- 4pt spacing scale; phone gutter **16**, card padding **20**

## Components — `core/widgets/`

| Widget | Notes |
|---|---|
| `PrimaryButton` | forest fill, white label, no shadow; disabled = same shape at 55% opacity |
| `SecondaryButton` | white fill, hairline border |
| `AccentButton` | lime fill, dark green label, always a pill |
| `DestructiveButton` | white fill, red border, red label — **never a solid red fill** |
| `AppCard` / `SelectableCard` | selected = mint fill + green border + `SelectedMarker` |
| `InfoCallout` | pale-lime block with an emoji lead-in |
| `MicroBadge` | uppercase pill (`PRIMARY`, `YOU'RE HERE`) |
| `LockerAddressPanel` | the locker block; shared by Ship and Profile |
| `WolevoMark` / `AnimatedWolevoMark` | the logo, as vector — no plugin, no asset |
| `AppSearchField` | the search box: soft pill, hairline edge, inline clear |
| `RetailerLogo` | store logos from `assets/logos/`, wordmark fallback |
| `SectionHeader` | section title + optional `View All` action |

**Search is not a form field.** `AppSearchField` exists because the themed
`InputDecoration` — heavy outline, 8px corners — reads as "fill this in", not
"search". Shop and Orders both use it. It owns **no debounce**: each caller keeps
its own, so a rebuild cannot restart someone else's timer.

`SectionHeader` uses `cardTitle` (18/700), not `h3` (22/700). At display size
these headings competed with the content beneath them.

## Mobile adaptation rules

The discovery screenshots were captured at **500–606px browser width** — a
responsive web breakpoint, **not a phone**. They are reference for colour, type,
spacing and copy **only**. Layout was redesigned for a 375–430px viewport:

| Web | Here |
|---|---|
| side-by-side fields | always stacked |
| centred modal (e.g. 3-step Add Address) | full-screen route |
| dropdown / `<select>` | bottom sheet (`showAppSheet`) |
| sidebar (Cost Summary, Profile nav) | single-column section / tab strip |
| header search bar | dedicated search screen |
| horizontal 5-step stepper | vertical stepper |
| long marketing scroll | Explore screen with tabs; scroll kept at `/welcome` |
| full-width white band under a hero | floating pill on the page background |
| 4-up fixed store grid | scrolling tiles, last one part-visible to signal it |

Every one of these is commented at its call site, so the reasoning survives.
