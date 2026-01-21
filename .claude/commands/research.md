---
description: Research a feature before planning - gathers context, constraints, and decisions needed
---

# Feature Research

Research and gather all context needed before planning a feature. This is the FIRST step in the pipeline and MUST be completed before `/plan`.

## Usage

```
/research <feature-name>
```

## Examples

```
/research sky-detection
/research particle-rendering
/research compass-integration
```

## What This Does

1. **Creates feature directory**: `.claude/features/<feature-name>/`
2. **Gathers context**:
   - Reads CLAUDE.md and project conventions
   - Reads WIND_LENS_MVP_SPEC.md for requirements
   - Searches existing codebase for related code
   - Identifies dependencies and constraints
3. **Documents findings** in `YYYY-MM-DDTHH:MM_research.md`:
   - Feature requirements from spec
   - Existing code analysis
   - Technical constraints
   - Open questions (MUST be resolved before planning)
   - Recommended approach
   - Risks and mitigations

## Research Document Template

The research document MUST include:

```markdown
# Research: <feature-name>

## Metadata
- **Feature:** <feature-name>
- **Created:** <timestamp>
- **Status:** research-complete | needs-clarification

## Requirements from Spec
[Extract relevant sections from WIND_LENS_MVP_SPEC.md]

## Existing Code Analysis
[What exists? What needs to change? What's the current state?]

## Technical Constraints
[From CLAUDE.md, performance targets, device requirements]

## Open Questions
- [ ] Question 1 (MUST resolve before planning)
- [ ] Question 2

## Recommended Approach
[Based on research, what's the best path forward?]

## Risks and Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| ... | ... | ... |

## Dependencies
[Other features/code this depends on]

## Next Step
Run `/plan <feature-name>` after all open questions are resolved.
```

## Pipeline Enforcement

**CRITICAL:** Research MUST be completed before planning.

The `/plan` command will check for:
- `.claude/features/<feature-name>/*_research.md` exists
- Status is `research-complete` (not `needs-clarification`)
- All open questions are marked resolved `[x]`

If any check fails, `/plan` will refuse to proceed.

## Output Location

Research documents are saved to:
- `.claude/features/<feature-name>/YYYY-MM-DDTHH:MM_research.md`

This directory is committed to git so research is preserved.

## User Input

$ARGUMENTS
