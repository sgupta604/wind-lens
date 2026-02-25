# Tasks: code-cleanup

## Metadata
- **Feature:** code-cleanup
- **Created:** 2026-02-15T17:33
- **Status:** complete
- **Based on:** 2026-02-15T17:33_plan.md

## Execution Rules
- Tasks within a phase are sequential unless marked **[P]** (parallelizable)
- Phases are sequential (complete Phase 1 before Phase 2, etc.)
- Check the box when a subtask is done
- Run `flutter analyze lib/` after each task to catch issues early
- Run `flutter test` after Phase 3 is complete

---

## Phase 1: Simple Removals [P]

These are independent single-file changes. All can be done in parallel.

### Task 1.1: Remove 20Hz debugPrint from pitch_based_sky_mask.dart [P]
- [x] Remove line 32: `debugPrint('Sky fraction: ${(skyFraction * 100).toStringAsFixed(1)}%');`
- [x] Remove line 1: `import 'package:flutter/foundation.dart';` (now unused)
- [x] Run `flutter analyze lib/services/sky_detection/pitch_based_sky_mask.dart`

**Files:** `lib/services/sky_detection/pitch_based_sky_mask.dart`

**Acceptance Criteria:**
- [x] No debugPrint call in `updatePitch()`
- [x] No unused imports
- [x] `flutter analyze` clean

---

### Task 1.2: Remove deprecated sampleRegionBottom constant [P]
- [x] Remove lines 98-99 from `auto_calibrating_sky_detector.dart`:
  ```dart
  @Deprecated('Use _getSampleRegionBottom() which calculates dynamically based on pitch')
  static const double sampleRegionBottom = 0.4;
  ```
- [x] Remove lines 125-129 from `auto_calibrating_sky_detector_test.dart`:
  ```dart
  test('sample region bottom base is 40% (but now dynamic)', () {
    // sampleRegionBottom is deprecated/reference - actual bottom is calculated
    // by _getSampleRegionBottom() based on pitch
    // ignore: deprecated_member_use_from_same_package
    expect(AutoCalibratingSkyDetector.sampleRegionBottom, 0.4);
  });
  ```
- [x] Also remove the comment block on lines 94-97 that references the deprecated constant:
  ```dart
  /// Bottom of the sampling region (as fraction of frame height).
  ///
  /// NOTE: This constant is kept for backwards compatibility and as a
  /// reference value. The actual sample region bottom is now calculated
  /// dynamically by [_getSampleRegionBottom] based on the current pitch angle.
  /// See BUG-002.5 fix for details.
  ```
- [x] Run `flutter analyze lib/services/sky_detection/auto_calibrating_sky_detector.dart`

**Files:**
- `lib/services/sky_detection/auto_calibrating_sky_detector.dart`
- `test/services/sky_detection/auto_calibrating_sky_detector_test.dart`

**Acceptance Criteria:**
- [x] `sampleRegionBottom` constant no longer exists
- [x] No test references the removed constant
- [x] `flutter analyze` clean

---

### Task 1.3: Clean up fake_wind_service.dart [P]
- [x] Remove the custom `debugPrint` function (lines 101-108):
  ```dart
  /// Debug print function (only prints in debug mode).
  void debugPrint(String message) {
    assert(() {
      // ignore: avoid_print
      print(message);
      return true;
    }());
  }
  ```
- [x] Remove the debugPrint call in `getWind()` (lines 48-49):
  ```dart
  debugPrint(
      'Wind: ${wind.speed.toStringAsFixed(1)}m/s @ ${wind.directionDegrees.toStringAsFixed(0)}deg');
  ```
- [x] Remove the debugPrint call in `getWindForAltitude()` (lines 94-95):
  ```dart
  debugPrint(
      'Wind (${level.displayName}): ${wind.speed.toStringAsFixed(1)}m/s @ ${wind.directionDegrees.toStringAsFixed(0)}deg at ${wind.altitude}m');
  ```
- [x] Verify no remaining references to `debugPrint` in the file (no import needed)
- [x] Run `flutter analyze lib/services/fake_wind_service.dart`

**Files:** `lib/services/fake_wind_service.dart`

**Acceptance Criteria:**
- [x] No custom `debugPrint` function exists in the file
- [x] No `debugPrint` calls remain in `getWind()` or `getWindForAltitude()`
- [x] No unused imports
- [x] `flutter analyze` clean

---

## Phase 2: Refactor particle_overlay.dart

### Task 2.1: Consolidate opacity calculation and remove dead code
- [x] Add a static helper method to `ParticleOverlayPainter`:
  ```dart
  /// Calculates particle opacity from age using a sine curve.
  ///
  /// Returns 0.0 at birth (age=0), peaks near 1.0 at mid-life,
  /// and fades back to 0.0 at expiration (age=1.0).
  static double _particleOpacity(double age) {
    return sin(age * 3.14159).clamp(0.0, 1.0);
  }
  ```
- [x] Replace line 489 in `_paintDots()`:
  - FROM: `final baseOpacity = sin(p.age * 3.14159).clamp(0.0, 1.0);`
  - TO: `final baseOpacity = _particleOpacity(p.age);`
- [x] Replace line 530 in `_paintStreamlines()`:
  - FROM: `final baseOpacity = sin(p.age * 3.14159).clamp(0.0, 1.0);`
  - TO: `final baseOpacity = _particleOpacity(p.age);`
- [x] Remove lines 290-293 (unused parallaxFactor):
  ```dart
  // NOTE: parallaxFactor is intentionally unused after BUG-004 fix
  // Kept for potential future subtle depth effects
  // ignore: unused_local_variable
  final parallaxFactor = widget.altitudeLevel.parallaxFactor;
  ```
- [x] Run `flutter analyze lib/widgets/particle_overlay.dart`

**Files:** `lib/widgets/particle_overlay.dart`

**Acceptance Criteria:**
- [x] Opacity calculation exists in exactly one place (the static helper)
- [x] Both `_paintDots()` and `_paintStreamlines()` call `_particleOpacity()`
- [x] No `parallaxFactor` variable or `ignore` comment in `_onTick()`
- [x] No `unused_local_variable` ignore comments remain
- [x] `flutter analyze` clean

---

## Phase 3: Extract Debug Panel

### Task 3.1: Create DebugPanel widget
- [x] Create `lib/widgets/debug_panel.dart`
- [x] Define `DebugPanel` as a `StatelessWidget` with these constructor params:
  - `heading` (double)
  - `pitch` (double)
  - `skyFraction` (double)
  - `isCalibrated` (bool)
  - `altitudeLevel` (AltitudeLevel)
  - `windData` (WindData)
  - `currentFps` (double)
  - `currentParticleCount` (int)
  - `viewMode` (ViewMode)
  - `showPanel` (bool)
  - `onTogglePanel` (VoidCallback)
  - `onToggleViewMode` (VoidCallback)
  - `onRecalibrate` (VoidCallback)
- [x] Move `_buildDebugToggleButton()` logic into `DebugPanel.build()` (the Positioned wrapper with MediaQuery stays in ARViewScreen)
- [x] Move `_buildDebugPanel()` logic into `DebugPanel.build()` (shown when `showPanel` is true)
- [x] Move `_buildDebugText()` as a private method of `DebugPanel`
- [x] Use callbacks for `onTogglePanel`, `onToggleViewMode`, and `onRecalibrate`
- [x] Add appropriate doc comments following the `CompassWidget` / `InfoBar` pattern

**Files:** `lib/widgets/debug_panel.dart` (NEW)

**Acceptance Criteria:**
- [x] `DebugPanel` is a `StatelessWidget`
- [x] All data flows through constructor params (no state in the widget)
- [x] All mutations flow through callback params
- [x] Doc comments present on class and constructor

---

### Task 3.2: Update ARViewScreen to use DebugPanel
- [x] Add `import '../widgets/debug_panel.dart';` to ar_view_screen.dart
- [x] Replace the debug toggle button (Layer 3) and debug panel (Layer 4) with a single `DebugPanel` widget
- [x] Remove `_buildDebugToggleButton()` method
- [x] Remove `_buildDebugPanel()` method
- [x] Remove `_buildDebugText()` method
- [x] Remove `_onRecalibratePressed()` method
- [x] Keep `_toggleDebugPanel()` and `_toggleViewMode()` (still needed as callbacks)
- [x] Pass `_skyDetector.forceRecalibrate` as the `onRecalibrate` callback
- [x] Verify the Positioned wrappers for the debug panel use `MediaQuery.of(context).padding.top` correctly
- [x] Run `flutter analyze lib/`

**Files:** `lib/screens/ar_view_screen.dart`

**Acceptance Criteria:**
- [x] No debug panel UI code remains in ARViewScreen (only callback methods)
- [x] ARViewScreen imports and uses `DebugPanel` widget
- [x] `flutter analyze` clean on entire lib/

---

## Phase 4: Verification

### Task 4.1: Run full test suite
- [x] Run `flutter test` and verify all tests pass
- [x] Run `flutter analyze lib/` and verify "No issues found!"
- [x] Verify test count is correct (should be one fewer than before due to removed sampleRegionBottom test)

**Acceptance Criteria:**
- [x] All tests pass (expected: 391 tests, down from 392)
- [x] `flutter analyze lib/` reports no issues
- [x] No regressions

---

## Handoff Checklist (for Test Agent)

- [x] All Phase 1-4 tasks completed
- [x] `flutter test` -- all tests passing
- [x] `flutter analyze lib/` -- no issues
- [x] No behavioral changes (cleanup only)
- [x] Files created: `lib/widgets/debug_panel.dart`
- [x] Files modified: 5 source files, 1 test file
- [x] Files removed: none
- [x] Net lines removed: ~30-40 lines across the codebase
