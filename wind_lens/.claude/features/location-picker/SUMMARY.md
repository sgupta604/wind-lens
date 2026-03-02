# Feature Summary: location-picker

## Overview

The location-picker feature adds the ability to override the device GPS position with a
manually-chosen location. Users tap a pin icon on the home screen to open a full-screen
OpenStreetMap map, tap anywhere to place a pin, and confirm to apply the location globally.
All wind data, horizon data, and dome visualizations immediately update for the chosen position.

The implementation also includes four bug fixes (found during on-device testing) and the
`LocationIndicatorChip` UX enhancement for the dome screen.

## Status

- **Completed:** 2026-03-02
- **Branch:** feature/location-picker (merged to master)
- **Tests:** 746 passing, 0 failures
- **Analyzer:** 0 errors, 0 warnings (13 pre-existing info-level Riverpod deprecations)

## What Was Built

### Core Feature: Location Override Provider Chain

A new Riverpod provider pair in `lib/core/providers/location_override_provider.dart`:

- `locationOverrideProvider` — a `@riverpod` Notifier holding `PositionData?`. Starts as
  `null` (use GPS). Exposes `set(PositionData)` and `clear()`.
- `effectivePositionProvider` — a computed provider returning `override ?? stablePosition`.
  Keeps the GPS chain alive at all times (always-watch pattern) to prevent AutoDispose
  disposal of upstream providers when an override is active.

All data providers (`windDataProvider`, `horizonProfileProvider`, `sceneStateProvider`,
`domeWindProfileProvider`) were updated to watch `effectivePositionProvider` instead of
`stablePositionProvider`. Sensor data (compass, pitch) is not affected.

### Location Picker Screen

`lib/features/location_picker/location_picker_screen.dart` — a full-screen
`ConsumerStatefulWidget` showing:

- OpenStreetMap tiles via `flutter_map` (no API key required)
- A draggable marker at the current effective position (override or GPS)
- Tap-anywhere-to-place-pin interaction
- Confirm button — writes to `locationOverrideProvider` and pops
- Cancel button — pops without modifying the provider
- Reset to GPS button — clears the override; shows a SnackBar if GPS is unavailable

Navigation from `HomeScreen` via `Navigator.push(MaterialPageRoute(...))`.

### Location Indicator Chip

`lib/features/wind_dome/widgets/location_indicator_chip.dart` — a `ConsumerWidget` pill
shown below the `DomeInfoBar` on the dome screen:

- GPS mode: pin icon + "GPS" label (white)
- Override mode: pin icon + "lat, lng" (4 decimal places, orange)
- Semi-transparent black background matching dome UI styling
- Semantics labels for accessibility

### Home Screen Integration

- `home_top_bar.dart` — pin icon button (`assets/icons/location_pin.png`) replacing the
  old "LOC" text button, navigates to `LocationPickerScreen`
- `home_screen.dart` — `_navigateToLocationPicker()` method

## Bug Fixes

Four bugs were discovered and fixed during on-device testing. All shared a single root
cause: UI code reading `stablePositionProvider` (raw GPS) instead of
`effectivePositionProvider` (GPS or override) for null-checks and display.

| Bug | File | Fix |
|-----|------|-----|
| BUG 1: Reset to GPS button did nothing when GPS unavailable | `location_picker_screen.dart` | Added `else` branch with SnackBar "Waiting for GPS signal..." |
| BUG 2: Re-entering map showed pin at (0, 0) | `location_picker_screen.dart` | Changed `initState()` to read `effectivePositionProvider` |
| BUG 3a: Dome screen showed "Waiting for GPS" overlay despite active override | `wind_dome_screen.dart` | Changed position watch from `stablePositionProvider` to `effectivePositionProvider` |
| BUG 3b/4: AR screen DataStatusBar stuck in "Waiting for GPS" state | `ar_view_screen.dart` | Changed position watch from `stablePositionProvider` to `effectivePositionProvider` |

### GPS Provider Chain Fix

A deeper bug was also fixed in `location_override_provider.dart`. The original
`effectivePositionProvider` used a conditional early-return pattern:

```dart
// BROKEN: stablePositionProvider is never watched when override is set
final override = ref.watch(locationOverrideProvider);
if (override != null) return override;
return ref.watch(stablePositionProvider);
```

Because Riverpod AutoDispose disposes providers with no active watchers, this caused the
entire GPS chain (`stablePositionProvider` and `gpsPositionProvider`) to be torn down while
an override was active. Clearing the override then returned null instead of the GPS
position.

Fixed with the always-watch pattern:

```dart
// FIXED: both providers are always watched; GPS chain stays alive
final override = ref.watch(locationOverrideProvider);
final gpsPosition = ref.watch(stablePositionProvider);
return override ?? gpsPosition;
```

## Architecture Decisions

1. **effectivePositionProvider in its own file** — `location_override_provider.dart` holds
   both `locationOverrideProvider` and `effectivePositionProvider` since they are tightly
   coupled. Keeping them separate from `data_providers.dart` clarifies their role as an
   override injection point.

2. **Always-watch pattern for GPS chain** — Watching both providers unconditionally
   (regardless of whether an override is set) keeps the GPS chain alive at all times. The
   cost is one extra provider watch; the benefit is correct behavior when clearing the
   override.

3. **stablePositionProvider preserved in Reset to GPS** — `_onResetToGps()` reads
   `stablePositionProvider` directly (not `effectivePositionProvider`) because the user's
   intent is specifically to snap back to GPS. After `clear()`, effective == stable anyway.

4. **Session-only persistence** — No `SharedPreferences` or local storage. Override resets
   to null on each cold start. Matches the confirmed user requirement.

5. **LocationIndicatorChip as ConsumerWidget** — Reads providers directly rather than
   accepting constructor arguments. Self-contained, easy to relocate to other screens.

6. **OSM tiles via flutter_map** — Both `flutter_map ^7.0.0` and `latlong2 ^0.9.1` were
   already in `pubspec.yaml`. No new dependencies were required.

## Files Changed

### New Files (6)

| File | Purpose |
|------|---------|
| `lib/core/providers/location_override_provider.dart` | `locationOverrideProvider` + `effectivePositionProvider` |
| `lib/core/providers/location_override_provider.g.dart` | Riverpod codegen output |
| `lib/features/location_picker/location_picker_screen.dart` | Full-screen OSM map picker |
| `lib/features/wind_dome/widgets/location_indicator_chip.dart` | GPS / override indicator pill |
| `assets/icons/location_pin.png` | Pin icon for home screen button |
| `test/core/providers/location_override_provider_test.dart` | 10 unit tests |
| `test/core/providers/effective_position_graph_test.dart` | 3 integration tests (provider graph) |
| `test/features/location_picker/location_picker_screen_test.dart` | 9 widget tests |
| `test/features/wind_dome/widgets/location_indicator_chip_test.dart` | 3 widget tests |

### Modified Files (8 source + 3 generated)

| File | Change |
|------|--------|
| `lib/core/providers/data_providers.dart` | Watch `effectivePositionProvider` (wind + horizon) |
| `lib/core/providers/data_providers.g.dart` | Regenerated |
| `lib/core/providers/scene_provider.dart` | Watch `effectivePositionProvider` |
| `lib/core/providers/scene_provider.g.dart` | Regenerated |
| `lib/features/wind_dome/providers/dome_providers.dart` | Watch `effectivePositionProvider` |
| `lib/features/wind_dome/providers/dome_providers.g.dart` | Regenerated |
| `lib/features/home/widgets/home_top_bar.dart` | Pin icon button replacing "LOC" text |
| `lib/features/home/home_screen.dart` | Navigation to `LocationPickerScreen` |
| `lib/features/ar_view/ar_view_screen.dart` | BUG 3b: watch `effectivePositionProvider` |
| `lib/features/wind_dome/wind_dome_screen.dart` | BUG 3a: watch `effectivePositionProvider` + `LocationIndicatorChip` |
| `pubspec.yaml` | Added `assets/icons/` directory declaration |
| `test/features/home/home_screen_test.dart` | Updated tests for pin icon button |

## Test Coverage

| Suite | Tests | Status |
|-------|-------|--------|
| `location_override_provider_test.dart` | 10 | Pass |
| `effective_position_graph_test.dart` | 3 | Pass |
| `location_picker_screen_test.dart` | 9 | Pass |
| `location_indicator_chip_test.dart` | 3 | Pass |
| Full auto-discovered suite | 746 | Pass |
| Explicit-path suite | 47 | Pass |

Key scenarios tested:
- Override set/clear semantics
- GPS chain stays alive during override (regression for AutoDispose bug)
- Map opens at effective position on re-entry (not at 0,0)
- Reset to GPS shows SnackBar when GPS unavailable
- Reset to GPS clears override when GPS available
- `LocationIndicatorChip` shows "GPS" vs coordinates reactively
- Cancel button pops without modifying provider

## Known Deferred Items

- On-device testing for GPS timing edge cases (BUG 1 SnackBar path requires GPS to be
  unavailable at tap time — verify on airplane mode or indoors)
- AR screen does not have a `LocationIndicatorChip` yet (dome screen only for MVP)
- Map tile caching is not implemented (OSM tiles require network; grey tiles when offline)
- Reverse geocoding (showing city name for selected location)
- Map search bar (type an address to navigate)
