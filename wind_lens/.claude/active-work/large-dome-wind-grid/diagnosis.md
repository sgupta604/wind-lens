# Diagnosis: Large Dome Wind Grid -- Three On-Device Bugs

## Overview

Three bugs were reported from on-device testing of the `large-dome-wind-grid` feature. All three share a common underlying root cause: **the dome screen and the dome wind field disagree about what one render unit represents at non-default dome sizes.** This inconsistency cascades into zoom mismatch (BUG 1), wrong spatial wind lookup (BUG 2), and frozen-looking particles (BUG 3).

---

## The Core Mismatch

Two different parts of the codebase compute dome geometry from `domeSizeMeters`, but they use different formulas:

**Screen (`wind_dome_screen.dart` line 172):**
```dart
final computedDomeR = domeSizeMeters / DomeConstants.metersPerRenderUnit;
// For 50km: computedDomeR = 50000 / 55.56 = 900 render units
```

**Fetcher (`dome_wind_fetcher.dart` line 191):**
```dart
final metersPerRenderUnit = radiusMeters / DomeConstants.domeR;
// For 50km: metersPerRenderUnit = 50000 / 18 = 2777.78
```

The screen SCALES UP the dome radius (keeping metersPerRenderUnit at the base rate of 55.56). The fetcher scales UP metersPerRenderUnit (keeping domeR at the base 18). These two approaches are contradictory. At the default 1km size they agree (1000/55.56 = 18, 1000/18 = 55.56), but at any other size they diverge.

| Dome Size | Screen domeR (RU) | Field metersPerRU | Screen's actual m/RU |
|-----------|-------------------|-------------------|----------------------|
| 1 km      | 18                | 55.56             | 55.56 (match)        |
| 5 km      | 90                | 277.78            | 55.56 (5x off)       |
| 15 km     | 270               | 833.33            | 55.56 (15x off)      |
| 50 km     | 900               | 2777.78           | 55.56 (50x off)      |

---

## BUG 1: Zoom Doesn't Reset on Preset Change

### Issue Summary
- **Problem:** When switching to 15km or 50km preset, the dome doesn't fit on screen.
- **Impact:** Dome is unusable at large sizes until user manually pinch-zooms.
- **Severity:** high

### Root Cause
- **Primary Cause:** `_camR` (camera orbit radius) is never reset when the dome size changes. It is initialized once to `DomeConstants.camR = 50.4` (calibrated for an 18-RU dome) and only changed by pinch gestures.
- **File:** `/workspace/wind_lens/lib/features/wind_dome/wind_dome_screen.dart` line 58 (initialization), lines 181-187 (dome size change listener -- missing zoom reset)
- **Problem Code:**
```dart
// Line 58: initialized once
double _camR = DomeConstants.camR;  // 18 * 2.8 = 50.4

// Lines 181-187: dome size change handler -- no _camR update!
ref.listen(domeSizeProvider, (prev, next) {
  if (prev == next) return;
  final newDomeR = next / DomeConstants.metersPerRenderUnit;
  final newDomeH = newDomeR * (DomeConstants.domeH / DomeConstants.domeR);
  _reinitializeParticles(newDomeR, newDomeH);
  // BUG: _camR is not updated here!
});
```
- **Why It Fails:** For a 50km dome (900 RU), the camera at distance 50.4 is inside the dome looking outward. The dome wireframe and particles fill the entire screen and extend far beyond. The camera needs to be proportionally farther away: `900 * 2.8 = 2520`.

### Evidence
- `DomeConstants.camR = domeR * 2.8 = 50.4` (line 77 of `dome_constants.dart`)
- `_reinitializeParticles` only respawns particles; does not touch `_camR`, `_theta`, or `_phi` (lines 155-161 of `wind_dome_screen.dart`)
- Pinch zoom clamp scales correctly (`DomeConstants.camRMin * scale`), but this only applies during active pinch gestures, not on preset change

### Fix Plan

**File:** `/workspace/wind_lens/lib/features/wind_dome/wind_dome_screen.dart`

**Change:** Add camera orbit radius reset in the `ref.listen(domeSizeProvider, ...)` callback.

Before (lines 181-187):
```dart
ref.listen(domeSizeProvider, (prev, next) {
  if (prev == next) return;
  final newDomeR = next / DomeConstants.metersPerRenderUnit;
  final newDomeH =
      newDomeR * (DomeConstants.domeH / DomeConstants.domeR);
  _reinitializeParticles(newDomeR, newDomeH);
});
```

After:
```dart
ref.listen(domeSizeProvider, (prev, next) {
  if (prev == next) return;
  final newDomeR = next / DomeConstants.metersPerRenderUnit;
  final newDomeH =
      newDomeR * (DomeConstants.domeH / DomeConstants.domeR);
  _reinitializeParticles(newDomeR, newDomeH);
  // Reset camera orbit to fit new dome size
  setState(() {
    _camR = newDomeR * 2.8;  // Same ratio as DomeConstants.camR / domeR
    // Optionally reset orbit angles to defaults:
    // _theta = DomeConstants.defaultTheta;
    // _phi = DomeConstants.defaultPhi;
  });
});
```

**Testing:** Tap 15km/50km preset buttons -- dome should auto-fit on screen at each size. Tap back to 1km -- should zoom back in.

---

## BUG 2: Wind Directions Wrong at Altitude (Grid Path)

### Issue Summary
- **Problem:** Surface wind shows NE on the external info bar but dome particles go SW. Higher altitude shows SW but dome shows NW.
- **Impact:** Dome displays incorrect wind patterns at >= 15km, defeating the purpose of spatial wind grid.
- **Severity:** critical

### Root Cause
- **Primary Cause:** `DomeWindField.metersPerRenderUnit` is set by the fetcher to `radiusMeters / 18`, but the screen creates a dome with radius `radiusMeters / 55.56` render units. When `_sampleLayer()` converts render-space coordinates to geographic coordinates, it uses the wrong metersPerRenderUnit, causing the geographic lookup to be wildly off-center.
- **Files:**
  - `/workspace/wind_lens/lib/services/wind/dome_wind_fetcher.dart` line 191 (sets wrong metersPerRenderUnit)
  - `/workspace/wind_lens/lib/features/wind_dome/models/dome_wind_field.dart` lines 143-151 (`_sampleLayer` uses wrong scale)
  - `/workspace/wind_lens/lib/features/wind_dome/wind_dome_screen.dart` line 172 (uses different scale)
- **Problem Code:**

In `dome_wind_fetcher.dart` (line 191):
```dart
final metersPerRenderUnit = radiusMeters / DomeConstants.domeR;
// For 50km: 50000 / 18 = 2777.78 m/RU
```

In `wind_dome_screen.dart` (line 172):
```dart
final computedDomeR = domeSizeMeters / DomeConstants.metersPerRenderUnit;
// For 50km: 50000 / 55.56 = 900 RU dome
// Actual m/RU in screen = 50000 / 900 = 55.56 (the base rate!)
```

- **Why It Fails:** A particle at x=200 render units in the screen's 900-RU dome is 200 * 55.56 = 11,111 meters east of center. But `_sampleLayer` computes `offsetLng = 200 * 2777.78 / (111320 * cosLat) = 6.25 degrees`, which is 555,556 meters -- 50x too far east! The grid lookup lands far outside the actual grid extent, gets clamped to the grid edge, and returns wind from the wrong location. At the grid edge, wind patterns can be completely different from the center, explaining the direction mismatch.

### Evidence (Mathematical Proof)

For a 50km dome with a particle at x=200, z=-100 (roughly 22% of dome radius):

**What the screen thinks:**
- Real position: 200 * 55.56 = 11,112m east, 100 * 55.56 = 5,556m north of center
- Geographic offset: ~0.125 deg lng, ~0.05 deg lat

**What `_sampleLayer` computes:**
- Geographic offset: 200 * 2777.78 / (111320 * 0.8) = 6.24 deg lng!
- This is ~555 km east of center -- completely outside the 50km dome

The grid clamps this to its edge, returning wind from the grid boundary. Different edges have different wind directions, producing seemingly random directions that mismatch the center wind shown on the info bar.

### Fix Plan

**File:** `/workspace/wind_lens/lib/services/wind/dome_wind_fetcher.dart`

**Change:** Use `DomeConstants.metersPerRenderUnit` (the base rate that the screen uses) instead of computing a dome-size-specific rate.

Before (line 191):
```dart
final metersPerRenderUnit = radiusMeters / DomeConstants.domeR;
```

After:
```dart
// Use the base metersPerRenderUnit that matches the screen's geometry.
// The screen scales dome radius (computedDomeR = size / baseRate), keeping
// the base rate constant. The field must use the same rate.
final metersPerRenderUnit = DomeConstants.metersPerRenderUnit;
```

Also update the DomeWindField construction (line 261):
```dart
// Already correct -- passes metersPerRenderUnit through:
metersPerRenderUnit: metersPerRenderUnit,
```

**Testing:**
1. Set dome to 15km or 50km.
2. Observe particle directions match the wind direction shown in the AR view info bar.
3. Existing unit tests in `dome_wind_field_test.dart` should still pass (they use `DomeConstants.metersPerRenderUnit` directly).

---

## BUG 3: 50km Particles Barely Move

### Issue Summary
- **Problem:** At 50km radius, particles appear almost stationary.
- **Impact:** Dome is visually dead/broken at large sizes.
- **Severity:** high

### Root Cause
- **Primary Cause:** `DomeConstants.velocityScale` (0.72 render-units/s per m/s) was calibrated for an 18-RU dome. The screen scales the dome to 900 RU at 50km, but velocityScale remains constant. Particle displacement per frame is the same absolute number of render units regardless of dome size, but the dome is 50x wider, so movement appears 50x slower.
- **File:** `/workspace/wind_lens/lib/features/wind_dome/models/dome_particle.dart` lines 122-123
- **Problem Code:**
```dart
// These produce the same displacement regardless of dome size:
x += wind.u * DomeConstants.velocityScale * dt;  // e.g., 10 * 0.72 * 0.0167 = 0.12 RU
z -= wind.v * DomeConstants.velocityScale * dt;   // Same
```
- **Why It Fails:**

| Dome Size | Dome Radius (RU) | Displacement per frame (RU) | Frames to cross dome | Time to cross |
|-----------|------------------|-----------------------------|---------------------|---------------|
| 1 km      | 18               | 0.12                        | 300                 | 5 sec         |
| 5 km      | 90               | 0.12                        | 1500                | 25 sec        |
| 15 km     | 270              | 0.12                        | 4500                | 75 sec        |
| 50 km     | 900              | 0.12                        | 15000               | 250 sec       |

At 50km, a 10 m/s wind takes over 4 minutes for a particle to cross the dome. This appears stationary.

### Evidence
- `DomeConstants.velocityScale = 0.72` (line 41 of `dome_constants.dart`)
- The comment on velocityScale (lines 38-41) explicitly states: "This ratio is constant across all dome sizes because tick() operates in render-units and the dome scales linearly (bigger dome = larger domeR = same RU velocity but more RU to cross)." This was written assuming domeR stays at 18, which is wrong -- the screen scales domeR.
- `tick()` does not receive or use the current dome radius for velocity scaling (lines 110-138 of `dome_particle.dart`)

### Fix Plan

**File:** `/workspace/wind_lens/lib/features/wind_dome/models/dome_particle.dart`

**Change:** Scale velocity by the ratio of current dome radius to base dome radius.

Before (lines 120-123):
```dart
// Apply wind velocity (render-units/second via velocityScale)
// +u = eastward  -> +x = East  (same sign, no flip needed)
// +v = northward -> -z = North (opposite sign, negate v)
x += wind.u * DomeConstants.velocityScale * dt;
z -= wind.v * DomeConstants.velocityScale * dt;
```

After:
```dart
// Apply wind velocity (render-units/second via velocityScale)
// Scale by dome size: larger domes need proportionally larger displacement
// to maintain the same visual crossing speed.
// +u = eastward  -> +x = East  (same sign, no flip needed)
// +v = northward -> -z = North (opposite sign, negate v)
final renderScale = domeR / DomeConstants.domeR;
x += wind.u * DomeConstants.velocityScale * renderScale * dt;
z -= wind.v * DomeConstants.velocityScale * renderScale * dt;
```

Also scale the updraft (lines 126-128):
```dart
// Gentle updraft: increases with altitude (prototype line 249)
// Scale by renderScale to match horizontal velocity scaling.
y += (DomeConstants.updraftBase +
        (y / domeH) * DomeConstants.updraftGradient) *
    renderScale * dt;
```

**Testing:**
1. At 50km, particles should visibly move at approximately the same visual speed as at 1km.
2. Existing unit tests with `domeR = DomeConstants.domeR` (18) will have `renderScale = 1.0` and produce identical results.
3. New test: verify velocity at 50km dome is 50x the velocity at 1km in absolute render units.

---

## Alternative Fix Strategy: Keep Dome at 18 RU

Instead of fixing each bug independently, there is a cleaner alternative: **change the screen to keep the dome at 18 RU for all sizes, and let only `metersPerRenderUnit` change.**

This would fix ALL THREE bugs at once:

**File:** `/workspace/wind_lens/lib/features/wind_dome/wind_dome_screen.dart`

**Change (line 172):**
```dart
// BEFORE: scales dome radius, keeps base metersPerRenderUnit
final computedDomeR = domeSizeMeters / DomeConstants.metersPerRenderUnit;

// AFTER: keeps dome at base radius, scales metersPerRenderUnit
final computedDomeR = DomeConstants.domeR;  // always 18
```

This approach:
- BUG 1: Dome always 18 RU, camera distance always correct. No zoom reset needed.
- BUG 2: metersPerRenderUnit from fetcher matches screen geometry. Spatial lookup correct.
- BUG 3: velocityScale calibrated for 18 RU dome. Particles move at correct visual speed.

**HOWEVER**, this approach means the dome wireframe, particle positions, and all rendering are identical at every size -- only the wind data changes. There would be no visual difference in dome geometry between 1km and 50km (just different wind patterns). This may or may not be acceptable depending on UX goals.

**Recommended approach:** Fix BUG 1 independently (zoom reset is needed regardless), but fix BUGs 2 and 3 by changing the fetcher to use the base metersPerRenderUnit. This keeps the screen's variable-size dome (which affects wireframe spacing and visual scale), while ensuring the wind field coordinates match the screen's geometry.

---

## Severity Assessment

| Bug | Severity | Priority | Rationale |
|-----|----------|----------|-----------|
| BUG 1: Zoom reset | High | Immediate | Dome is unusable at large sizes without manual workaround |
| BUG 2: Wrong direction | Critical | Immediate | Displays objectively incorrect wind data, defeats feature purpose |
| BUG 3: Particles frozen | High | Immediate | Feature appears broken at large sizes |

All three bugs make the large-dome feature unusable. They should be fixed together since BUGs 2 and 3 share the same root cause (metersPerRenderUnit mismatch).

---

## Recommended Workflow

1. **`/plan large-dome-wind-grid`** -- Plan the fix incorporating all three bug fixes
2. **`/implement large-dome-wind-grid`** -- Apply the fixes:
   - `wind_dome_screen.dart`: Add `_camR` reset in dome size listener
   - `dome_wind_fetcher.dart`: Use `DomeConstants.metersPerRenderUnit` instead of `radiusMeters / domeR`
   - `dome_particle.dart`: Scale velocity by `domeR / DomeConstants.domeR`
3. **`/test large-dome-wind-grid`** -- Run full test suite + new tests for velocity scaling and zoom reset
4. **On-device verification** -- Verify all three fixes on real device
