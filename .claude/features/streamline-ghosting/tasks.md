# Tasks: Streamline Ghosting Bug Fix (BUG-007)

## Metadata

- **Feature:** streamline-ghosting (BUG-007)
- **Created:** 2026-02-03T00:30
- **Status:** implementation-complete
- **Based On:** `/workspace/.claude/features/streamline-ghosting/2026-02-03T00:30_plan.md`

---

## Execution Rules

1. **TDD Order:** Write tests (Phase 1) BEFORE implementation (Phase 2)
2. **Sequential:** Tasks within each phase must be done in order
3. **Completion:** Mark checkbox `[x]` when subtask is done
4. **Testing:** Run tests after each task to verify no regressions

---

## Phase 1: Tests (TDD - Write Failing Tests First)

### Task 1.1: Write test for trail reset on particle respawn

- [x] Add test to `particle_overlay_test.dart`
- [x] Test that when particle is reset via expiration, trail is cleared
- [x] Test should verify `trailCount == 0` after particle recycle
- [x] Run test - should FAIL (expected, TDD)

**File:** `/workspace/wind_lens/test/widgets/particle_overlay_test.dart`

**Test Name:** `'particles reset via _resetToSkyPosition have cleared trail'`

**Acceptance Criteria:**
- [x] Test exists and runs
- [x] Test fails before fix (verifies bug exists)

---

### Task 1.2: Write test for trail reset on screen edge wrap (streamlines mode)

- [x] Add test to `particle_overlay_test.dart`
- [x] Test that in streamlines mode, edge wrapping clears trail
- [x] Test should verify no cross-screen line artifacts

**File:** `/workspace/wind_lens/test/widgets/particle_overlay_test.dart`

**Test Name:** `'streamlines mode clears trail on screen edge wrap'`

**Acceptance Criteria:**
- [x] Test exists and runs
- [x] Test verifies streamlines-specific behavior

---

### Task 1.3: Write test for dots mode NOT affected by fix

- [x] Add test to `particle_overlay_test.dart`
- [x] Test that dots mode behavior unchanged by edge wrap
- [x] This ensures fix does not break existing functionality

**File:** `/workspace/wind_lens/test/widgets/particle_overlay_test.dart`

**Test Name:** `'dots mode edge wrap does not affect particle state unnecessarily'`

**Acceptance Criteria:**
- [x] Test exists and runs
- [x] Test passes (dots mode should already work)

---

### Task 1.4: Write integration test for no ghost segments after recycle

- [x] Add integration test that simulates full particle lifecycle
- [x] Run animation, force particle recycle, verify rendering
- [x] Test should detect if ghost lines would be drawn

**File:** `/workspace/wind_lens/test/widgets/particle_overlay_test.dart`

**Test Name:** `'no ghost trail segments after particle respawn in streamlines mode'`

**Acceptance Criteria:**
- [x] Test exists and runs
- [x] Test covers the full recycle scenario

---

## Phase 2: Implementation (Fix the Bug)

### Task 2.1: Add resetTrail() call in _resetToSkyPosition()

- [x] Open `/workspace/wind_lens/lib/widgets/particle_overlay.dart`
- [x] Locate `_resetToSkyPosition()` method (lines 199-223)
- [x] Add `p.resetTrail();` after `p.age = 0.0;` in all three code paths:
  - [x] Line 206 (high sky fraction path)
  - [x] Line 217 (found sky position in loop)
  - [x] Line 225 (fallback path)
- [x] Run tests to verify fix

**File:** `/workspace/wind_lens/lib/widgets/particle_overlay.dart`

**Lines:** 199-226

**Acceptance Criteria:**
- [x] `resetTrail()` called in all three return paths
- [x] Task 1.1 test now passes
- [x] Task 1.4 test now passes

---

### Task 2.2: Add resetTrail() call on screen edge wrap (streamlines mode only)

- [x] Locate edge wrapping code in `_onTick()` (lines 327-336)
- [x] Add `wrapped` boolean tracking
- [x] Add conditional `resetTrail()` call when wrapped && isStreamlines
- [x] Run tests to verify fix

**File:** `/workspace/wind_lens/lib/widgets/particle_overlay.dart`

**Lines:** 327-336

**Code Change:**
```dart
// Before:
if (p.x < 0) p.x += 1.0;
if (p.x > 1) p.x -= 1.0;
if (p.y < 0) p.y += 1.0;
if (p.y > 1) p.y -= 1.0;

// After:
bool wrapped = false;
if (p.x < 0) { p.x += 1.0; wrapped = true; }
if (p.x > 1) { p.x -= 1.0; wrapped = true; }
if (p.y < 0) { p.y += 1.0; wrapped = true; }
if (p.y > 1) { p.y -= 1.0; wrapped = true; }
if (wrapped && isStreamlines) {
  p.resetTrail();
}
```

**Acceptance Criteria:**
- [x] Edge wrap code updated with `wrapped` tracking
- [x] `resetTrail()` called only when `wrapped && isStreamlines`
- [x] Task 1.2 test now passes
- [x] Task 1.3 test still passes (dots mode unaffected)

---

## Phase 3: Validation

### Task 3.1: Run full test suite

- [x] Run `flutter test` in `/workspace/wind_lens`
- [x] Verify all 358 tests pass (354 existing + 4 new)
- [x] Document test count and results

**Command:** `cd /workspace/wind_lens && flutter test`

**Result:** 358 tests passing

**Acceptance Criteria:**
- [x] All tests pass
- [x] No regressions introduced
- [x] New tests (4) pass

---

### Task 3.2: Verify build succeeds

- [x] Run `flutter analyze`
- [x] Verify no new compilation errors or warnings

**Command:** `cd /workspace/wind_lens && flutter analyze`

**Result:** No new issues introduced (62 pre-existing deprecation warnings in unrelated test file)

**Acceptance Criteria:**
- [x] Build completes successfully
- [x] No new warnings introduced

---

## Phase 4: Handoff to Test Agent

### Handoff Checklist

Before running `/test streamline-ghosting`:

- [x] All Phase 1 tasks complete (tests written)
- [x] All Phase 2 tasks complete (implementation done)
- [x] All Phase 3 tasks complete (validation passed)
- [x] 358 tests passing (354 original + 4 new)
- [x] Build succeeds
- [x] Code changes match plan specification

### Files Changed

| File | Change Type | Description |
|------|-------------|-------------|
| `lib/widgets/particle_overlay.dart` | Modified | Added resetTrail() calls in 2 locations |
| `test/widgets/particle_overlay_test.dart` | Modified | Added 4 new tests |

### Manual Testing Required

The following must be tested on a real device (cannot be automated):

- [ ] Run app in streamlines mode for 5+ minutes
- [ ] Move phone rapidly to trigger particle recycling
- [ ] Verify no ghost trails accumulate at screen edges
- [ ] Verify particles spawn cleanly without cross-screen lines
- [ ] Verify dots mode still works correctly
- [ ] Verify FPS remains 45+

---

## Summary

| Phase | Tasks | Description |
|-------|-------|-------------|
| Phase 1 | 1.1-1.4 | Write failing tests (TDD) - COMPLETE |
| Phase 2 | 2.1-2.2 | Implement fix - COMPLETE |
| Phase 3 | 3.1-3.2 | Validate all tests pass - COMPLETE |
| Phase 4 | Handoff | Ready for Test Agent - COMPLETE |

**Total Tasks:** 8
**Completed:** 8
**Estimated Time:** 30-45 minutes
**Actual Time:** ~15 minutes
**Risk Level:** Low (targeted fix, well-understood root cause)
