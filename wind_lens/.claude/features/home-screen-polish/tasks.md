# Tasks: home-screen-polish

| Field | Value |
|-------|-------|
| Feature | home-screen-polish |
| Created | 2026-03-04T15:30 |
| Status | complete |
| Based on | 2026-03-04T15:30_plan.md |

## Execution Rules

- Tasks are sequential (too small for parallelization)
- TDD: write test first (Phase 1), then implement (Phase 2)
- Mark items with [x] when complete

---

## Phase 1: Test (TDD -- write failing test first)

### Task 1.1: Add unit label test
- [x] Add test to `home_wind_row_test.dart` that verifies 'm/s' is displayed in the speed column when wind data is available
- [x] Run test -- confirm it FAILS (currently shows 'mph')

**Files:** `test/features/home/widgets/home_wind_row_test.dart`

**Acceptance Criteria:**
- [x] Test exists and asserts `find.text('m/s')` finds one widget
- [x] Test fails before implementation (red phase)

---

## Phase 2: Implementation

### Task 2.1: Fix unit label and semantics in HomeWindRow
- [x] Line 60: change `'mph'` to `'m/s'`
- [x] Line 55: change `'miles per hour'` to `'meters per second'`

**Files:** `lib/features/home/widgets/home_wind_row.dart`

**Acceptance Criteria:**
- [x] Speed column shows "m/s"
- [x] Semantics label says "meters per second"

### Task 2.2: Brighten colors in HomeWindRow
- [x] Line 129: change `0xFF333333` to `0xFF555555` (header labels)
- [x] Line 147: change `0xFF444444` to `0xFF777777` (sublabels)

**Files:** `lib/features/home/widgets/home_wind_row.dart`

**Acceptance Criteria:**
- [x] Header label color is `Color(0xFF555555)`
- [x] Sublabel color is `Color(0xFF777777)`

### Task 2.3: Brighten subtitle color in HomeTopBar
- [x] Line 78: change `0xFF444444` to `0xFF666666`

**Files:** `lib/features/home/widgets/home_top_bar.dart`

**Acceptance Criteria:**
- [x] "ATMOSPHERIC AR" subtitle color is `Color(0xFF666666)`

---

## Phase 3: Verification

### Task 3.1: Run all tests
- [x] Run `flutter test` -- all tests pass
- [x] Run explicit test paths: `flutter test test/utils/ test/services/sensors/ test/services/sky_detection/sky_mask_test.dart test/core/providers/data_providers_test.dart`
- [x] New unit label test passes (green phase)

**Acceptance Criteria:**
- [x] 0 test failures
- [x] 0 analyzer errors
- [x] New test from Task 1.1 passes

---

## Handoff Checklist (for Test Agent)

- [x] All existing tests still pass
- [x] 1 new test added and passing
- [x] No analyzer errors or warnings introduced
- [x] Build succeeds (`flutter build` or `flutter analyze`)
