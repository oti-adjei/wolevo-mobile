# Wolevo Mobile — a concept client

> [!IMPORTANT]
> **Unofficial hobby project. Not affiliated with Wolevo.**
>
> Wolevo is a real shop-and-ship service with a live web app. This repository is
> not theirs, was not commissioned by them, and is not endorsed by them. It is a
> personal case study: our take on what a mobile client for that kind of service
> could look like.
>
> **There is no API.** The endpoints in the code (`api.wolevo.com`,
> `staging-api.wolevo.com`) are a speculative shape, not a real service — nothing
> in this repository talks to Wolevo's systems. The app runs entirely on mock
> data.

A Flutter client for a shop-and-ship service — the flow where you buy from US
stores and have it delivered to Ghana or Nigeria. Built in free time to work
through the mobile design problem end to end: what the screens are, how the data
layer should be shaped, and what a production-grade Flutter codebase looks like
when nothing is rushed.

```bash
export PATH="$HOME/fvm/versions/3.44.8/bin:$PATH"
flutter pub get
flutter run          # demo login: demo@wolevo.com / Demo1234!
```

Runs entirely on mock data — no backend, no keys, no `.env`.

## Docs

**Start here: [`docs/handbook/`](docs/handbook/README.md)** — architecture, data
layer, design system, screens, brand pipeline, testing, conventions and
observability, in reading order.

[`discovery-notes.md`](discovery-notes.md) is the source of truth for copy,
field lists, API shapes and visual tokens: a structured capture of the public web
app at wolevo.com, used as a reference point so the concept stayed grounded in a
real product rather than invented wholesale. Personal identifiers from the
capture were replaced with demo values. Where a gap had to be filled, the code
says so with `// ASSUMPTION:` or `// INFERRED SCREEN:`.

## Verify

```bash
flutter analyze      # expect: No issues found!
flutter test         # expect: 27 tests, All tests passed!
```
