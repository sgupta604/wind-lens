# Tasks: Wind Animation World-Fixed Anchoring (BUG-004)

## Feature Metadata

| Field | Value |
|-------|-------|
| Feature | wind-anchoring |
| Type | Bug Fix |
| Timestamp | 2026-01-22T14:30 |
| Status | implemented |
| Based On | `2026-01-22T14:30_plan.md` |

## Execution Rules

1. **TDD Order:** Write tests BEFORE implementation
2. **Sequential Execution:** Tasks must be done in order (dependencies)
3. **Completion Markers:** Check off items as completed
4. **No Parallel Tasks:** This is a focused fix - do sequentially

---

## Phase 1: Tests First (TDD)

### Task 1.1: Add World Anchoring Unit Tests

- [x] Add new test group `'ParticleOverlay World Anchoring'` to test file
- [x] Implement test: "all altitude levels shift equally on heading change"
- [x] Implement test: "90-degree rotation produces approximately 25% shift"
- [x] Implement test: "heading wraparound handled correctly (359 -> 1 degrees)"
- [x] Run tests - verify they compile and execute

**Files:** `/workspace/wind_lens/test/widgets/particle_overlay_test.dart`

**Test Details:**

```dart
group('ParticleOverlay World Anchoring', () {
  testWidgets('all altitude levels shift equally on heading change', ...);
  testWidgets('90-degree rotation produces approximately 25% particle shift', ...);
  testWidgets('heading wraparound handled correctly (359 to 1 degrees)', ...);
});
```

**Acceptance Criteria:**
- [x] Three new tests added
- [x] Tests compile without errors
- [x] Tests pass after implementation

---

## Phase 2: Core Implementation

### Task 2.1: Fix World Anchoring in particle_overlay.dart

- [x] Open `/workspace/wind_lens/lib/widgets/particle_overlay.dart`
- [x] Locate line 266 (parallax application in `_onTick()`)
- [x] Change `p.x -= (headingDelta / 360.0) * parallaxFactor;`
- [x] To: `p.x -= (headingDelta / 360.0);`
- [x] Update comment above to explain world anchoring
- [x] Verify `parallaxFactor` variable is no longer used (kept for future)

**Files:** `/workspace/wind_lens/lib/widgets/particle_overlay.dart` (lines 262-270)

**Before:**
```dart
// Apply parallax offset based on heading change
// Higher altitude (lower parallax factor) = less movement when phone rotates
p.x -= (headingDelta / 360.0) * parallaxFactor;
```

**After:**
```dart
// WORLD ANCHORING: All particles are 100% anchored to world space
// When phone rotates X degrees, particles shift X/360 of screen width
// This creates the AR illusion of particles fixed in the real sky
// Spec: "Particles should appear to stay fixed in world space" (Section 11)
// BUG-004 Fix: Removed parallaxFactor multiplication that broke world anchoring
p.x -= (headingDelta / 360.0);
```

**Acceptance Criteria:**
- [x] Line 269 no longer multiplies by parallaxFactor
- [x] Comment updated to explain world anchoring
- [x] Code compiles without errors

---

### Task 2.2: Update Documentation in altitude_level.dart

- [x] Open `/workspace/wind_lens/lib/models/altitude_level.dart`
- [x] Locate `parallaxFactor` getter (lines 84-98)
- [x] Update documentation to reflect new usage
- [x] Clarify that depth perception comes from color/size/speed

**Files:** `/workspace/wind_lens/lib/models/altitude_level.dart` (lines 84-98)

**Before:**
```dart
/// Parallax factor for creating depth perception.
///
/// Lower values = objects appear further away (less movement when rotating phone).
/// - surface: 1.0 (close, moves most when phone rotates)
/// - midLevel: 0.6 (moderate distance)
/// - jetStream: 0.3 (far away, barely moves when phone rotates)
///
/// This creates the illusion that higher altitude particles are further
/// from the viewer, similar to how distant mountains appear to move
/// less than nearby trees when you turn your head.
```

**After:**
```dart
/// Parallax factor for potential depth effects.
///
/// NOTE: As of BUG-004 fix, this factor is NO LONGER used for world anchoring.
/// All altitude levels now use 100% world anchoring (particles stay fixed in
/// real-world space when phone rotates).
///
/// Depth perception is achieved through other visual properties:
/// - Particle color: white (surface) -> cyan (mid) -> purple (jet stream)
/// - Trail scale: 1.0 -> 0.7 -> 0.5 (shorter = further)
/// - Speed multiplier: 1.0x -> 1.5x -> 3.0x (faster at altitude)
///
/// Values retained for potential future subtle parallax enhancement:
/// - surface: 1.0
/// - midLevel: 0.6
/// - jetStream: 0.3
```

**Acceptance Criteria:**
- [x] Documentation updated
- [x] Explains BUG-004 fix
- [x] Lists alternative depth cues

---

## Phase 3: Verification

### Task 3.1: Run Unit Tests

- [x] Run `flutter test test/widgets/particle_overlay_test.dart`
- [x] Verify all existing tests pass
- [x] Verify new world anchoring tests pass
- [x] Fix any test failures

**Command:**
```bash
cd /workspace/wind_lens && flutter test test/widgets/particle_overlay_test.dart
```

**Acceptance Criteria:**
- [x] All tests pass (30 tests, 0 failures)
- [x] No warnings or errors

---

### Task 3.2: Run Full Test Suite

- [x] Run `flutter test` for entire project
- [x] Verify no regressions introduced
- [x] Fix any failures

**Command:**
```bash
cd /workspace/wind_lens && flutter test
```

**Acceptance Criteria:**
- [x] All project tests pass (253 tests, 0 failures)
- [x] Build succeeds

---

### Task 3.3: Verify Build

- [x] Run `flutter analyze` - no issues found
- [x] Run `flutter build bundle` - build succeeds
- [x] Note: Full device testing requires real device

**Command:**
```bash
cd /workspace/wind_lens && flutter analyze
cd /workspace/wind_lens && flutter build bundle
```

**Acceptance Criteria:**
- [x] Build completes successfully
- [x] No compilation errors
- [x] No static analysis issues

---

## Phase 4: Ready for Test Agent

### Handoff Checklist

Before marking complete, verify:

- [x] **Code Changes**
  - [x] particle_overlay.dart: World anchoring formula fixed
  - [x] altitude_level.dart: Documentation updated

- [x] **Tests**
  - [x] 3 new world anchoring tests added
  - [x] All new tests pass
  - [x] All existing tests pass (no regressions)

- [x] **Build**
  - [x] `flutter test` passes (253 tests)
  - [x] `flutter build bundle` succeeds
  - [x] `flutter analyze` no issues

- [x] **Documentation**
  - [x] Code comments explain the fix
  - [x] altitude_level.dart documents depth perception approach

---

## Summary

| Phase | Tasks | Est. Time | Actual |
|-------|-------|-----------|--------|
| 1. Tests First | 1 task | 15 min | Complete |
| 2. Core Implementation | 2 tasks | 15 min | Complete |
| 3. Verification | 3 tasks | 15 min | Complete |
| **Total** | **6 tasks** | **~45 min** | **Complete** |

## Files Modified

1. `/workspace/wind_lens/lib/widgets/particle_overlay.dart` - Fix formula (line 269)
2. `/workspace/wind_lens/lib/models/altitude_level.dart` - Update docs (lines 84-98)
3. `/workspace/wind_lens/test/widgets/particle_overlay_test.dart` - Add 3 tests (lines 864-987)

## Manual Testing (Post-Implementation)

After `/test` passes, manually verify on real device:

1. Run app on physical device
2. Point phone at sky
3. Slowly rotate phone 90 degrees clockwise
4. **Expected:** ALL particles (white, cyan, purple) shift equally left
5. **Verify:** Particles feel "fixed in sky" not "stuck to screen"
6. Test all three altitude levels via slider
