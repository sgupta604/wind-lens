# Pipeline Status

> **Claude: READ THIS FILE FIRST on every new session.**
> Then check ROADMAP.md for feature order.

---

## Current State

**Current Feature:** project-setup
**Current Phase:** test-complete
**Next Command:** `/finalize project-setup`

---

## Pipeline Progress (Current Feature)

```
[x] /research  - Complete
[x] /plan      - Complete
[x] /implement - Complete
[x] /test      - Complete (ALL TESTS PASSED)
[ ] /finalize  - Not started
```

---

## Overall MVP Progress

See `ROADMAP.md` for full feature list and requirements.

| # | Feature | Status |
|---|---------|--------|
| 0 | project-setup | **<- CURRENT** |
| 1 | camera-feed | waiting |
| 2 | compass-sensors | waiting |
| 3 | sky-detection | waiting |
| 4 | particle-system | waiting |
| 5 | wind-animation | waiting |
| 6 | altitude-depth | waiting |
| 7 | polish | waiting |

---

## What To Do

**If this is a new session:**
1. Report this status to user
2. Ask: "Ready to run `/finalize project-setup`?"

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

Example after `/implement project-setup` completes:
```
**Current Phase:** implement-complete
**Next Command:** `/test project-setup`

[x] /research  - Complete
[x] /plan      - Complete
[x] /implement - Complete
[ ] /test      - Not started
...
```

When feature completes (`/finalize` done):
1. Update Overall MVP Progress table
2. Set Current Feature to next feature
3. Reset Pipeline Progress checkboxes
4. Set Next Command to `/research <next-feature>`
