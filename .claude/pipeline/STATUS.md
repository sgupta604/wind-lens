# Pipeline Status

> **Claude: READ THIS FILE FIRST on every new session.**
> Then check ROADMAP_PHASE2.md for next features.

---

## Current State

**Current Feature:** Ready for Phase 2
**Current Phase:** idle
**Next Command:** Pick from ROADMAP_PHASE2.md (recommend: `performance-optimization`)

**Phase 2 Roadmap:** `.claude/pipeline/ROADMAP_PHASE2.md`
**Issues Tracker:** `.claude/pipeline/POST_MVP_ISSUES.md`

---

## Pipeline Progress (Current Feature)

BUG-005: Altitude Slider Drag Gesture - **COMPLETED**

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

---

## What To Do

**🎉 MVP + POST-MVP BUGS COMPLETE - READY FOR PHASE 2! 🎉**

### Phase 2 Features (in priority order)

See `.claude/pipeline/ROADMAP_PHASE2.md` for full details.

**Phase 2a: Foundation (do first)**
1. `performance-optimization` - Fix FPS (currently 5, should be 45-60)
2. `particle-colors` - Improve visibility against sky
3. `compass-widget` - Small compass in corner

**Phase 2b: Location & Data**
4. `location-awareness` - GPS + heading for real data
5. `sky-viewport` - Calculate visible sky cone
6. `real-wind-data` - Integrate EDR API

**Phase 2c: Advanced**
7. `map-view` - Toggle AR ↔ top-down weather map
8. `altitude-input` - Input specific altitude in feet

### To Start a Feature

```bash
/research <feature-name>
/plan <feature-name>
/implement <feature-name>
/test <feature-name>
/finalize <feature-name>
```

### User Testing Notes (2026-01-22)

**Working:**
- Sky detection calibrates on cloudy day
- Particles masked to sky regions
- World anchoring correct
- Drag gesture on altitude slider

**Issues:**
- FPS: 5 (very low - investigate first)
- Particle colors hard to see
- Trees not well detected

**Screenshot:** `/workspace/IMG_4343.PNG`

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
