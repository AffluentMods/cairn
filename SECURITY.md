<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# Security policy

## Reporting a vulnerability

Email **security@affluentlabs.dev** with a description, steps to reproduce, and the affected
version. Please do not open a public issue for a security problem.

You will get an acknowledgement within a few days. There is no bug bounty, but real reports
are credited in the release notes if you would like.

## Scope

- The Cairn Android app (this repository).
- The optional Cairn sync server and the Affluent Labs proxy (their own repositories).

## What Cairn does with your data

- No account, no analytics, no ads, no third-party tracking.
- Location is used for the map puck and for recordings, and stays on the device.
- Network requests send only a coordinate or a map area to the public data sources listed in
  the README, plus the optional Affluent Labs proxy, which logs nothing but a rate-limit
  counter.
- Optional sync is end-to-end encrypted: the server only ever holds ciphertext it cannot
  read, and sync is off by default.

See [docs/PRIVACY.md](docs/PRIVACY.md) for the full statement.
