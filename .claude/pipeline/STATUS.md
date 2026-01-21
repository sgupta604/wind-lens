# Pipeline Status

> **Claude: READ THIS FILE FIRST on every new session.**
> Then check ROADMAP.md for feature order.

---

## Current State

**Current Feature:** polish
**Current Phase:** ready-to-research
**Next Command:** `/research polish`

---

## Pipeline Progress (Current Feature)

```
[ ] /research  - Not started
[ ] /plan      - Not started
[ ] /implement - Not started
[ ] /test      - Not started
[ ] /finalize  - Not started
```

---

## Overall MVP Progress

See `ROADMAP.md` for full feature list and requirements.

| # | Feature | Status |
|---|---------|--------|
| 0 | project-setup | DONE |
| 1 | camera-feed | DONE |
| 2 | compass-sensors | DONE |
| 3 | sky-detection | DONE |
| 4 | particle-system | DONE |
| 5 | wind-animation | DONE |
| 6 | altitude-depth | DONE |
| 7 | polish | **<- CURRENT** |

---

## What To Do

**If this is a new session:**
1. Report this status to user
2. Ask: "Ready to run `/research polish`?"

**If user says "continue" or "next":**
- Run the Next Command shown above

**If user asks about a different feature:**
- Remind them we must complete current feature first
- Exception: user explicitly wants to skip (document why)

---

## How To Update This File

After each pipeline step, update:

1. **Current Phase** to the completed step
2. **Next Command** to the next step
3. **Pipeline Progress** checkboxes

Example after `/test compass-sensors` passes:
```
**Current Phase:** test-complete
**Next Command:** `/finalize compass-sensors`

[x] /research  - Complete
[x] /plan      - Complete
[x] /implement - Complete
[x] /test      - Complete
[ ] /finalize  - Not started
```

When feature completes (`/finalize` done):
1. Update Overall MVP Progress table
2. Set Current Feature to next feature
3. Reset Pipeline Progress checkboxes
4. Set Next Command to `/research <next-feature>`
