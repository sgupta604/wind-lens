# Summary: Dome Wind Direction Bug Fix

| Field | Value |
|-------|-------|
| Feature | dome-direction-bug |
| Finalized | 2026-03-04 |
| Branch | feature/on-device-fixes-march |
| Commit | (see git log) |

---

## What Was Fixed

The wind dome visualization displayed particle flow in the wrong north-south direction compared to the AR view. A user pointing at SW wind would see SW in the AR overlay but NW in the dome.

### Root Cause

`DomeParticle.tick()` applied the v-component (northward wind) to the z-axis with the wrong sign. The dome coordinate system defines +z = South, but the wind convention defines +v = Northward (toward -z in dome space). Adding instead of subtracting caused all north-south wind components to be inverted.

**Buggy code:**
```dart
z += wind.v * DomeConstants.velocityScale * dt;  // wrong: +v moves toward +z (South)
```

**Fixed code:**
```dart
// +u = eastward  -> +x = East  (same sign, no flip needed)
// +v = northward -> -z = North (opposite sign, negate v)
x += wind.u * DomeConstants.velocityScale * dt;
z -= wind.v * DomeConstants.velocityScale * dt;  // correct: +v moves toward -z (North)
```

---

## Files Changed

### Source Files

| File | Change |
|------|--------|
| `lib/features/wind_dome/models/dome_particle.dart` | Line 122: `z +=` -> `z -=`; coordinate mapping comments added |
| `lib/features/wind_dome/models/dome_constants.dart` | velocityScale doc comment extended with 20x speedup factor explanation |

### Test Files

| File | Change |
|------|--------|
| `test/features/wind_dome/models/dome_particle_test.dart` | 2 new directional unit tests added (v-component and u-component) |
| `test/features/wind_dome/widgets/dome_info_bar_test.dart` | Updated for 4 size presets (added 5km); new `tapping 5km` test |
| `test/features/wind_dome/widgets/dome_painter_test.dart` | New 5km render smoke test (domeR=90.0) |

---

## Test Results

| Suite | Tests | Passed | Failed |
|-------|-------|--------|--------|
| flutter test (auto-discovered) | 842 | 842 | 0 |
| flutter test (explicit paths) | 47 | 47 | 0 |
| **Total** | **889** | **889** | **0** |

Static analysis: 0 errors, 0 warnings, 13 pre-existing info items (Riverpod Ref deprecations + doc comment HTML warnings).

---

## On-Device Verification Recommended

The automated tests verify the sign fix is mathematically correct. Manual on-device verification is recommended:

- Open AR view and dome view with real wind data
- Confirm wind direction matches between AR particles and dome particles at surface, mid-level, and jet stream altitudes
- Example: SW wind should flow toward NE in both views

---

## Metrics

- Lines added: ~90 (doc comments + tests)
- Lines deleted: 1 (sign change is a single character)
- New tests: 4 (2 directional unit tests, 1 preset test, 1 smoke test)
- Files changed: 5 (2 source, 3 test)
