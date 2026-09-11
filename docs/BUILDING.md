<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# Building and running Cairn

## Prerequisites

- Flutter (Dart SDK `^3.6.0`).
- Android SDK + a device or emulator. The physical phone is the source of truth
  for maps, location, and performance; the emulator is for reproduction and
  simulated location.

## Flavors

Two Android product flavors share one applicationId:

- `community` (default, fully unlocked, no Google libraries).
- `store` (Summit gate via `--dart-define=CAIRN_STORE=true`).

A flavor is required, so pass `--flavor`:

```
flutter build apk --debug --flavor community
flutter run --flavor community
```

Building without `--flavor` assembles both and then fails to locate a single
APK. Match the ABI to the target: a physical phone is usually `android-arm64`,
the standard Android emulator is `android-x64`. An arm64 APK will not run on an
x86_64 emulator (`dlopen ... is for EM_AARCH64`).

```
flutter build apk --debug --flavor community --target-platform android-x64
adb install -r -d build/app/outputs/flutter-apk/app-community-debug.apk
```

## Codegen

After changing a Riverpod, Freezed, Drift, or json_serializable annotated file:

```
dart run build_runner build --delete-conflicting-outputs
```

Generated files (`*.g.dart`, `*.freezed.dart`) are committed.

## Before every commit

```
flutter analyze   # must be clean
flutter test      # must pass
```

## Simulating a hike (no GPS needed)

Follow mode and route recording can be exercised without moving:

1. Debug build only: Settings > Developer > **Simulate location**, turn it on.
2. Load a route in Navigate ("Navigate this trail" from Explore, or a saved
   route), then tap **Start**.
3. Recording walks the loaded route: the camera follows heading-up, distance
   remaining counts down, and off-route logic runs. Turn the toggle off to use
   the real GPS again.

The simulator lives in `lib/data/sources/location_source.dart`
(`SimulatedLocationSource` / `simulateAlong`) behind the `LocationSource`
interface, and is ignored entirely in release builds.

### Emulator location, the manual way

You can also drive the OS location the app reads from GPS:

```
adb emu geo fix <lon> <lat>     # one fix, e.g. adb emu geo fix -121.47 46.44
```

Android Studio's Extended Controls > Location can play back a GPX or KML track
if you prefer a scripted route without the in-app simulator.
