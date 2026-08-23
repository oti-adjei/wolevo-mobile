# Wolevo Mobile

Flutter client for Wolevo — a shop-and-ship service for Ghana and Nigeria.

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
field lists, API shapes and visual tokens: a structured capture of the live web
app at wolevo.com. Do not invent product behaviour that is not in there — where
a gap had to be filled, the code says so with `// ASSUMPTION:` or
`// INFERRED SCREEN:`.

## Verify

```bash
flutter analyze      # expect: No issues found!
flutter test         # expect: 27 tests, All tests passed!
```
