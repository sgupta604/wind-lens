# Tasks: particle-system

## Metadata
- **Feature:** particle-system
- **Created:** 2026-01-21T01:37
- **Status:** implementation-complete
- **Based On:** 2026-01-21T01:37_plan.md

---

## Execution Rules

1. **TDD Order:** Write tests BEFORE implementation (tests will fail initially)
2. **Sequential:** Tasks must be completed in order unless marked `[P]`
3. **Parallel OK:** Tasks marked `[P]` can run in parallel with other `[P]` tasks
4. **Completion:** Check boxes when subtasks are done

---

## Phase 1: Setup

No setup required for this feature. Existing project structure and SkyMask are already in place.

---

## Phase 2: Tests (TDD - Write Tests First)

### Task 2.1: Write Particle Model Tests

Write unit tests for the Particle model BEFORE implementing it.

- [x] Create test file `test/models/particle_test.dart`
- [x] Write test: creates with default values (x=0, y=0, age=0, trailLength=10)
- [x] Write test: creates with custom values
- [x] Write test: reset() randomizes x and y positions
- [x] Write test: reset() resets age to 0.0
- [x] Write test: isExpired returns true when age >= 1.0
- [x] Write test: isExpired returns false when age < 1.0
- [x] Write test: positions stay in 0-1 range after reset
- [x] Run tests (expect failures - implementation doesn't exist yet)

**Files:** `test/models/particle_test.dart`

**Acceptance Criteria:**
- [x] Test file compiles
- [x] All tests fail (no implementation yet)
- [x] Tests cover all public API of Particle

---

### Task 2.2: Write ParticleOverlay Widget Tests [P]

Write widget tests for ParticleOverlay BEFORE implementing it.

- [x] Create test file `test/widgets/particle_overlay_test.dart`
- [x] Create mock SkyMask for testing
- [x] Write test: creates with required skyMask parameter
- [x] Write test: uses CustomPaint widget
- [x] Write test: respects particleCount parameter (default 2000)
- [x] Write test: accepts optional windAngle parameter
- [x] Run tests (expect failures - implementation doesn't exist yet)

**Files:** `test/widgets/particle_overlay_test.dart`

**Acceptance Criteria:**
- [x] Test file compiles
- [x] All tests fail (no implementation yet)
- [x] Tests cover widget construction and structure

---

## Phase 3: Core Implementation (Sequential)

### Task 3.1: Implement Particle Model

Create the Particle data class.

- [x] Create file `lib/models/particle.dart`
- [x] Import `dart:math` for Random
- [x] Implement Particle class with x, y, age, trailLength fields
- [x] Implement constructor with default values
- [x] Implement reset(Random random) method
- [x] Implement isExpired getter
- [x] Run particle tests (all should pass now)

**Files:** `lib/models/particle.dart`

**Acceptance Criteria:**
- [x] All Task 2.1 tests pass
- [x] `flutter analyze lib/models/particle.dart` shows no issues

---

### Task 3.2: Implement ParticleOverlay Widget

Create the StatefulWidget with Ticker animation.

- [x] Create file `lib/widgets/particle_overlay.dart`
- [x] Import required packages (flutter, dart:math)
- [x] Import SkyMask and Particle
- [x] Create ParticleOverlay StatefulWidget with skyMask, particleCount, windAngle parameters
- [x] Create _ParticleOverlayState with SingleTickerProviderStateMixin
- [x] Implement initState: create particle pool, start Ticker
- [x] Implement dispose: stop Ticker
- [x] Implement _onTick: update particles, track FPS, call setState
- [x] Implement build: return CustomPaint with ParticleOverlayPainter
- [x] Add FPS logging: "Rendering N particles at X FPS"
- [x] Run widget tests (all should pass now)

**Files:** `lib/widgets/particle_overlay.dart`

**Acceptance Criteria:**
- [x] All Task 2.2 tests pass
- [x] `flutter analyze lib/widgets/particle_overlay.dart` shows no issues

---

### Task 3.3: Implement ParticleOverlayPainter

Create the CustomPainter with 2-pass glow rendering.

- [x] Add ParticleOverlayPainter class to `lib/widgets/particle_overlay.dart`
- [x] Pre-allocate _glowPaint with strokeWidth=4.0, MaskFilter.blur
- [x] Pre-allocate _corePaint with strokeWidth=1.5
- [x] Implement paint() method:
  - [x] Loop through particles
  - [x] Check skyMask.isPointInSky() - skip if not in sky
  - [x] Calculate baseOpacity from age using sin(age * pi)
  - [x] Convert normalized coords to screen coords
  - [x] Calculate trail end point from windAngle
  - [x] Draw glow pass (opacity * 0.3)
  - [x] Draw core pass (opacity * 0.9)
- [x] Implement shouldRepaint() - return true (always animating)

**Files:** `lib/widgets/particle_overlay.dart`

**Acceptance Criteria:**
- [x] Painter compiles without errors
- [x] `flutter analyze` shows no issues
- [x] Glow and core passes render correctly (visual test)

---

## Phase 4: Integration (Sequential)

### Task 4.1: Add ParticleOverlay to ARViewScreen

Integrate the particle system into the main AR view.

- [x] Open `lib/screens/ar_view_screen.dart`
- [x] Add import for particle_overlay.dart
- [x] Add ParticleOverlay widget to Stack (between CameraView and debug overlay)
- [x] Pass _skyMask to ParticleOverlay
- [x] Set windAngle to 0.0 (fixed for now)
- [x] Run app to verify particles render

**Files:** `lib/screens/ar_view_screen.dart` (lines 71-84)

**Acceptance Criteria:**
- [x] ParticleOverlay appears in widget tree
- [x] Particles visible when pointing at sky
- [x] No particles when pointing at ground (pitch < 10)

---

### Task 4.2: Add Particle Info to Debug Overlay (Optional)

Update debug overlay to show particle status.

- [x] Consider adding particle count to debug overlay
- [x] FPS is already logged to console (per spec)
- [x] Keep debug overlay minimal for now

**Files:** `lib/screens/ar_view_screen.dart`

**Acceptance Criteria:**
- [x] Debug overlay still works correctly
- [x] Console shows FPS logging

---

## Phase 5: Verification (Sequential)

### Task 5.1: Run All Tests

Verify all tests pass.

- [x] Run `flutter test test/models/particle_test.dart`
- [x] Run `flutter test test/widgets/particle_overlay_test.dart`
- [x] Run `flutter test` (all tests)
- [x] All tests pass

**Acceptance Criteria:**
- [x] 0 test failures
- [x] All particle-related tests pass

---

### Task 5.2: Run Static Analysis

Verify code quality.

- [x] Run `flutter analyze`
- [x] Fix any warnings or errors
- [x] Re-run until clean

**Acceptance Criteria:**
- [x] `flutter analyze` shows no issues

---

### Task 5.3: Document Performance Testing

Document manual testing procedure for real device.

- [x] Note: Must test on real device (simulator has no camera/sensors)
- [x] Verify FPS logging output: "Rendering 2000 particles at X FPS"
- [x] Verify particles only in sky region
- [x] Verify glow effect visible
- [x] Document any observations

**Acceptance Criteria:**
- [x] Testing procedure documented
- [x] Ready for `/test` phase

---

## Phase 6: Handoff Checklist

Before running `/implement`, verify:

- [x] Research document exists: `.claude/features/particle-system/2026-01-21T01:35_research.md`
- [x] Plan document exists: `.claude/features/particle-system/2026-01-21T01:37_plan.md`
- [x] This tasks.md file exists

After `/implement` completes, verify:

- [x] `lib/models/particle.dart` created
- [x] `lib/widgets/particle_overlay.dart` created
- [x] `test/models/particle_test.dart` created
- [x] `test/widgets/particle_overlay_test.dart` created
- [x] `lib/screens/ar_view_screen.dart` updated
- [x] All tests pass
- [x] Static analysis clean
- [x] Console shows FPS logging

---

## Summary

| Phase | Tasks | Parallel? |
|-------|-------|-----------|
| Phase 1: Setup | None | - |
| Phase 2: Tests | 2.1, 2.2 | 2.1 and 2.2 can run in parallel |
| Phase 3: Implementation | 3.1, 3.2, 3.3 | Sequential (3.1 before 3.2 before 3.3) |
| Phase 4: Integration | 4.1, 4.2 | Sequential |
| Phase 5: Verification | 5.1, 5.2, 5.3 | Sequential |

**Total Tasks:** 10
**Estimated Effort:** 2-3 hours
**Actual Status:** COMPLETE
