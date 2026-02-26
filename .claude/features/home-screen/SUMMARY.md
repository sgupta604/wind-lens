# Summary: Home Screen (SPEC-002)

**Feature:** home-screen
**Finalized:** 2026-02-26
**Branch:** `feature/wind-dome-homescreen`
**Commit:** feat(home): add home screen with terrain panorama and wind dashboard

---

## What Was Built

A new `HomeScreen` replaces direct-to-camera launch as the app entry point. The screen provides a calm dashboard view with Shyft Lens branding, live wind data, a procedural terrain panorama with animated particles, an altitude rail, a compass bar, and layer toggles. The user taps "LIVE AR" to enter the camera AR view.

---

## Metrics

| Metric | Value |
|--------|-------|
| New source files | 9 |
| New test files | 3 |
| Modified source files | 2 (`lib/app.dart`, `pubspec.yaml`) |
| Modified test files | 1 (`test/widget_test.dart`) |
| New tests added | 18 |
| Total test suite | 628 (was 610) |
| Analyzer issues in new code | 0 |
| Pre-existing info issues (full lib/) | 12 (all pre-existing, Riverpod 3.0 / HTML doc comment) |

---

## Files Created

### Source

| File | Purpose |
|------|---------|
| `lib/core/utils/wind_utils.dart` | `degreesToCardinal()` — 16-point compass rose |
| `lib/features/home/home_screen.dart` | Main screen: ConsumerStatefulWidget, AnimationController, Column layout |
| `lib/features/home/widgets/home_top_bar.dart` | Logo "ShyftLens" + "ATMOSPHERIC AR" subtitle + Live AR button with pulsing red dot |
| `lib/features/home/widgets/home_wind_row.dart` | Three-column data row: Speed, Direction, Altitude. ConsumerWidget |
| `lib/features/home/widgets/home_terrain_section.dart` | Stack: grid + terrain bezier + particles + altitude rail + compass bar |
| `lib/features/home/widgets/home_particle_painter.dart` | CustomPainter with 80 `_HomeParticle` objects, trail rendering, sinusoidal wiggle |
| `lib/features/home/widgets/home_altitude_rail.dart` | Right-edge altitude ticks (5 levels, 3 tappable). ConsumerWidget |
| `lib/features/home/widgets/home_compass_bar.dart` | Bottom compass row (8 directions), ValueListenableBuilder on headingNotifier |
| `lib/features/home/widgets/home_layer_toggles.dart` | Four toggle buttons (visual-only in MVP) |

### Tests

| File | Tests | Coverage |
|------|-------|---------|
| `test/core/utils/wind_utils_test.dart` | 6 | `degreesToCardinal` edge cases |
| `test/features/home/home_screen_test.dart` | 8 | Rendering, navigation, sub-widget presence |
| `test/features/home/widgets/home_wind_row_test.dart` | 4 | Null state, speed, direction, altitude display |

---

## Files Modified

| File | Change |
|------|--------|
| `lib/app.dart` | Entry point changed to `HomeScreen`, title changed to `"Shyft Lens"` |
| `pubspec.yaml` | Added `google_fonts: ^6.1.0` |
| `test/widget_test.dart` | Updated to expect `HomeScreen` as app home (intentional, not regression) |

---

## Post-Implementation Bug Fixes (Applied During Feature)

Three visual issues were found during device testing and fixed before finalization:

1. **Terrain too dark/invisible** — Added gradient fill, ridge glow line, and moved terrain silhouette higher on screen.
2. **Particles stuck at left edge** — Extracted `HomeParticleState` from painter. Flutter recreates `CustomPainter` instances each rebuild; particle state was being reset. Fix: store particle list in the parent `StatefulWidget` and pass reference into the painter.
3. **Dead black space** — Added sky atmosphere radial gradient (top of terrain section) and a horizon reference line.

---

## Architecture Decisions

### CustomPainter State Survival Pattern (New Pattern — Added to CLAUDE.md)
Flutter recreates `CustomPainter` on every widget rebuild. Mutable simulation state (particle positions, velocities, trails) must be owned by the parent `StatefulWidget`, not the painter. The painter receives a reference to the particle list and mutates it in place during `paint()`. This pattern is documented in CLAUDE.md under "Key Technical Details".

### HomeTopBar Owns Its Own AnimationController
The pulsing red dot on the Live AR button uses a separate `AnimationController` with `SingleTickerProviderStateMixin` inside `HomeTopBar`. This isolates the pulse animation from the particle `AnimationController` owned by `HomeScreen` — cleaner lifecycle management with no shared state.

### ValueListenableBuilder for Compass Bar
`HomeCompassBar` uses `ValueListenableBuilder<double>` on `sensorNotifiers.headingNotifier` rather than `setState` or `ref.watch`. This matches the pattern used in `ARViewScreen` / `ParticleOverlay` — zero widget rebuilds for 20-50 Hz heading updates.

### Layer Toggles Are Visual-Only in MVP
The four layer buttons (PARTICLES, PRESSURE, TERRAIN, CLOUDS) have no functional wiring. Wiring to `detectionModeProvider` is deferred to a follow-up, as documented in the spec's "Deferred" section.

---

## Provider Dependencies (Read-Only, No New Providers)

The HomeScreen is a pure consumer of the existing Riverpod graph. No new providers or services were created.

| Provider | Used for |
|----------|---------|
| `sceneStateProvider` | Wind speed, direction for `HomeWindRow` |
| `selectedAltitudeProvider` | Active altitude for `HomeAltitudeRail` + `HomeWindRow` |
| `sensorNotifiersProvider` | `headingNotifier` for `HomeCompassBar` active direction |

---

## Quality Gate Results

| Check | Result |
|-------|--------|
| `flutter test` (628 tests) | PASS |
| `flutter analyze lib/features/home/` | 0 issues |
| `flutter analyze lib/core/utils/wind_utils.dart` | 0 issues |
| `flutter analyze lib/` (full) | 12 info (all pre-existing) |
| TODO markers in new code | 0 |
| `debugPrint` in new code | 0 |
| Accessibility (`Semantics`) | Present on interactive elements |
| Object allocation in render loop | 0 (particle list is pre-allocated) |

---

## Future Swap-In Points

The home screen is designed for incremental enhancement:

| Deferred Feature | Swap-In Point |
|------------------|---------------|
| Real terrain from `HorizonProfile` | `HomeTerrainPainter` accepts optional `HorizonProfile? profile` param — pass non-null when P2B-002 lands |
| Layer toggle wiring | `HomeLayerToggles` — wire to `detectionModeProvider` |
| Wind-influenced particle direction | `HomeParticlePainter` accepts optional `WindData? windData` — use `uComponent` to bias `vx` |
| Transition animation | Add `PageRouteBuilder` with fade or slide in `_navigateToAR()` |

---

## Next Pipeline Step

Feature `home-screen` is finalized. The next feature in the roadmap is `wind-dome` (SPEC-002-wind-dome.md). Run `/research wind-dome` to begin.
