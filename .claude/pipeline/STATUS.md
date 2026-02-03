# Pipeline Status

> **Claude: READ THIS FILE FIRST on every new session.**
> Then check ROADMAP_PHASE2.md for next features.

---

## Current State

**Current Feature:** None (ready for next Phase 2 feature)
**Current Phase:** Idle
**Next Command:** See ROADMAP_PHASE2.md for next features

### Next Recommended Feature

**compass-widget** - Small compass widget in corner showing direction (Quick win, low complexity)

**Phase 2 Roadmap:** `.claude/pipeline/ROADMAP_PHASE2.md`
**Issues Tracker:** `.claude/pipeline/POST_MVP_ISSUES.md`

---

## Most Recently Completed

Feature: wind-streamlines (P2A-002) - **FINALIZED** (2026-02-03)

- [x] /research - Complete (2026-02-02)
- [x] /plan - Complete (2026-02-02)
- [x] /implement - Complete (2026-02-03)
- [x] /test - Complete (2026-02-03) - All 354 tests passing
- [x] /finalize - Complete (2026-02-03)

**Summary:** Implemented Windy.com-style flowing wind streamlines with speed-based color gradient (blue→purple), altitude-specific trail lengths, and ViewMode toggle. Added 59 new tests (354 total, up from 295). Uses efficient Float32List circular buffer for trail storage. Zero regressions.

**Documentation:** `.claude/features/wind-streamlines/SUMMARY.md`
**Commit:** 02f345a - feat(particles): add Windy.com-style wind streamlines

---

## Previously Completed

### Previous: Sky Detection Regression Fix

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

---

## What To Do

**Next: Choose next Phase 2 feature from ROADMAP_PHASE2.md**

### Phase 2 Features (in priority order)

See `.claude/pipeline/ROADMAP_PHASE2.md` for full details.

**Phase 2a: Foundation & Visuals**
1. ~~`performance-optimization`~~ - Fix FPS (5 to 45+) **DONE**
2. ~~`wind-streamlines`~~ - Windy.com style flowing trails **DONE**
3. `particle-colors` - Can merge with wind-streamlines (included in wind-streamlines)
4. `compass-widget` - Small compass in corner **<-- RECOMMENDED NEXT (Quick win)**

**Phase 2b: Location & Data**
5. `location-awareness` - GPS + heading for real data
6. `sky-viewport` - Calculate visible sky cone
7. `real-wind-data` - Integrate EDR API

**Phase 2c: Advanced**
8. `map-view` - Toggle AR <-> top-down weather map
9. `altitude-input` - Input specific altitude in feet

### To Continue

```bash
/research compass-widget  # Recommended next feature
```

### User Testing Notes (2026-02-03)

**Working:**
- Sky detection calibrates on cloudy day
- Sky detection works under overhangs/porches (fixed BUG-006)
- Particles masked to sky regions
- World anchoring correct
- Drag gesture on altitude slider
- FPS: 45+ (fixed from 5)
- Streamline visualization implemented (Windy.com style) **NEW**

**Known Limitations:**
- Trees not well recognized by sky detection (deferred - ML would be required)
- Streamlines visual quality needs device testing validation

**Device Testing Required:**
- Build on iOS device and validate streamline appearance
- Verify FPS maintains 45+ with streamlines enabled
- Test user experience with ViewMode toggle

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
