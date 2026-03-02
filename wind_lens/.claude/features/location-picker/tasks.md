# Tasks: location-picker (Bug Fixes + UX Enhancement)

## Metadata
- **Feature:** location-picker (bug fixes)
- **Created:** 2026-03-02T12:00
- **Status:** implement-complete
- **Based-on:** 2026-03-02T12:00_plan.md + diagnosis.md
- **Estimated new tests:** ~8
- **Estimated modified source files:** 4 modified + 2 new

## Execution Rules
- Tasks are numbered by phase (e.g., Task 1.1, 2.1)
- [P] = parallelizable with other [P] tasks in the same phase
- TDD: Phase 2 writes tests BEFORE Phase 3 implementation
- Checkboxes track subtask completion

---

## Phase 1: Tests First (TDD)

### Task 1.1: [P] Write tests for BUG 1 and BUG 2 fixes
- [x] Add test: `_onResetToGps shows SnackBar when GPS is null`
- [x] Add test: `_onResetToGps clears location override`
- [x] Add test: `initState uses effectivePositionProvider for initial center`

**Files:** `test/features/location_picker/location_picker_screen_test.dart`

**Acceptance Criteria:**
- [x] 3 new tests written
- [x] Tests initially fail (TDD -- implementation not done yet)

### Task 1.2: [P] Write tests for LocationIndicatorChip (UX enhancement)
- [x] Create `test/features/wind_dome/widgets/location_indicator_chip_test.dart`
- [x] Test: shows "GPS" label when no override is set
- [x] Test: shows coordinates when override is set
- [x] Test: updates reactively when override changes (set then clear)

**Files:** `test/features/wind_dome/widgets/location_indicator_chip_test.dart`

**Acceptance Criteria:**
- [x] 3 new tests written
- [x] Tests initially fail (widget does not exist yet)

---

## Phase 2: Bug Fixes (All [P] -- independent changes)

### Task 2.1: [P] Fix BUG 1 -- Reset to GPS button unresponsive
- [x] In `location_picker_screen.dart`, add `else` branch to `_onResetToGps()` (after line 75)
- [x] In the else branch: show SnackBar with "Waiting for GPS signal..." when mounted
- [x] Verify the `clear()` call on line 68 still executes unconditionally (it does)

**Files:** `lib/features/location_picker/location_picker_screen.dart`

**Acceptance Criteria:**
- [x] Tapping "Reset to GPS" when GPS is null shows a SnackBar
- [x] Tapping "Reset to GPS" when GPS is available snaps the pin to GPS
- [x] Override is always cleared regardless of GPS availability

### Task 2.2: [P] Fix BUG 2 -- Re-entering map goes to 0,0
- [x] In `location_picker_screen.dart` line 37, change `ref.read(stablePositionProvider)` to `ref.read(effectivePositionProvider)`
- [x] Update variable name from `gps` to `position` for clarity
- [x] Import already present (`location_override_provider.dart` on line 8)

**Files:** `lib/features/location_picker/location_picker_screen.dart`

**Acceptance Criteria:**
- [x] Re-entering map after setting override shows override position, not (0,0)
- [x] Opening map for first time with GPS available shows GPS position
- [x] Opening map with no GPS and no override falls back to (0,0)

### Task 2.3: [P] Fix BUG 3a -- Dome screen "Waiting for GPS" with override set
- [x] In `wind_dome_screen.dart` line 166, change `ref.watch(stablePositionProvider)` to `ref.watch(effectivePositionProvider)`
- [x] Add import: `import '../../core/providers/location_override_provider.dart';`
- [x] Removed the now-unused `sensor_providers.dart` import (replaced with location_override_provider.dart)

**Files:** `lib/features/wind_dome/wind_dome_screen.dart`

**Acceptance Criteria:**
- [x] "Waiting for GPS..." message disappears when location override is set
- [x] "Waiting for GPS..." still shows when neither GPS nor override is available
- [x] Wind dome continues to render correctly with override position

### Task 2.4: [P] Fix BUG 3b + BUG 4 -- AR screen "Waiting for GPS" with override set
- [x] In `ar_view_screen.dart` line 169, change `ref.watch(stablePositionProvider)` to `ref.watch(effectivePositionProvider)`
- [x] Add import: `import 'package:wind_lens/core/providers/location_override_provider.dart';`
- [x] Lines 233-234: `latitude: position?.latitude, longitude: position?.longitude` now automatically show override coords in DebugPanel
- [x] Kept sensor_providers.dart import (still needed for sensorNotifiersProvider, selectedAltitudeProvider)

**Files:** `lib/features/ar_view/ar_view_screen.dart`

**Acceptance Criteria:**
- [x] DataStatusBar shows correct state with override (no permanent "Waiting for GPS")
- [x] DebugPanel shows override coordinates when override is active
- [x] Everything works normally when no override is set (GPS mode)

---

## Phase 3: UX Enhancement (Sequential)

### Task 3.1: Create LocationIndicatorChip widget
- [x] Create `lib/features/wind_dome/widgets/location_indicator_chip.dart`
- [x] Implement as ConsumerWidget reading `locationOverrideProvider` and `effectivePositionProvider`
- [x] When no override: show pin icon + "GPS" text
- [x] When override set: show pin icon + "lat, lng" (4 decimal places)
- [x] Styling: semi-transparent black pill (matching dome UI), white text, compact size
- [x] Add Semantics label: "Location source: GPS" or "Location source: custom coordinates"

**Files:** `lib/features/wind_dome/widgets/location_indicator_chip.dart`

**Acceptance Criteria:**
- [x] Widget renders with correct text for GPS mode
- [x] Widget renders with correct text for override mode
- [x] Styling matches dome screen aesthetic
- [x] Semantics label present

### Task 3.2: Wire LocationIndicatorChip into dome screen
- [x] Import `location_indicator_chip.dart` in `wind_dome_screen.dart`
- [x] Add the chip as a Positioned widget below the DomeInfoBar (top area, left-aligned)
- [x] Position: below info bar (top padding + 56), left: 16

**Files:** `lib/features/wind_dome/wind_dome_screen.dart`

**Acceptance Criteria:**
- [x] Chip visible on dome screen
- [x] Chip shows correct location source
- [x] Does not overlap with other UI elements

---

## Phase 4: Verify [P]

### Task 4.1: [P] Run new tests
- [x] Run `flutter test test/features/location_picker/location_picker_screen_test.dart` -- 9 tests passing
- [x] Run `flutter test test/features/wind_dome/widgets/location_indicator_chip_test.dart` -- 3 tests passing
- [x] All new tests pass
- [x] No failures

**Files:** Test files

**Acceptance Criteria:**
- [x] All 5 new tests pass (2 bug fix + 3 UX)

### Task 4.2: [P] Run full test suite
- [x] Run `flutter test` (auto-discovered) -- 745 tests passing
- [x] Run explicit-path tests -- 47 tests passing
- [x] Total: 792 tests passing (zero failures)
- [x] Run `flutter analyze lib/` -- zero errors, zero warnings (13 info-level issues, all pre-existing Riverpod deprecations)

**Files:** All test files

**Acceptance Criteria:**
- [x] Zero test failures across entire suite
- [x] Zero analyzer errors
- [x] No regressions from provider swap

---

## Phase 5: Ready for Test Agent

### Task 5.1: Handoff verification
- [x] All bug fix tests pass
- [x] All UX enhancement tests pass
- [x] All existing tests pass (no regressions)
- [x] `flutter analyze lib/` clean
- [x] Changes documented in implementation.md

**Acceptance Criteria:**
- [x] Zero test failures
- [x] Zero analyzer errors
- [x] BUG 1-4 resolved
- [x] UX enhancement implemented

---

## Handoff Checklist for Test Agent

- [x] BUG 1: Reset to GPS shows SnackBar when GPS null, clears override always
- [x] BUG 2: Map opens at override position on re-entry, not (0,0)
- [x] BUG 3a: Dome screen hides "Waiting for GPS" when override is set
- [x] BUG 3b/4: AR screen hides "Waiting for GPS" when override is set
- [x] UX: LocationIndicatorChip shows GPS vs custom coords on dome screen
- [x] All new tests pass (5)
- [x] All existing tests pass (no regressions)
- [x] `flutter analyze lib/` clean
- [ ] On-device testing recommended for BUG 1 (GPS timing) and BUG 2 (map re-entry)

---

## Summary

| Phase | Tasks | New Tests | Parallel? |
|-------|-------|-----------|-----------|
| 1. Tests First (TDD) | 2 | 5 | Yes [P] |
| 2. Bug Fixes | 4 | 0 | Yes [P] |
| 3. UX Enhancement | 2 | 0 | No (sequential) |
| 4. Verify | 2 | 0 | Yes [P] |
| 5. Handoff | 1 | 0 | No |
| **Total** | **11** | **5** | |

### Changes by File

| File | Bugs Fixed | Change Type |
|------|-----------|-------------|
| `location_picker_screen.dart` | BUG 1, BUG 2 | Modify (2 methods) |
| `wind_dome_screen.dart` | BUG 3a | Modify (1 line + import + chip) |
| `ar_view_screen.dart` | BUG 3b, BUG 4 | Modify (1 line + import) |
| `location_indicator_chip.dart` | UX | New file |
| `location_indicator_chip_test.dart` | UX | New test file |
| `location_picker_screen_test.dart` | BUG 1, BUG 2 | Modify (add tests) |
