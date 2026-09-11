<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# Contributing to Cairn

Thanks for helping. A few house rules keep the codebase coherent.

## Before a big change

Open an issue first. It saves everyone time if a large PR turns out to duplicate work or
head in a direction the project will not take.

## Ground rules

- Cairn is GPL-3.0-or-later. By contributing you agree your contribution is licensed under
  the same terms. No CLA, no copyright assignment.
- Every user-visible string is a localization key in `lib/l10n/app_en.arb`, read via
  `context.l10n.keyName`. No hardcoded strings in the UI.
- No em dashes anywhere: not in code, comments, strings, docs, or commit messages. Use
  commas, periods, colons, or parentheses.
- No analytics, ads, crash reporting SDKs, or third-party tracking. Ever.
- No API keys in the app. Keyed data sources go through the Affluent Labs proxy.
- Every network call is HTTPS and carries the Cairn User-Agent.
- Store distances and temperatures in SI internally. Format only at the edge.
- Every Dart file starts with `// SPDX-License-Identifier: GPL-3.0-or-later`.

## Before you push

```bash
flutter analyze          # must be clean
flutter test             # must pass
tool/check_spdx.sh       # every Dart file has the SPDX header
```

Zero analyzer warnings is the bar. Commit messages inside a feature can follow conventional
commits; the maintainer squashes to `phase-N: summary` on the main line.

## Fixing map data

A wrong trail name, a missing spring, a mislabeled path: that lives in
[OpenStreetMap](https://www.openstreetmap.org), not in Cairn. Edit it there and it reaches
everyone. Open a "data correction" issue if you are not sure how.
