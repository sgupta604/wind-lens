# Wind Lens Development Pipeline

> **CRITICAL:** This pipeline is MANDATORY. Claude MUST follow these steps in order.
> Skipping steps or working outside the pipeline is NOT ALLOWED.

## Pipeline Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           HAPPY PATH FLOW                                    │
│                                                                             │
│   /research → /plan → /implement → /test → /finalize                       │
│       │          │          │          │          │                         │
│       ▼          ▼          ▼          ▼          ▼                         │
│   research.md  plan.md   impl.md   success.md  PR Created                  │
│               tasks.md                                                      │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                           FAILURE PATH FLOW                                  │
│                                                                             │
│   /test (fails) → /diagnose → /plan → /implement → /test → /finalize       │
│        │              │          │          │          │          │         │
│        ▼              ▼          ▼          ▼          ▼          ▼         │
│   failure.md    diagnosis.md  plan.md   impl.md   success.md  PR Created   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
.claude/
├── pipeline/
│   └── WORKFLOW.md          # This file - pipeline rules
├── features/                # Committed to git - design docs
│   └── <feature-name>/
│       ├── YYYY-MM-DDTHH:MM_research.md
│       ├── YYYY-MM-DDTHH:MM_plan.md
│       └── tasks.md
├── active-work/             # NOT committed - working files
│   └── <feature-name>/
│       ├── implementation.md
│       ├── test-success.md   # OR
│       ├── test-failure.md
│       └── diagnosis.md
└── agents/                  # Agent definitions
    ├── plan-agent.md
    ├── execute-agent.md
    ├── test-agent.md
    ├── finalize-agent.md
    └── diagnose-agent.md
```

## Pipeline Steps (MUST Follow In Order)

### Step 1: Research (`/research <feature-name>`)

**Purpose:** Gather all context before planning

**Agent:** None (direct work)

**Inputs:**
- Feature name from user
- WIND_LENS_MVP_SPEC.md
- CLAUDE.md
- Existing codebase

**Outputs:**
- `.claude/features/<feature-name>/YYYY-MM-DDTHH:MM_research.md`

**Gate:** Research is complete when:
- [ ] All requirements extracted from spec
- [ ] Existing code analyzed
- [ ] Constraints documented
- [ ] Open questions resolved (all `[x]`)
- [ ] Status = `research-complete`

**CANNOT proceed to /plan until gate passes.**

---

### Step 2: Plan (`/plan <feature-name>`)

**Purpose:** Design architecture and break into tasks

**Agent:** plan-agent

**Inputs:**
- `.claude/features/<feature-name>/*_research.md` (REQUIRED)
- CLAUDE.md
- WIND_LENS_MVP_SPEC.md

**Outputs:**
- `.claude/features/<feature-name>/YYYY-MM-DDTHH:MM_plan.md`
- `.claude/features/<feature-name>/tasks.md`

**Gate:** Planning is complete when:
- [ ] Architecture designed with diagrams
- [ ] File structure mapped
- [ ] Tasks broken into discrete, testable units
- [ ] Tasks ordered by dependencies
- [ ] Testing strategy defined

**CANNOT proceed to /implement until gate passes.**

---

### Step 3: Implement (`/implement <feature-name>`)

**Purpose:** Execute tasks following TDD

**Agent:** execute-agent

**Inputs:**
- `.claude/features/<feature-name>/tasks.md` (REQUIRED)
- `.claude/features/<feature-name>/*_plan.md` (REQUIRED)
- `.claude/features/<feature-name>/*_research.md`

**Outputs:**
- `.claude/active-work/<feature-name>/implementation.md`
- Actual code changes
- Updated `tasks.md` with checkmarks

**Gate:** Implementation is complete when:
- [ ] All tasks marked `[x]` in tasks.md
- [ ] All unit tests passing
- [ ] Build succeeds
- [ ] `implementation.md` created

**CANNOT proceed to /test until gate passes.**

---

### Step 4: Test (`/test <feature-name>`)

**Purpose:** Validate feature works end-to-end

**Agent:** test-agent

**Inputs:**
- `.claude/active-work/<feature-name>/implementation.md` (REQUIRED)
- `.claude/features/<feature-name>/tasks.md`

**Outputs (ONE of):**
- `.claude/active-work/<feature-name>/test-success.md` → proceed to /finalize
- `.claude/active-work/<feature-name>/test-failure.md` → proceed to /diagnose

**Gate:** Testing is complete when:
- [ ] All tests executed
- [ ] Report created
- [ ] Clear next step identified

---

### Step 5a: Finalize (`/finalize <feature-name>`) - On Success

**Purpose:** Prepare feature for release

**Agent:** finalize-agent

**Inputs:**
- `.claude/active-work/<feature-name>/test-success.md` (REQUIRED)
- `.claude/active-work/<feature-name>/implementation.md`

**Outputs:**
- Documentation cleanup
- Git commit
- Pull request

**Gate:** Finalization is complete when:
- [ ] All quality checks pass
- [ ] Documentation TODOs removed
- [ ] Commit created
- [ ] PR opened

---

### Step 5b: Diagnose (`/diagnose <feature-name>`) - On Failure

**Purpose:** Find root cause of test failures

**Agent:** diagnose-agent

**Inputs:**
- `.claude/active-work/<feature-name>/test-failure.md` (REQUIRED)
- Error logs, stack traces

**Outputs:**
- `.claude/active-work/<feature-name>/diagnosis.md`

**Gate:** Diagnosis is complete when:
- [ ] Issue reproduced
- [ ] Root cause identified
- [ ] Fix plan created with file:line changes

**After diagnosis → return to /plan with fix plan**

---

## Enforcement Rules

### Rule 1: No Skipping Steps

```
❌ FORBIDDEN:
- Starting implementation without research
- Starting implementation without plan
- Finalizing without testing
- Committing without passing tests

✅ REQUIRED:
- Follow pipeline order exactly
- Check for required input files before proceeding
- Create output files before marking step complete
```

### Rule 2: No Working Outside Pipeline

```
❌ FORBIDDEN:
- Making code changes without going through /implement
- Writing tests without a plan
- Creating PRs without /finalize

✅ REQUIRED:
- All code work goes through the pipeline
- Use appropriate commands for each phase
- Let agents do their specialized work
```

### Rule 3: Handoff Files Are Mandatory

```
Each step MUST read input files and create output files:

/research  →  creates research.md
/plan      →  reads research.md, creates plan.md + tasks.md
/implement →  reads plan.md + tasks.md, creates implementation.md
/test      →  reads implementation.md, creates success.md or failure.md
/finalize  →  reads success.md, creates commit + PR
/diagnose  →  reads failure.md, creates diagnosis.md
```

### Rule 4: Gates Must Pass

```
Before proceeding to next step, verify:

□ Required input files exist
□ Previous step's gate conditions met
□ Output files created with required content
```

## Quick Reference

| Command | Agent | Input Files | Output Files |
|---------|-------|-------------|--------------|
| /research | - | spec, codebase | research.md |
| /plan | plan-agent | research.md | plan.md, tasks.md |
| /implement | execute-agent | plan.md, tasks.md | implementation.md |
| /test | test-agent | implementation.md | success.md OR failure.md |
| /finalize | finalize-agent | success.md | commit, PR |
| /diagnose | diagnose-agent | failure.md | diagnosis.md |

## Breaking Down Features

For testable, incremental development:

1. **Break MVP into phases** (from WIND_LENS_MVP_SPEC.md):
   - Phase 1: Sky Detection
   - Phase 2: Particle Rendering
   - Phase 3: Spatial Depth
   - Phase 4: Wind Data & Polish

2. **Each phase becomes a feature**:
   - `/research sky-detection`
   - `/plan sky-detection`
   - `/implement sky-detection`
   - `/test sky-detection`
   - `/finalize sky-detection`

3. **Test EACH phase before moving to next**:
   - Don't start Phase 2 until Phase 1 passes all tests
   - This catches issues early

## Error Recovery

### If stuck in any phase:

1. Check if required input files exist
2. Check if previous gate conditions were met
3. If files missing, go back to previous step
4. If unclear, ask user for clarification

### If tests keep failing:

```
/test → failure → /diagnose → diagnosis.md → /plan (with fix) → /implement → /test
```

Loop until tests pass, then proceed to /finalize.
