---
description: Check pipeline status - shows current feature, phase, and next command
---

# Pipeline Status

Check the current state of the development pipeline. Shows what's been done, what's in progress, and what to do next.

## Usage

```
/status
```

## What This Does

1. **Reads pipeline status** from `.claude/pipeline/STATUS.md`
2. **Scans feature directories** to verify actual state
3. **Reports current status**:
   - Active feature (if any)
   - Current pipeline phase
   - What files exist
   - **Next command to run**

## Output Example

```
📊 PIPELINE STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current Feature: sky-detection
Current Phase:   implement-complete

Pipeline Progress:
  [x] /research  → research.md exists
  [x] /plan      → plan.md, tasks.md exist
  [x] /implement → implementation.md exists
  [ ] /test      → NOT STARTED
  [ ] /finalize  → NOT STARTED

📍 NEXT STEP: /test sky-detection

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Automatic Status Check

Claude should run `/status` (or read STATUS.md):
- At the START of every new session
- Before suggesting any work
- When user asks "where are we?" or similar

## Verifying Status

The status command cross-checks:

1. **STATUS.md says** what phase we're in
2. **Actual files exist** to confirm:
   - `.claude/features/<feature>/*_research.md` → research done
   - `.claude/features/<feature>/*_plan.md` → planning done
   - `.claude/features/<feature>/tasks.md` → tasks created
   - `.claude/active-work/<feature>/implementation.md` → implementation done
   - `.claude/active-work/<feature>/test-success.md` → tests passed
   - `.claude/active-work/<feature>/test-failure.md` → tests failed

If STATUS.md and actual files don't match, report the discrepancy.

## No Arguments Needed

$ARGUMENTS
