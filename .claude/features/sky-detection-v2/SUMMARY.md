# Feature Summary: Sky Detection Level 2a (Auto-Calibrating)

## Overview

Implemented Level 2a auto-calibrating sky detection for Wind Lens, upgrading from simple pitch-based detection to intelligent color-based sky recognition. The system learns sky colors from camera frames and uses HSV color space analysis to distinguish actual sky from ceilings, buildings, and other non-sky objects.

## Problem Solved

The original pitch-based sky detection (Level 1) had critical limitations:
- Detected indoor ceilings as "sky" when phone tilted up
- Ignored actual blue sky at low tilt angles
- No per-pixel understanding of what is actually sky
- Resulted in unrealistic particle rendering

## Solution Implemented

Created a self-calibrating color-based detector that:
1. Samples sky colors when phone points up (pitch > 45 degrees)
2. Builds statistical HSV profile with mean, standard deviation, and percentile ranges
3. Scores each camera pixel as sky/not-sky based on learned profile
4. Auto-recalibrates every 5 minutes to adapt to lighting changes
5. Falls back to pitch-based detection when not calibrated

## Architecture

```
ARViewScreen
    |
    +--> CameraView (onFrame callback)
    |        |
    |        v
    |    AutoCalibratingSkyDetector
    |        |
    |        +--> HSVHistogram (learned sky profile)
    |        |        |
    |        |        v
    |        |    ColorUtils.rgbToHsv()
    |        |
    |        +--> PitchBasedSkyMask (fallback)
    |
    +--> ParticleOverlay (uses detector as SkyMask)
```

## Components Created

### Models
- **HSV** (`lib/models/hsv.dart`) - HSV color space representation with hue (0-360), saturation (0-1), value (0-1)

### Utilities
- **ColorUtils** (`lib/utils/color_utils.dart`) - RGB to HSV conversion with support for both iOS BGRA and Android YUV420 image formats

### Services
- **HSVHistogram** (`lib/services/sky_detection/hsv_histogram.dart`) - Statistical sky color profile using Gaussian scoring with percentile-based outlier exclusion
- **AutoCalibratingSkyDetector** (`lib/services/sky_detection/auto_calibrating_sky_detector.dart`) - Main detector managing calibration lifecycle, mask generation, and SkyMask interface implementation

### Integration
- **CameraView** (`lib/widgets/camera_view.dart`) - Added image streaming support to provide camera frames to detector
- **ARViewScreen** (`lib/screens/ar_view_screen.dart`) - Integrated detector with camera callbacks and debug panel

## Key Implementation Details

### Calibration Strategy
- Triggers when pitch > 45 degrees AND `processFrame()` called
- Samples top 10-40% of camera frame (sky region)
- Samples every 10th pixel (~1,200 samples) for performance
- Uses 5th and 95th percentiles to exclude outliers (clouds, birds, buildings)

### Detection Algorithm
- Downscales frame to 128x96 for processing (12,288 pixels)
- For each pixel:
  - Convert to HSV color space
  - Calculate position weight (sky prior based on y-coordinate)
  - Calculate color match score using Gaussian distribution
  - Combined score = colorScore × positionWeight
  - Mark as sky if score > 0.4 threshold
- Skips bottom 20% of frame (position weight < 0.2)

### Performance Optimizations
- Pre-allocated mask buffer (single allocation, reused)
- Downscaling reduces pixel processing from full resolution
- Position-based early skip for lower frame regions
- Minimum std dev threshold prevents division by zero

### Platform Support
- **iOS**: BGRA image format handling
- **Android**: YUV420 image format with color space conversion

### Fallback Behavior
- Before calibration: Uses PitchBasedSkyMask (original Level 1 behavior)
- Ensures app always functional, even before first calibration
- Seamless transition to color-based detection after calibration

## Testing

### Test Coverage
- **Total Tests:** 236 (70 new, 166 existing)
- **Test Success Rate:** 100%
- **Flutter Analyze:** 0 issues

### New Tests Breakdown
- HSV Model: 13 tests - Construction, edge cases, equality
- ColorUtils: 14 tests - RGB to HSV conversion for pure colors, achromatic colors, sky blue
- HSVHistogram: 16 tests - Sample processing, match scoring, percentile calculation, edge cases
- AutoCalibratingSkyDetector: 27 tests - Calibration lifecycle, fallback behavior, SkyMask interface compliance, state transitions

### Test Scenarios Validated
1. **Calibration Flow:**
   - Initial uncalibrated state with fallback
   - Calibration trigger conditions
   - Manual calibration for testing
   - Recalibration after 5 minutes

2. **Detection Accuracy:**
   - HSV conversion accuracy for all primary colors
   - Histogram building from varied samples
   - Match scoring (1.0 for exact match, 0.0 for outliers)
   - Percentile-based outlier exclusion

3. **Fallback Behavior:**
   - Pre-calibration pitch-based detection
   - Post-calibration color-based detection
   - Seamless state transitions

4. **SkyMask Interface:**
   - skyFraction returns valid range (0.0-1.0)
   - isPointInSky handles edge cases (negative coords, > 1.0)
   - Interface compliance for ParticleOverlay integration

## Files Changed

### New Files (8 files)
| File | Lines | Purpose |
|------|-------|---------|
| `lib/models/hsv.dart` | 35 | HSV color model |
| `lib/utils/color_utils.dart` | 85 | Color conversion utilities |
| `lib/services/sky_detection/hsv_histogram.dart` | 165 | Statistical sky profile |
| `lib/services/sky_detection/auto_calibrating_sky_detector.dart` | 330 | Main detector implementation |
| `test/models/hsv_test.dart` | 105 | HSV model tests (13) |
| `test/utils/color_utils_test.dart` | 110 | Color utilities tests (14) |
| `test/services/sky_detection/hsv_histogram_test.dart` | 175 | Histogram tests (16) |
| `test/services/sky_detection/auto_calibrating_sky_detector_test.dart` | 230 | Detector tests (27) |

### Modified Files (2 files)
| File | Changes |
|------|---------|
| `lib/widgets/camera_view.dart` | Added image streaming support |
| `lib/screens/ar_view_screen.dart` | Integrated AutoCalibratingSkyDetector, added calibration status to debug panel |

## Metrics

- **Lines Added:** ~1,440
- **Tests Added:** 70
- **Test Success Rate:** 100% (236/236 passing)
- **Code Quality:** 0 flutter analyze issues
- **Performance Target:** < 16ms per frame (requires real device validation)

## Manual Testing Required

While all automated tests pass, the following requires physical device testing:

### Critical Tests
- [ ] App launches without crash on iOS device
- [ ] App launches without crash on Android device
- [ ] Camera preview displays correctly on both platforms
- [ ] Point phone up at sky (pitch > 45), verify "Sky Cal: Yes" in debug panel
- [ ] Verify particles appear in sky regions only after calibration
- [ ] Monitor FPS (target: 60 FPS maintained)

### Platform-Specific Tests
- [ ] iOS: Verify BGRA image format handling
- [ ] Android: Verify YUV420 image format handling
- [ ] Both: Verify processFrame() < 16ms

### Calibration Scenarios
- [ ] Clear blue sky: High sky fraction after calibration
- [ ] Indoor ceiling: Lower sky fraction, different color profile
- [ ] Mixed scene (sky + buildings): Partial masking works correctly
- [ ] Wait 5 minutes: Verify recalibration triggers

### Performance Tests
- [ ] Monitor FPS during operation (target: 60 FPS)
- [ ] Verify no frame drops during calibration
- [ ] Verify no memory leaks over 10+ minutes of use

## Impact

### User-Facing Improvements
- Accurate sky detection indoors vs outdoors
- Particles only appear where actual sky is visible
- Adapts to changing lighting conditions automatically
- More realistic AR experience

### Technical Improvements
- Cross-platform image format support
- Performance-optimized frame processing
- Robust statistical approach with outlier handling
- Clean SkyMask interface for future enhancements

### Foundation for Future Work
This implementation provides the foundation for:
- BUG-003: Per-pixel particle masking (depends on this feature)
- Level 2b: Integral images for uniformity checking
- Level 3: ML-based sky segmentation (if needed)

## Next Steps

1. **Real Device Testing:** Validate on physical iOS and Android devices
2. **Performance Validation:** Confirm < 16ms frame processing time
3. **Integration with Particle Masking:** Use detector for per-pixel particle rendering (BUG-003)
4. **User Feedback:** Test in various lighting conditions and environments

## Conclusion

Successfully implemented Level 2a auto-calibrating sky detection as specified in MVP requirements. The system provides intelligent color-based sky recognition with automatic adaptation to lighting conditions, while maintaining backward compatibility through fallback behavior. All automated quality gates passed (236 tests, 0 analyze issues), ready for real device validation.

---

**Status:** Implementation Complete, Ready for Device Testing
**Pipeline:** `/research` → `/plan` → `/implement` → `/test` → `/finalize` ✓
**Issue:** BUG-002 (Sky Detection Level 2a Auto-Calibrating) - RESOLVED
