# Pipeline Status

> **Claude: READ THIS FILE FIRST on every new session.**
> Then check ROADMAP.md for feature order.

---

## Current State

**Current Feature:** None (BUG-003 complete, ready for next issue)
**Current Phase:** idle
**Next Command:** Start next issue from POST_MVP_ISSUES.md or user request

**Issues Tracker:** `.claude/pipeline/POST_MVP_ISSUES.md`

---

## Pipeline Progress (Current Feature)

```
[x] /diagnose  - Complete (2026-01-21) - Root cause identified
[x] /plan      - Complete (2026-01-21) - Implementation plan and tasks created
[x] /implement - Complete (2026-01-21) - Sky-aware spawning implemented with TDD
[x] /test      - Complete (2026-01-21) - All 242 tests passing
[x] /finalize  - Complete (2026-01-21) - Committed locally
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
| BUG-001 | Debug Panel Missing | DONE (2026-01-21) |
| BUG-002 | Sky Detection Level 2a Auto-Calibrating | DONE (2026-01-21) |
| BUG-003 | Particles not masked to sky pixels | DONE (2026-01-21) |
| BUG-004 | Wind animation not world-fixed | Ready to start |

---

## What To Do

**BUG-003 particle-masking COMPLETE!**

All pipeline stages complete for BUG-003:
- `/diagnose` - Root cause identified (particles spawning everywhere)
- `/plan` - Implementation plan with 14 tasks created
- `/implement` - TDD implementation complete (42 lines production, 302 lines tests)
- `/test` - All 242 tests passing, flutter analyze clean
- `/finalize` - Local commit created, SUMMARY.md written

**Results:**
- Particles now spawn only in sky regions (true AR experience)
- 6 new tests added for sky-aware spawning
- Performance optimized for high/low sky fractions
- Graceful fallback prevents infinite loops

**Next issue:** BUG-004 (Wind animation not world-fixed) or user request

**Summary:** `.claude/features/particle-masking/SUMMARY.md`

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
