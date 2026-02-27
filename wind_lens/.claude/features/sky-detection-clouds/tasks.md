# Tasks: Sky Detection Cloud Coverage Fix (BUG-011)

## Metadata

- **Feature:** sky-detection-clouds
- **Timestamp:** 2026-02-06
- **Status:** implemented
- **Based On:** `2026-02-06_plan.md`

## Execution Rules

- Tasks are numbered by phase (e.g., Task 2.1 = Phase 2, Task 1)
- `[P]` = parallelizable with other tasks in the same phase
- Complete each task's acceptance criteria before moving on
- TDD: write tests (Phase 2) BEFORE implementation (Phase 3)
- Mark checkboxes as tasks are completed

---

## Phase 1: Setup

### Task 1.1: Expose cloud scoring methods for testing

- [x] Add `@visibleForTesting` public wrappers for `_isCloudLike()` and `_cloudSkyScore()` in `auto_calibrating_sky_detector.dart` (following the existing pattern of `getPositionWeight()` and `getSampleRegionBottom()`)
- [x] Add placeholder implementations that return `false` / `0.0` (so tests can be written against the API before real logic)
- [x] Verify build compiles with `flutter analyze lib/`

**Files:** `lib/services/sky_detection/auto_calibrating_sky_detector.dart`

**Acceptance Criteria:**
- [x] `isCloudLike(HSV)` and `cloudSkyScore(HSV)` are accessible from tests
- [x] Placeholder returns `false` and `0.0` respectively
- [x] `flutter analyze lib/` reports no issues (pre-existing SDK errors only)

---

## Phase 2: Tests (TDD - Write First, Expect Failures)

### Task 2.1: Write cloud bypass unit tests [P]

- [x] Add `cloud bypass scoring` test group in `auto_calibrating_sky_detector_test.dart`
- [x] Test 1: `_isCloudLike returns true for white cloud (S=0.02, V=0.96)`
- [x] Test 2: `_isCloudLike returns true for gray cloud (S=0.08, V=0.75)`
- [x] Test 3: `_isCloudLike returns false for dark shadow (S=0.05, V=0.25)`
- [x] Test 4: `_isCloudLike returns false for saturated object (S=0.50, V=0.60)`
- [x] Test 5: `_isCloudLike returns false for blue sky (S=0.40, V=0.85)`
- [x] Test 6: `_cloudSkyScore returns high score for white cloud (S=0.02, V=0.96)`
- [x] Test 7: `_cloudSkyScore returns moderate score for gray cloud (S=0.08, V=0.75)`
- [x] Test 8: `_cloudSkyScore returns higher score for brighter cloud`
- [x] Run tests; expect failures for Tests 1, 2, 6, 7, 8 (placeholder returns false/0.0)

**Files:** `test/services/sky_detection/auto_calibrating_sky_detector_test.dart`

**Acceptance Criteria:**
- [x] 8 new tests written and compilable
- [x] Tests 3, 4, 5 pass (placeholder `false` is correct for non-cloud pixels)
- [x] Tests 1, 2, 6, 7, 8 fail (expected -- implementations are placeholders)

### Task 2.2: Write isSkyLikeColor threshold test [P]

- [x] Add test in `hsv_histogram_test.dart` for S=0.18 H=50 V=0.70: should return `true` with new threshold
- [x] Run test; expect failure (current threshold is 0.15, so S=0.18 with non-blue hue returns `false`)

**Files:** `test/services/sky_detection/hsv_histogram_test.dart`

**Acceptance Criteria:**
- [x] 1 new test written and compilable
- [x] Test fails (expected -- current threshold is 0.15)

---

## Phase 3: Core Implementation (Sequential)

### Task 3.1: Implement `_isCloudLike()` and `_cloudSkyScore()`

- [x] Replace placeholder `_isCloudLike()` with real logic:
  - Return `true` when `hsv.s < 0.15 && hsv.v >= 0.45`
- [x] Replace placeholder `_cloudSkyScore()` with real logic:
  - `brightnessScore = ((hsv.v - 0.45) / 0.55).clamp(0.0, 1.0)`
  - `desaturationScore = (1.0 - hsv.s / 0.15).clamp(0.0, 1.0)`
  - Return `(brightnessScore * 0.6 + desaturationScore * 0.4).clamp(0.0, 1.0)`
- [x] Run Task 2.1 tests; all 8 now pass

**Files:** `lib/services/sky_detection/auto_calibrating_sky_detector.dart`

**Acceptance Criteria:**
- [x] All 8 cloud bypass tests pass
- [x] `flutter analyze lib/` reports no issues

### Task 3.2: Integrate dual-path scoring in `_generateMask()`

- [x] Modify `_generateMask()` lines 464-468 to compute both scores:
  ```dart
  final blueScore = _skyHistogram!.matchScore(hsv);
  final cloudScore = _isCloudLike(hsv) ? _cloudSkyScore(hsv) : 0.0;
  final colorScore = blueScore > cloudScore ? blueScore : cloudScore;
  final combinedScore = colorScore * positionWeight;
  ```
- [x] Run all existing tests to verify no regressions

**Files:** `lib/services/sky_detection/auto_calibrating_sky_detector.dart`

**Acceptance Criteria:**
- [x] `_generateMask()` uses dual-path scoring
- [x] All existing tests still pass (no regressions)
- [x] `flutter analyze lib/` reports no issues

### Task 3.3: Widen `isSkyLikeColor()` saturation threshold

- [x] Change `hsv.s < 0.15` to `hsv.s < 0.20` in `isSkyLikeColor()` (line 38 of `hsv_histogram.dart`)
- [x] Run Task 2.2 test; now passes
- [x] Run all existing `isSkyLikeColor` tests to verify no regressions

**Files:** `lib/services/sky_detection/hsv_histogram.dart`

**Acceptance Criteria:**
- [x] Threshold updated to 0.20
- [x] New threshold test passes
- [x] All existing `isSkyLikeColor` tests still pass
- [x] `flutter analyze lib/` reports no issues

---

## Phase 4: Integration

### Task 4.1: Run full test suite

- [x] Run `flutter test` for entire project
- [x] Run `flutter analyze lib/`
- [x] Verify zero test failures
- [x] Verify zero analysis issues

**Files:** All test files

**Acceptance Criteria:**
- [x] All 400 tests pass (391 existing + 9 new)
- [x] Static analysis clean (pre-existing SDK errors only)
- [x] No regressions

---

## Phase 5: Polish

### Task 5.1: Add documentation comments [P]

- [x] Add doc comments to `_isCloudLike()` explaining cloud HSV characteristics
- [x] Add doc comment to `_cloudSkyScore()` explaining the scoring formula
- [x] Add inline comment in `_generateMask()` explaining the dual-path approach
- [x] Reference BUG-011 in comments for traceability

**Files:** `lib/services/sky_detection/auto_calibrating_sky_detector.dart`

**Acceptance Criteria:**
- [x] All new methods have doc comments
- [x] BUG-011 referenced in at least one comment
- [x] `flutter analyze lib/` still clean

---

## Phase 6: Ready for Test Agent

### Handoff Checklist

- [x] All unit tests pass (`flutter test`) -- 400 tests passing
- [x] Static analysis clean (`flutter analyze lib/`)
- [x] No regressions in existing tests
- [x] 9 new tests added (8 cloud bypass + 1 isSkyLikeColor threshold)
- [x] Code changes limited to 2 files:
  - `auto_calibrating_sky_detector.dart` (~25 lines of new code)
  - `hsv_histogram.dart` (1 line changed: 0.15 -> 0.20)
- [x] Build succeeds
- [x] implementation.md created

### Files Modified Summary

| File | Lines Changed | Change Type |
|------|---------------|-------------|
| `lib/services/sky_detection/auto_calibrating_sky_detector.dart` | ~25 new lines | Add cloud bypass methods + integrate in `_generateMask()` |
| `lib/services/sky_detection/hsv_histogram.dart` | 1 line | Threshold 0.15 -> 0.20 in `isSkyLikeColor()` |
| `test/services/sky_detection/auto_calibrating_sky_detector_test.dart` | ~80 new lines | 8 new tests in `cloud bypass scoring` group |
| `test/services/sky_detection/hsv_histogram_test.dart` | ~10 new lines | 1 new test for widened threshold |

### Device Testing Notes (for manual verification)

- Point camera at sky with white clouds
- Verify sky fraction reports >= 60% (was 29-35%)
- Verify particles render in both blue sky AND white cloud regions
- Verify no false positives on white buildings or concrete when phone tilted down
