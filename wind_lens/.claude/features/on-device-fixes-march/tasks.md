# Tasks: on-device-fixes-march

## Metadata
- **Feature:** on-device-fixes-march
- **Created:** 2026-03-03T12:00
- **Status:** implementation-complete
- **Based on:** 2026-03-03T12:00_plan.md
- **Branch:** feature/wind-dome-homescreen

## Execution Rules

- Tasks are grouped into phases and numbered (e.g., Task 1.1, Task 2.1)
- [P] = parallelizable with other [P] tasks in the same phase
- Execute phases in order; within a phase, respect dependencies
- TDD: write/update tests BEFORE implementation where applicable
- Mark tasks complete with [x] when done

---

## Phase 1: Setup (Sequential)

### Task 1.1: Verify baseline tests pass
- [x] Run `flutter test` in `/workspace/wind_lens` to confirm all existing tests pass
- [x] Run `flutter analyze lib/` to confirm zero errors

**Files:** None (verification only)

**Acceptance Criteria:**
- [x] All tests pass (746+ expected) -- 746 passed
- [x] Zero analyzer errors -- 13 info-level only (pre-existing)

---

## Phase 2: Tests First (TDD)

### Task 2.1: [P] Update jet stream pressure level test (BUG C)
- [x] Open `test/services/wind/ogc_edr_wind_source_test.dart`
- [x] Update the test "getWind with AltitudeLevel.jetStream passes pressureLevel 300" (line 89-98):
  - Change test name to reflect 200 hPa
  - Change expected value from `[300]` to `[200]`
- [x] Run the updated test file -- it SHOULD FAIL (TDD: test fails before implementation) -- CONFIRMED FAILED

**Files:** `test/services/wind/ogc_edr_wind_source_test.dart`

**Acceptance Criteria:**
- [x] Test expects pressureLevel 200 for jetStream
- [x] Test fails before implementation (proves test catches the bug)

### Task 2.2: [P] Add DomeInfoBar live wind speed tests (BUG A)
- [x] Open `test/features/wind_dome/widgets/dome_info_bar_test.dart`
- [x] Add test: "shows AR wind speed when hoursAhead is 0"
- [x] Add test: "shows dome surface speed when hoursAhead > 0"
- [x] Run the updated test file -- tests SHOULD FAIL (TDD) -- CONFIRMED: live test failed, forecast test passed

**Files:** `test/features/wind_dome/widgets/dome_info_bar_test.dart`

**Acceptance Criteria:**
- [x] Test for live speed sourcing from windDataProvider
- [x] Test for forecast speed sourcing from dome data
- [x] Tests fail before implementation

### Task 2.3: [P] Move LocationIndicatorChip test to shared path (BUG D)
- [x] Copy `test/features/wind_dome/widgets/location_indicator_chip_test.dart` to `test/core/widgets/location_indicator_chip_test.dart`
- [x] Update the import path in the copied test from `features/wind_dome/widgets/location_indicator_chip.dart` to `core/widgets/location_indicator_chip.dart`
- [x] Run the copied test file -- it SHOULD FAIL (file does not exist at new path yet) -- CONFIRMED FAILED
- [x] Keep the original test file unchanged for now (dome re-export shim will make it pass)

**Files:** `test/core/widgets/location_indicator_chip_test.dart` (new)

**Acceptance Criteria:**
- [x] Test file exists at shared path
- [x] Import references `core/widgets/location_indicator_chip.dart`
- [x] Test fails before implementation (import target does not exist)

---

## Phase 3: Core Implementation (Sequential)

### Task 3.1: Move LocationIndicatorChip to shared location (BUG D)
- [x] Create `lib/core/widgets/location_indicator_chip.dart` with the exact content from `lib/features/wind_dome/widgets/location_indicator_chip.dart`
- [x] Replace `lib/features/wind_dome/widgets/location_indicator_chip.dart` content with a single-line re-export: `export 'package:wind_lens/core/widgets/location_indicator_chip.dart';`
- [x] Run `test/core/widgets/location_indicator_chip_test.dart` -- PASSED (3/3)
- [x] Run `test/features/wind_dome/widgets/location_indicator_chip_test.dart` -- PASSED (3/3 via re-export)

**Files:**
- `lib/core/widgets/location_indicator_chip.dart` (new)
- `lib/features/wind_dome/widgets/location_indicator_chip.dart` (modified to re-export)

**Acceptance Criteria:**
- [x] Chip exists at `lib/core/widgets/location_indicator_chip.dart`
- [x] Old path re-exports to new path
- [x] Both test files pass

### Task 3.2: Add LocationIndicatorChip to AR screen (BUG D)
- [x] Open `lib/features/ar_view/ar_view_screen.dart`
- [x] Add import for `package:wind_lens/core/widgets/location_indicator_chip.dart`
- [x] Add a new Positioned widget in the Stack (Layer 9: top-right)
- [x] Run `flutter analyze lib/` -- zero errors (1 pre-existing info)
- [x] Run all tests -- all pass

**Files:** `lib/features/ar_view/ar_view_screen.dart`

**Acceptance Criteria:**
- [x] LocationIndicatorChip appears in AR screen Stack
- [x] Import uses canonical `core/widgets/` path
- [x] Zero analyzer errors

### Task 3.3: Change jet stream pressure level to 200 hPa (BUG C)
- [x] Open `lib/services/wind/ogc_edr_wind_source.dart`
- [x] Change line 70: `AltitudeLevel.jetStream => 300` to `AltitudeLevel.jetStream => 200`
- [x] Update the class doc comment: change "300 hPa (~9,000m)" to "200 hPa (~11,800m)"
- [x] Run `test/services/wind/ogc_edr_wind_source_test.dart` -- ALL 13 PASSED
- [x] Run all wind tests to confirm no regressions

**Files:** `lib/services/wind/ogc_edr_wind_source.dart`

**Acceptance Criteria:**
- [x] `_altitudeToPressure(AltitudeLevel.jetStream)` returns 200
- [x] Doc comment updated
- [x] All wind tests pass

### Task 3.4: Align DomeInfoBar live speed with AR wind provider (BUG A)
- [x] Open `lib/features/wind_dome/widgets/dome_info_bar.dart`
- [x] Add import for `package:wind_lens/core/providers/data_providers.dart`
- [x] In the `build()` method, add: `final arWind = ref.watch(windDataProvider);`
- [x] Modify the wind speed computation: live uses AR speed, forecast uses dome speed
- [x] Run `test/features/wind_dome/widgets/dome_info_bar_test.dart` -- ALL 9 PASSED
- [x] Run all dome tests to confirm no regressions -- ALL 77 PASSED

**Files:** `lib/features/wind_dome/widgets/dome_info_bar.dart`

**Acceptance Criteria:**
- [x] Live mode displays AR wind speed
- [x] Forecast mode displays dome surface speed
- [x] Fallback works when windDataProvider is loading
- [x] All dome tests pass

### Task 3.5: Add debug logging to DomeWindFetcher (BUG B)
- [x] Open `lib/services/wind/dome_wind_fetcher.dart`
- [x] Add `import 'dart:developer' show log;` (zero-cost in release builds)
- [x] After the `Future.wait` completes, add timestep count logging
- [x] After `hourlyFields` is assembled, add u/v variation check logging
- [x] Run all dome wind fetcher tests -- ALL 9 PASSED

**Files:** `lib/services/wind/dome_wind_fetcher.dart`

**Acceptance Criteria:**
- [x] Debug logging added (visible in device console / `flutter logs`)
- [x] No new imports that affect release performance (dart:developer `log` is stripped in release)
- [x] All existing tests still pass

---

## Phase 4: Integration Verification (Sequential)

### Task 4.1: Run full test suite
- [x] Run `flutter test` to verify all auto-discovered tests pass -- 751 PASSED
- [x] Run non-auto-discovered tests -- 47 PASSED
- [x] Run `flutter analyze lib/` -- zero errors, 13 info-level (pre-existing)

**Files:** None (verification only)

**Acceptance Criteria:**
- [x] All tests pass (746+ existing + ~4 new) -- 751 auto + 47 non-auto = 798 total
- [x] Zero analyzer errors

---

## Phase 5: Polish (Parallel OK)

### Task 5.1: [P] Update CLAUDE.md if needed
- [x] Check if CLAUDE.md altitude table needs update (currently says 250 hPa for jet stream)
- [x] Updated to "200 hPa" and "11,800m" to match the new code
- [x] Confirmed no stale references to 300 hPa or 250 hPa remain

**Files:** `/workspace/CLAUDE.md`

**Acceptance Criteria:**
- [x] CLAUDE.md altitude table reflects 200 hPa for jet stream
- [x] No stale references to 300 hPa

### Task 5.2: [P] Verify dome import path still works
- [x] Confirm `wind_dome_screen.dart` still compiles (uses old import path through re-export)
- [x] Run dome tests to confirm -- ALL 77 PASSED

**Files:** `lib/features/wind_dome/wind_dome_screen.dart` (no modification needed)

**Acceptance Criteria:**
- [x] Dome screen compiles and renders LocationIndicatorChip
- [x] All dome widget tests pass

---

## Phase 6: Handoff to Test Agent

### Pre-Handoff Checklist
- [x] All unit tests pass (750+ total) -- 798 total (751 auto + 47 non-auto)
- [x] `flutter analyze lib/` -- zero errors
- [x] No uncommitted build artifacts or temp files
- [x] `tasks.md` fully checked off through Phase 5
- [x] Summary of changes documented in implementation.md

### What the Test Agent Should Verify
1. **Full test suite passes** (auto-discovered + explicit paths)
2. **Analyzer clean** (zero errors, zero warnings in new code)
3. **On-device verification needed:**
   - AR screen: LocationIndicatorChip visible in top-right
   - AR screen: Jet stream altitude shows non-zero wind speed
   - Dome screen: "Live" speed matches AR surface speed
   - Dome screen: Moving forecast slider visibly changes particle direction
   - Check device console logs from DomeWindFetcher for timestep count and u/v variation

---

## Summary

| Bug | Fix | Files Changed | Tests |
|-----|-----|---------------|-------|
| D (AR location chip) | Move chip to `core/widgets/`, add to AR Stack | 3 new + 2 modified | 3 moved + 0 new |
| C (Jet stream 0.0) | Change 300 -> 200 hPa | 1 modified | 1 updated |
| A (Dome speed mismatch) | DomeInfoBar reads windDataProvider when live | 1 modified | 2 new |
| B (Forecast slider) | Debug logging in DomeWindFetcher | 1 modified | 0 new |

**Total:** 3 new files, 6 modified files, 5 new/updated tests
