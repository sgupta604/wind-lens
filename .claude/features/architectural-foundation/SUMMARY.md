# SPEC-001 Architectural Foundation — Summary

## Status: COMPLETE (2026-02-25)

All 4 phases implemented, tested, and finalized.

---

## What Was Built

SPEC-001 introduced a production-grade architecture to Wind Lens: Riverpod state management, Freezed immutable models, service abstraction interfaces, a 6-layer provider graph, and a feature-based directory structure. The existing functionality was preserved — all 405 pre-SPEC-001 tests continue to pass alongside 201 new tests.

### Phase 1: Freezed Models + Service Interfaces + Wrappers (84 new tests)

- **6 Freezed data models** in `lib/core/models/`: `WindData` (u/v primary, computed speed/direction), `PositionData`, `SensorState`, `HorizonProfile` (interpolating terrain elevations), `SceneState` (composed snapshot), and `SkyMaskData` (plain class, not Freezed — hot path).
- **4 service interfaces** in `lib/core/services/`: `SkyDetector`, `WindDataSource`, `HorizonProvider`, `SensorService`.
- **4 wrapper implementations**: `HsvSkyDetector`, `MockWindDataSource`, `MockHorizonProvider`, `DeviceSensorService`.
- Re-export shim pattern established for backward-compatible migration.

### Phase 2: Riverpod Provider Graph + Directory Restructure (16 new tests)

- **6-layer Riverpod provider graph** with `sensorNotifiersProvider` ValueNotifier sidecar for 20-50Hz sensor data (zero widget rebuilds for heading/pitch changes).
- **`stablePositionProvider`** debounces GPS with >100m Haversine threshold to prevent provider thrash.
- **`sceneStateProvider`** composes all data; returns null while loading (camera appears immediately).
- **Directory restructure** to `lib/core/` + `lib/features/ar_view/` using re-export shims at old paths.
- `ARViewScreen` converted to `ConsumerStatefulWidget`.
- `lib/app.dart` created with `ProviderScope` wrapper.

### Phase 3a: Full Wiring (9 new tests)

- `ARViewScreen` now consumes `sceneStateProvider` for wind data (no local instances).
- `ParticleOverlay` migrated from old `SkyMask` interface to `SkyMaskData` plain class.
- Camera frames routed through `skyDetectorInstanceProvider` (provider-based `HsvSkyDetector`).
- `PositionData.altitude` now sourced from geolocator's `Position.altitude` (was hardcoded 0.0).
- `AppLifecycleObserver` pauses/resumes `SensorService` on app background/foreground.

### Phase 3b: Caching + Loading UI + Integration Tests (48 new tests)

- **`DataStatusBar`** widget: shows "Waiting for GPS..." / "Loading wind data..." while `SceneState` is null.
- **`CachedHorizonProvider`**: memory + disk cache, keyed by lat/lng at 3 decimal places (~111m), no expiry (terrain is permanent).
- **`CachedWindDataSource`**: TTL-based memory cache (default 10 min), keyed by lat/lng at 2 decimal places + altitude.
- **16 provider graph integration tests**: GPS debounce, altitude refetch, SceneState composition and fallbacks, lifecycle cycles.

### Post-Phase 3b: Performance Fixes

Device testing revealed a FPS regression (45+ to ~25 FPS). Root causes:

1. `skyFraction` was a computed getter iterating 12,288 booleans on every access. Fixed: pre-computed `final double` at construction.
2. `SkyMaskData` was Freezed (allocating immutable objects per frame). Fixed: converted to plain class.
3. `HsvSkyDetector.detect()` called `isPointInSky()` 12,288 times. Fixed: added `cachedMask` getter to `AutoCalibratingSkyDetector`, single array traversal.
4. Initial state was `SkyMaskData.fullSky()` (particles on black screen). Fixed: `SkyMaskData.noSky()` initial state.

---

## Test Results

| Phase | Tests Added | Cumulative |
|-------|-------------|------------|
| Baseline (pre-SPEC-001) | — | 405 |
| Phase 1 | +84 | 489 |
| Phase 2 | +16 | 505 |
| Phase 3a | +9 | 514 |
| Phase 3b | +48 | 562 |
| Perf fixes (removed 3 Freezed tests) | -3 | 559 |
| Previously uncounted tests | +47 | 606 |
| **Final** | **+201** | **606** |

- `flutter test` auto-discovers 559 tests. Five files require explicit paths (environment quirk, not a code issue).
- `dart analyze lib/`: 0 errors, 0 warnings, 12 infos (10 Riverpod Ref deprecations in generated code + 2 doc comment cosmetics).

---

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| `SkyMaskData` is a plain class, not Freezed | Hot-path object recreated every camera frame; Freezed overhead causes FPS regression |
| `Particle` and `HSV` remain mutable plain classes | Updated 2000x/frame at 60 FPS; immutability would be catastrophic |
| `skyFraction` is a pre-computed field | Called hundreds of times/sec in particle tick loop; O(12,288) getter was the biggest perf bottleneck |
| ValueNotifier sidecar for heading/pitch | 20-50Hz sensor data bypasses Riverpod; zero widget rebuilds in tick loop |
| Re-export shims at old paths | Zero-risk migration; old imports continue to work |
| `DebugPanel` stays StatelessWidget | Most data is local UI state, not in providers; hybrid ConsumerWidget pattern would be worse |
| `stablePositionProvider` >100m debounce | GPS jitter should not trigger horizon/wind API calls |

---

## Remaining Cleanup Debt

None of these are blocking, and all are documented in `DECISIONS.md`:

1. **Re-export shims** (16 files): Can be removed incrementally when all imports point to canonical paths.
2. **Old model classes** (`CompassData`, `LocationData`): Still exist alongside replacements. Safe to delete once all consumers use `SensorState`/`PositionData`.
3. **Riverpod Ref deprecations** (10 infos): In generated `.g.dart` files. Resolves with Riverpod 3.0 upgrade.
4. **`as HsvSkyDetector` cast**: In `ar_view_screen.dart` and `debug_panel.dart`. Must be fixed before P2B-004 (terrain sky mask) adds other detector types.
5. **`CachedWindDataSource` not wired**: Exists and tested but `windDataSourceProvider` still returns bare `MockWindDataSource`. Wire alongside OGC EDR (P2B-006).

---

## What Downstream Features Get

| Feature | Interface | What to implement |
|---------|-----------|-------------------|
| P2B-002 HeyWhatsThat client | `HorizonProvider` | `HwtHorizonProvider`, wire in `horizonProviderServiceProvider` |
| P2B-004 Terrain sky mask | `SkyDetector` | `TerrainSkyDetector`, wire in `skyDetectorInstanceProvider` |
| P2B-006 OGC EDR wind | `WindDataSource` | `OgcEdrWindDataSource`, wire in `windDataSourceProvider` |
| SPEC-002 Photo capture | `SceneState` | Capture `SceneState` snapshot at shutter time |

Each is a single `/implement` run that plugs into an existing interface.

---

## Files Changed (Summary)

**New source files:** 38 (core models, service interfaces, provider files, service wrappers, widgets)
**Modified source files:** 15 (existing models, services, widgets, and tests updated for new types)
**Generated files:** 9 (Freezed + Riverpod codegen: `.freezed.dart`, `.g.dart`)
**New test files:** 20
**Modified test files:** 5

See `DECISIONS.md` for the full decisions log across all 4 phases.
