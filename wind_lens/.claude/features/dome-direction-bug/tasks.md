# Tasks: Dome Wind Direction Bug Fix

| Field | Value |
|-------|-------|
| Feature | dome-direction-bug |
| Created | 2026-03-04T00:00 |
| Status | complete |
| Based on | `2026-03-04T00:00_plan.md` |

## Execution Rules

- Follow TDD: write tests first (Phase 1), then apply fix (Phase 2), then verify (Phase 3).
- Phases are sequential. No parallelism needed -- this is a 3-step fix.
- Mark each checkbox when complete.

---

## Phase 1: Test (TDD - write failing tests)

### Task 1.1: Add directional unit tests to dome_particle_test.dart
- [x] Add test: 'positive v (northward wind) moves particle in -z direction'
  - Create DomeWindField with u=0, v=+10 at two layers (0m and 1800m)
  - Place particle at origin (x=0, y=1.0, z=0)
  - Tick once with dt=1/60
  - Assert p.z < 0 (northward = -z in dome space)
  - Assert p.x close to 0 (no east-west wind)
- [x] Add test: 'positive u (eastward wind) moves particle in +x direction'
  - Create DomeWindField with u=+10, v=0 at two layers (0m and 1800m)
  - Place particle at origin (x=0, y=1.0, z=0)
  - Tick once with dt=1/60
  - Assert p.x > 0 (eastward = +x in dome space)
  - Assert p.z close to 0 (no north-south wind)
- [x] Run `flutter test test/features/wind_dome/models/dome_particle_test.dart`
  - v-direction test FAILED (confirmed bug exists) -- p.z was +0.12, expected < 0
  - u-direction test PASSED (confirmed u is correct)

**Files:** `test/features/wind_dome/models/dome_particle_test.dart`

**Acceptance Criteria:**
- [x] Two new tests added in the `tick()` group
- [x] v-direction test fails before fix (confirms bug)
- [x] u-direction test passes (confirms u not broken)

---

## Phase 2: Fix

### Task 2.1: Negate v-component in DomeParticle.tick()
- [x] Change line 121 of `dome_particle.dart` from `z += wind.v` to `z -= wind.v`
- [x] Update inline comment to document the coordinate mapping
- [x] Run `flutter test test/features/wind_dome/models/dome_particle_test.dart`
  - All 20 tests PASSED including both new directional tests

**Files:** `lib/features/wind_dome/models/dome_particle.dart` (line 122)

**Acceptance Criteria:**
- [x] Line 122 reads `z -= wind.v * DomeConstants.velocityScale * dt;`
- [x] All dome_particle_test.dart tests pass (including 2 new directional tests)

---

## Phase 3: Verify

### Task 3.1: Run full test suite
- [x] Run `flutter test` from the project root
- [x] Verify all tests pass: **777 tests, 0 failures**
- [x] No new warnings or errors (13 pre-existing info-level warnings only)

**Acceptance Criteria:**
- [x] Full test suite passes with 0 failures
- [x] No regressions introduced

---

## Handoff Checklist (for Test Agent)

- [x] `dome_particle.dart` line 122: `z -=` instead of `z +=`
- [x] Two new directional tests in `dome_particle_test.dart`
- [x] Full test suite passes (777 tests)
- [x] Ready for `/test dome-direction-bug`
