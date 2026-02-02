---
description: Research a feature before planning - spawns research-agent to gather requirements and context
---

# Feature Research

Research and gather all context needed before planning a feature. This command spawns the **research-agent** to thoroughly analyze requirements, existing code, and constraints.

This is the FIRST step in the pipeline and MUST be completed before `/plan`.

## Usage

```
/research <feature-name>
```

## Examples

```
/research project-setup
/research sky-detection
/research particle-system
```

## What This Does

1. **Spawns the research-agent** to perform thorough research
2. **Creates feature directory**: `.claude/features/<feature-name>/`
3. **Agent gathers context**:
   - Reads feature README for context
   - Reads ROADMAP.md for dependencies
   - Reads CLAUDE.md for project conventions
   - Reads WIND_LENS_MVP_SPEC.md for requirements
   - Analyzes existing codebase
   - Identifies constraints and risks
4. **Agent creates research document**: `YYYY-MM-DDTHH:MM_research.md`

## The Research Agent

The research-agent is specialized in:
- Extracting requirements from specifications
- Analyzing existing code for reuse/modification
- Identifying risks and constraints
- Documenting open questions
- Recommending implementation approach

See `.claude/agents/research-agent.md` for full details.

## Research Document Output

The agent creates `.claude/features/<feature-name>/YYYY-MM-DDTHH:MM_research.md` containing:

```markdown
# Research: <feature-name>

## Metadata
- Feature, timestamp, status

## Feature Context
- From ROADMAP.md and README

## Requirements from Spec
- Functional requirements (checkboxes)
- Technical requirements (with specific values)
- Code examples from spec
- Warnings/critical notes

## Existing Code Analysis
- Project state
- Code to reuse
- Code to modify
- Patterns to follow

## Constraints
- Performance, platform, dependencies

## Risk Assessment
- Technical risks with mitigations
- Complexity rating

## Open Questions
- Questions with recommendations
- Status: resolved or needs input

## Recommended Approach
- Implementation strategy
- Order of work
- What to defer

## Next Step
- /plan if ready, or resolve questions first
```

## Pipeline Enforcement

**CRITICAL:** Research MUST be completed before planning.

The `/plan` command will check for:
- `.claude/features/<feature-name>/*_research.md` exists
- Status is `research-complete` (not `needs-clarification`)
- All open questions are marked resolved `[x]`

If any check fails, `/plan` will refuse to proceed.

## Status Values

- **research-complete** → Ready for `/plan`
- **needs-clarification** → Open questions need user input

## After Research

When research completes:

1. Agent updates `STATUS.md` with new phase
2. If status is `research-complete`:
   - Agent prompts: "Research done. Run `/plan <feature-name>`?"
3. If status is `needs-clarification`:
   - Agent lists open questions needing resolution
   - User must answer before proceeding

## User Input

$ARGUMENTS
