---
description: Rework a feature with a different approach - user wants to change direction
---

# Rework Feature

User is unhappy with the current approach and wants to try something different. This command resets a feature to the planning phase with new constraints.

## Usage

```
/rework <feature-name>
```

## When To Use

- User says "I don't like this approach"
- User says "try it a different way"
- User wants to switch from one implementation strategy to another
- Feature works but user wants it done differently

## Examples

```
/rework sky-detection
# User: "Use color-based detection instead of pitch-based"

/rework particle-system
# User: "I want fewer particles with longer trails"
```

## What This Does

1. **Preserves the old work** (doesn't delete, moves to archive)
2. **Creates a rework document** capturing:
   - What approach was tried
   - Why user wants to change
   - New constraints/requirements
3. **Resets pipeline to /plan phase** with new constraints
4. **Updates STATUS.md**

## Process

### Step 1: Document the Pivot

Create `.claude/active-work/<feature>/rework-YYYY-MM-DD.md`:

```markdown
# Rework: <feature-name>

## Previous Approach
[What was implemented]

## Why Changing
[User's feedback - quote them directly]

## New Approach
[What user wants instead]

## Constraints
[Any new requirements or constraints]
```

### Step 2: Archive Old Implementation

Move (don't delete) old files:
- `.claude/features/<feature>/*_plan.md` → `.claude/features/<feature>/archive/`
- `.claude/active-work/<feature>/implementation.md` → archive

Keep `*_research.md` - research is usually still valid.

### Step 3: Update STATUS.md

```markdown
**Current Feature:** <feature-name>
**Current Phase:** rework-planning
**Next Command:** `/plan <feature-name>`

Note: Reworking with new approach. See rework-YYYY-MM-DD.md for context.
```

### Step 4: Proceed to /plan

The `/plan` command will:
- Read the rework document for new constraints
- Create a new plan with the different approach
- Generate new tasks

## Important Notes

- **Research usually doesn't need redoing** - requirements are the same, just approach changes
- **Tell Claude the NEW approach clearly** - be specific about what you want different
- **Old work is archived, not deleted** - can reference or restore if needed

## After /rework

Pipeline continues normally:
```
/rework → /plan (new approach) → /implement → /test → /finalize
```

## User Input

$ARGUMENTS
