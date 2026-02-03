# Post-MVP Issues Tracker

> **Purpose:** Track bugs and gaps discovered during real-device testing.
> Each issue goes through the pipeline: `/diagnose` → `/plan` → `/implement` → `/test`

---

## Summary

| ID | Issue | Severity | Status | Spec Section |
|----|-------|----------|--------|--------------|
| BUG-001 | Debug panel missing | Medium | **DONE** | Section 10 |
| BUG-002 | Sky detection pitch-only (no color masking) | **Critical** | **DONE** | Section 3 |
| BUG-002.5 | Sky detection not working on real device | **Critical** | **DONE** | Section 3 |
| BUG-003 | Particles not masked to sky pixels | **Critical** | **DONE** | Section 4 |
| BUG-004 | Wind animation not world-fixed | High | **DONE** | Section 5 |
| BUG-005 | Altitude slider UX (buttons vs slider) | Low | **DONE** | Section 7 |
| BUG-006 | Sky detection regression (particles on porch ceiling) | **Critical** | **DONE** | Section 3 |
| BUG-007 | Streamline ghosting (ghost trails on respawn) | **Critical** | **DONE** | Section 4 |

---

## Issue Details

### BUG-001: Debug Panel Missing

**Severity:** Medium
**Status:** DONE (2026-01-21)
**Spec Reference:** MVP Spec Section 10 - Debug Panel

**Expected Behavior:**
- 3-finger tap toggles debug panel visibility
- Shows: FPS, particle count, heading, pitch, sky fraction, device orientation

**Actual Behavior (BEFORE FIX):**
- No debug panel visible
- No toggle button or gesture
- User cannot see compass heading or any debug info

**User Report:**
> "I do not see a compass anywhere that is updating as i turn the phone. I only see the heading of the wind. there is no debug panel/button either."

**Fix Implemented:**
- Added "DBG" toggle button in top-left corner (40x40 pixels, semi-transparent)
- Button toggles debug panel visibility with haptic feedback
- Debug panel displays 7 metrics: Heading, Pitch, Sky%, Altitude, Wind, FPS, Particles
- Maintained backward compatibility with 3-finger gesture
- All 166 tests passing, flutter analyze clean

**Pipeline:** `/diagnose debug-panel` → `/plan` → `/implement` → `/test` → `/finalize` ✓

---

### BUG-002: Sky Detection Pitch-Only (No Color Masking)

**Severity:** Critical
**Status:** DONE (2026-01-21)
**Spec Reference:** MVP Spec Section 3 - Sky Detection

**Expected Behavior:**
- Level 1 (pitch) for initial testing
- Level 2a (auto-calibrating color) RECOMMENDED for real use
- App samples sky colors and builds HSV profile
- Detects actual sky pixels vs buildings/trees/ceiling

**Actual Behavior:**
- Only Level 1 pitch-based implemented
- Ceiling detected as "sky" indoors
- Blue sky outdoors ignored until phone tilted high enough
- No actual pixel-level sky detection

**User Report:**
> "when i tilt straight up it thinks its the sky but i did it in my room and it thought my ceiling was the sky. when i point it outside to the sky it ignores lots of blue until i tilt high enough"

**Root Cause (confirmed):**
- Level 2a auto-calibrating detection was planned in research but not implemented
- Current implementation just uses pitch angle to calculate a skyFraction threshold

**Fix Implemented:**
- Implemented Level 2a auto-calibrating sky detection with HSV color analysis
- System samples sky colors from top 10-40% of frame when pitch > 45 degrees
- Builds statistical HSV histogram profile (mean, std dev, percentiles)
- Scores each pixel as sky/not-sky based on learned profile
- Auto-recalibrates every 5 minutes for lighting changes
- Falls back to pitch-based detection when not calibrated
- Cross-platform support (iOS BGRA, Android YUV420)
- 70 new tests added (236 total passing), flutter analyze clean
- Performance optimized: downscaling to 128x96, pre-allocated mask buffer

**Components Created:**
- `lib/models/hsv.dart` - HSV color model
- `lib/utils/color_utils.dart` - RGB/YUV to HSV conversion
- `lib/services/sky_detection/hsv_histogram.dart` - Statistical sky profile
- `lib/services/sky_detection/auto_calibrating_sky_detector.dart` - Main detector
- 4 test files with 70 comprehensive tests

**Pipeline:** `/diagnose sky-detection` → `/plan` → `/implement` → `/test` → `/finalize` ✓

---

### BUG-002.5: Sky Detection Not Working on Real Device

**Severity:** Critical
**Status:** DONE (2026-01-22)
**Spec Reference:** MVP Spec Section 3 - Sky Detection

**Expected Behavior:**
- Sky detection should work at various phone angles (not just pointing straight up)
- Should detect actual sky pixels based on color, not just pitch angle
- Particles should appear where sky is visible in camera feed
- When pointing down, no particles (correct)

**Actual Behavior (BEFORE FIX):**
- Sky detection doesn't recognize sky at all
- Phone has to be pointed nearly straight up to see particles
- Color-based detection not triggering on real device
- System stuck in pitch-based fallback mode

**User Report:**
> "sky detection does not work whatsoever anymore. a phone does not need to be pointed directly up to see particles. obviously if its pointing down it shouldn't show any particles. but it should be searching for where the sky is."

**Root Cause (confirmed):**
- Calibration threshold of 45 degrees was too high for natural viewing angles
- Users typically view sky at 20-40 degree angles
- Calibration never triggered during normal use
- Color-based detection remained inactive

**Fix Implemented:**
- Lowered calibration threshold from 45 to 25 degrees
- Changed sample region top from 10% to 5% (safer at lower angles)
- Added dynamic sample region based on pitch angle:
  - 60+ degrees: sample top 5-50% (looking high up)
  - 45-59 degrees: sample top 5-40% (original behavior)
  - 35-44 degrees: sample top 5-30% (moderate angle)
  - 25-34 degrees: sample top 5-20% (conservative)
  - <25 degrees: sample top 5-15% (very conservative)
- 8 new tests added (250 total passing), flutter analyze clean

**Components Modified:**
- `lib/services/sky_detection/auto_calibrating_sky_detector.dart`
- `test/services/sky_detection/auto_calibrating_sky_detector_test.dart`

**Pipeline:** `/diagnose sky-detection-v2` → `/plan` → `/implement` → `/test` → `/finalize` ✓

---

### BUG-003: Particles Not Masked to Sky Pixels

**Severity:** Critical
**Status:** **DONE** (2026-01-21)
**Spec Reference:** MVP Spec Section 1, 4

**Expected Behavior:**
- Spec: "overlays flowing wind particles ONLY in the sky region — not on buildings, trees, or ground"
- Particles should render ONLY where sky pixels are detected
- Per-pixel masking based on sky detection

**Actual Behavior:**
- Particles render in entire top portion of screen above threshold line
- No per-pixel masking
- Particles appear "on the phone" not "in the sky"
- Looks like a video playing on screen

**User Report:**
> "the particle system seems good, but it still looks like it's on the phone instead of the sky far away. if we mask the sky and only draw where the sky is it should work"

**Root Cause (suspected):**
- Particles use `isPointInSky(normalizedY)` which only checks Y position
- No actual sky mask being applied to particle rendering
- Depends on BUG-002 being fixed first (need real sky detection)

**Pipeline:** `/diagnose particle-masking` → `/plan` → `/implement`
**Blocked by:** BUG-002

---

### BUG-004: Wind Animation Not World-Fixed

**Severity:** High
**Status:** **DONE** (2026-01-22)
**Spec Reference:** MVP Spec Section 5, 11 - Compass Integration

**Expected Behavior:**
- Particles should feel anchored to the real sky
- When you rotate phone, particles should stay in place (world-fixed)
- All altitude levels should shift equally when phone rotates
- Formula: particles shift by `(headingDelta / 360.0)` of screen width

**Actual Behavior (BEFORE FIX):**
- Surface particles (parallax 1.0) were 100% world-fixed (correct)
- Mid-level particles (parallax 0.6) were only 60% world-fixed (broken)
- Jet stream particles (parallax 0.3) were only 30% world-fixed (broken)
- Higher altitude particles felt "stuck to screen" instead of anchored in world space

**User Report:**
> "wind animation seems like a video playing on top of my screen, it doesn't stay consistent as i move my phone around"

**Root Cause (confirmed):**
- Original formula conflated world anchoring with parallax depth:
  ```dart
  p.x -= (headingDelta / 360.0) * parallaxFactor;
  ```
- parallaxFactor varied by altitude (1.0, 0.6, 0.3)
- This meant jet stream particles only shifted 30% when they should shift 100%

**Fix Implemented:**
- Changed formula to apply 100% world anchoring for ALL altitude levels:
  ```dart
  p.x -= (headingDelta / 360.0);
  ```
- Depth perception now achieved through other visual cues:
  - Particle color (white → cyan → purple)
  - Trail scale (1.0 → 0.7 → 0.5)
  - Speed multiplier (1.0x → 1.5x → 3.0x)
- 3 new tests added (253 total passing), flutter analyze clean

**Components Modified:**
- `lib/widgets/particle_overlay.dart` - Fixed world anchoring formula (line 269)
- `lib/models/altitude_level.dart` - Updated parallaxFactor documentation
- `test/widgets/particle_overlay_test.dart` - Added 3 world anchoring tests

**Pipeline:** `/diagnose wind-anchoring` → `/plan` → `/implement` → `/test` → `/finalize` ✓

---

### BUG-005: Altitude Slider UX

**Severity:** Low
**Status:** DONE (2026-01-22)
**Spec Reference:** MVP Spec Section 7 - Altitude Slider

**Expected Behavior:**
- Vertical slider with glassmorphism styling
- Smooth dragging between altitude levels
- Visual depth indication
- Spec: "Interaction: Tap segment OR drag"

**Actual Behavior (BEFORE FIX):**
- Only tap interaction implemented
- Works as discrete buttons between levels
- Cannot drag to select levels

**User Report:**
> "the slider is more of a button between the different levels"

**Root Cause (confirmed):**
- Drag gesture handler not implemented
- Only tap handlers on individual segments

**Fix Implemented:**
- Added vertical drag gesture support via outer GestureDetector
- Users can now tap OR drag to select altitude levels
- Haptic feedback on level changes during drag
- Helper method `_levelFromY()` converts Y position to altitude level
- Preserved tap interaction (no regression)
- All 254 tests passing, flutter analyze clean

**Components Modified:**
- `lib/widgets/altitude_slider.dart` (+18 lines)
- `test/widgets/altitude_slider_test.dart` (+44 lines, 1 new test)

**Pipeline:** `/diagnose altitude-slider` → `/plan` → `/implement` → `/test` → `/finalize` ✓

---

### BUG-006: Sky Detection Regression (Particles on Porch Ceiling)

**Severity:** Critical
**Status:** DONE (2026-02-02)
**Spec Reference:** MVP Spec Section 3 - Sky Detection

**Expected Behavior:**
- Particles should ONLY appear in actual sky regions
- When under overhang/porch, particles should appear in sky gaps, not on ceiling
- Sky detection should accurately distinguish sky from structures

**Actual Behavior (BEFORE FIX):**
- Particles appear on porch ceiling (top of frame)
- Actual sky (visible in middle of frame) may or may not have particles
- Detection incorrectly classifies porch ceiling as "sky"

**User Report:**
Screenshot `/workspace/images/IMG_4344.PNG` shows particles (pink/magenta) rendering on wooden porch ceiling slats instead of the gray overcast sky visible in the middle portion of the frame.

**Root Cause (confirmed):**
The sky detection design assumes the TOP of the camera frame is sky during calibration:
1. Calibration samples pixels from top 5-50% of frame (based on pitch angle)
2. When user is under porch, top of frame is porch ceiling, not sky
3. System learns porch ceiling color as "sky" color
4. Detection uses position weight that gives maximum (1.0) to top 20% of frame
5. Porch ceiling gets high color match + high position weight = classified as sky

This is a **design flaw** that was exposed by the under-porch use case, NOT a regression from code changes.

**Fix Implemented:**
- Added `isSkyLikeColor()` static method to filter non-sky colors during calibration
  - Accepts blue sky (hue 180-250, moderate saturation)
  - Accepts gray/overcast sky (low saturation)
  - Rejects brown/tan (hue 20-45), green (hue 80-150), dark shadows, highly saturated colors
- Implemented multi-region sampling (4 regions instead of 1)
  - Top center, middle center, top left corner, top right corner
  - Increases chance of finding actual sky when top is obstructed
- Reduced position weight from 1.0 to 0.85 for top of frame
  - Makes color matching more influential than position assumption
- Added `forceRecalibrate()` method and "Recal Sky" button in debug panel
  - Provides manual recalibration fallback for edge cases
- All 295 tests passing (254 original + 41 new), flutter analyze clean

**Components Modified:**
- `lib/services/sky_detection/hsv_histogram.dart` (+25 lines)
- `lib/services/sky_detection/auto_calibrating_sky_detector.dart` (~100 lines modified)
- `lib/screens/ar_view_screen.dart` (+25 lines)
- `test/services/sky_detection/hsv_histogram_test.dart` (+130 lines, 24 tests)
- `test/services/sky_detection/auto_calibrating_sky_detector_test.dart` (+100 lines, 17 tests)

**Pipeline:** `/diagnose sky-detection-regression` → `/plan` → `/implement` → `/test` → `/finalize` ✓

---

### BUG-007: Streamline Ghosting (Ghost Trails on Respawn)

**Severity:** Critical
**Status:** DONE (2026-02-03)
**Spec Reference:** MVP Spec Section 4 - Particle System

**Expected Behavior:**
- Particle trails should only show the recent movement path in streamlines mode
- When particles are respawned or wrapped around screen edges, trails should be cleared
- No ghost trails should persist from previous particle positions

**Actual Behavior (BEFORE FIX):**
- Long diagonal ghost trails appeared across the entire screen
- Trails persisted after particles were recycled via `_resetToSkyPosition()`
- Cross-screen diagonal lines appeared when particles wrapped at edges
- Artifacts accumulated over time, making visualization unusable

**User Report:**
Screenshots `/workspace/images/IMG_4357.PNG` through `/workspace/images/IMG_4360.PNG` show severe ghost trail artifacts in streamlines mode, with diagonal lines spanning the entire screen.

**Root Cause (confirmed):**
The particle trail buffer (`trailX` and `trailY` Float32List) was not being cleared in two critical scenarios:

1. **Particle respawn via `_resetToSkyPosition()`:** When particles expired or moved out of sky regions, they were teleported to new positions, but the trail buffer retained old coordinates. This caused the renderer to draw lines from the old position to the new position, creating ghost trails.

2. **Screen edge wrapping:** When particles wrapped around screen edges (x or y coordinate exceeding bounds), the trail buffer was not cleared, causing cross-screen diagonal lines to appear.

The `Particle` class already had a `resetTrail()` method (sets `trailCount = 0` and `trailWriteIndex = 0`) that was correctly called in the `reset()` method, but this method was not being invoked in the two problematic code paths.

**Fix Implemented:**
- Added `p.resetTrail()` calls in `_resetToSkyPosition()` (all 3 code paths: high sky fraction, found position, fallback)
- Added conditional trail reset on screen edge wrapping (streamlines mode only)
- Added 4 new tests to verify fix and prevent regression
- All 358 tests passing (354 original + 4 new), flutter analyze clean
- Zero performance impact (O(1) operation)

**Components Modified:**
- `lib/widgets/particle_overlay.dart` - Added resetTrail() calls in 5 locations
  - Lines 206, 217, 225: In `_resetToSkyPosition()` method
  - Lines 327-336: In edge wrapping logic with `wrapped` flag tracking
- `test/widgets/particle_overlay_test.dart` - Added 4 BUG-007 tests
  - "particles reset via _resetToSkyPosition have cleared trail"
  - "streamlines mode clears trail on screen edge wrap"
  - "dots mode edge wrap does not affect particle state unnecessarily"
  - "no ghost trail segments after particle respawn in streamlines mode"

**Documentation:**
- `.claude/features/streamline-ghosting/SUMMARY.md`
- `.claude/features/streamline-ghosting/2026-02-03T00:30_plan.md`
- `.claude/features/streamline-ghosting/tasks.md`

**Commit:** 08065c0 - fix(particles): prevent streamline ghosting on particle respawn

**Pipeline:** `/diagnose streamline-ghosting` → `/plan` → `/implement` → `/test` → `/finalize` ✓

---

## Recommended Fix Order

Based on dependencies and severity:

```
1. BUG-001: Debug Panel      (Medium) - Helps debug other issues
2. BUG-002: Sky Detection    (Critical) - Foundation for masking
3. BUG-003: Particle Masking (Critical) - Depends on BUG-002
4. BUG-004: World-Fixed      (High) - Independent, can parallel with 2-3
5. BUG-005: Slider UX        (Low) - Polish, do last
```

**Suggested approach:**
1. Fix debug panel first so we can see what's happening
2. Implement Level 2a color-based sky detection
3. Update particle renderer to use actual sky mask
4. Fix compass-based world anchoring
5. Polish slider UX if time permits

---

## Pipeline Workflow

For each issue:
```
/diagnose <issue-name>  → Understand root cause, create diagnosis.md
/plan <issue-name>      → Design fix, create plan.md and tasks.md
/implement <issue-name> → Build the fix following TDD
/test <issue-name>      → Validate on real device
/finalize <issue-name>  → Commit when working
```

---

## Notes

- All issues require **real device testing** - simulator won't show these problems
- BUG-002 and BUG-003 are the core issues that make the app feel "fake"
- Fixing sky detection properly will likely resolve most visual complaints
- Consider combining BUG-002 + BUG-003 into single feature: `sky-masking-v2`
