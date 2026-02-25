# Tasks: Compass Service Architectural Rewrite (BUG-009 v2)

## Metadata
- **Feature:** compass-freeze (BUG-009 v2)
- **Created:** 2026-02-06
- **Status:** implement-complete
- **Based on:** `2026-02-06_plan_v2.md`
- **Previous (failed):** v1 plan + implementation (dead zone reorder -- did not fix device freeze)

## Execution Rules
- Tasks are sequential unless marked [P]
- TDD: write/update tests first (Phase 2), then implement (Phase 3)
- Mark each checkbox when complete
- Run `flutter test` after each phase to verify

---

## Phase 1: Setup (Discard broken working tree changes)

### Task 1.1: Restore committed compass_service.dart
- [x] Run `git checkout HEAD -- wind_lens/lib/services/compass_service.dart` to restore the committed v1 version
- [x] Verify `flutter test` passes with restored file (27 compass tests)
- [x] Verify `flutter analyze lib/` has no issues (compass_service.dart specifically)

**Files:** `wind_lens/lib/services/compass_service.dart`

**Acceptance Criteria:**
- [x] Working tree matches committed version (203 lines)
- [x] All 27 compass service tests pass
- [x] No analyzer warnings on compass_service.dart

---

## Phase 2: Tests (TDD -- write tests first, some will fail until implementation)

### Task 2.1: Remove dead zone constant tests
- [x] Remove the test `'should have heading dead zone of 1.0 degrees'` (references `CompassService.headingDeadZone`)
- [x] Remove the test `'should have pitch dead zone of 2.0 degrees'` (references `CompassService.pitchDeadZone`)
- [x] Update the test `'should have smoothing factor of 0.1'` to expect `0.15` and reference `CompassService.smoothingFactor`

**Files:** `wind_lens/test/services/compass_service_test.dart`

**Acceptance Criteria:**
- [x] Dead zone constant tests removed (2 tests)
- [x] Smoothing factor test updated to expect 0.15

### Task 2.2: Add new architecture tests
- [x] Test: `emitInterval` constant equals `Duration(milliseconds: 50)`
- [x] Test: `_lerpAngle` wraparound clockwise (350 -> 10 should interpolate through 360/0)
- [x] Test: `_lerpAngle` wraparound counterclockwise (10 -> 350 should interpolate through 360/0)
- [x] Test: `_lerpAngle` normal case (45 -> 90 interpolates linearly)
- [x] Test: `tick()` emits one CompassData event to the stream
- [x] Test: `setRawHeading` + multiple `tick()` calls produce continuous stream events (no freeze)

**Files:** `wind_lens/test/services/compass_service_test.dart`

**Acceptance Criteria:**
- [x] 6+ new tests added (actually 10 new tests)
- [x] Tests compile and pass after Task 3.1

### Task 2.3: Update existing regression tests for new architecture
- [x] Review all 7 BUG-009 regression tests -- backward-compatible via `simulateMagnetometerEvent`/`simulateAccelerometerEvent`
- [x] Update convergence tolerance values for smoothingFactor 0.15
- [x] Add test: continuous stream emission during stationary hold (set heading, tick 100 times, verify 100 stream events received)
- [x] Add test: continuous stream emission during slow rotation (set heading incrementally, tick each time, verify all ticks emitted)

**Files:** `wind_lens/test/services/compass_service_test.dart`

**Acceptance Criteria:**
- [x] All regression tests updated for new architecture
- [x] 2 new stream-emission-count tests added
- [x] All tests pass after Task 3.1

---

## Phase 3: Core Implementation

### Task 3.1: Rewrite compass_service.dart with timer-based architecture
- [x] Replace entire file contents with the timer-based decoupled architecture
- [x] Include all imports: `dart:async`, `dart:math`, `package:flutter/foundation.dart`, `package:sensors_plus/sensors_plus.dart`, `../models/compass_data.dart`
- [x] Define constants: `smoothingFactor = 0.15`, `emitInterval = Duration(milliseconds: 50)`
- [x] Remove constants: `headingDeadZone`, `pitchDeadZone`
- [x] Internal state: `_rawHeading`, `_rawPitch`, `_smoothedHeading`, `_smoothedPitch`
- [x] Subscriptions: `_magnetometerSub`, `_accelerometerSub`, `_emitTimer`
- [x] `start()`: sensor callbacks only store raw values, `Timer.periodic` at `emitInterval` does smoothing + emission
- [x] `_lerpAngle()`: circular interpolation with `(to - from + 540) % 360 - 180` formula
- [x] `dispose()`: cancel timer, cancel subscriptions, close controller
- [x] `@visibleForTesting` helpers: `setRawHeading()`, `setRawPitch()`, `tick()`, `simulateMagnetometerEvent()`, `simulateAccelerometerEvent()`
- [x] Verify public API is identical: `stream`, `heading`, `pitch`, `start()`, `dispose()`
- [x] Run `flutter analyze lib/services/compass_service.dart` -- no issues

**Files:** `wind_lens/lib/services/compass_service.dart`

**Acceptance Criteria:**
- [x] File compiles with zero analyzer warnings
- [x] Public API unchanged (stream, heading, pitch, start, dispose)
- [x] No dead zone constants or dead zone logic anywhere
- [x] Timer-based emission at 20 Hz
- [x] Circular angle interpolation via `_lerpAngle`
- [x] All `@visibleForTesting` helpers present

---

## Phase 4: Verification

### Task 4.1: Run full test suite
- [x] Run `flutter test` on compass service tests -- all 35 pass
- [x] Run full non-widget test suite -- all 264 pass (256 previous + 8 net new)
- [x] Run `flutter analyze lib/services/compass_service.dart` -- no issues
- [x] Verify no regressions in any non-compass tests (229 other tests all pass)

**Acceptance Criteria:**
- [x] All 35 compass service tests pass
- [x] All 264 total non-widget tests pass
- [x] No analyzer warnings or errors on compass_service.dart
- [x] No regressions in existing non-compass tests
- [x] All new architecture tests pass
- [x] All BUG-009 regression tests pass

---

## Handoff Checklist (for Test Agent)

- [x] All unit tests pass (`flutter test test/services/compass_service_test.dart`)
- [x] Static analysis clean (`dart analyze lib/services/compass_service.dart`)
- [x] No new dependencies added
- [x] Public API of CompassService unchanged
- [x] Timer-based architecture eliminates dead zone convergence trap
- [x] Backward-compatible test helpers preserved
- [x] New tests specifically verify continuous stream emission (no freeze)
- [ ] Build succeeds (`flutter build ios --no-codesign` or `flutter build apk`) -- requires device SDK
- [ ] Manual device test: compass tracks continuously during slow rotation (no freeze after 1 second)
