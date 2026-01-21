# Pipeline Status

> **Claude: READ THIS FILE FIRST on every new session.**
> Then check ROADMAP.md for feature order.

---

## Current State

**Current Feature:** sky-detection-v2
**Current Phase:** finalize-complete
**Next Command:** See POST_MVP_ISSUES.md for next issue (BUG-003 or BUG-004)

**Issues Tracker:** `.claude/pipeline/POST_MVP_ISSUES.md`

---

## Pipeline Progress (Current Feature)

```
[x] /research  - Used diagnosis from .claude/active-work/sky-detection/diagnosis.md
[x] /plan      - Complete (2026-01-21T04:30)
[x] /implement - Complete (2026-01-21)
[x] /test      - Complete (236 tests passing)
[x] /finalize  - Complete (2026-01-21)
```

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

## Post-MVP Bugs/Features In Progress

| Issue | Description | Status |
|-------|-------------|--------|
| BUG-002 | Sky Detection Level 2a Auto-Calibrating | DONE (2026-01-21) |
| BUG-003 | Particles not masked to sky pixels | Ready to start (requires BUG-002) |
| BUG-004 | Wind animation not world-fixed | Ready to start |

---

## What To Do

**BUG-002 sky-detection-v2 COMPLETE!**

Level 2a Auto-Calibrating Sky Detection has been successfully implemented and finalized. All 236 tests passing, flutter analyze clean.

**Next Priority Issues:**

1. **BUG-003: Particle Masking** (Critical) - Now unblocked with BUG-002 complete
   - Use AutoCalibratingSkyDetector for per-pixel particle masking
   - Run `/diagnose particle-masking` to start

2. **BUG-004: World-Fixed Animation** (High) - Can be done in parallel
   - Fix compass integration for world-anchored particles
   - Run `/diagnose wind-anchoring` to start

---

## How To Update This File

After each pipeline step, update:

1. **Current Phase** to the completed step
2. **Next Command** to the next step
3. **Pipeline Progress** checkboxes

Example after `/implement sky-detection-v2` completes:
```
**Current Phase:** implement-complete
**Next Command:** `/test sky-detection-v2`

[x] /research  - Complete
[x] /plan      - Complete
[x] /implement - Complete
[ ] /test      - Not started
[ ] /finalize  - Not started
```

When feature completes (`/finalize` done):
1. Update Post-MVP Bugs/Features table
2. Set Current Feature to next issue
3. Reset Pipeline Progress checkboxes
4. Set Next Command to next issue workflow
