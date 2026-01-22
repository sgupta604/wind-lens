# Pipeline Status

> **Claude: READ THIS FILE FIRST on every new session.**
> Then check ROADMAP.md for feature order.

---

## Current State

**Current Feature:** None (ready for next issue)
**Current Phase:** Idle
**Next Command:** Review POST_MVP_ISSUES.md for next issue to address

**Issues Tracker:** `.claude/pipeline/POST_MVP_ISSUES.md`

---

## Pipeline Progress (Current Feature)

No feature currently in progress. BUG-002.5 has been completed.

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
| BUG-001 | Debug Panel Missing | DONE (2026-01-21) |
| BUG-002 | Sky Detection Level 2a Auto-Calibrating | DONE (2026-01-21) |
| BUG-002.5 | Sky Detection Not Working on Real Device | DONE (2026-01-22) |
| BUG-003 | Particles not masked to sky pixels | DONE (2026-01-21) |
| BUG-004 | Wind animation not world-fixed | Ready to start |

---

## What To Do

**BUG-002.5 COMPLETE!**

Sky detection calibration threshold fix has been finalized and committed.

**What was fixed:**
- Lowered calibration threshold from 45 to 25 degrees
- Changed sample region top from 10% to 5%
- Added dynamic sample region based on pitch angle
- All 250 tests passing, flutter analyze clean

**Next available issues:**
- BUG-004: Wind animation not world-fixed (High priority)
- BUG-005: Altitude slider UX (Low priority)

To start next issue:
1. Review POST_MVP_ISSUES.md
2. Run `/diagnose <issue-name>` for the next bug to fix

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
