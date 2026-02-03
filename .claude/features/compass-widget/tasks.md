# Task Breakdown: compass-widget

## Metadata
- **Feature:** compass-widget
- **Created:** 2026-02-03T19:28
- **Status:** implement-complete
- **Based On:** 2026-02-03T19:28_plan.md

---

## Execution Rules

1. **TDD Order:** Write tests BEFORE implementation (Phase 1 before Phase 2)
2. **Sequential:** Tasks must be completed in order within each phase
3. **[P] Marker:** Tasks marked [P] can run in parallel with other [P] tasks
4. **Completion:** Mark checkbox when task is fully done

---

## Phase 1: Tests (TDD - Write First)

### Task 1.1: Create Test File Structure
- [x] Create `/workspace/wind_lens/test/widgets/compass_widget_test.dart`
- [x] Add imports for flutter_test, material, compass_widget

**Files:** `test/widgets/compass_widget_test.dart`

**Acceptance Criteria:**
- [x] Test file exists and compiles
- [x] Imports are correct

---

### Task 1.2: Write CompassWidget Unit Tests
- [x] Test: renders without crashing
- [x] Test: has BackdropFilter for glassmorphism
- [x] Test: has ClipRRect for rounded corners
- [x] Test: has CustomPaint widget
- [x] Test: accepts heading boundary values (0, 180, 360)
- [x] Test: displays cardinal directions (N, S, E, W)

**Files:** `test/widgets/compass_widget_test.dart`

**Acceptance Criteria:**
- [x] All 6 tests written
- [x] Tests fail initially (widget doesn't exist yet)

---

### Task 1.3: Write CompassPainter Unit Tests
- [x] Test: shouldRepaint returns true when heading changes
- [x] Test: shouldRepaint returns false when heading unchanged

**Files:** `test/widgets/compass_widget_test.dart`

**Acceptance Criteria:**
- [x] Both tests written
- [x] Tests fail initially (painter doesn't exist yet)

---

## Phase 2: Core Implementation

### Task 2.1: Create CompassWidget File
- [x] Create `/workspace/wind_lens/lib/widgets/compass_widget.dart`
- [x] Add imports (dart:ui, dart:math, flutter/material)
- [x] Define CompassWidget class extending StatelessWidget
- [x] Add heading property with required parameter
- [x] Add size constants (_diameter = 68.0, _borderRadius = 34.0)

**Files:** `lib/widgets/compass_widget.dart`

**Acceptance Criteria:**
- [x] File exists
- [x] Widget compiles
- [x] Takes heading as required parameter

---

### Task 2.2: Implement Glassmorphism Container
- [x] Add ClipRRect with circular border radius
- [x] Add BackdropFilter with blur(sigmaX: 10, sigmaY: 10)
- [x] Add Container with semi-transparent background
- [x] Add border with alpha 0.3
- [x] Set fixed size (68 x 68)

**Files:** `lib/widgets/compass_widget.dart`

**Acceptance Criteria:**
- [x] Glassmorphism tests pass
- [x] ClipRRect test passes
- [x] BackdropFilter test passes

---

### Task 2.3: Implement CompassPainter
- [x] Create CompassPainter class extending CustomPainter
- [x] Add heading property
- [x] Implement paint() method skeleton
- [x] Implement shouldRepaint() method

**Files:** `lib/widgets/compass_widget.dart`

**Acceptance Criteria:**
- [x] shouldRepaint tests pass
- [x] Painter compiles

---

### Task 2.4: Implement Compass Dial Drawing
- [x] Draw outer ring (circle stroke)
- [x] Save canvas and rotate by -heading degrees
- [x] Draw cardinal labels (N in red, S/E/W in white)
- [x] Restore canvas
- [x] Draw direction indicator (triangle at top)
- [x] Add tick marks for visual reference

**Files:** `lib/widgets/compass_widget.dart`

**Acceptance Criteria:**
- [x] Cardinal direction test passes
- [x] All widget tests pass

---

### Task 2.5: Connect Painter to Widget
- [x] Add CustomPaint to widget build method
- [x] Pass heading to CompassPainter
- [x] Set size to (_diameter, _diameter)

**Files:** `lib/widgets/compass_widget.dart`

**Acceptance Criteria:**
- [x] CustomPaint test passes
- [x] All CompassWidget tests pass

---

## Phase 3: Integration

### Task 3.1: Add CompassWidget to ARViewScreen
- [x] Import compass_widget.dart
- [x] Add Layer 7 comment
- [x] Add Positioned widget at bottom-left
- [x] Set left: 16, bottom: bottomPadding + 76
- [x] Add CompassWidget with heading: _heading

**Files:** `lib/screens/ar_view_screen.dart` (lines ~245-262)

**Acceptance Criteria:**
- [x] CompassWidget appears in ARViewScreen
- [x] Position is bottom-left, above InfoBar
- [x] Does not overlap with other UI elements

---

## Phase 4: Verification

### Task 4.1: Run All Tests
- [x] Run `flutter test` in wind_lens directory
- [x] Verify all 358+ tests pass (original + new compass tests)
- [x] No regressions

**Files:** N/A (test execution)

**Acceptance Criteria:**
- [x] All tests pass
- [x] No test failures
- [x] New test count: 375 (original 358 + 17 new)

---

### Task 4.2: Build Verification
- [x] Run `flutter analyze lib/`
- [x] Verify analysis succeeds
- [x] No compilation errors

**Files:** N/A (build execution)

**Acceptance Criteria:**
- [x] Analysis completes successfully
- [x] No errors in lib/ folder

---

## Handoff Checklist for Test Agent

Before running `/test compass-widget`:

- [x] `compass_widget.dart` exists at `lib/widgets/`
- [x] `compass_widget_test.dart` exists at `test/widgets/`
- [x] ARViewScreen imports and uses CompassWidget
- [x] All new tests pass locally
- [x] Build succeeds

---

## Summary

| Phase | Tasks | Estimated Time |
|-------|-------|----------------|
| Phase 1: Tests | 3 tasks | ~15 min |
| Phase 2: Implementation | 5 tasks | ~30 min |
| Phase 3: Integration | 1 task | ~5 min |
| Phase 4: Verification | 2 tasks | ~10 min |
| **Total** | **11 tasks** | **~60 min** |

---

## Dependencies Graph

```
Task 1.1 (test file)
    |
Task 1.2 (widget tests) -+
Task 1.3 (painter tests) |
    |                    |
Task 2.1 (create widget) |
    |                    |
Task 2.2 (glassmorphism) |
    |                    |
Task 2.3 (painter class) |
    |                    |
Task 2.4 (dial drawing) <+
    |
Task 2.5 (connect)
    |
Task 3.1 (integration)
    |
Task 4.1 (tests)
    |
Task 4.2 (build)
```
