# gimbal-lock: Gimbal Lock Heading Freeze Mitigation (v2)

**Status:** FINALIZED (2026-02-25)
**Branch:** `feature/terrain-sky-detection`
**Approach:** Hysteresis-based heading lock (replaces v1 soft blend)

## Problem

When the phone is tilted nearly straight up (pitch ~90 degrees, pointing at zenith),
compass heading becomes mathematically unreliable due to gimbal lock. The two horizontal
axes of the device collapse into one degree of freedom, causing the OS compass to output
erratic or flipped headings. This reversed wind particle direction when the phone was
pointed nearly straight up.

## Solution (v2 - Hysteresis Lock)

Lock heading entirely when raw pitch exceeds 65 degrees; unlock only when raw pitch drops
below 55 degrees. The 10-degree hysteresis band prevents oscillation at the boundary from
sensor noise. The heading saved on lock is the value from the PREVIOUS tick (before any
gimbal-lock contamination), not the potentially-flipped current frame.

Uses raw pitch (not smoothed) so the lock engages instantly, before the smoothed value
has time to chase any flipped heading readings.

### Why v2 over v1 (soft blend)

The v1 approach gradually reduced the smoothing alpha to zero between 65 and 80 degrees.
This allowed the smoothed heading to drift even within the blend zone if the lock region
was occupied for several seconds (alpha > 0 means the heading still moves toward whatever
erratic raw value the compass reports). The hysteresis lock is binary and unconditional:
once locked, the heading does not move at all.

## Implementation

### Files Modified

**`/workspace/wind_lens/lib/services/compass_service.dart`** (194 -> 270 lines)
- Removed v1 constants `headingLockStartPitch` and `headingLockEndPitch`
- Added two constants: `headingLockPitch = 65.0` and `headingUnlockPitch = 55.0`
- Added two fields: `_isHeadingLocked` (bool) and `_lastStableHeading` (double)
- Added `isHeadingLocked` getter annotated with `@visibleForTesting` for test observability
- Modified timer callback and `tick()` helper: update lock state from raw pitch, then
  either freeze heading (locked) or track raw heading and save stable value (unlocked)
- Both the live timer callback and `tick()` contain identical logic (as required)

**`/workspace/wind_lens/test/services/compass_service_test.dart`** (790 -> 940+ lines)
- Replaced v1 `Gimbal Lock Mitigation` group (7 tests) with v2 group (11 tests)
- Tests cover:
  - Lock threshold: heading locks when |rawPitch| >= 65
  - Hysteresis band: heading stays locked when pitch is between 55 and 65
  - Unlock threshold: heading unlocks when |rawPitch| < 55
  - Negative pitch: lock applies symmetrically (phone tilted backward)
  - Stable heading preservation: saved value is from the pre-lock tick
  - Freeze during lock: heading unchanged even with varying raw compass
  - Unlock and resume: heading converges to new target after unlocking
  - Rapid tilt scenario: simultaneous pitch+heading flip preserves pre-flip heading
  - Integration tests: behavior with existing timer architecture

## Test Results

- 47/47 compass service tests passing (36 pre-existing + 11 new v2 tests)
- All pre-existing BUG-009 regression tests still pass (no regressions)
- dart analyze clean on compass_service.dart (no errors/warnings)

## Design Decisions

- **Binary lock, not blend:** v2 is all-or-nothing. Once the raw pitch crosses 65, the
  heading is completely frozen. No partial drift in the transition zone.
- **Raw pitch for lock decision:** Smoothed pitch lags by several ticks; by the time
  the smoothed value crosses 65 the heading may have already chased a flipped value.
  Raw pitch reacts instantly.
- **Hysteresis band (65/55):** Prevents oscillation at the boundary. A 10-degree gap
  means brief pitch jitter around the threshold does not repeatedly lock/unlock.
- **Save heading before lock frame:** On the tick that transitions to locked, the code
  restores `_lastStableHeading` (saved from all previous unlocked ticks) rather than
  using `_smoothedHeading` from the current frame, which may already be contaminated
  by a flipped compass reading that triggered the threshold crossing.
- **Symmetric lock for negative pitch:** `rawPitchAbs` handles phones tilted backward;
  gimbal lock occurs in both directions at zenith.
