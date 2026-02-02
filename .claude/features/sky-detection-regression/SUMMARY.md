# Sky Detection Regression Fix - Feature Summary

## Overview

Fixed critical bug (BUG-006) where sky detection calibration failed when users were under overhangs, porches, or any structure that placed non-sky colors at the top of the camera frame. The fix ensures the app correctly identifies actual sky regions even when obstructed.

**Issue:** The auto-calibrating sky detector assumed the top of the frame was always sky, which failed when porch ceilings or overhangs were visible above the user.

**Solution:** Multi-faceted approach combining sky color heuristics, multi-region sampling, reduced position bias, and manual recalibration capability.

---

## Root Cause Analysis

### Original Behavior
The `AutoCalibratingSkyDetector` calibrated by:
1. Sampling pixels from the top 20% of the frame (assuming top = sky)
2. Giving maximum weight (1.0) to pixels at the top of frame
3. Sampling from a single region only

### Failure Scenario
When standing under a porch:
- Top of frame shows brown/tan porch ceiling
- Actual sky is visible in middle/sides of frame
- Detector sampled ceiling colors as "sky"
- Resulting sky mask incorrectly identified ceiling as sky
- Particles rendered on porch ceiling instead of actual sky

---

## Changes Made

### 1. Sky Color Heuristics (`HSVHistogram`)
**File:** `lib/services/sky_detection/hsv_histogram.dart`

Added static method `isSkyLikeColor(HSV hsv)` to filter non-sky colors during calibration:

**Accepts:**
- Blue sky: Hue 180-250°, saturation 0.1-0.7, value > 0.35
- Gray/overcast sky: Saturation < 0.15, value > 0.35

**Rejects:**
- Brown/tan (porch ceilings): Hue 20-45°
- Green (foliage): Hue 80-150°
- Dark shadows: Value < 0.35
- Highly saturated colors: Saturation > 0.7

**Impact:** Prevents non-sky colors from contaminating the sky calibration histogram.

---

### 2. Multi-Region Sampling (`AutoCalibratingSkyDetector`)
**File:** `lib/services/sky_detection/auto_calibrating_sky_detector.dart`

Changed from single-region sampling to 4 regions:

| Region | Coverage | Purpose |
|--------|----------|---------|
| Top center | [0.20, 0.80, 0.05, 0.20] | Original region |
| Middle center | [0.25, 0.75, 0.30, 0.50] | Catch sky when top is obstructed |
| Top left corner | [0.05, 0.30, 0.05, 0.25] | Catch edge sky |
| Top right corner | [0.70, 0.95, 0.05, 0.25] | Catch edge sky |

All sampled pixels are filtered through `isSkyLikeColor()` before being added to the calibration set.

**Impact:** Increases the chance of finding actual sky even when the top center is obstructed by an overhang.

---

### 3. Reduced Position Weight Bias (`AutoCalibratingSkyDetector`)
**File:** `lib/services/sky_detection/auto_calibrating_sky_detector.dart`

Modified `_calculatePositionWeight()` to reduce top-of-frame bias:

**Before:**
- Top weight: 1.0 (100% confidence that top = sky)
- Bottom threshold: 0.9

**After:**
- Top weight: 0.85 (reduced confidence)
- Bottom threshold: 0.85

**Impact:** Makes color matching more influential than position. The detector relies more on actual color similarity rather than assuming "top = sky."

---

### 4. Manual Recalibration (`AutoCalibratingSkyDetector` + `ARViewScreen`)
**Files:**
- `lib/services/sky_detection/auto_calibrating_sky_detector.dart`
- `lib/screens/ar_view_screen.dart`

Added `forceRecalibrate()` method and "Recal Sky" button in debug panel:

**Method:**
- Clears histogram, last calibration time, cached mask
- Triggers fresh calibration on next frame
- Provides user escape hatch for edge cases

**UI:**
- Button in debug panel (accessible via triple-tap)
- Haptic feedback on press
- User can manually trigger recalibration when needed

**Impact:** Provides fallback mechanism for scenarios where automatic calibration fails or becomes stale.

---

## Test Coverage

### New Tests Added: 41

**HSVHistogram.isSkyLikeColor (24 tests):**
- Blue sky detection (5 tests)
- Gray/overcast sky detection (3 tests)
- Brown/tan rejection (3 tests)
- Green foliage rejection (3 tests)
- Dark shadow rejection (3 tests)
- Saturated color rejection (3 tests)
- Edge cases (4 tests)

**AutoCalibratingSkyDetector Sampling (6 tests):**
- Multi-region sampling from all 4 regions
- Sky color filtering during sampling
- Calibration success/failure scenarios

**AutoCalibratingSkyDetector Position Weight (7 tests):**
- Top weight reduced to 0.85 (not 1.0)
- Bottom threshold at 0.85
- Linear gradient calculation
- Boundary conditions

**AutoCalibratingSkyDetector Manual Recalibration (4 tests):**
- forceRecalibrate() clears state
- needsCalibration returns true after force
- Can recalibrate after force
- Safe to call on uncalibrated detector

### Test Results
- **Total tests:** 295 (254 original + 41 new)
- **Pass rate:** 100%
- **Analyzer:** No issues
- **No regressions:** All original tests still pass

---

## How to Verify the Fix

### Automated Verification (CI)
```bash
cd wind_lens
flutter test          # All 295 tests pass
flutter analyze       # No issues
```

### Manual Verification (Device Required)

#### 1. Under Porch/Overhang Test (Core Fix)
1. Build and run on iOS device
2. Stand under a porch with partial sky visible
3. Point camera toward sky (sky visible in middle, ceiling at top)
4. Enable debug panel (triple-tap screen)
5. Wait for "Sky Cal: Yes"
6. Verify particles appear ONLY in actual sky region
7. Verify porch ceiling has NO particles

**Expected:** Particles masked correctly, ceiling excluded.

#### 2. Normal Outdoor Test (Regression Check)
1. Test in open area with clear sky view
2. Point camera at sky
3. Verify calibration succeeds quickly
4. Verify particles fill sky region correctly

**Expected:** No regression from previous behavior.

#### 3. Manual Recalibration Test
1. Enable debug panel (triple-tap)
2. Tap "Recal Sky" button
3. Feel haptic feedback
4. Point camera at actual sky
5. Verify "Sky Cal: Yes" appears
6. Verify particles update to correct region

**Expected:** Manual recalibration works, haptic feedback present.

#### 4. Performance Test
1. Check FPS in debug panel
2. Verify FPS >= 45
3. Monitor during calibration

**Expected:** No performance regression from previous optimization.

---

## Files Modified

### Production Code (3 files)
1. `wind_lens/lib/services/sky_detection/hsv_histogram.dart` (+25 lines)
   - Added `isSkyLikeColor()` static method
2. `wind_lens/lib/services/sky_detection/auto_calibrating_sky_detector.dart` (~100 lines modified)
   - Multi-region sampling constants
   - Updated `_samplePixelsBGRA()` for multi-region + filtering
   - Updated `_samplePixelsYUV()` for multi-region + filtering
   - Reduced position weight from 1.0 to 0.85
   - Added `forceRecalibrate()` method
   - Added `getPositionWeight()` getter for testing
3. `wind_lens/lib/screens/ar_view_screen.dart` (+25 lines)
   - Added "Recal Sky" button to debug panel
   - Added `_onRecalibratePressed()` handler with haptic feedback

### Test Code (2 files)
1. `wind_lens/test/services/sky_detection/hsv_histogram_test.dart` (+130 lines)
   - 24 new tests for sky color heuristics
2. `wind_lens/test/services/sky_detection/auto_calibrating_sky_detector_test.dart` (+100 lines)
   - 17 new tests for sampling, position weight, and manual recalibration

---

## Edge Cases Handled

### 1. Overcast Sky with Bright Ceiling
- Sky color heuristics accept gray/overcast sky (low saturation)
- Multi-region sampling increases chances of finding actual sky
- Validated via unit tests

### 2. Sunset/Sunrise Colors Near Hue Boundary
- Edge case tests cover hue boundary conditions (hue 180° boundary)
- Validated via unit tests

### 3. Insufficient Sky-Like Samples
- Minimum sample threshold of 10 sky-like samples required
- Calibration fails gracefully if not enough sky samples found
- Debug logging added for troubleshooting
- Validated via unit tests

### 4. User Under Tree Canopy
- Green foliage (hue 80-150°) rejected by sky color heuristics
- Multi-region sampling helps find sky gaps in foliage
- Manual recalibration provides escape hatch

---

## Performance Impact

- **Multi-region sampling overhead:** Minimal - samples are still strided (every 10th pixel)
- **Sky color filtering overhead:** Negligible - simple HSV threshold checks
- **Test suite performance:** 295 tests run in ~3 seconds
- **Runtime FPS:** Device testing required to confirm FPS >= 45 maintained

---

## Known Limitations

### Requires Device Testing
The following scenarios cannot be validated in CI and require physical device testing:
- Actual porch/overhang scenario with real camera feed
- Manual recalibration with actual sky
- FPS performance during operation
- Color-based sky detection accuracy in varying lighting conditions

### Not Covered by This Fix
- Indoor ceiling lights (expected failure - no actual sky visible)
- Extremely low light conditions (existing limitation)
- Rapid camera motion during calibration (existing limitation)

---

## Related Issues

- **Closes:** BUG-006 (Sky detection fails under porch/overhang)
- **Depends on:** Performance optimization (BUG-005) - FPS baseline of 45+ required
- **Relates to:** Auto-calibrating sky detection (MVP feature)

---

## Next Steps

1. Deploy to test device for manual validation
2. Test all 4 manual verification scenarios above
3. If device tests pass, mark BUG-006 as resolved
4. Monitor for user feedback on edge cases
5. Consider ML-based sky detection (Level 3) if heuristics insufficient

---

## Rollback Plan

If this fix causes issues, phases can be rolled back independently:

1. **Phase 1 (Heuristics):** Remove `isSkyLikeColor` filter, sample all colors
2. **Phase 2 (Multi-region):** Revert to single top-region sampling
3. **Phase 3 (Position weight):** Restore original 1.0 top weight
4. **Phase 4 (Recal button):** Remove button from UI

Each phase was implemented with clear boundaries for targeted rollback.

---

## References

- Research: `.claude/features/sky-detection-regression/2026-02-02T23:15_research.md`
- Plan: `.claude/features/sky-detection-regression/2026-02-02T23:15_plan.md`
- Tasks: `.claude/features/sky-detection-regression/tasks.md`
- Implementation: `.claude/active-work/sky-detection-regression/implementation.md`
- Test Report: `.claude/active-work/sky-detection-regression/test-success.md`
