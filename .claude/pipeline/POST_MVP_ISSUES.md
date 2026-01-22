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
| BUG-004 | Wind animation not world-fixed | High | Open | Section 5 |
| BUG-005 | Altitude slider UX (buttons vs slider) | Low | Open | Section 7 |

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
**Status:** Open
**Spec Reference:** MVP Spec Section 5 - Compass Integration

**Expected Behavior:**
- Particles should feel anchored to the real sky
- When you rotate phone, particles should stay in place (world-fixed)
- Uses compass heading to offset particle positions
- Formula: `screenAngle = windDirection - compassHeading`

**Actual Behavior:**
- Particles move with the phone
- Feels like a video overlay
- No sense of looking at real sky through a window

**User Report:**
> "wind animation seems like a video playing on top of my screen, it doesn't stay consistent as i move my phone around"

**Root Cause (suspected):**
- Compass heading may not be applied to particle position offset
- Particles may be using screen coordinates instead of world coordinates

**Pipeline:** `/diagnose wind-anchoring` → `/plan` → `/implement`

---

### BUG-005: Altitude Slider UX

**Severity:** Low
**Status:** Open
**Spec Reference:** MVP Spec Section 7 - Altitude Slider

**Expected Behavior:**
- Vertical slider with glassmorphism styling
- Smooth dragging between altitude levels
- Visual depth indication

**Actual Behavior:**
- Works as discrete buttons between levels
- Functional but UX differs from spec

**User Report:**
> "the slider is more of a button between the different levels"

**Pipeline:** `/diagnose altitude-slider` → `/plan` → `/implement`

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
