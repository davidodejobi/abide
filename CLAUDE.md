# Abide — Project Guide

Abide is a Flutter hymnal app (package id `openbaptisthymnal`; display name "Abide").
It ships a Baptist hymnal with multi-language packs, favorites, a split/parallel view,
onboarding, and is growing toward Bible reading and sermon notes.

## Tooling

**Locally**, Flutter runs through fvm — version pinned in `.fvmrc` (currently `3.38.4`). Prefix commands with `fvm`:

- Run: `fvm flutter run`
- Analyze: `fvm flutter analyze`
- Test: `fvm flutter test`
- Codegen (auto_route, freezed, json_serializable, riverpod): `fvm dart run build_runner build --delete-conflicting-outputs`

**In CI, drop the prefix.** The workflows install the pinned SDK directly, so `flutter` and `dart` are on PATH and no `fvm` binary exists — `fvm flutter test` there fails with "command not found". The prefix is how a *human machine* selects the right SDK; CI has already selected it.

## Architecture

Feature-First + Clean Architecture. See `feature_arch.md` for the full data-layer strategy.

```
lib/
  core/          # shared: app.dart, router, theme, storage, providers, utils, widgets
  data/          # bundled JSON assets layer (bible, hymns, notes)
  features/<feature>/
    ui/          # pages/, widgets/, viewmodels/ — UI never touches data layer directly
    domain/      # usecases, pure Dart, no Flutter deps
    data/        # repositories + sources/{local,remote}
    model/       # data classes (freezed / json_serializable)
    providers/   # Riverpod providers/notifiers
```

Existing features: `hymn`, `bible`, `dashboard`, `notes`, `onboarding`, `settings`.

## State management — Riverpod (IMPORTANT)

- **Strongly prefer the plain `Notifier` / `NotifierProvider` pattern. Avoid codegen (`@riverpod`) for new providers.**
  Example to follow: `lib/features/hymn/providers/favorites_provider.dart`.
- Some legacy `@riverpod` codegen providers exist (e.g. `hymnDetailProvider`) — don't expand that pattern.

## Routing — auto_route v10

- Config in `lib/core/router/app_router.dart` (`@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')`).
- Annotate screens/pages with `@RoutePage()`. Class `FooPage`/`FooScreen` → generated `FooRoute`.
- After adding/changing a route, run build_runner to regenerate `app_router.gr.dart`.
- Onboarding is gated via `showOnboarding` + `onboardingDeepLink`.

## Theme & fonts

- Theme tokens in `lib/core/theme/` (`app_colors.dart`, `app_text_styles.dart`).
- Fonts: **EBGaramond** (serif, hymn content), **Geist** (UI sans), **ShantellSans** + **PatrickHand** (onboarding doodle/hand-drawn styles).
- Icons are SVGs compiled via `vector_graphics_compiler`; load with `VectorGraphic(loader: AssetBytesLoader('foo'.iconSvg))`.

## Conventions

- Lints: `analysis_options.yaml` (flutter_lints). Keep `fvm flutter analyze` clean.
- Sharing images: capture a widget via `RepaintBoundary` + `RenderRepaintBoundary.toImage()`; share through `ShareService` (`lib/core/utils/services/share_service.dart`). Note `share_plus` v12 — `Share.shareXFiles` is deprecated; use `SharePlus.instance.share(ShareParams(...))`.
- No new docs/markdown files unless asked.

## Git

- Main branch: `main`. Feature work happens on branches / worktrees off the latest base.
