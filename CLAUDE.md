# Cairn: rules for Claude Code

- Read docs/cairn-build-spec.md first. Work phases in order. Update docs/PROGRESS.md after each phase.
- This repo is public and GPL-3.0-or-later. SPDX header on every Dart file. Never commit keystores, debug-symbols/, .env, or keys.
- Two flavors: community (default, fully unlocked, no Google libraries) and store (Summit gate via --dart-define=CAIRN_STORE=true). Work in community. Touch store only in Phase 9.
- Flutter + Dart. Riverpod (generated). Drift. maplibre_gl. go_router. Dio.
- Every user-visible string is an l10n key in lib/l10n/app_en.arb. No exceptions.
- No em dashes anywhere. Not in code, comments, strings, docs, or commits.
- No analytics, ads, crash SDKs, or third-party tracking.
- No API keys in the app. Keyed sources go through the Affluent Labs proxy (Phase 8).
- All network calls HTTPS. User-Agent "Cairn/<version> (contact@affluentlabs.dev)" on every request.
- Units: SI internally, format at the edge via UnitFormatter.
- Elevation gain uses DEM with 5 m hysteresis. Never raw GPS altitude deltas.
- flutter analyze must be clean and flutter test must pass before every commit.
- Commit message format: phase-N: what shipped.
- Decisions made without the user go in docs/DECISIONS.md with a one-line reason.
- If an API's real field names differ from the spec, trust the API and log it in docs/API_NOTES.md.
- Do not start Phase 10 or later without the user.

## Codegen

Riverpod, Freezed, Drift, and json_serializable all use build_runner. After changing
an annotated file, run:

```
dart run build_runner build --delete-conflicting-outputs
```

Generated files (*.g.dart, *.freezed.dart) are committed so CI does not need to run
codegen to analyze. Regenerate and commit whenever an annotated source changes.
