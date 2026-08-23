# 8. Testing

```bash
flutter test          # 27 tests across 2 files
flutter analyze       # must be clean
```

## What's here

| File | Covers |
|---|---|
| `test/smoke_test.dart` | every screen renders at a real phone viewport |
| `test/onboarding_navigation_test.dart` | the onboarding CTAs, driven through the real router |
| `test/support/fake_auth_repository.dart` | synchronous auth double |

## The smoke suite

Each screen is pumped at **390×844** (iPhone 15-class) and asserted on its real
copy. It is a wiring and layout check, not a golden test — but it earns its
keep, because a `RenderFlex overflowed` is a *thrown exception* in Flutter
tests, so overflows fail the build instead of shipping as a yellow-striped box
nobody noticed.

Bugs this suite has already caught, all of which looked fine at a glance:

- `/pricing` hero overflowing 9px as the sliver app bar collapses
- Home's Active Shipments card overflowing 28px on its header row
- Explore's hero `Row` overflowing 136px — now a `Wrap`
- Explore's `SliverPersistentHeader` declaring 62px while measuring 58 — a hard
  sliver assertion that would have crashed the screen on device
- Explore's hero row overflowing 136px at 390pt
- Authenticated screens building before the session resolved, throwing on
  `requireValue` — the reason `AuthGate` exists
- `SplashScreen` calling `context.go` with no router above it

## The navigation suite

`onboarding_navigation_test.dart` builds the **real `routerProvider`** and taps
real buttons. It asserts more than "does the tap work":

- Skip and Explore-first both **persist the seen flag** — otherwise a user who
  skips gets onboarded on every launch
- A **second launch bypasses** onboarding
- The auth guard **doesn't bounce** public destinations

## Writing tests

Two things that will bite you:

**Off-screen widgets aren't built.** In a `ListView`/sliver, a finder for
content below the fold returns nothing. Scroll first:

```dart
await tester.drag(find.byType(ListView).first, const Offset(0, -600));
await tester.pump();
```

Use `.first` when a screen has more than one scrollable — product pages have a
vertical page scroller *and* a horizontal thumbnail strip, and `drag()` needs a
single target.

**Field labels are `RichText`.** `AppTextField` renders the label and its red
required asterisk as two spans, so `find.text('First Name')` fails. Assert on
`find.byType(TextField)` or on placeholder/helper text instead.

## Gaps worth filling

Honest list of what is *not* covered:

- No golden tests — visual regressions aren't caught
- Repository mocks have no unit tests of their own
- The cart → checkout flow isn't driven end-to-end
- Icon switching is untested (it needs a platform channel; the repository
  degrades to a no-op in tests)
