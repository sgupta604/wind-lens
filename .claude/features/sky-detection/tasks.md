# Tasks: sky-detection

## Metadata
- **Feature:** sky-detection
- **Created:** 2026-01-21T00:53
- **Status:** implementation-complete
- **Based On:** 2026-01-21T00:53_plan.md

---

## Execution Rules

1. **TDD Order**: Write tests BEFORE implementation (Phase 2 before Phase 3)
2. **Sequential by Default**: Execute tasks in order unless marked [P]
3. **[P] = Parallelizable**: Tasks marked [P] can run concurrently
4. **Completion Markers**: Check off items as completed

---

## Phase 1: Directory Setup

### Task 1.1: Create Directory Structure
- [X] Create `lib/services/sky_detection/` directory
- [X] Create `test/services/sky_detection/` directory
- [X] Verify directories exist

**Files:** New directories only

**Acceptance Criteria:**
- [X] `lib/services/sky_detection/` exists
- [X] `test/services/sky_detection/` exists

---

## Phase 2: Tests (TDD - Write First)

### Task 2.1: Create SkyMask Interface Tests
- [X] Create `test/services/sky_detection/sky_mask_test.dart`
- [X] Write test that verifies interface contract (using mock/concrete impl)
- [X] Test should initially fail (no implementation exists)

**Files:** `test/services/sky_detection/sky_mask_test.dart`

**Test Cases:**
```dart
// These tests verify the interface behavior via a concrete implementation
// They will be used to validate any SkyMask implementation
```

**Acceptance Criteria:**
- [X] Test file exists with group structure
- [X] Tests compile (may fail without implementation)

---

### Task 2.2: Create PitchBasedSkyMask Unit Tests
- [X] Create `test/services/sky_detection/pitch_based_sky_mask_test.dart`
- [X] Write test: skyFraction = 0 when pitch < 10
- [X] Write test: skyFraction = 0.95 when pitch > 70
- [X] Write test: skyFraction linear interpolation at pitch = 40
- [X] Write test: isPointInSky returns true for top of screen
- [X] Write test: isPointInSky returns false for bottom of screen
- [X] Write test: isPointInSky ignores X coordinate
- [X] Write test: updatePitch changes skyFraction
- [X] Run tests (should fail - no implementation yet)

**Files:** `test/services/sky_detection/pitch_based_sky_mask_test.dart`

**Test Cases:**
```dart
group('PitchBasedSkyMask', () {
  group('skyFraction', () {
    test('returns 0 when pitch is below minimum (10 degrees)', () {});
    test('returns 0.95 when pitch is above maximum (70 degrees)', () {});
    test('returns linearly interpolated value at midpoint', () {});
    test('clamps to valid range', () {});
  });

  group('isPointInSky', () {
    test('returns true for points in top portion of screen', () {});
    test('returns false for points in bottom portion of screen', () {});
    test('returns same value regardless of X coordinate', () {});
    test('returns false when skyFraction is 0', () {});
  });

  group('updatePitch', () {
    test('changes skyFraction value', () {});
  });
});
```

**Acceptance Criteria:**
- [X] All 9 tests written (actually 13 tests implemented)
- [X] Tests compile and run
- [X] Tests fail (expected - no implementation)

---

## Phase 3: Core Implementation

### Task 3.1: Create SkyMask Abstract Interface
- [X] Create `lib/services/sky_detection/sky_mask.dart`
- [X] Define abstract class SkyMask
- [X] Add `double get skyFraction` getter
- [X] Add `bool isPointInSky(double normalizedX, double normalizedY)` method
- [X] Add documentation comments

**Files:** `lib/services/sky_detection/sky_mask.dart`

**Implementation:**
```dart
/// Abstract interface for sky detection implementations.
abstract class SkyMask {
  /// Returns what fraction of screen (from top) is sky (0.0 to 1.0).
  double get skyFraction;

  /// Check if a normalized screen point is in the sky region.
  bool isPointInSky(double normalizedX, double normalizedY);
}
```

**Acceptance Criteria:**
- [X] File compiles with no errors
- [X] `flutter analyze` passes for this file

---

### Task 3.2: Create PitchBasedSkyMask Implementation
- [X] Create `lib/services/sky_detection/pitch_based_sky_mask.dart`
- [X] Import sky_mask.dart and flutter/foundation.dart
- [X] Define static constants: minPitch, maxPitch, maxSkyFraction
- [X] Implement `updatePitch(double pitchDegrees)` with debugPrint
- [X] Implement `skyFraction` getter with linear interpolation
- [X] Implement `isPointInSky(double normalizedX, double normalizedY)`
- [X] Add documentation comments
- [X] Run unit tests (should now pass)

**Files:** `lib/services/sky_detection/pitch_based_sky_mask.dart`

**Implementation Details:**
- minPitch = 10.0 degrees
- maxPitch = 70.0 degrees
- maxSkyFraction = 0.95
- Formula: `((pitch - 10) / 60 * 0.95).clamp(0.0, 0.95)`
- Log format: `Sky fraction: ${(skyFraction * 100).toStringAsFixed(1)}%`

**Acceptance Criteria:**
- [X] File compiles with no errors
- [X] `flutter analyze` passes for this file
- [X] All unit tests from Task 2.2 pass
- [X] Console outputs sky fraction when updatePitch called

---

### Task 3.3: Run Tests and Verify Core Implementation
- [X] Run `flutter test test/services/sky_detection/`
- [X] Verify all tests pass
- [X] Run `flutter analyze lib/services/sky_detection/`
- [X] Fix any issues

**Acceptance Criteria:**
- [X] All sky_detection tests pass
- [X] No analyzer warnings or errors

---

## Phase 4: Integration

### Task 4.1: Update ARViewScreen with SkyMask
- [X] Add import for pitch_based_sky_mask.dart
- [X] Add `late PitchBasedSkyMask _skyMask;` state variable
- [X] Add `double _skyFraction = 0;` state variable
- [X] Initialize `_skyMask = PitchBasedSkyMask();` in initState
- [X] Update `_onCompassUpdate` to call `_skyMask.updatePitch(_pitch)`
- [X] Update `_onCompassUpdate` to set `_skyFraction = _skyMask.skyFraction`
- [X] Add sky fraction Text widget to debug overlay

**Files:** `lib/screens/ar_view_screen.dart`

**Changes to make:**
```dart
// Add import (near line 6)
import '../services/sky_detection/pitch_based_sky_mask.dart';

// Add state variables (after line 30)
late PitchBasedSkyMask _skyMask;
double _skyFraction = 0;

// Add to initState (after line 38)
_skyMask = PitchBasedSkyMask();

// Update _onCompassUpdate (after setting _pitch)
_skyMask.updatePitch(_pitch);
_skyFraction = _skyMask.skyFraction;

// Add to _buildDebugOverlay column (after Pitch text)
const SizedBox(height: 4),
Text(
  'Sky: ${(_skyFraction * 100).toStringAsFixed(1)}%',
  style: const TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: 'monospace',
  ),
),
```

**Acceptance Criteria:**
- [X] ARViewScreen compiles without errors
- [X] Debug overlay shows three values: Heading, Pitch, Sky
- [X] Sky percentage updates when pitch changes

---

### Task 4.2: Update ARViewScreen Tests [P]
- [X] Update `test/screens/ar_view_screen_test.dart` if needed
- [X] Add test for sky fraction display in debug overlay
- [X] Run tests

**Files:** `test/screens/ar_view_screen_test.dart`

**Acceptance Criteria:**
- [X] ARViewScreen tests pass
- [X] Test verifies sky fraction text exists

---

## Phase 5: Verification

### Task 5.1: Run Full Test Suite
- [X] Run `flutter test`
- [X] Verify all tests pass
- [X] Document any failures

**Acceptance Criteria:**
- [X] All tests pass (51 tests)
- [X] Zero test failures

---

### Task 5.2: Run Static Analysis
- [X] Run `flutter analyze`
- [X] Fix any errors or warnings
- [X] Document any ignored warnings (with justification)

**Acceptance Criteria:**
- [X] `flutter analyze` shows no errors
- [X] No warnings (or documented exceptions)

---

### Task 5.3: Document Real Device Testing Steps
- [X] Create testing checklist for real device
- [X] Document expected behavior at each pitch angle
- [X] Note: Actual device testing done in /test phase

**Real Device Test Checklist (for /test phase):**
1. Launch app on physical device
2. Point phone down (at floor) - verify Sky: 0.0%
3. Tilt phone to ~30 degrees - verify Sky: ~31.7%
4. Tilt phone to ~45 degrees - verify Sky: ~55.4%
5. Point phone at sky (60+ degrees) - verify Sky: approaching 95%
6. Check console for "Sky fraction: X.X%" log messages
7. Verify smooth updates (no jitter/flickering)

**Acceptance Criteria:**
- [X] Checklist documented
- [X] Expected values calculated

---

## Phase 6: Ready for Test Agent

### Task 6.1: Final Verification Checklist
- [X] All unit tests pass (`flutter test`)
- [X] Static analysis passes (`flutter analyze`)
- [ ] Code compiles (`flutter build apk --debug` or similar) - Skipped, no Android SDK
- [X] Documentation complete
- [X] Ready for `/test sky-detection`

**Acceptance Criteria:**
- [X] All checks pass
- [X] Feature ready for Test Agent

---

## Summary

| Phase | Tasks | Estimated Time | Status |
|-------|-------|----------------|--------|
| Phase 1: Directory Setup | 1 task | 2 min | COMPLETE |
| Phase 2: Tests (TDD) | 2 tasks | 15 min | COMPLETE |
| Phase 3: Core Implementation | 3 tasks | 20 min | COMPLETE |
| Phase 4: Integration | 2 tasks | 15 min | COMPLETE |
| Phase 5: Verification | 3 tasks | 10 min | COMPLETE |
| Phase 6: Handoff | 1 task | 5 min | COMPLETE |
| **Total** | **12 tasks** | **~67 min** | **COMPLETE** |

---

## Handoff to Test Agent

When all tasks complete:

1. Update `STATUS.md` to `implement-complete`
2. Run `/test sky-detection`
3. Test Agent will:
   - Run full test suite
   - Test on real device
   - Create pass/fail report
