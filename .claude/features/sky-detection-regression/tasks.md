# Tasks: sky-detection-regression (BUG-006)

## Metadata
- **Feature:** sky-detection-regression
- **Created:** 2026-02-02T23:15
- **Status:** implement-complete
- **Based On:** 2026-02-02T23:15_plan.md
- **Severity:** Critical

---

## Execution Rules

1. **Complete phases in order** - Each phase depends on the previous
2. **[P] marks parallelizable tasks** - Tasks without [P] MUST be sequential
3. **TDD approach** - Write tests BEFORE implementation where noted
4. **Run tests after each task** - `flutter test` must pass before proceeding
5. **DO NOT break existing functionality** - All 254 tests must pass

---

## Phase 1: Sky Color Heuristics

> Goal: Add validation that sampled colors are sky-like (blue/gray, bright, uniform)

### Task 1.1: Write Tests for Sky Color Detection
- [x] Add test: `isSkyLikeColor returns true for blue sky HSV`
- [x] Add test: `isSkyLikeColor returns true for gray overcast HSV`
- [x] Add test: `isSkyLikeColor returns false for brown/tan HSV`
- [x] Add test: `isSkyLikeColor returns false for green foliage HSV`
- [x] Add test: `isSkyLikeColor returns false for dark shadows HSV`
- [x] Add test: `isSkyLikeColor returns false for saturated colors HSV`
- [x] Run `flutter test` (tests will fail - TDD)

**Files:** `wind_lens/test/services/sky_detection/hsv_histogram_test.dart`

**Acceptance Criteria:**
- [x] 6+ new tests written for isSkyLikeColor (24 tests added)
- [x] Tests fail initially (method doesn't exist yet)

---

### Task 1.2: Implement isSkyLikeColor Static Method
- [x] Add `isSkyLikeColor(HSV hsv)` static method to HSVHistogram class
- [x] Implement blue sky detection (hue 180-250, moderate saturation)
- [x] Implement gray sky detection (low saturation, high value)
- [x] Implement rejection for brown/tan/green/dark colors
- [x] Run `flutter test`

**Files:** `wind_lens/lib/services/sky_detection/hsv_histogram.dart`

**Specific Implementation:**
```dart
/// Returns true if the HSV color is consistent with sky appearance.
///
/// Sky colors include:
/// - Blue sky: Hue 180-250, moderate saturation (0.1-0.7), bright (V > 0.35)
/// - Gray/overcast: Low saturation (< 0.15), bright (V > 0.35)
///
/// Rejects:
/// - Brown/tan (porch ceilings): Hue 20-45
/// - Green (foliage): Hue 80-150
/// - Dark colors (shadows): V < 0.35
/// - Highly saturated colors: S > 0.7
static bool isSkyLikeColor(HSV hsv) {
  // Very low saturation = gray (overcast sky, clouds)
  if (hsv.s < 0.15) {
    return hsv.v >= 0.35; // Gray but not too dark
  }

  // Blue sky range
  final isBlueHue = hsv.h >= 180 && hsv.h <= 250;
  final isReasonableSaturation = hsv.s >= 0.1 && hsv.s <= 0.7;
  final isBright = hsv.v >= 0.35;

  return isBlueHue && isReasonableSaturation && isBright;
}
```

**Acceptance Criteria:**
- [x] Method implemented
- [x] All 6+ sky color tests pass (24 tests pass)
- [x] All existing tests still pass

---

## Phase 2: Multi-Region Sampling

> Goal: Sample from multiple regions instead of just the top

### Task 2.1: Write Tests for Multi-Region Sampling
- [x] Add test: `calibration samples from top center region`
- [x] Add test: `calibration samples from middle center region`
- [x] Add test: `calibration samples from top corners`
- [x] Add test: `calibration filters non-sky samples`
- [x] Add test: `calibration succeeds with only sky-like samples`
- [x] Run `flutter test` (tests will fail - TDD)

**Files:** `wind_lens/test/services/sky_detection/auto_calibrating_sky_detector_test.dart`

**Acceptance Criteria:**
- [x] 5+ new tests for multi-region sampling (6 tests added)
- [x] Tests cover filtering behavior

---

### Task 2.2: Add Sampling Region Constants
- [x] Define sampling region boundaries as constants
- [x] Document each region's purpose
- [x] Run `flutter test`

**Files:** `wind_lens/lib/services/sky_detection/auto_calibrating_sky_detector.dart`

**Specific Implementation (add after line 90):**
```dart
// ============= Multi-Region Sampling Configuration =============

/// Regions to sample during calibration.
/// Each region is defined as (startX, endX, startY, endY) fractions.
static const List<List<double>> _samplingRegions = [
  [0.20, 0.80, 0.05, 0.20],  // Top center (original)
  [0.25, 0.75, 0.30, 0.50],  // Middle center (new)
  [0.05, 0.30, 0.05, 0.25],  // Top left corner (new)
  [0.70, 0.95, 0.05, 0.25],  // Top right corner (new)
];
```

**Acceptance Criteria:**
- [x] Constants added
- [x] All tests pass

---

### Task 2.3: Implement Multi-Region Sampling for BGRA (iOS)
- [x] Modify `_samplePixelsBGRA` to sample from all regions
- [x] Apply `HSVHistogram.isSkyLikeColor` filter to samples
- [x] Collect filtered samples into the list
- [x] Run `flutter test`

**Files:** `wind_lens/lib/services/sky_detection/auto_calibrating_sky_detector.dart`

**Specific Changes to _samplePixelsBGRA (lines 272-303):**
```dart
void _samplePixelsBGRA(
  CameraImage image,
  int width,
  int height,
  List<HSV> samples,
) {
  final bytes = image.planes[0].bytes;
  final bytesPerRow = image.planes[0].bytesPerRow;

  // Sample from multiple regions
  for (final region in _samplingRegions) {
    final startX = (width * region[0]).floor();
    final endX = (width * region[1]).floor();
    final startY = (height * region[2]).floor();
    final endY = (height * region[3]).floor();

    // Sample every 10th pixel for speed
    const stride = 10;

    for (int y = startY; y < endY; y += stride) {
      for (int x = startX; x < endX; x += stride) {
        final idx = y * bytesPerRow + x * 4;
        if (idx + 3 >= bytes.length) continue;

        // BGRA format
        final b = bytes[idx];
        final g = bytes[idx + 1];
        final r = bytes[idx + 2];

        final hsv = ColorUtils.rgbToHsv(r, g, b);

        // Filter: only keep sky-like colors
        if (HSVHistogram.isSkyLikeColor(hsv)) {
          samples.add(hsv);
        }
      }
    }
  }
}
```

**Acceptance Criteria:**
- [x] Multi-region sampling implemented for BGRA
- [x] Sky-like filtering applied
- [x] All tests pass

---

### Task 2.4: [P] Implement Multi-Region Sampling for YUV (Android)
- [x] Modify `_samplePixelsYUV` with same multi-region logic
- [x] Apply `HSVHistogram.isSkyLikeColor` filter
- [x] Run `flutter test`

**Files:** `wind_lens/lib/services/sky_detection/auto_calibrating_sky_detector.dart`

**Specific Changes to _samplePixelsYUV (lines 305-350):**
Apply same multi-region and filtering logic as Task 2.3.

**Acceptance Criteria:**
- [x] Multi-region sampling implemented for YUV
- [x] Sky-like filtering applied
- [x] All tests pass

---

### Task 2.5: Update Calibration Minimum Sample Check
- [x] Increase minimum samples or add sky-sample minimum
- [x] Add debug logging for filtered sample count
- [x] Run `flutter test`

**Files:** `wind_lens/lib/services/sky_detection/auto_calibrating_sky_detector.dart`

**Specific Changes (around line 257):**
```dart
if (samples.length < 10) {
  if (kDebugMode) {
    debugPrint('Sky calibration: insufficient sky-like samples (${samples.length})');
  }
  return;
}
```

**Acceptance Criteria:**
- [x] Minimum sample check updated
- [x] Debug logging added
- [x] All tests pass

---

## Phase 3: Reduce Position Weight Bias

> Goal: Make color matching more important than position

### Task 3.1: Write Tests for Position Weight
- [x] Add test: `position weight at top (0.0) returns 0.85 (not 1.0)`
- [x] Add test: `position weight at middle (0.5) returns reasonable value`
- [x] Add test: `position weight at bottom (0.9) returns near zero`
- [x] Run `flutter test` (tests may fail - need to expose method)

**Files:** `wind_lens/test/services/sky_detection/auto_calibrating_sky_detector_test.dart`

**Acceptance Criteria:**
- [x] Tests for new position weight behavior (7 tests added)

---

### Task 3.2: Modify Position Weight Calculation
- [x] Reduce top weight from 1.0 to 0.85
- [x] Adjust ramp to span 0.2-0.85 of frame
- [x] Run `flutter test`

**Files:** `wind_lens/lib/services/sky_detection/auto_calibrating_sky_detector.dart`

**Specific Changes (lines 420-427):**
```dart
/// Calculates position-based sky prior.
///
/// Returns higher weight for top of frame, lower for bottom.
/// Reduced top bias (0.85 instead of 1.0) to rely more on color matching.
double _calculatePositionWeight(double normalizedY) {
  // Reduced top bias - don't assume top is always sky
  if (normalizedY < 0.2) return 0.85;  // Was 1.0
  if (normalizedY > 0.85) return 0.0;  // Was 0.9

  // Linear ramp from 0.85 at y=0.2 to 0.0 at y=0.85
  return 0.85 - (normalizedY - 0.2) / 0.65 * 0.85;
}
```

**Acceptance Criteria:**
- [x] Position weight reduced for top
- [x] All tests pass
- [x] Color matching more influential

---

## Phase 4: Manual Recalibration

> Goal: Allow user to force recalibration via UI

### Task 4.1: Write Tests for Force Recalibrate
- [x] Add test: `forceRecalibrate clears histogram`
- [x] Add test: `forceRecalibrate clears last calibration time`
- [x] Add test: `needsCalibration returns true after forceRecalibrate`
- [x] Run `flutter test` (tests will fail - TDD)

**Files:** `wind_lens/test/services/sky_detection/auto_calibrating_sky_detector_test.dart`

**Acceptance Criteria:**
- [x] 3 tests for forceRecalibrate method (4 tests added)

---

### Task 4.2: Implement forceRecalibrate Method
- [x] Add `forceRecalibrate()` public method
- [x] Clear `_skyHistogram`
- [x] Clear `_lastCalibration`
- [x] Clear `_cachedMask`
- [x] Run `flutter test`

**Files:** `wind_lens/lib/services/sky_detection/auto_calibrating_sky_detector.dart`

**Specific Implementation (add after line 173):**
```dart
/// Forces immediate recalibration from the next camera frame.
///
/// Call this when the user requests manual recalibration.
/// The detector will recalibrate on the next frame with sufficient pitch.
/// User should point the camera at actual sky for best results.
void forceRecalibrate() {
  _skyHistogram = null;
  _lastCalibration = null;
  _cachedMask = null;
  _cachedSkyFraction = 0.0;

  if (kDebugMode) {
    debugPrint('Sky calibration: forced recalibration requested');
  }
}
```

**Acceptance Criteria:**
- [x] Method implemented
- [x] All tests pass
- [x] State correctly cleared

---

### Task 4.3: Add Recalibrate Button to Debug Panel
- [x] Add "Recal Sky" button to debug panel in ARViewScreen
- [x] Wire button to call `_skyDetector.forceRecalibrate()`
- [x] Add haptic feedback on tap
- [x] Run `flutter test`

**Files:** `wind_lens/lib/screens/ar_view_screen.dart`

**Specific Changes (in _buildDebugPanel, around line 300):**
```dart
Widget _buildDebugPanel() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ... existing debug text rows ...
        _buildDebugText('Particles: $_currentParticleCount'),
        const SizedBox(height: 8),
        // NEW: Recalibrate button
        GestureDetector(
          onTap: _onRecalibratePressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Recal Sky',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

void _onRecalibratePressed() {
  HapticFeedback.mediumImpact();
  _skyDetector.forceRecalibrate();
}
```

**Acceptance Criteria:**
- [x] Button added to debug panel
- [x] Button calls forceRecalibrate
- [x] Haptic feedback works
- [x] All tests pass

---

## Phase 5: Verification & Testing

> Goal: Verify fix works on device, no regressions

### Task 5.1: Run Full Test Suite
- [x] Run `flutter test`
- [x] Verify all tests pass (254+)
- [x] Run `flutter analyze` for warnings
- [x] Fix any issues

**Files:** All test files

**Acceptance Criteria:**
- [x] All tests pass (295 tests: 254 original + 41 new)
- [x] No analyzer warnings in modified files

---

### Task 5.2: Device Test - Under Porch/Overhang
- [ ] Build and run on iOS device
- [ ] Stand under porch/overhang
- [ ] Point phone toward sky (sky visible in middle of frame)
- [ ] Verify particles appear ONLY in actual sky region
- [ ] Verify porch ceiling has NO particles
- [ ] Document results

**Files:** None (device testing)

**Acceptance Criteria:**
- [ ] Particles masked correctly under overhang
- [ ] Porch ceiling excluded from particle region

---

### Task 5.3: Device Test - Normal Outdoor
- [ ] Test in open outdoor area (no overhead obstruction)
- [ ] Point phone at sky
- [ ] Verify calibration succeeds
- [ ] Verify particles fill sky region correctly
- [ ] Verify no regression from previous behavior

**Files:** None (device testing)

**Acceptance Criteria:**
- [ ] Normal outdoor conditions work correctly
- [ ] No regression

---

### Task 5.4: Device Test - Manual Recalibration
- [ ] Enable debug panel (3-finger tap or DBG button)
- [ ] Tap "Recal Sky" button
- [ ] Point camera at actual sky
- [ ] Verify calibration resets and succeeds
- [ ] Verify particles update to correct sky region

**Files:** None (device testing)

**Acceptance Criteria:**
- [ ] Manual recalibration works
- [ ] User can correct bad calibration

---

### Task 5.5: Performance Verification
- [ ] Check FPS in debug panel during operation
- [ ] Verify FPS >= 45 (no regression from performance optimization)
- [ ] Verify processFrame() performance acceptable

**Files:** None (device testing)

**Acceptance Criteria:**
- [ ] FPS >= 45 maintained
- [ ] No performance regression

---

### Task 5.6: Update Implementation Notes
- [ ] Document all changes made
- [ ] Document test results
- [ ] Note any edge cases discovered
- [ ] Mark feature ready for finalize

**Files:** `.claude/active-work/sky-detection-regression/implementation.md`

**Acceptance Criteria:**
- [ ] Implementation documented
- [ ] Test results documented

---

## Handoff Checklist for Test Agent

Before running `/test sky-detection-regression`:

- [ ] All tasks in Phases 1-4 completed
- [ ] All unit tests passing (254+)
- [ ] Phase 5 device tests completed
- [ ] No regressions in normal sky detection
- [ ] Manual recalibration button functional

---

## Rollback Plan

If fix causes issues:

1. **Phase 1 (Heuristics):** Remove isSkyLikeColor filter, return to sampling all colors
2. **Phase 2 (Multi-region):** Revert to single top-region sampling
3. **Phase 3 (Position weight):** Restore original 1.0 top weight
4. **Phase 4 (Recal button):** Remove button from UI

Each phase committed separately for targeted rollback:
```bash
git revert <commit-hash>
```

---

## Summary

| Phase | Tasks | Purpose |
|-------|-------|---------|
| 1. Sky Heuristics | 2 | Filter non-sky colors from calibration |
| 2. Multi-Region | 5 | Sample from multiple frame regions |
| 3. Position Weight | 2 | Reduce top-of-frame bias |
| 4. Manual Recal | 3 | User-triggered recalibration |
| 5. Verification | 6 | Device testing and documentation |
| **Total** | **18 tasks** | **Fix under-overhang scenario** |

---

## Expected Outcome

After implementation:
1. Standing under a porch, particles will appear ONLY in the actual sky region (middle of frame)
2. Porch ceiling will be correctly excluded from the sky mask
3. User can tap "Recal Sky" to manually trigger recalibration
4. Normal outdoor conditions continue to work correctly
5. Performance (FPS >= 45) maintained
