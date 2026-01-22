# Tasks: BUG-002.5 - Sky Detection Not Working on Real Device

## Feature Metadata

| Field | Value |
|-------|-------|
| Feature | sky-detection-v2-fix |
| Type | Bug Fix |
| Created | 2026-01-21T12:00 |
| Status | Implementation Complete |
| Based On | `2026-01-21T12:00_plan.md` |

---

## Execution Rules

1. **TDD Order:** Write tests BEFORE implementation
2. **Sequential execution** unless marked with [P] for parallelizable
3. **Completion:** Mark tasks with [x] when done
4. **Acceptance criteria:** All checkboxes must pass before task is complete

---

## Phase 1: Setup (No Database Changes)

*No setup required - this is a modification to existing code.*

---

## Phase 2: Tests (TDD - Write First)

### Task 2.1: Update Existing Threshold Tests

- [x] Update test `calibration threshold is 45 degrees` to expect 25 degrees
- [x] Update test `sample region top is 10%` to expect 5%
- [x] Modify or remove test `sample region bottom is 40%` (now dynamic)
- [x] Run tests - they should FAIL (expected, implementation not done yet)

**Files:** `test/services/sky_detection/auto_calibrating_sky_detector_test.dart`

**Acceptance Criteria:**
- [x] Test for calibration threshold expects 25.0
- [x] Test for sample region top expects 0.05
- [x] No test expects static 0.4 for sample region bottom

---

### Task 2.2: Add Tests for Dynamic Sample Region

- [x] Add test: `_getSampleRegionBottom returns 0.20 for pitch 25-34`
- [x] Add test: `_getSampleRegionBottom returns 0.30 for pitch 35-44`
- [x] Add test: `_getSampleRegionBottom returns 0.40 for pitch 45-59`
- [x] Add test: `_getSampleRegionBottom returns 0.50 for pitch 60+`
- [x] Add test group for `dynamic sample region` behavior
- [x] Run tests - they should FAIL (method not implemented yet)

**Files:** `test/services/sky_detection/auto_calibrating_sky_detector_test.dart`

**Acceptance Criteria:**
- [x] Four tests for different pitch ranges
- [x] Tests verify boundary conditions (25, 35, 45, 60)
- [x] Tests verify mid-range values work correctly

---

### Task 2.3: Add Integration Test for Calibration Trigger

- [x] Add test: `calibration can be attempted at 25 degree pitch`
- [x] Add test: `calibration uses smaller sample region at lower pitch`
- [x] Verify tests compile but fail (implementation pending)

**Files:** `test/services/sky_detection/auto_calibrating_sky_detector_test.dart`

**Acceptance Criteria:**
- [x] Tests verify calibration logic at 25 degrees
- [x] Tests document expected behavior

---

## Phase 3: Core Implementation (Sequential)

### Task 3.1: Lower Calibration Threshold

- [x] Change `calibrationPitchThreshold` from 45.0 to 25.0
- [x] Update doc comment to reflect new threshold
- [x] Run threshold tests - they should now PASS

**Files:** `lib/services/sky_detection/auto_calibrating_sky_detector.dart`

**Location:** Line 46

**Before:**
```dart
static const double calibrationPitchThreshold = 45.0;
```

**After:**
```dart
static const double calibrationPitchThreshold = 25.0;
```

**Acceptance Criteria:**
- [x] Constant value is 25.0
- [x] Doc comment updated
- [x] `calibration threshold is 25 degrees` test passes

---

### Task 3.2: Update Sample Region Top Constant

- [x] Change `sampleRegionTop` from 0.1 to 0.05
- [x] Update doc comment
- [x] Run sample region top tests - they should now PASS

**Files:** `lib/services/sky_detection/auto_calibrating_sky_detector.dart`

**Location:** Line 49

**Before:**
```dart
static const double sampleRegionTop = 0.1;
```

**After:**
```dart
static const double sampleRegionTop = 0.05;
```

**Acceptance Criteria:**
- [x] Constant value is 0.05
- [x] Doc comment mentions "top 5%"
- [x] `sample region top is 5%` test passes

---

### Task 3.3: Implement Dynamic Sample Region Method

- [x] Add `_getSampleRegionBottom()` method
- [x] Method returns different values based on `_pitch`:
  - pitch >= 60: return 0.50
  - pitch >= 45: return 0.40
  - pitch >= 35: return 0.30
  - pitch >= 25: return 0.20
  - else: return 0.15
- [x] Add comprehensive doc comment
- [x] Run dynamic sample region tests - they should now PASS

**Files:** `lib/services/sky_detection/auto_calibrating_sky_detector.dart`

**Location:** After line 118 (after `updatePitch` method)

**Implementation:**
```dart
/// Calculates the sample region bottom boundary based on current pitch.
///
/// At lower pitch angles, we sample more conservatively (smaller region)
/// to avoid accidentally sampling buildings/trees near the horizon.
/// At higher pitch angles, we can sample more aggressively.
///
/// Pitch ranges and sample regions:
/// - 60+ degrees: sample top 5-50% (looking high up)
/// - 45-59 degrees: sample top 5-40% (original behavior)
/// - 35-44 degrees: sample top 5-30% (moderate angle)
/// - 25-34 degrees: sample top 5-20% (conservative)
/// - <25 degrees: sample top 5-15% (very conservative)
///
/// Returns the bottom boundary as a fraction of frame height (0.0-1.0).
double _getSampleRegionBottom() {
  if (_pitch >= 60) return 0.50;
  if (_pitch >= 45) return 0.40;
  if (_pitch >= 35) return 0.30;
  if (_pitch >= 25) return 0.20;
  return 0.15;
}
```

**Acceptance Criteria:**
- [x] Method implemented with correct pitch thresholds
- [x] Doc comment explains the logic
- [x] All dynamic sample region tests pass

---

### Task 3.4: Make _getSampleRegionBottom Testable

- [x] Add a public getter or method to expose sample region for testing
- [x] Option A: Add `@visibleForTesting` annotation on a public method
- [x] Option B: Add a test-only getter
- [x] Update tests to use the testable method

**Files:**
- `lib/services/sky_detection/auto_calibrating_sky_detector.dart`
- `test/services/sky_detection/auto_calibrating_sky_detector_test.dart`

**Acceptance Criteria:**
- [x] Tests can verify sample region calculation
- [x] Production code unaffected

---

### Task 3.5: Update Calibration Methods to Use Dynamic Region

- [x] Update `_samplePixelsBGRA` to use `_getSampleRegionBottom()` instead of static constant
- [x] Update `_samplePixelsYUV` to use `_getSampleRegionBottom()` instead of static constant
- [x] Remove or deprecate the static `sampleRegionBottom` constant (or keep for reference)
- [x] Verify calibration uses correct region at different pitches

**Files:** `lib/services/sky_detection/auto_calibrating_sky_detector.dart`

**Locations:**
- `_samplePixelsBGRA` method (~line 221)
- `_samplePixelsYUV` method (~line 261)

**Before (in both methods):**
```dart
final endY = (height * sampleRegionBottom).floor();
```

**After (in both methods):**
```dart
final endY = (height * _getSampleRegionBottom()).floor();
```

**Acceptance Criteria:**
- [x] Both sampling methods use dynamic region
- [x] Static constant either removed or marked as deprecated/reference
- [x] Integration tests pass

---

## Phase 4: Integration (Sequential)

### Task 4.1: Run Full Test Suite

- [x] Run `flutter test` for all tests
- [x] Verify all sky detection tests pass
- [x] Verify no regressions in other tests
- [x] Fix any failing tests

**Command:** `cd /workspace/wind_lens && flutter test`

**Acceptance Criteria:**
- [x] All tests pass (250 tests passed)
- [x] No regressions

---

### Task 4.2: Static Analysis

- [x] Run `flutter analyze`
- [x] Fix any lint warnings
- [x] Verify no new issues introduced

**Command:** `cd /workspace/wind_lens && flutter analyze`

**Acceptance Criteria:**
- [x] No analyzer errors
- [x] No new warnings

---

## Phase 5: Polish [P] (Can Run in Parallel)

### Task 5.1: Update Documentation Comments [P]

- [x] Update class-level doc comment to mention 25-degree threshold
- [x] Update `calibrationPitchThreshold` doc comment
- [x] Update `sampleRegionTop` doc comment
- [x] Ensure all doc comments are consistent

**Files:** `lib/services/sky_detection/auto_calibrating_sky_detector.dart`

**Acceptance Criteria:**
- [x] Doc comments mention correct thresholds
- [x] Comments explain dynamic sample region behavior

---

### Task 5.2: Add Deprecation Note for Static sampleRegionBottom [P]

- [x] Either remove `sampleRegionBottom` constant
- [x] Or add deprecation comment explaining it's now dynamic
- [x] Ensure code compiles

**Files:** `lib/services/sky_detection/auto_calibrating_sky_detector.dart`

**Acceptance Criteria:**
- [x] Constant is either removed or clearly deprecated
- [x] No compilation errors

---

## Phase 6: Ready for Test Agent

### Task 6.1: Final Verification

- [x] All unit tests pass (`flutter test`)
- [x] Static analysis clean (`flutter analyze`)
- [x] Build succeeds (validated by finalize agent)
- [x] Code review checklist:
  - [x] Calibration threshold lowered to 25 degrees
  - [x] Sample region top at 5%
  - [x] Dynamic sample region method implemented
  - [x] Sampling methods use dynamic region
  - [x] Tests updated and passing

**Acceptance Criteria:**
- [x] Ready for real device testing
- [x] No build errors
- [x] All automated tests pass

---

## Handoff Checklist for Test Agent

When all tasks are complete, verify:

- [x] `calibrationPitchThreshold` is 25.0
- [x] `sampleRegionTop` is 0.05
- [x] `_getSampleRegionBottom()` method exists and works correctly
- [x] Both `_samplePixelsBGRA` and `_samplePixelsYUV` use dynamic region
- [x] All tests in `auto_calibrating_sky_detector_test.dart` pass
- [x] `flutter analyze` shows no errors
- [x] `flutter test` shows all tests passing
- [x] Build succeeds

### Real Device Test Instructions

1. Build and deploy to iOS device
2. Open app and enable debug panel (tap DBG button)
3. Point phone at sky at ~30 degree angle
4. Watch for "Sky Cal: Yes" to appear
5. Pan phone around - particles should appear in sky regions
6. Point at buildings - particles should NOT appear on buildings
7. Test at different times of day (if possible)
