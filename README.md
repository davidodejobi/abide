# Abide

[![flutter](https://github.com/davidodejobi/abide/actions/workflows/flutter.yml/badge.svg)](https://github.com/davidodejobi/abide/actions/workflows/flutter.yml)
[![codecov](https://codecov.io/gh/davidodejobi/abide/graph/badge.svg?token=RLZK8V5I05)](https://codecov.io/gh/davidodejobi/abide)

A hymnal and Bible reader for all Christians. Multi-language hymn packs,
favorites, a parallel split view, offline Bible translations, and tablets
(notes) that link back to scripture.

The package id is still `openbaptisthymnal` for store continuity; the app is
called Abide.

## Tooling

Flutter is pinned with [fvm](https://fvm.app) — see `.fvmrc` (currently 3.38.4).

```bash
fvm flutter run
fvm flutter analyze
fvm flutter test
fvm dart run build_runner build --delete-conflicting-outputs
```

## Testing

```bash
fvm flutter test                         # everything, goldens included
fvm flutter test --coverage              # writes coverage/lcov.info
fvm flutter test --exclude-tags golden   # skip goldens
```

The layout mirrors `lib/`, plus:

| Path | What lives there |
| --- | --- |
| `test/support/` | `pump_app.dart` (widget harness, in-memory DB), `fixtures.dart` (deterministic builders) |
| `test/golden/` | Alchemist golden tests |
| `test/goldens/` | the committed `.png` files |
| `test/flutter_test_config.dart` | Alchemist config; Flutter applies it to the whole suite |

**Regenerating goldens** — one file at a time, with `-j 1`. Running every golden
file at once can OOM the test host (killed, exit 137):

```bash
fvm flutter test test/golden/hymn_list_tile_golden_test.dart --update-goldens -j 1
```

If a golden seeded on macOS still won't match ubuntu, label the PR
`update-goldens` and CI reseeds it onto the branch.

Goldens use the Ahem font and disable shadows, which is what makes them
byte-identical across macOS and Linux and therefore safe to gate in CI. The
tradeoff is real: the committed PNGs show block text, so they catch layout,
colour and state regressions, not typography.

### Conventions

- **BDD naming.** `group('Given …')` → `group('When …')` → `test('Then …')`, so
  the test name reads as a sentence.
- **Determinism.** No wall clock, no randomness. `fixtures.dart` exports a fixed
  `fixedNow`, and every builder defaults its timestamps to it.
- **Fixtures over literals.** `tabletRow(title: 'Psalm 23')`, not a six-field
  constructor inlined in the test.
- **Never `pumpAndSettle`** on a tree with looping animations — it waits for a
  quiet frame that never comes. Use `pumpApp`, which pumps a fixed duration.
- **Call `flushTimers()`** at the end of any test whose tree holds a stream
  subscription or a repeating animation. Otherwise the straggler timer outlives
  the test and trips the pending-timer assertion, failing a test that passed.

### Coverage

The CI gate measures the **logic layers** (domain, data, providers, core),
excluding generated code and `lib/**/ui/**`.

UI is verified by widget and golden tests — by behaviour and by pixels, not by
line count. Counting UI lines in the gate would mean that adding a widget test
for a large screen *drops* overall coverage and fails the build, punishing
exactly the thing we want people to do.

Never lower the gate to make CI green. Write the test.
