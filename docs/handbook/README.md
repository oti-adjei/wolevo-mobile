# Wolevo Mobile — Handbook

Everything a new engineer needs to understand and work on this codebase.

Read in order:

| # | Document | What it covers |
|---|---|---|
| 1 | [Getting started](01-getting-started.md) | Toolchain, running the app, demo credentials |
| 2 | [What the product is](02-product.md) | The two flows, the locker, why it exists |
| 3 | [Architecture](03-architecture.md) | Layers, folder rules, state, navigation |
| 4 | [Design system](04-design-system.md) | Tokens, typography, the mobile adaptation rules |
| 5 | [Data layer](05-data-layer.md) | Repositories, mocks, API conventions, going live |
| 6 | [Screens](06-screens.md) | Every route and what owns it |
| 7 | [Brand assets](07-brand-assets.md) | The vector mark, splash, app icons, seasonal icons |
| 8 | [Testing](08-testing.md) | What is covered, how to add to it |
| 9 | [Conventions & gotchas](09-conventions.md) | House rules and the traps we already hit |
| 10 | [Environments, logging & analytics](10-observability.md) | Build envs, the logging seam, Sentry/PostHog plan |
| 11 | [CI & releases](11-releases.md) | GitHub workflows, cutting a release, signing |

## The one-paragraph version

Wolevo is a shop-and-ship service for Ghana and Nigeria. This is the Flutter
client: 14 features, five bottom tabs, ~150 Dart files. It is **feature-first**,
uses **Riverpod** for state and **go_router** for navigation, and every feature
talks to its own **repository interface**. Today every repository is backed by an
in-memory mock, so the whole app is runnable and demoable with no server.
Swapping in the real API means writing Dio implementations and changing one
provider line per feature — no UI changes.

The same seam pattern covers logging and analytics: features call `AppLogger`
and `AnalyticsClient`, never a vendor SDK.

```bash
export PATH="$HOME/fvm/versions/3.44.8/bin:$PATH"
flutter run          # demo@wolevo.com / Demo1234!
flutter analyze && flutter test
```

## Where the design comes from

Three sources, in order of authority:

1. **`discovery-notes.md`** — a structured capture of the live web app. Ground
   truth for copy, field lists, API shapes and visual tokens.
2. **Client app mockups** — supplied mid-build; the reason Home, Shop and the
   nav were restyled. Where they conflicted with discovery, discovery won on
   *behaviour*, the mockups won on *layout*.
3. Inference, always marked in code.

## Ground truth

The design and copy in this app are not invented. They were captured from the
live web app at `wolevo.com` in a structured discovery pass, written up in
[`discovery-notes.md`](../../discovery-notes.md) at the repo root. **That file is
the source of truth for copy, field lists, API shapes and visual tokens.**

Two rules follow from that, and they matter:

1. **Don't invent product behaviour.** If it isn't in the notes, it isn't
   observed. Where we had to fill a gap, the code says so with an
   `// ASSUMPTION:` comment (67 of them at time of writing) or, for a whole
   screen, an `// INFERRED SCREEN:` banner.
2. **Copy is quoted, not paraphrased.** Error strings, button labels and helper
   text match the web app character for character. If you change one, check the
   notes first.

Search for these when you want to know what is solid and what is a guess:

```bash
grep -rn "ASSUMPTION" lib | wc -l      # gap-filling decisions
grep -rln "INFERRED SCREEN" lib        # screens never observable
```
