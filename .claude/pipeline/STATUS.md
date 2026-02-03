# Pipeline Status

> **Claude: READ THIS FILE FIRST on every new session.**
> Then check ROADMAP_PHASE2.md for next features.

---

## Current State

**Current Feature:** wind-streamlines
**Current Phase:** test-complete
**Next Command:** `/finalize wind-streamlines`

### Pipeline Progress: wind-streamlines

- [x] /research - Complete (2026-02-02)
- [x] /plan - Complete (2026-02-02)
- [x] /implement - Complete (2026-02-03) - 354 tests passing
- [x] /test - Complete (2026-02-03) - All 354 tests PASS
- [ ] /finalize - Not started

**Research Document:** `.claude/features/wind-streamlines/2026-02-02T23:45_research.md`
**Plan Document:** `.claude/features/wind-streamlines/2026-02-02T23:55_plan.md`
**Task Breakdown:** `.claude/features/wind-streamlines/tasks.md`
**Implementation Summary:** `.claude/active-work/wind-streamlines/implementation.md`
**Test Success Report:** `.claude/active-work/wind-streamlines/test-success.md`

**Phase 2 Roadmap:** `.claude/pipeline/ROADMAP_PHASE2.md`
**Issues Tracker:** `.claude/pipeline/POST_MVP_ISSUES.md`

### Implementation Summary (2026-02-03)

**New Files:**
- `lib/models/view_mode.dart` - ViewMode enum (dots, streamlines)
- `lib/utils/wind_colors.dart` - Speed-based color gradient utility
- `test/models/view_mode_test.dart` - 10 tests
- `test/utils/wind_colors_test.dart` - 21 tests

**Modified Files:**
- `lib/models/particle.dart` - Trail storage (Float32List circular buffer)
- `lib/models/altitude_level.dart` - streamlineTrailPoints (12/18/25)
- `lib/widgets/particle_overlay.dart` - Streamline rendering mode
- `lib/screens/ar_view_screen.dart` - Toggle UI, particle count adjustment

**Test Results:**
- All 354 tests pass (was 295, added 59 new)
- No regressions in existing functionality

---

## Most Recently Completed

Feature: sky-detection-regression (BUG-006) - **FINALIZED** (2026-02-02)

- [x] /diagnose - Complete (2026-02-02)
- [x] /plan - Complete (2026-02-02)
- [x] /implement - Complete (2026-02-02)
- [x] /test - Complete (2026-02-02) - All 295 tests passing
- [x] /finalize - Complete (2026-02-02)

**Summary:** Fixed sky detection calibration failure under overhangs/porches through multi-region sampling, sky color heuristics, reduced position bias, and manual recalibration. All 295 tests passing (254 original + 41 new).

**Documentation:** `.claude/features/sky-detection-regression/SUMMARY.md`

---

## Previously Completed

### Most Recent: Performance Optimization

Feature: performance-optimization - **FINALIZED** (2026-02-02)
- [x] /test - Complete (2026-02-02)
- [x] /finalize - Complete (2026-02-02)

**Summary:** Optimized render loop from 5 FPS to target 45+ FPS through debugPrint removal, setState elimination, and memory allocation reduction. All 254 tests passing.

**Documentation:** `.claude/features/performance-optimization/SUMMARY.md`

---

## Previously Completed

### Most Recent: BUG-005

BUG-005: Altitude Slider Drag Gesture - **COMPLETED** (2026-01-22)

- [x] /diagnose - Complete (from `.claude/active-work/altitude-slider/diagnosis.md`)
- [x] /plan - Complete (2026-01-22)
- [x] /implement - Complete (2026-01-22)
- [x] /test - Complete (2026-01-22) - All 254 tests passing
- [x] /finalize - Complete (2026-01-22)

---

## Previously Completed

### Most Recent: BUG-004

BUG-004: Wind Animation Not World-Fixed - **COMPLETED** (2026-01-22)

- [x] /diagnose - Complete (2026-01-22)
- [x] /plan - Complete (2026-01-22)
- [x] /implement - Complete (2026-01-22)
- [x] /test - Complete (2026-01-22) - All 253 tests passing
- [x] /finalize - Complete (2026-01-22)

**Fix Summary:**
Changed world anchoring formula to apply 100% anchoring for all altitude levels (removed parallaxFactor multiplication). Depth perception now achieved via color, trail scale, and speed. All tests passing, no regressions.

Feature summary: `.claude/features/wind-anchoring/SUMMARY.md`

### Earlier Completed: BUG-005

BUG-005: Altitude Slider Drag Gesture - **COMPLETED** (2026-01-22)

- [x] /diagnose - Complete (from `.claude/active-work/altitude-slider/diagnosis.md`)
- [x] /plan - Complete (2026-01-22)
- [x] /implement - Complete (2026-01-22)
- [x] /test - Complete (2026-01-22) - All 254 tests passing
- [x] /finalize - Complete (2026-01-22)

### Earlier Completed Features

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
| P2A-002 | wind-streamlines (Windy.com style trails) | TEST COMPLETE (2026-02-03) |

---

## What To Do

**Current: Run `/finalize wind-streamlines` to commit and finalize**

### Phase 2 Features (in priority order)

See `.claude/pipeline/ROADMAP_PHASE2.md` for full details.

**Phase 2a: Foundation & Visuals**
1. ~~`performance-optimization`~~ - Fix FPS (5 to 45+) **DONE**
2. `wind-streamlines` - Windy.com style flowing trails **<-- TEST COMPLETE, NEED /finalize**
3. `particle-colors` - Can merge with wind-streamlines (included in wind-streamlines)
4. `compass-widget` - Small compass in corner

**Phase 2b: Location & Data**
5. `location-awareness` - GPS + heading for real data
6. `sky-viewport` - Calculate visible sky cone
7. `real-wind-data` - Integrate EDR API

**Phase 2c: Advanced**
8. `map-view` - Toggle AR <-> top-down weather map
9. `altitude-input` - Input specific altitude in feet

### To Continue

```bash
/finalize wind-streamlines # All tests pass - ready to finalize
```

### User Testing Notes (2026-02-02)

**Working:**
- Sky detection calibrates on cloudy day
- Sky detection works under overhangs/porches (fixed BUG-006)
- Particles masked to sky regions
- World anchoring correct
- Drag gesture on altitude slider
- FPS: 45+ (fixed from 5)

**Current Issues:**
- Particle appearance: "sprinkles" not ideal - want Windy.com style streamlines **<-- IMPLEMENTED**
- Trees not well recognized by sky detection (deferred)

**Screenshots:**
- `/workspace/images/app_img.PNG` - Current app (working, but dots)
- `/workspace/images/windy_img_goal.png` - Target visual (Windy.com streamlines)

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
