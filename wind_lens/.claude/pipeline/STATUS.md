# Pipeline Status

**Last updated:** 2026-03-05

## Current Feature: app-performance-polish

| Field | Value |
|-------|-------|
| Feature | app-performance-polish (Streams 1-4 + Phase 6 bugfixes DONE) |
| Phase | implement-complete — needs /test |
| Next step | /test app-performance-polish |
| Branch | feature/app-performance-polish (pushed to origin) |
| Notes | All streams + Phase 6 bugfixes implemented. 835 tests pass, 47 explicit-path tests pass, 0 analyzer errors. Bugs fixed: (1) keepAlive on sensorNotifiersProvider, (2) ref.read in HomeScreen initState, (3) heading line removed, (4) dome zoom deferred init. Implementation summary at `.claude/active-work/app-performance-polish/implementation_phase6.md`. |

## Previous Feature: large-dome-wind-grid / dome-radius-stale-data

## Phase History: large-dome-wind-grid + dome-radius-stale-data

| Phase | Status | Date | Notes |
|-------|--------|------|-------|
| research | complete | 2026-03-04 | 7 FRs, 7 TRs, all questions resolved, hybrid grid+point approach recommended |
| plan | complete | 2026-03-04 | 7 files to modify, 0 new files, 18 tasks in 6 phases, ~25 new tests |
| implement | complete | 2026-03-04 | 6 source files modified, 3 test files updated, 817 tests pass, 0 errors, 0 warnings |
| diagnose | complete | 2026-03-04 | 3 bugs found: zoom reset, wrong grid direction, frozen particles. Root cause: metersPerRenderUnit mismatch between screen and field |
| diagnose (v2) | complete | 2026-03-04 | Direction bug at 15km/50km: code coordinate system verified correct. Primary root cause: grid API returns different wind data than point API. Defensive fix: sort Folkweather axes + add diagnostic logging |
| implement (v2) | complete | 2026-03-04 | Folkweather sort+reindex fix in both area parsers, diagnostic logging in fetcher + API client, 3 new tests, 825 tests pass |
| dome-radius-stale-data | complete | 2026-03-04 | Cache key includes radius, DomeWindProfile carries radiusMeters, stale-data guard in provider, 25km grid threshold, 25km preset |
| test | complete | 2026-03-04 | 825 tests pass (exit code 0), 47 explicit path tests pass, dart analyze 0 errors 0 warnings |
| finalize | complete | 2026-03-04 | PR created to master, branch feature/large-dome-wind-grid |

## Parked Feature: home-screen-polish

| Phase | Status | Date | Notes |
|-------|--------|------|-------|
| research | skipped | 2026-03-04 | User provided requirements inline (3 cosmetic fixes) |
| plan | complete | 2026-03-04 | 2 files to modify, 1 new test, 3-phase task breakdown |
| implement | pending | - | - |
| test | pending | - | - |
| finalize | pending | - | - |

## Previous Feature: dome-direction-bug

| Phase | Status | Date | Notes |
|-------|--------|------|-------|
| research | skipped | 2026-03-04 | Diagnosis at `.claude/active-work/dome-direction-bug/diagnosis.md` serves as research |
| plan | complete | 2026-03-04 | Single-line fix + 2 directional tests, 3-phase task breakdown |
| implement | complete | 2026-03-04 | z -= wind.v sign fix, 2 directional tests, 5km preset tests |
| test | complete | 2026-03-04 | 842 tests pass (auto) + 47 explicit = 889 total, 0 errors, 0 warnings |
| finalize | complete | 2026-03-04 | Committed locally on feature/on-device-fixes-march |

## Previous Feature: altitude-slider-redesign

| Phase | Status | Date | Notes |
|-------|--------|------|-------|
| research | complete | 2026-03-03 | 43 files analyzed, 298 enum refs across 32 files, Option A (expand enum) recommended |
| plan | complete | 2026-03-03 | Architecture plan + 6-phase task breakdown |
| implement | complete | 2026-03-03 | 6 enum values, collapsible slider, 6-tick rail, dome label, 775 tests pass |
| test | complete | 2026-03-03 | 822 tests pass (775 + 47), 0 errors, 0 warnings |
| finalize | complete | 2026-03-04 | Committed locally on feature/on-device-fixes-march |

## Next Command

```
/test app-performance-polish
```
