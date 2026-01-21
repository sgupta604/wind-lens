# Tasks: compass-sensors

## Metadata
- **Feature:** compass-sensors
- **Created:** 2026-01-21T00:33
- **Status:** implementation-complete
- **Based On:** 2026-01-21T00:33_plan.md

---

## Execution Rules

1. **Sequential by default:** Complete tasks in order unless marked `[P]`
2. **`[P]` = Parallelizable:** These tasks can run concurrently
3. **TDD approach:** Write tests before implementation (Phase 2 before Phase 3)
4. **Checkboxes:** Mark `[x]` when subtask is complete
5. **Acceptance criteria:** All checkboxes must pass before task is complete

---

## Phase 1: Directory Setup

### Task 1.1: Create Services Directory
- [x] Create `lib/services/` directory
- [x] Verify directory exists

**Files:** `lib/services/`

**Acceptance Criteria:**
- [x] Directory `lib/services/` exists

---

### Task 1.2: Create Test Services Directory [P]
- [x] Create `test/services/` directory
- [x] Verify directory exists

**Files:** `test/services/`

**Acceptance Criteria:**
- [x] Directory `test/services/` exists

---

### Task 1.3: Create Models Directory [P]
- [x] Create `lib/models/` directory (if not exists)
- [x] Verify directory exists

**Files:** `lib/models/`

**Acceptance Criteria:**
- [x] Directory `lib/models/` exists

---

## Phase 2: Tests (TDD)

### Task 2.1: Create CompassData Model Tests
- [x] Create `test/models/compass_data_test.dart`
- [x] Write test for CompassData construction
- [x] Write test for CompassData equality (optional)
- [x] Run tests (expect fail - model not implemented)

**Files:** `test/models/compass_data_test.dart`

**Acceptance Criteria:**
- [x] Test file exists
- [x] Tests are syntactically valid
- [x] Tests fail because model doesn't exist yet

---

### Task 2.2: Create CompassService Unit Tests
- [x] Create `test/services/compass_service_test.dart`
- [x] Write test: initial heading and pitch are 0
- [x] Write test: heading calculation from magnetometer event
- [x] Write test: heading wraparound (359 -> 1 degree)
- [x] Write test: heading wraparound (1 -> 359 degree)
- [x] Write test: heading dead zone (changes < 1.0 ignored)
- [x] Write test: pitch calculation from accelerometer event
- [x] Write test: pitch dead zone (changes < 2.0 ignored)
- [x] Write test: smoothing factor applied correctly
- [x] Write test: stream emits CompassData updates
- [x] Write test: dispose cancels subscriptions
- [x] Run tests (expect fail - service not implemented)

**Files:** `test/services/compass_service_test.dart`

**Acceptance Criteria:**
- [x] Test file exists with comprehensive test coverage
- [x] Tests are syntactically valid
- [x] Tests fail because service doesn't exist yet

---

## Phase 3: Core Implementation

### Task 3.1: Create CompassData Model
- [x] Create `lib/models/compass_data.dart`
- [x] Implement CompassData class with heading and pitch fields
- [x] Add const constructor
- [x] Add documentation comments
- [x] Run `flutter analyze` on file
- [x] Run model tests (Task 2.1 tests should pass)

**Files:** `lib/models/compass_data.dart`

**Acceptance Criteria:**
- [x] Model file exists
- [x] Class has `heading` and `pitch` double fields
- [x] Constructor is const
- [x] `flutter analyze` passes
- [x] Model tests pass

---

### Task 3.2: Create CompassService
- [x] Create `lib/services/compass_service.dart`
- [x] Import sensors_plus and dart:math
- [x] Define constants: smoothingFactor (0.1), headingDeadZone (1.0), pitchDeadZone (2.0)
- [x] Implement private state: _smoothedHeading, _smoothedPitch
- [x] Implement magnetometer subscription and event handler
- [x] Implement accelerometer subscription and event handler
- [x] Implement heading calculation with wraparound handling
- [x] Implement pitch calculation
- [x] Implement dead zone logic for both sensors
- [x] Implement smoothing filter for both sensors
- [x] Add logging: "Heading: X.X, Pitch: Y.Y"
- [x] Implement `heading` and `pitch` getters
- [x] Implement `Stream<CompassData>` getter
- [x] Implement `start()` method
- [x] Implement `dispose()` method
- [x] Add documentation comments
- [x] Run `flutter analyze` on file
- [x] Run service tests (Task 2.2 tests should pass)

**Files:** `lib/services/compass_service.dart`

**Acceptance Criteria:**
- [x] Service file exists
- [x] Constants match spec values
- [x] Smoothing algorithm implemented correctly
- [x] Dead zones prevent small updates
- [x] Heading wraparound handled correctly
- [x] Stream emits updates
- [x] `flutter analyze` passes
- [x] Service tests pass

---

## Phase 4: Integration

### Task 4.1: Update ARViewScreen
- [x] Convert ARViewScreen from StatelessWidget to StatefulWidget
- [x] Add CompassService instance as state
- [x] Add StreamSubscription for compass updates
- [x] Add state variables for current heading and pitch
- [x] Call `_compassService.start()` in initState
- [x] Subscribe to compass stream in initState
- [x] Call `setState()` on compass updates
- [x] Call `_compassService.dispose()` in dispose
- [x] Cancel stream subscription in dispose
- [x] Run `flutter analyze`

**Files:** `lib/screens/ar_view_screen.dart`

**Acceptance Criteria:**
- [x] ARViewScreen is a StatefulWidget
- [x] CompassService is properly initialized
- [x] Service is started on screen mount
- [x] Service is disposed on screen unmount
- [x] State updates on compass changes
- [x] `flutter analyze` passes

---

### Task 4.2: Add Debug Overlay
- [x] Add Stack widget to wrap CameraView
- [x] Create debug overlay widget positioned at top-left
- [x] Display current heading value (formatted to 1 decimal)
- [x] Display current pitch value (formatted to 1 decimal)
- [x] Style with semi-transparent background
- [x] Ensure overlay doesn't interfere with camera view
- [x] Run `flutter analyze`

**Files:** `lib/screens/ar_view_screen.dart`

**Acceptance Criteria:**
- [x] Debug overlay visible on screen
- [x] Heading displayed as "Heading: X.X°"
- [x] Pitch displayed as "Pitch: X.X°"
- [x] Overlay has semi-transparent background
- [x] Camera view still fully visible
- [x] `flutter analyze` passes

---

## Phase 5: Verification

### Task 5.1: Run All Tests
- [x] Run `flutter test`
- [x] All unit tests pass
- [x] No test failures or errors

**Acceptance Criteria:**
- [x] `flutter test` exits with code 0
- [x] All compass-sensors related tests pass (33 total tests passing)

---

### Task 5.2: Run Static Analysis
- [x] Run `flutter analyze`
- [x] No errors
- [x] No warnings (or documented exceptions)

**Acceptance Criteria:**
- [x] `flutter analyze` shows no issues

---

### Task 5.3: Document Real Device Testing [P]
- [x] Document manual testing steps for real device
- [x] Note: Simulator cannot test sensors
- [x] Include expected behaviors to verify

**Files:** `.claude/active-work/compass-sensors/implementation.md`

**Acceptance Criteria:**
- [x] Manual testing steps documented
- [x] Expected behaviors listed

---

## Phase 6: Handoff to Test Agent

### Pre-Handoff Checklist

Before running `/test compass-sensors`:

- [x] All Phase 5 tasks complete
- [x] `flutter analyze` passes
- [x] `flutter test` passes
- [x] implementation.md created in `.claude/active-work/compass-sensors/`
- [x] No uncommitted changes that would break build

### Files Created/Modified Summary

| File | Action | Status |
|------|--------|--------|
| `lib/models/compass_data.dart` | CREATE | Complete |
| `lib/services/compass_service.dart` | CREATE | Complete |
| `lib/screens/ar_view_screen.dart` | MODIFY | Complete |
| `test/models/compass_data_test.dart` | CREATE | Complete |
| `test/services/compass_service_test.dart` | CREATE | Complete |

---

## Notes

- **Real device required:** Sensors only work on physical iOS/Android devices
- **Debug overlay is temporary:** Will be refined in polish phase
- **Logging required:** Console should show "Heading: X.X°, Pitch: Y.Y°" updates
- **All 33 tests passing:** 5 model tests + 20 service tests + 8 existing tests
