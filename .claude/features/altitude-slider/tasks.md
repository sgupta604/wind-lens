# Tasks: Altitude Slider Drag Gesture (BUG-005)

## Metadata
- **Feature:** altitude-slider (bug fix)
- **Created:** 2026-01-22T10:30
- **Status:** ready-for-implementation
- **Based On:** `2026-01-22T10:30_plan.md`
- **Priority:** LOW
- **Estimated Effort:** ~30 minutes

## Execution Rules

1. Tasks are sequential unless marked with [P] (parallelizable)
2. TDD: Write tests before implementation (Phase 2 before Phase 3)
3. Mark tasks complete with [x] as you finish them
4. Run tests after each task to verify no regressions

---

## Phase 1: Setup (None required)

No setup needed - this is a modification to existing file.

---

## Phase 2: Tests (TDD - Write First)

### Task 2.1: Add Drag Gesture Test
- [x] Open `/workspace/wind_lens/test/widgets/altitude_slider_test.dart`
- [x] Add test: `calls onChanged when dragging between segments`
- [x] Test should simulate vertical drag gesture
- [x] Verify callback fires with correct AltitudeLevel values
- [x] Run tests (expect new test to FAIL - TDD red phase)

**Files:** `test/widgets/altitude_slider_test.dart`

**Test Code Outline:**
```dart
testWidgets('calls onChanged when dragging between segments', (tester) async {
  final List<AltitudeLevel> changedLevels = [];

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: AltitudeSlider(
            value: AltitudeLevel.jetStream,
            onChanged: (level) => changedLevels.add(level),
          ),
        ),
      ),
    ),
  );

  // Get slider position
  final sliderFinder = find.byType(AltitudeSlider);
  final sliderCenter = tester.getCenter(sliderFinder);

  // Simulate drag from top (JET) to bottom (SFC)
  // Start at top segment, drag through mid to bottom
  await tester.drag(sliderFinder, const Offset(0, 100)); // Drag down 100px
  await tester.pump();

  // Should have triggered callbacks for MID and SFC
  expect(changedLevels, contains(AltitudeLevel.midLevel));
  expect(changedLevels, contains(AltitudeLevel.surface));
});
```

**Acceptance Criteria:**
- [x] Test compiles and runs
- [x] Test FAILS (drag not yet implemented) - TDD red phase

---

## Phase 3: Core Implementation

### Task 3.1: Add Level-from-Y Helper Method
- [x] Open `/workspace/wind_lens/lib/widgets/altitude_slider.dart`
- [x] Add `_levelFromY(double localY)` method after `_getLabel()` method
- [x] Method converts Y position to AltitudeLevel
- [x] Handle edge cases (clamp to valid range)

**Files:** `lib/widgets/altitude_slider.dart`

**Code to Add (after line 62):**
```dart
/// Determines which altitude level corresponds to a Y position.
AltitudeLevel _levelFromY(double localY) {
  final segmentIndex = (localY / _segmentHeight).floor().clamp(0, 2);
  return switch (segmentIndex) {
    0 => AltitudeLevel.jetStream,
    1 => AltitudeLevel.midLevel,
    _ => AltitudeLevel.surface,
  };
}
```

**Acceptance Criteria:**
- [x] Method added to AltitudeSlider class
- [x] Returns jetStream for Y 0-55
- [x] Returns midLevel for Y 56-111
- [x] Returns surface for Y 112+

---

### Task 3.2: Wrap Widget in Drag-Detecting GestureDetector
- [x] Modify `build()` method
- [x] Wrap existing `ClipRRect` in new `GestureDetector`
- [x] Add `onVerticalDragUpdate` handler
- [x] Calculate level from drag position
- [x] Trigger haptic and callback when level changes

**Files:** `lib/widgets/altitude_slider.dart`

**Code Change (lines 65-101):**
```dart
@override
Widget build(BuildContext context) {
  return GestureDetector(
    onVerticalDragUpdate: (details) {
      final newLevel = _levelFromY(details.localPosition.dy);
      if (newLevel != value) {
        HapticFeedback.lightImpact();
        onChanged(newLevel);
      }
    },
    child: ClipRRect(
      // ... existing ClipRRect code unchanged ...
    ),
  );
}
```

**Acceptance Criteria:**
- [x] Outer GestureDetector wraps ClipRRect
- [x] onVerticalDragUpdate handler implemented
- [x] Haptic fires on level change
- [x] Callback fires with new level

---

## Phase 4: Verification

### Task 4.1: Run All Widget Tests [P]
- [x] Run `flutter test test/widgets/altitude_slider_test.dart`
- [x] All tests pass including new drag test
- [x] No regressions in existing tap tests

**Acceptance Criteria:**
- [x] New drag test passes (TDD green phase)
- [x] Existing tap tests still pass
- [x] No test failures

---

### Task 4.2: Manual Testing (Real Device) [P]
- [x] Build and run on device: `flutter run`
- [x] Tap each segment - verify works
- [x] Drag from JET to SFC - verify all levels select in order
- [x] Drag from SFC to JET - verify all levels select in order
- [x] Verify haptic feedback on each level change
- [x] Verify no duplicate haptics when holding within segment

**Acceptance Criteria:**
- [x] Tap interaction works (no regression)
- [x] Drag interaction works
- [x] Haptic feedback feels correct
- [x] Visual selection updates during drag

---

## Phase 5: Cleanup

### Task 5.1: Update Widget Documentation
- [x] Update docstring at top of AltitudeSlider class
- [x] Change "tap to select" to "tap or drag to select"

**Files:** `lib/widgets/altitude_slider.dart`

**Acceptance Criteria:**
- [x] Docstring accurately describes both interactions

---

## Handoff Checklist (for Test Agent)

Before running `/test altitude-slider`:

- [x] All implementation tasks completed
- [x] `flutter test test/widgets/` passes
- [x] No lint warnings in altitude_slider.dart
- [x] Manual verification on device completed
- [x] Widget supports both tap AND drag interactions

## Summary

| Phase | Tasks | Status |
|-------|-------|--------|
| Phase 1: Setup | 0 | N/A |
| Phase 2: Tests | 1 | Complete |
| Phase 3: Implementation | 2 | Complete |
| Phase 4: Verification | 2 | Complete |
| Phase 5: Cleanup | 1 | Complete |
| **Total** | **6** | **Complete** |

## Files Changed

| File | Type | Change |
|------|------|--------|
| `lib/widgets/altitude_slider.dart` | Modified | Add drag gesture support (~18 lines) |
| `test/widgets/altitude_slider_test.dart` | Modified | Add drag test (~20 lines) |
