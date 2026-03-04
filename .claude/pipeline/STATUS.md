# Pipeline Status

> **Claude: READ THIS FILE FIRST on every new session.**
> Then check ROADMAP_PHASE2.md for next features.

---

## Current State

**Current Feature:** home-screen-polish
**Current Phase:** finalized
**Branch:** `feature/home-screen-polish`
**Next Command:** Merge PR or start next feature
**Master:** Pending merge of on-device-fixes-march (commit 4e12bc4, PR open)

### Completed Pipeline: home-screen-polish (quick UI polish) - **FINALIZED** (2026-03-04)

- [x] /research - Complete (2026-03-04) - 2 in-scope fixes (mph label, sublabel contrast), 2 out-of-scope items documented
- [x] /plan - Complete (2026-03-04) - 2 files modified, 1 test file updated, 1 new test, 3 phases, 5 tasks
- [x] /implement - Complete (2026-03-04) - 2 files modified, 1 test added, all tests pass, 0 analyzer errors
- [x] /test - Complete (2026-03-04) - 863 tests passing, 0 failures, 0 analyzer errors, test-success.md created
- [x] /finalize - Complete (2026-03-04) - Commit bad0302, pushed to origin/feature/home-screen-polish, PR ready to create at https://github.com/sgupta604/wind-lens/pull/new/feature/home-screen-polish

**Research Document:** `.claude/features/home-screen-polish/2026-03-04T15:00_research.md`
**Plan Document:** `.claude/features/home-screen-polish/2026-03-04T15:30_plan.md`
**Tasks:** `.claude/features/home-screen-polish/tasks.md`
**Implementation:** `.claude/active-work/home-screen-polish/implementation.md`

### Completed Pipeline: heywhatsthat-client (P2B-002+003) - **FINALIZED** (2026-03-04)

- [x] /research - Complete (2026-03-04) - SPEC-003 analyzed, 3 new files, 4 modified, ~10 new tests, all questions resolved
- [x] /plan - Complete (2026-03-04) - 3 new files, 5 modified, ~18 new tests, 6 phases, 14 tasks
- [x] /implement - Complete (2026-03-04) - 4 new files, 7 modified, 18 new tests, 844 total passing, 0 analyzer errors
- [x] /test - Complete (2026-03-04) - 797 auto-discovered + 47 explicit = 844 total passing, 0 errors, 0 warnings in lib/, test-success.md created
- [x] /finalize - Complete (2026-03-04) - Commit b840a31, pushed to origin/feature/heywhatsthat-client, PR #1 created at https://github.com/sgupta604/wind-lens/pull/1

**Research Document:** `.claude/features/heywhatsthat-client/2026-03-04T12:00_research.md`
**Plan Document:** `.claude/features/heywhatsthat-client/2026-03-04T13:00_plan.md`
**Tasks:** `.claude/features/heywhatsthat-client/tasks.md`

### Completed Pipeline: altitude-slider-redesign (FINALIZED 2026-03-04)

- [x] /research - Complete (2026-03-03) - 43 files reference AltitudeLevel, expand enum approach, 6 pressure stops
- [x] /plan - Complete (2026-03-03) - 6 prod files modified, ~15 new tests, 6 phases, 12 tasks
- [x] /implement - Complete (2026-03-03) - 6 enum values, collapsible slider, 6-tick rail, dome label, 775 tests pass
- [x] /test - Complete (2026-03-03) - 822 tests passing, 0 errors, 0 warnings
- [x] /finalize - Complete (2026-03-04) - Committed 9a7763f on feature/on-device-fixes-march

**Research Document:** `.claude/features/altitude-slider-redesign/2026-03-03T03:18_research.md`
**Plan Document:** `.claude/features/altitude-slider-redesign/2026-03-03T04:00_plan.md`
**Tasks:** `.claude/features/altitude-slider-redesign/tasks.md`
**Summary:** `.claude/features/altitude-slider-redesign/SUMMARY.md`

### Completed Pipeline: on-device-fixes-march (FINALIZED 2026-03-03)

- [x] /research - Complete (2026-03-02) - 4 bugs analyzed, root causes identified, all questions resolved
- [x] /plan - Complete (2026-03-03) - 3 new + 5 modified files, ~4 new tests, 6 phases, 11 tasks
- [x] /implement - Complete (2026-03-03) - 3 new + 7 modified files, 5 new tests, 866 total passing
- [x] /test - Complete (2026-03-03) - 866 tests passing, 0 failures, 0 analyzer errors
- [x] /finalize - Complete (2026-03-03) - Committed 4e12bc4, pushed to origin/feature/on-device-fixes-march

**Research Document:** `.claude/features/on-device-fixes-march/2026-03-02T14:00_research.md`
**Plan Document:** `.claude/features/on-device-fixes-march/2026-03-03T12:00_plan.md`
**Tasks:** `.claude/features/on-device-fixes-march/tasks.md`

### Completed Pipeline: location-picker (FINALIZED 2026-03-02)

- [x] /research - Complete (2026-03-01) - Provider graph analysis, 4 new files, 5 modified, flutter_map already in deps
- [x] /plan - Complete (2026-03-01) - 4 new source + 2 test files, 5 modified files, ~20 new tests, 6 phases, 15 tasks
- [x] /implement - Complete (2026-03-02) - 6 new source, 5 modified, 20 new tests, 786 total passing, zero analyzer errors
- [x] /test - On-device testing found 4 bugs + 1 UX request
- [x] /diagnose - Complete (2026-03-02) - Root cause: UI reads stablePositionProvider instead of effectivePositionProvider
- [x] /plan (fix) - Complete (2026-03-02) - 4 modified + 2 new files, ~8 new tests, 5 phases, 11 tasks
- [x] /implement (fix) - Complete (2026-03-02) - 4 bugs fixed, 1 UX enhancement, 5 new tests, 792 total passing, zero analyzer errors
- [x] /test (fix) - Complete (2026-03-02) - 746 tests passing, 0 failures, 0 analyzer errors
- [x] /finalize - Complete (2026-03-02) - Committed eb67ef0, merged to master be7a848, pushed to remote

**Research Document:** `.claude/features/location-picker/2026-03-01T12:00_research.md`
**Original Plan:** `.claude/features/location-picker/2026-03-01T12:30_plan.md`
**Fix Plan:** `.claude/features/location-picker/2026-03-02T12:00_plan.md`
**Tasks:** `.claude/features/location-picker/tasks.md`
**Diagnosis:** `.claude/active-work/location-picker/diagnosis.md`

### Previous Pipeline: wind-dome-render-fixes (7 rendering/gesture fixes from on-device testing)

- [x] /research - Complete (2026-02-27) - 7 issues documented in WIND_DOME_RENDER_FIXES.md
- [x] /plan - Complete (2026-02-27) - 3 files modified, 1 new test file, ~8 new tests, 6 phases, 13 tasks
- [x] /implement - Complete (2026-02-27) - 3 files modified, 8 new tests, 717 total passing, zero analyzer issues
- [x] /test - Complete (2026-03-01) - 719 tests passing, 72 dome tests, zero analyzer errors, test-success.md created
- [x] /finalize - Complete (2026-03-01) - 225 lines added, committed locally, SUMMARY.md created

**Fixes Brief:** `.claude/features/wind-dome/WIND_DOME_RENDER_FIXES.md`
**Research Document:** `.claude/features/wind-dome-render-fixes/2026-02-27T16:00_research.md`
**Plan Document:** `.claude/features/wind-dome-render-fixes/2026-02-27T16:00_plan.md`
**Tasks:** `.claude/features/wind-dome-render-fixes/tasks.md`

### Previous Pipeline: wind-dome-rendering (complete rendering rewrite porting JSX prototype)

- [x] /research - Complete (2026-02-27) - Prototype analysis, 3 files to rewrite, 1 to update
- [x] /plan - Complete (2026-02-27) - 3 rewrites + 1 update, 12 tasks in 6 phases, ~5 new tests
- [x] /implement - Complete (2026-02-27) - 4 files rewritten, 3 test files updated, 62 dome tests (was 56), all pass
- [ ] /test - Deferred (on-device testing found 7 rendering issues -> wind-dome-render-fixes pipeline)
- [ ] /finalize - Deferred (blocked by wind-dome-render-fixes)

**Research Document:** `.claude/features/wind-dome-rendering/2026-02-27T14:00_research.md`
**Plan Document:** `.claude/features/wind-dome-rendering/2026-02-27T14:00_plan.md`
**Tasks:** `.claude/features/wind-dome-rendering/tasks.md`

### Previous Pipeline: wind-dome-fixes (rendering/gesture bug fixes) - **SUPERSEDED**

- [x] /research - Complete (2026-02-27) - On-device testing diagnosis, 5 discrete issues identified
- [x] /plan - Complete (2026-02-27) - 5 fixes, 11 tasks in 6 phases, ~6 new tests, 5 files modified
- [x] /implement - Complete (2026-02-27) - 5 fixes applied, 6 new tests, 703 total passing, zero analyzer issues
- [-] /test - Superseded by wind-dome-rendering (full rewrite makes incremental fixes obsolete)
- [-] /finalize - Superseded by wind-dome-rendering

**Plan Document:** `.claude/features/wind-dome-fixes/2026-02-27T13:00_plan.md`
**Tasks:** `.claude/features/wind-dome-fixes/tasks.md`
**Implementation:** `.claude/active-work/wind-dome-fixes/implementation.md`

### Completed Pipeline: wind-dome (Phase 1 MVP) - **IMPLEMENTED** (2026-02-27)

- [x] /research - Skipped (SPEC-002-wind-dome version2.md serves as research)
- [x] /plan - Complete (2026-02-27) - 10 new files, 4 modified, ~63 new tests, 6 phases
- [x] /implement - Complete (2026-02-27) - 11 new files, 4 modified, 69 new tests, all passing
- [ ] /test - Deferred (on-device testing found rendering bugs → wind-dome-fixes pipeline)
- [ ] /finalize - Deferred (blocked by wind-dome-fixes)

**Spec Document:** `.claude/features/wind-dome/SPEC-002-wind-dome version2.md`
**Plan Document:** `.claude/features/wind-dome/2026-02-27T12:00_plan.md`
**Tasks:** `.claude/features/wind-dome/tasks.md`

### Completed Pipeline: home-screen (SPEC-002) - **FINALIZED** (2026-02-26)

- [x] /research - Complete (spec serves as research: SPEC-002_home_screen.md)
- [x] /plan - Complete (2026-02-26) - 12 new files, 2 modified, ~18 new tests, 6 phases
- [x] /implement - Complete (2026-02-26) - 12 new files, 3 modified, 18 new tests, all passing
- [x] /test - Complete (2026-02-26) - 628 tests passing, zero analyzer issues in new code
- [x] /finalize - Complete (2026-02-26) - CLAUDE.md updated (test count + CustomPainter state pattern), SUMMARY.md created, committed locally

**Spec Document:** `.claude/features/home-screen/SPEC-002_home_screen.md`
**Plan Document:** `.claude/features/home-screen/2026-02-26T12:00_plan.md`
**Tasks:** `.claude/features/home-screen/tasks.md`
**Summary:** `.claude/features/home-screen/SUMMARY.md`

### Completed Pipeline: real-wind-data (P2B-006) - **FINALIZED** (2026-02-26)

- [x] /research - Complete (2026-02-26) - Live API testing, dual-API fallback designed, companion Dart implementation created
- [x] /plan - Complete (2026-02-26) - Architecture, 4 new files, 1 modified file, ~36 new tests, 6 phases
- [x] /implement - Complete (2026-02-26) - 4 new source files, 3 new test files, service_providers.dart wired
- [x] /test - Complete (2026-02-26) - 610 tests passing (+37 new), zero analyzer issues in new code
- [x] /finalize - Complete (2026-02-26) - CLAUDE.md updated, SUMMARY.md created, committed locally

**Research Document:** `.claude/features/real-wind-data/P2B-006_ogc_edr_wind_research.md`
**Plan Document:** `.claude/features/real-wind-data/2026-02-26T12:00_plan.md`
**Tasks:** `.claude/features/real-wind-data/tasks.md`
**Summary:** `.claude/features/real-wind-data/SUMMARY.md`

### Previous Feature: gimbal-lock v2 (FINALIZED 2026-02-25)

### Current Pipeline: architectural-foundation (SPEC-001) - **FINALIZED** (2026-02-25)

- [x] /research - Complete (2026-02-25) - Full codebase audit (25 source files, 405 tests), SPEC-001/002 analysis, 8 gaps identified, 3-phase plan confirmed
- [x] /plan - Complete (2026-02-25) - 3-phase architecture, 14 Phase 1 tasks (granular), Phase 2/3 high-level
- [x] /implement Phase 1 - COMPLETE (2026-02-25) - All 14 tasks done, 489 tests passing (84 new), zero analyzer issues
- [x] /implement Phase 2 - COMPLETE (2026-02-25) - All 10 tasks done (2 deferred by design), 505 tests passing (16 new), zero analyzer errors
- [x] /implement Phase 3a - COMPLETE (2026-02-25) - All 6 tasks done, 514 tests passing (9 new), zero analyzer errors
- [x] /implement Phase 3b - COMPLETE (2026-02-25) - DataStatusBar, CachedHorizonProvider, CachedWindDataSource, 16 integration tests, 606 tests total
- [x] /test - COMPLETE (2026-02-25) - 606 tests passing, dart analyze 0 errors/0 warnings
- [x] /finalize - COMPLETE (2026-02-25) - CLAUDE.md updated, SUMMARY.md created, committed locally

**Research Document:** `.claude/features/architectural-foundation/2026-02-25T14:00_research.md`
**Spec Document:** `.claude/features/SPEC-001-architectural-foundation.md`
**Plan Document:** `.claude/features/architectural-foundation/2026-02-25T17:00_plan.md`
**Tasks:** `.claude/features/architectural-foundation/tasks.md`
**DECISIONS.md:** `.claude/features/architectural-foundation/DECISIONS.md`

**Implementation phases (split into 4 runs for context management):**
- Phase 1: Freezed deps + models + service interfaces + wrap existing code (14 tasks) ✅
- Phase 2: Riverpod provider graph + directory restructure + wire AR view (10 tasks) ✅
- Phase 3a: Complete the wiring — SceneState consumption, SkyMask→SkyMaskData, camera→detector, altitude, lifecycle (6 tasks)
- Phase 3b: Polish and validate — DataStatusBar, caching, integration tests, finalize (5 tasks)

### Upcoming (after SPEC-001)
- **SPEC-002** photo-capture-overlay (depends on SPEC-001) — **Spec:** `.claude/features/SPEC-002-photo-capture-overlay.md`
- **P2B-002+003** heywhatsthat-client + horizon-cache (merged into one feature)
- **P2B-004+005** terrain-sky-mask + detection-mode-toggle
- **P2B-006** real-wind-data (OGC EDR)

### Last Completed Pipeline: location-service (P2B-001) - **FINALIZED** (2026-02-15)

- [x] /research - Complete (2026-02-15) - Package analysis, permission audit, service pattern design
- [x] /plan - Complete (2026-02-15) - Architecture, file structure, 7 tasks in 6 phases, ~14 new tests
- [x] /implement - Complete (2026-02-15) - 4 new files, 3 modified, 14 new tests, 405 total passing
- [x] /test - Complete (2026-02-15) - All 405 tests passing, 0 analyzer issues, all acceptance criteria met
- [x] /finalize - Complete (2026-02-15) - Committed locally

**Research Document:** `.claude/features/location-service/2026-02-15T20:00_research.md`
**Plan Document:** `.claude/features/location-service/2026-02-15T20:30_plan.md`
**Tasks:** `.claude/features/location-service/tasks.md`
**Implementation:** `.claude/active-work/location-service/implementation.md`
**Test Report:** `.claude/active-work/location-service/test-success.md`
**Summary:** `.claude/features/location-service/SUMMARY.md`
**Finalization:** `.claude/features/location-service/FINALIZATION_REPORT.md`
**Commit:** 60dbe61 - feat(location): add GPS location service for terrain sky detection

**Research Document:** `.claude/features/location-service/2026-02-15T20:00_research.md`
**Plan Document:** `.claude/features/location-service/2026-02-15T20:30_plan.md`
**Tasks:** `.claude/features/location-service/tasks.md`

### Previous Completed Pipeline: compass-native - **FINALIZED** (2026-02-13)

- [x] /research - Complete (2026-02-13) - Package analysis, API preservation plan
- [x] /plan - Complete (2026-02-13) - Minimal swap: flutter_compass for heading, keep everything else
- [x] /implement - Complete (2026-02-13) - Replaced magnetometer with flutter_compass, 392 tests passing, zero regressions
- [x] /test - Complete (2026-02-13) - All 392 tests passing, static analysis clean
- [x] /finalize - Complete (2026-02-13) - Committed locally

**Research Document:** `.claude/features/compass-native/2026-02-13T12:00_research.md`
**Plan Document:** `.claude/features/compass-native/2026-02-13T12:30_plan.md`
**Tasks:** `.claude/features/compass-native/tasks.md`
**Implementation:** `.claude/active-work/compass-native/implementation.md`
**Test Report:** `.claude/active-work/compass-native/test-success.md`
**Summary:** `.claude/features/compass-native/SUMMARY.md`
**Finalization:** `.claude/features/compass-native/FINALIZATION_REPORT.md`
**Commit:** (local, not pushed) - fix(compass): use native OS compass via flutter_compass instead of raw magnetometer

### Previous Pipeline: compass-freeze v2 (BUG-009 v2) - **FINALIZED** (2026-02-06)

- [x] /diagnose - Complete (2026-02-06) - v2 diagnosis: architectural rewrite needed
- [x] /plan - Complete (2026-02-06) - Timer-based decoupled architecture designed
- [x] /implement - Complete (2026-02-06) - Timer-based rewrite, 35 compass tests, 264 total tests, zero regressions
- [x] /test - Complete (2026-02-06) - All 390 tests passing, static analysis clean
- [x] /finalize - Complete (2026-02-06) - Committed locally

**Diagnosis Document:** `.claude/active-work/compass-freeze/diagnosis_v2.md`
**Plan Document:** `.claude/features/compass-freeze/2026-02-06_plan_v2.md`
**Tasks:** `.claude/features/compass-freeze/tasks.md`
**Implementation:** `.claude/active-work/compass-freeze/implementation_v2.md`
**Test Report:** `.claude/active-work/compass-freeze/test-success-v2.md`
**Summary:** `.claude/features/compass-freeze/SUMMARY.md`
**Finalization:** `.claude/features/compass-freeze/FINALIZATION_REPORT.md`
**Commit:** (local, not pushed) - fix(compass): rewrite CompassService with timer-based architecture to prevent freeze

### Previous Attempt (Failed)

compass-freeze v1 (BUG-009) - **FAILED ON DEVICE** (2026-02-06)

- [x] /diagnose - Complete (2026-02-06)
- [x] /plan - Complete (2026-02-06)
- [x] /implement - Complete (2026-02-06) - 382 tests passing, 7 new regression tests
- [x] /test - Complete (2026-02-06) - All 382 tests passing, no regressions
- [x] /finalize - Complete (2026-02-06) - Committed locally (but fix didn't work on device)

**Why it failed:** Reordering dead zone after smoothing still caused freeze once smoothed value converged. Dead zone architecture was fundamentally flawed.

**Diagnosis Document:** `.claude/active-work/compass-freeze/diagnosis.md`
**Plan Document:** `.claude/features/compass-freeze/2026-02-06T04:45_plan.md`
**Tasks:** `.claude/features/compass-freeze/tasks.md`
**Implementation:** `.claude/active-work/compass-freeze/implementation.md`
**Test Report:** `.claude/active-work/compass-freeze/test-success.md`

### Previously Completed Feature

compass-freeze (BUG-009) - **FINALIZED** (2026-02-06)

- [x] /diagnose - Complete (2026-02-06)
- [x] /plan - Complete (2026-02-06)
- [x] /implement - Complete (2026-02-06)
- [x] /test - Complete (2026-02-06) - All 382 tests passing
- [x] /finalize - Complete (2026-02-06) - Committed locally

**Summary:** Fixed compass widget freeze (stops updating after ~1 second). Root cause: dead zone check blocked smoothing, creating convergence trap. Fix: reordered code so smoothing always runs, dead zone only gates stream emission. Added 7 regression tests. All 382 tests passing, zero regressions.

**Documentation:** `.claude/features/compass-freeze/SUMMARY.md`
**Commit:** (local, not pushed) - fix(compass): prevent compass widget freeze from dead zone convergence trap

### Earlier Completed Feature

compass-widget-bugs (BUG-008) - **FINALIZED** (2026-02-03)

- [x] /diagnose - Complete (2026-02-03)
- [x] /plan - Complete (2026-02-03)
- [x] /implement - Complete (2026-02-03)
- [x] /test - Complete (2026-02-03) - All 375 tests passing
- [x] /finalize - Complete (2026-02-03)

**Diagnosis Document:** `.claude/active-work/compass-widget-bugs/diagnosis.md`
**Plan Document:** `.claude/features/compass-widget-bugs/2026-02-03T19:57_plan.md`
**Tasks:** `.claude/features/compass-widget-bugs/tasks.md`
**Implementation:** `.claude/active-work/compass-widget-bugs/implementation.md`
**Summary:** `.claude/features/compass-widget-bugs/SUMMARY.md`

**Phase 2 Roadmap:** `.claude/pipeline/ROADMAP_PHASE2.md`
**Issues Tracker:** `.claude/pipeline/POST_MVP_ISSUES.md`

---

## Implementation Summary (2026-02-06)

**Bug Fix:** Compass Widget Freeze (BUG-009 v2) - Compass stops updating after ~1 second

**What was fixed:**
- Root cause: Dead zone architecture caused convergence trap (even after v1 reordering fix)
- Fix: Full architectural rewrite to timer-based decoupled design with no dead zones
- Architecture: Sensor callbacks store raw values; 20 Hz timer smooths and always emits
- Circular interpolation: `_lerpAngle()` handles 0/360 wraparound correctly

**Files Modified:**
- `/workspace/wind_lens/lib/services/compass_service.dart` (203 → 190 lines)
  - Complete rewrite with timer-based architecture
  - Removed dead zone constants and gating logic
  - Added circular interpolation (`_lerpAngle`)
  - Added test helpers: `setRawHeading()`, `setRawPitch()`, `tick()`
- `/workspace/wind_lens/test/services/compass_service_test.dart` (553 → 741 lines)
  - Added 11 new tests (circular interpolation, continuous emission, timer architecture)
  - Removed 3 dead zone tests (no longer applicable)
  - Net: +8 tests

**Test Results:**
- All 390 tests passing (382 existing + 8 new)
- No regressions
- Flutter analyze lib/ - No issues found
- Test report: `.claude/active-work/compass-freeze/test-success-v2.md`

---

## Most Recently Completed

Bug Fix: compass-widget-bugs (BUG-008) - **FINALIZED** (2026-02-03)

- [x] /diagnose - Complete (2026-02-03)
- [x] /plan - Complete (2026-02-03)
- [x] /implement - Complete (2026-02-03)
- [x] /test - Complete (2026-02-03) - All 375 tests passing
- [x] /finalize - Complete (2026-02-03)

**Summary:** Fixed compass widget position overlap with InfoBar by increasing bottom offset from 76px to 92px (adds 16px visible gap). Verified compass rotation logic is working correctly (no fix needed for Bug 2). Single-line change, zero regressions. All 375 tests passing.

**Documentation:** `.claude/features/compass-widget-bugs/SUMMARY.md`
**Commit:** 4483af9 - fix(ui): adjust compass widget position above InfoBar

---

## Previously Completed

### Previous: Compass Widget Feature

Feature: compass-widget (P2A-003) - **FINALIZED** (2026-02-03)

- [x] /research - Complete (2026-02-03)
- [x] /plan - Complete (2026-02-03)
- [x] /implement - Complete (2026-02-03)
- [x] /test - Complete (2026-02-03) - All 375 tests passing
- [x] /finalize - Complete (2026-02-03)

**Summary:** Added circular compass widget (68x68px) in bottom-left corner showing device heading with rotating cardinal directions (N, S, E, W). N label is red and prominent. Glassmorphism styling matches AltitudeSlider and InfoBar. Widget positioned above InfoBar as Layer 7 in ARViewScreen. Added 17 new tests (375 total).

**Documentation:** `.claude/features/compass-widget/SUMMARY.md`
**Commit:** 2c93e83 - feat(ui): add compass widget showing device heading

### Previous: Streamline Ghosting Fix

Feature: streamline-ghosting (BUG-007) - **FINALIZED** (2026-02-03)

- [x] /diagnose - Complete (2026-02-03)
- [x] /plan - Complete (2026-02-03)
- [x] /implement - Complete (2026-02-03)
- [x] /test - Complete (2026-02-03) - All 358 tests passing
- [x] /finalize - Complete (2026-02-03)

**Summary:** Fixed critical bug where particle trails persisted incorrectly when particles were respawned or wrapped around screen edges, creating ghost trails across the entire screen. Added `resetTrail()` calls in 5 locations (3 in `_resetToSkyPosition()`, 2 for edge wrapping). Added 4 new tests. All 358 tests passing, no performance impact.

**Documentation:** `.claude/features/streamline-ghosting/SUMMARY.md`
**Commit:** 08065c0 - fix(particles): prevent streamline ghosting on particle respawn

---

## Previously Completed

### Previous: Wind Streamlines Feature

Feature: wind-streamlines (P2A-002) - **FINALIZED** (2026-02-03)

- [x] /research - Complete (2026-02-02)
- [x] /plan - Complete (2026-02-02)
- [x] /implement - Complete (2026-02-03)
- [x] /test - Complete (2026-02-03) - All 354 tests passing
- [x] /finalize - Complete (2026-02-03)

**Summary:** Implemented Windy.com-style flowing wind streamlines with speed-based color gradient (blue→purple), altitude-specific trail lengths, and ViewMode toggle. Added 59 new tests (354 total, up from 295). Uses efficient Float32List circular buffer for trail storage. Zero regressions.

**Documentation:** `.claude/features/wind-streamlines/SUMMARY.md`
**Commit:** 02f345a - feat(particles): add Windy.com-style wind streamlines

### Earlier: Sky Detection Regression Fix

Feature: sky-detection-regression (BUG-006) - **FINALIZED** (2026-02-02)

- [x] /diagnose - Complete (2026-02-02)
- [x] /plan - Complete (2026-02-02)
- [x] /implement - Complete (2026-02-02)
- [x] /test - Complete (2026-02-02) - All 295 tests passing
- [x] /finalize - Complete (2026-02-02)

**Summary:** Fixed sky detection calibration failure under overhangs/porches through multi-region sampling, sky color heuristics, reduced position bias, and manual recalibration. All 295 tests passing (254 original + 41 new).

**Documentation:** `.claude/features/sky-detection-regression/SUMMARY.md`

### Earlier: Performance Optimization

Feature: performance-optimization - **FINALIZED** (2026-02-02)
- [x] /test - Complete (2026-02-02)
- [x] /finalize - Complete (2026-02-02)

**Summary:** Optimized render loop from 5 FPS to target 45+ FPS through debugPrint removal, setState elimination, and memory allocation reduction. All 254 tests passing.

**Documentation:** `.claude/features/performance-optimization/SUMMARY.md`

---

## Earlier Completed Features

### BUG-005: Altitude Slider Drag Gesture

BUG-005: Altitude Slider Drag Gesture - **COMPLETED** (2026-01-22)

- [x] /diagnose - Complete (from `.claude/active-work/altitude-slider/diagnosis.md`)
- [x] /plan - Complete (2026-01-22)
- [x] /implement - Complete (2026-01-22)
- [x] /test - Complete (2026-01-22) - All 254 tests passing
- [x] /finalize - Complete (2026-01-22)

### BUG-004: Wind Animation Not World-Fixed

BUG-004: Wind Animation Not World-Fixed - **COMPLETED** (2026-01-22)

- [x] /diagnose - Complete (2026-01-22)
- [x] /plan - Complete (2026-01-22)
- [x] /implement - Complete (2026-01-22)
- [x] /test - Complete (2026-01-22) - All 253 tests passing
- [x] /finalize - Complete (2026-01-22)

**Fix Summary:**
Changed world anchoring formula to apply 100% anchoring for all altitude levels (removed parallaxFactor multiplication). Depth perception now achieved via color, trail scale, and speed. All tests passing, no regressions.

Feature summary: `.claude/features/wind-anchoring/SUMMARY.md`

### Earlier Completed Bugs

See POST_MVP_ISSUES.md for details on BUG-001, BUG-002, BUG-002.5, BUG-003.

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

## Post-MVP Bugs/Features Completed

| Issue | Description | Status |
|-------|-------------|--------|
| BUG-001 | Debug Panel Missing | DONE (2026-01-21) |
| BUG-002 | Sky Detection Level 2a Auto-Calibrating | DONE (2026-01-21) |
| BUG-002.5 | Sky Detection Not Working on Real Device | DONE (2026-01-22) |
| BUG-003 | Particles not masked to sky pixels | DONE (2026-01-21) |
| BUG-004 | Wind animation not world-fixed | DONE (2026-01-22) |
| BUG-005 | Altitude slider UX (drag gesture) | DONE (2026-01-22) |
| P2A-001 | Performance optimization (5 FPS to 45+ FPS) | DONE (2026-02-02) |
| BUG-006 | Sky detection regression (overhang scenario) | DONE (2026-02-02) |
| P2A-002 | wind-streamlines (Windy.com style trails) | DONE (2026-02-03) |
| BUG-007 | Streamline ghosting (ghost trails on respawn) | DONE (2026-02-03) |
| P2A-003 | compass-widget | DONE (2026-02-03) |
| BUG-008 | Compass widget bugs (position overlap + rotation check) | DONE (2026-02-03) |
| BUG-009 | Compass widget freeze (stops updating after ~1s) | DONE v2 (2026-02-06) |
| compass-native | Native OS compass integration (flutter_compass) | DONE (2026-02-13) |
| P2B-001 | location-service | DONE (2026-02-15) |
| SPEC-001 | architectural-foundation | DONE (2026-02-25) |
| gimbal-lock v2 | Heading freeze at high pitch angles — hysteresis lock (replaces v1 soft blend) | DONE (2026-02-25) |
| P2B-006 | real-wind-data (OGC EDR — Shyft primary, Folkweather fallback) | DONE (2026-02-26) |
| home-screen | HomeScreen landing page, Shyft Lens branding, terrain panorama, animated particles | DONE (2026-02-26) |
| wind-dome | 3D wind dome visualization, dome painter, altitude rings, real wind data | DONE (2026-03-01) |
| location-picker | OSM map picker, location override provider, effectivePositionProvider, GPS chain fix, LocationIndicatorChip | DONE (2026-03-02) |
| P2B-002+003 | heywhatsthat-client: HwtHorizonProvider, real terrain silhouette on home screen, declination+panoramaId fields | DONE (2026-03-04) |
| home-screen-polish | Fix mph→m/s unit label, brighten header/sublabel/subtitle colors for legibility | DONE (2026-03-04) |

---

## What To Do

**Next: Start Phase 2b pipeline — Terrain Sky Detection & Location**

### Phase 2b Steps (incremental, one at a time)

See `ROADMAP_PHASE2.md` for full details. All work on branch `feature/terrain-sky-detection`.

| Step | Feature | Status | Description |
|------|---------|--------|-------------|
| 1 | P2B-001 location-service | **FINALIZED** | GPS coordinates + permissions |
| 2 | P2B-002 heywhatsthat-client | **Next** | API client for horizon data |
| 3 | P2B-003 horizon-cache | Waiting | Cache horizon profiles locally |
| 4 | P2B-004 terrain-sky-mask | Waiting | Map horizon onto camera view |
| 5 | P2B-005 detection-mode-toggle | Waiting | HSV / Terrain / Combined toggle |
| 6 | P2B-006 real-wind-data | **FINALIZED** | OGC EDR real wind data (Shyft/Folkweather) |

**Reference docs:**
- `/workspace/heywhatsthat-api-reference (1).md` — HeyWhatsThat API endpoints
- `/workspace/sky-claculation.md` — FOV/frustum math, EDR radius calculations

### User Testing Notes (2026-02-03)

**Working:**
- Sky detection calibrates on cloudy day
- Sky detection works under overhangs/porches (fixed BUG-006)
- Particles masked to sky regions
- World anchoring correct
- Drag gesture on altitude slider
- FPS: 45+ (fixed from 5)
- Streamline visualization implemented (Windy.com style)
- Streamline ghosting fix implemented (BUG-007) **COMPLETE**
- Compass widget implemented (P2A-003) **COMPLETE**

**Known Limitations:**
- Trees not well recognized by sky detection (deferred - ML would be required)

**Device Testing Required:**
- Compass widget position (verify 16px gap above InfoBar)
- Compass rotation (verify smooth rotation with device heading)

**Screenshots:**
- `/workspace/images/app_img.PNG` - Previous app with dots
- `/workspace/images/windy_img_goal.png` - Reference (Windy.com streamlines)

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
