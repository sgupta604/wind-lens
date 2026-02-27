# Tasks: gimbal-lock (v2 -- Hysteresis)

## Metadata
- **Feature:** gimbal-lock
- **Created:** 2026-02-25T22:30
- **Reworked:** 2026-02-25 (v2 hysteresis replaces v1 soft blend)
- **Status:** implement-complete
- **Based On:** `2026-02-25T22:30_plan.md` + user v2 specification

## Execution Rules

- **TDD Order:** Tests in Phase 2 are written FIRST and expected to FAIL. Implementation in Phase 3 makes them pass.
- **Single file:** All changes are in `compass_service.dart` and `compass_service_test.dart` under `wind_lens/`.

---

## Phase 1: v2 Tests (TDD -- write tests first, they should FAIL)

### Task 1.1: Replace v1 "Gimbal Lock Mitigation" test group with v2 hysteresis tests

- [x] Remove entire v1 "Gimbal Lock Mitigation" group (headingAlpha unit tests + soft blend integration tests)
- [x] Create new group `'Gimbal Lock Mitigation v2 (Hysteresis)'`
- [x] Add hysteresis lock/unlock threshold tests:
  - [x] `heading locks when raw pitch >= 65 degrees`
  - [x] `heading stays locked when raw pitch drops to 60 (between thresholds)`
  - [x] `heading unlocks when raw pitch drops below 55 degrees`
  - [x] `heading locks for negative pitch (phone tilted backward)`
- [x] Add stable heading preservation tests:
  - [x] `saves heading from before the lock frame, not the current frame`
  - [x] `heading remains frozen while locked even with varying raw heading`
- [x] Add unlock and resume test:
  - [x] `heading converges to new target after unlocking`
- [x] Add rapid tilt scenario test:
  - [x] `simultaneous pitch+heading flip preserves pre-flip heading`
- [x] Add integration tests:
  - [x] `heading unchanged after tick when pitch above lock threshold`
  - [x] `heading resumes tracking when pitch drops below unlock threshold`
- [x] Verify tests FAIL with v1 code (isHeadingLocked getter does not exist)

**Files:** `test/services/compass_service_test.dart`

**Acceptance Criteria:**
- [x] 11 tests exist in the v2 group (replaces 7 v1 tests)
- [x] Tests use `isHeadingLocked` getter for state assertions
- [x] Tests FAIL before v2 implementation

---

## Phase 2: v2 Implementation

### Task 2.1: Replace v1 constants with v2 hysteresis constants

- [x] Remove `headingLockStartPitch = 65.0` and `headingLockEndPitch = 80.0`
- [x] Add `headingLockPitch = 65.0` (raw pitch threshold to LOCK heading)
- [x] Add `headingUnlockPitch = 55.0` (raw pitch threshold to UNLOCK heading)
- [x] Add doc comments explaining hysteresis behavior

**Files:** `lib/services/compass_service.dart`

### Task 2.2: Add v2 state variables

- [x] Add `bool _isHeadingLocked = false` (whether heading is currently locked)
- [x] Add `double _lastStableHeading = 0` (heading saved when pitch was below threshold)
- [x] Add doc comments explaining purpose of each variable

**Files:** `lib/services/compass_service.dart`

### Task 2.3: Add isHeadingLocked public getter

- [x] Add `bool get isHeadingLocked => _isHeadingLocked` getter
- [x] Mark as `@visibleForTesting`
- [x] Add doc comment explaining test observability purpose

**Files:** `lib/services/compass_service.dart`

### Task 2.4: Remove headingAlpha() static method

- [x] Remove the entire `headingAlpha()` method (no longer needed -- binary lock, not soft blend)
- [x] Verify no references to headingAlpha remain in lib/

**Files:** `lib/services/compass_service.dart`

### Task 2.5: Replace timer callback with v2 hysteresis logic

- [x] Smooth pitch first (unchanged)
- [x] Use RAW pitch (not smoothed) for lock decision via `_rawPitch.abs()`
- [x] Lock: when `!_isHeadingLocked && rawPitchAbs >= headingLockPitch`, set `_isHeadingLocked = true` and restore `_smoothedHeading = _lastStableHeading`
- [x] Unlock: when `_isHeadingLocked && rawPitchAbs < headingUnlockPitch`, set `_isHeadingLocked = false`
- [x] When locked: do NOT update `_smoothedHeading`
- [x] When unlocked: normal heading tracking + save `_lastStableHeading = _smoothedHeading`
- [x] Always emit CompassData (BUG-009 rule preserved)

**Files:** `lib/services/compass_service.dart`

### Task 2.6: Update tick() test helper to match timer callback

- [x] Copy identical logic from timer callback into `tick()`
- [x] Verify `tick()` body matches timer callback body exactly

**Files:** `lib/services/compass_service.dart`

---

## Phase 3: Verification

### Task 3.1: Run all tests and static analysis

- [x] Run `flutter test` in `wind_lens/` -- all tests must pass
- [x] Run `dart analyze lib/` -- zero errors, zero warnings
- [x] Verify compass_service_test.dart: 47 tests passing
- [x] Verify full suite: 569 tests passing, exit code 0
- [x] Spot-check: existing BUG-009 regression tests still pass
- [x] Spot-check: existing pitch convergence tests still pass

**Acceptance Criteria:**
- [x] All tests pass (569 total including 11 new v2 gimbal lock tests)
- [x] Zero analyzer issues in compass_service.dart (12 pre-existing info-level issues in other files)
- [x] No regressions in existing compass tests

---

## Phase 4: Ready for Test Agent

### Handoff Checklist

- [x] All 11 new v2 gimbal lock tests pass
- [x] All existing tests still pass (569 total)
- [x] `dart analyze lib/services/compass_service.dart` -- zero issues
- [x] Only `compass_service.dart` modified (no downstream changes)
- [x] Only `compass_service_test.dart` test file modified
- [x] No new packages added
- [x] No API changes (CompassData unchanged, stream behavior unchanged for pitch < 55)
- [x] v2 constants documented with doc comments
- [x] `isHeadingLocked` getter marked `@visibleForTesting` for test observability
- [x] `headingAlpha()` removed (replaced by binary lock)
- [x] Timer callback and tick() have identical logic

### What to Test on Device

- Tilt phone from horizontal (pitch=0) to straight up (pitch=90) -- heading should NOT flip
- Hold phone between 55-65 degrees (hysteresis zone) -- heading should stay locked if it was locked
- Tilt back down below 55 degrees -- heading should resume tracking
- Normal operation (pitch < 55) -- heading should be completely unaffected
- Compass widget should freeze (not spin) when pointing straight up
- Particles should maintain consistent direction when tilting past 65 degrees
- Rapid tilt: quickly point phone straight up and verify no heading jump
