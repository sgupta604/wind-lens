# Tasks: compass-native

## Metadata
- **Feature:** compass-native
- **Created:** 2026-02-13T12:30
- **Status:** implement-complete
- **Based on:** 2026-02-13T12:30_plan.md

## Execution Rules

- Tasks are executed in order (1.1 -> 2.1 -> 3.1 -> 4.1)
- [P] marks tasks that can run in parallel with other [P] tasks in the same phase
- TDD: Phase 2 writes tests BEFORE Phase 3 implements the code
- Mark each checkbox when complete

---

## Phase 1: Setup

### Task 1.1: Add flutter_compass dependency
- [x] Add `flutter_compass: ^0.8.1` to `pubspec.yaml` dependencies (after sensors_plus line)
- [x] Run `flutter pub get` in `/workspace/wind_lens/`
- [x] Verify no dependency conflicts

**Files:** `wind_lens/pubspec.yaml`

**Acceptance Criteria:**
- [x] `flutter pub get` completes without errors
- [x] `flutter_compass` appears in `pubspec.lock`

---

## Phase 2: Tests (TDD)

### Task 2.1: Add null-heading tests
- [x] Add test group `'Null heading handling (compass-native)'` to `compass_service_test.dart`
- [x] Test: heading retains previous value when `_rawHeading` is not updated (simulates null from flutter_compass)
- [x] Test: heading holds steady through multiple ticks without `_rawHeading` change
- [x] Run existing 390 tests to confirm no regressions

**Files:** `wind_lens/test/services/compass_service_test.dart`

**Acceptance Criteria:**
- [x] New tests pass (they test existing behavior via test helpers, so they pass before implementation too)
- [x] All 390 existing tests still pass
- [x] Total test count: 392+

---

## Phase 3: Core Implementation

### Task 3.1: Replace magnetometer heading with flutter_compass in CompassService
- [x] Add import: `import 'package:flutter_compass/flutter_compass.dart';`
- [x] Replace field: `StreamSubscription<MagnetometerEvent>? _magnetometerSub` with `StreamSubscription<CompassEvent>? _compassSub`
- [x] Replace magnetometer subscription in `start()` with `FlutterCompass.events?.listen(...)` with null-heading guard
- [x] Update `dispose()`: replace `_magnetometerSub?.cancel()` with `_compassSub?.cancel()`
- [x] Update class-level doc comment to mention flutter_compass
- [x] Keep all other code unchanged (accelerometer, timer, _lerpAngle, test helpers, public API)
- [x] Run `flutter analyze lib/` -- no issues
- [x] Run all tests -- all pass

**Files:** `wind_lens/lib/services/compass_service.dart`

**Acceptance Criteria:**
- [x] `flutter analyze lib/` reports no issues
- [x] All 392+ tests pass (390 existing + 2 new)
- [x] `start()` uses `FlutterCompass.events` instead of `magnetometerEventStream()`
- [x] Null heading from flutter_compass is handled (retains previous `_rawHeading`)
- [x] Public API is identical (stream, heading, pitch, start, dispose)
- [x] Test helpers are identical (setRawHeading, setRawPitch, tick, simulateMagnetometerEvent, simulateAccelerometerEvent)

---

## Phase 4: Verification

### Task 4.1: Full test suite and static analysis
- [x] Run `flutter test` in `/workspace/wind_lens/` -- all tests pass
- [x] Run `flutter analyze lib/` -- no issues
- [x] Verify `pubspec.yaml` has flutter_compass dependency
- [x] Verify compass_service.dart uses FlutterCompass.events in start()
- [x] Verify compass_service.dart still uses accelerometerEventStream for pitch
- [x] Verify no other files were modified (compass_widget, ar_view_screen, wind_state, etc.)

**Files:** All files in scope

**Acceptance Criteria:**
- [x] All tests pass (392+)
- [x] Static analysis clean
- [x] Only 3 files modified: pubspec.yaml, compass_service.dart, compass_service_test.dart
- [x] Public API unchanged

---

## Handoff Checklist (for Test Agent)

- [x] `flutter pub get` succeeds
- [x] `flutter analyze lib/` -- no issues
- [x] `flutter test` -- all tests pass (392+)
- [x] Only 3 files modified (pubspec.yaml, compass_service.dart, compass_service_test.dart)
- [x] CompassService public API is unchanged (stream, heading, pitch, start, dispose)
- [x] CompassService test helpers are unchanged (setRawHeading, setRawPitch, tick, simulateMagnetometerEvent, simulateAccelerometerEvent)
- [x] No changes to compass_widget.dart, ar_view_screen.dart, wind_state.dart, or any model files
- [x] New null-heading tests exist and pass
- [x] flutter_compass is imported and used in start() method
- [x] sensors_plus is still imported and used for accelerometer (pitch)
