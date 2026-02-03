# Pipeline Status

> **Claude: READ THIS FILE FIRST on every new session.**
> Then check ROADMAP_PHASE2.md for next features.

---

## Current State

**Current Feature:** None (ready for next feature)
**Current Phase:** idle
**Next Command:** Check ROADMAP_PHASE2.md for next feature

### Last Completed Feature

compass-widget-bugs (BUG-008) - **FINALIZED** (2026-02-03)

- [x] /diagnose - Complete (2026-02-03)
- [x] /plan - Complete (2026-02-03)
- [x] /implement - Complete (2026-02-03)
- [x] /test - Complete (2026-02-03) - All 375 tests passing
- [x] /finalize - Complete (2026-02-03)

**Diagnosis Document:** `.claude/active-work/compass-widget-bugs/diagnosis.md`
**Plan Document:** `.claude/features/compass-widget-bugs/2026-02-03T19:57_plan.md`
**Tasks:** `.claude/features/compass-widget-bugs/tasks.md`
**Implementation:** `.claude/active-work/compass-widget-bugs/implementation.md`
**Summary:** `.claude/features/compass-widget-bugs/SUMMARY.md`

**Phase 2 Roadmap:** `.claude/pipeline/ROADMAP_PHASE2.md`
**Issues Tracker:** `.claude/pipeline/POST_MVP_ISSUES.md`

---

## Implementation Summary (2026-02-03)

**Bug Fix:** Compass Widget Bugs (BUG-008) - Position overlap with InfoBar

**What was fixed:**
- Bug 1 (Position): Changed compass bottom offset from 76px to 92px, adding 16px visible gap above InfoBar
- Bug 2 (Static): Verified compass rotation is working correctly - no code changes needed

**Files Modified:**
- `/workspace/wind_lens/lib/screens/ar_view_screen.dart` (line 260 - single line change)

**Test Results:**
- All 375 tests passing
- No regressions
- Flutter analyze lib/ - No issues found
- Test report: `.claude/active-work/compass-widget-bugs/test-success.md`

---

## Most Recently Completed

Bug Fix: compass-widget-bugs (BUG-008) - **FINALIZED** (2026-02-03)

- [x] /diagnose - Complete (2026-02-03)
- [x] /plan - Complete (2026-02-03)
- [x] /implement - Complete (2026-02-03)
- [x] /test - Complete (2026-02-03) - All 375 tests passing
- [x] /finalize - Complete (2026-02-03)

**Summary:** Fixed compass widget position overlap with InfoBar by increasing bottom offset from 76px to 92px (adds 16px visible gap). Verified compass rotation logic is working correctly (no fix needed for Bug 2). Single-line change, zero regressions. All 375 tests passing.

**Documentation:** `.claude/features/compass-widget-bugs/SUMMARY.md`
**Commit:** 4483af9 - fix(ui): adjust compass widget position above InfoBar

---

## Previously Completed

### Previous: Compass Widget Feature

Feature: compass-widget (P2A-003) - **FINALIZED** (2026-02-03)

- [x] /research - Complete (2026-02-03)
- [x] /plan - Complete (2026-02-03)
- [x] /implement - Complete (2026-02-03)
- [x] /test - Complete (2026-02-03) - All 375 tests passing
- [x] /finalize - Complete (2026-02-03)

**Summary:** Added circular compass widget (68x68px) in bottom-left corner showing device heading with rotating cardinal directions (N, S, E, W). N label is red and prominent. Glassmorphism styling matches AltitudeSlider and InfoBar. Widget positioned above InfoBar as Layer 7 in ARViewScreen. Added 17 new tests (375 total).

**Documentation:** `.claude/features/compass-widget/SUMMARY.md`
**Commit:** 2c93e83 - feat(ui): add compass widget showing device heading

### Previous: Streamline Ghosting Fix

Feature: streamline-ghosting (BUG-007) - **FINALIZED** (2026-02-03)

- [x] /diagnose - Complete (2026-02-03)
- [x] /plan - Complete (2026-02-03)
- [x] /implement - Complete (2026-02-03)
- [x] /test - Complete (2026-02-03) - All 358 tests passing
- [x] /finalize - Complete (2026-02-03)

**Summary:** Fixed critical bug where particle trails persisted incorrectly when particles were respawned or wrapped around screen edges, creating ghost trails across the entire screen. Added `resetTrail()` calls in 5 locations (3 in `_resetToSkyPosition()`, 2 for edge wrapping). Added 4 new tests. All 358 tests passing, no performance impact.

**Documentation:** `.claude/features/streamline-ghosting/SUMMARY.md`
**Commit:** 08065c0 - fix(particles): prevent streamline ghosting on particle respawn

---

## Previously Completed

### Previous: Wind Streamlines Feature

Feature: wind-streamlines (P2A-002) - **FINALIZED** (2026-02-03)

- [x] /research - Complete (2026-02-02)
- [x] /plan - Complete (2026-02-02)
- [x] /implement - Complete (2026-02-03)
- [x] /test - Complete (2026-02-03) - All 354 tests passing
- [x] /finalize - Complete (2026-02-03)

**Summary:** Implemented Windy.com-style flowing wind streamlines with speed-based color gradient (blue→purple), altitude-specific trail lengths, and ViewMode toggle. Added 59 new tests (354 total, up from 295). Uses efficient Float32List circular buffer for trail storage. Zero regressions.

**Documentation:** `.claude/features/wind-streamlines/SUMMARY.md`
**Commit:** 02f345a - feat(particles): add Windy.com-style wind streamlines

### Earlier: Sky Detection Regression Fix

Feature: sky-detection-regression (BUG-006) - **FINALIZED** (2026-02-02)

- [x] /diagnose - Complete (2026-02-02)
- [x] /plan - Complete (2026-02-02)
- [x] /implement - Complete (2026-02-02)
- [x] /test - Complete (2026-02-02) - All 295 tests passing
- [x] /finalize - Complete (2026-02-02)

**Summary:** Fixed sky detection calibration failure under overhangs/porches through multi-region sampling, sky color heuristics, reduced position bias, and manual recalibration. All 295 tests passing (254 original + 41 new).

**Documentation:** `.claude/features/sky-detection-regression/SUMMARY.md`

### Earlier: Performance Optimization

Feature: performance-optimization - **FINALIZED** (2026-02-02)
- [x] /test - Complete (2026-02-02)
- [x] /finalize - Complete (2026-02-02)

**Summary:** Optimized render loop from 5 FPS to target 45+ FPS through debugPrint removal, setState elimination, and memory allocation reduction. All 254 tests passing.

**Documentation:** `.claude/features/performance-optimization/SUMMARY.md`

---

## Earlier Completed Features

### BUG-005: Altitude Slider Drag Gesture

BUG-005: Altitude Slider Drag Gesture - **COMPLETED** (2026-01-22)

- [x] /diagnose - Complete (from `.claude/active-work/altitude-slider/diagnosis.md`)
- [x] /plan - Complete (2026-01-22)
- [x] /implement - Complete (2026-01-22)
- [x] /test - Complete (2026-01-22) - All 254 tests passing
- [x] /finalize - Complete (2026-01-22)

### BUG-004: Wind Animation Not World-Fixed

BUG-004: Wind Animation Not World-Fixed - **COMPLETED** (2026-01-22)

- [x] /diagnose - Complete (2026-01-22)
- [x] /plan - Complete (2026-01-22)
- [x] /implement - Complete (2026-01-22)
- [x] /test - Complete (2026-01-22) - All 253 tests passing
- [x] /finalize - Complete (2026-01-22)

**Fix Summary:**
Changed world anchoring formula to apply 100% anchoring for all altitude levels (removed parallaxFactor multiplication). Depth perception now achieved via color, trail scale, and speed. All tests passing, no regressions.

Feature summary: `.claude/features/wind-anchoring/SUMMARY.md`

### Earlier Completed Bugs

See POST_MVP_ISSUES.md for details on BUG-001, BUG-002, BUG-002.5, BUG-003.

---

## Overall MVP Progress

All 8 features complete! Wind Lens MVP is ready for testing on device.

| # | Feature | Status |
|---|---------|--------|
| 0 | project-setup | DONE |
| 1 | camera-feed | DONE |
| 2 | compass-sensors | DONE |
| 3 | sky-detection | DONE |
| 4 | particle-system | DONE |
| 5 | wind-animation | DONE |
| 6 | altitude-depth | DONE |
| 7 | polish | DONE |

**MVP STATUS: COMPLETE**

---

## Post-MVP Bugs/Features Completed

| Issue | Description | Status |
|-------|-------------|--------|
| BUG-001 | Debug Panel Missing | DONE (2026-01-21) |
| BUG-002 | Sky Detection Level 2a Auto-Calibrating | DONE (2026-01-21) |
| BUG-002.5 | Sky Detection Not Working on Real Device | DONE (2026-01-22) |
| BUG-003 | Particles not masked to sky pixels | DONE (2026-01-21) |
| BUG-004 | Wind animation not world-fixed | DONE (2026-01-22) |
| BUG-005 | Altitude slider UX (drag gesture) | DONE (2026-01-22) |
| P2A-001 | Performance optimization (5 FPS to 45+ FPS) | DONE (2026-02-02) |
| BUG-006 | Sky detection regression (overhang scenario) | DONE (2026-02-02) |
| P2A-002 | wind-streamlines (Windy.com style trails) | DONE (2026-02-03) |
| BUG-007 | Streamline ghosting (ghost trails on respawn) | DONE (2026-02-03) |
| P2A-003 | compass-widget | DONE (2026-02-03) |
| BUG-008 | Compass widget bugs (position overlap + rotation check) | DONE (2026-02-03) |

---

## What To Do

**Next: Select next feature from Phase 2 roadmap**

### Phase 2 Features (in priority order)

See `.claude/pipeline/ROADMAP_PHASE2.md` for full details.

**Phase 2a: Foundation & Visuals**
1. ~~`performance-optimization`~~ - Fix FPS (5 to 45+) **DONE**
2. ~~`wind-streamlines`~~ - Windy.com style flowing trails **DONE**
3. `particle-colors` - Can merge with wind-streamlines (included in wind-streamlines)
4. ~~`compass-widget`~~ - Small compass in corner **DONE**

**Phase 2b: Location & Data**
5. `location-awareness` - GPS + heading for real data
6. `sky-viewport` - Calculate visible sky cone
7. `real-wind-data` - Integrate EDR API

**Phase 2c: Advanced**
8. `map-view` - Toggle AR <-> top-down weather map
9. `altitude-input` - Input specific altitude in feet

### User Testing Notes (2026-02-03)

**Working:**
- Sky detection calibrates on cloudy day
- Sky detection works under overhangs/porches (fixed BUG-006)
- Particles masked to sky regions
- World anchoring correct
- Drag gesture on altitude slider
- FPS: 45+ (fixed from 5)
- Streamline visualization implemented (Windy.com style)
- Streamline ghosting fix implemented (BUG-007) **COMPLETE**
- Compass widget implemented (P2A-003) **COMPLETE**

**Known Limitations:**
- Trees not well recognized by sky detection (deferred - ML would be required)

**Device Testing Required:**
- Compass widget position (verify 16px gap above InfoBar)
- Compass rotation (verify smooth rotation with device heading)

**Screenshots:**
- `/workspace/images/app_img.PNG` - Previous app with dots
- `/workspace/images/windy_img_goal.png` - Reference (Windy.com streamlines)

---

## How To Update This File

After each pipeline step, update:

1. **Current Phase** to the completed step
2. **Next Command** to the next step
3. **Pipeline Progress** checkboxes

Example after `/plan particle-masking` completes:
```
**Current Phase:** plan-complete
**Next Command:** `/implement particle-masking`

[x] /diagnose  - Complete
[x] /plan      - Complete
[ ] /implement - Not started
[ ] /test      - Not started
[ ] /finalize  - Not started
```

When feature completes (`/finalize` done):
1. Update Post-MVP Bugs/Features table
2. Set Current Feature to next issue
3. Reset Pipeline Progress checkboxes
4. Set Next Command to next issue workflow
