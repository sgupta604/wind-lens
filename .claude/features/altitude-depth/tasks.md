# Tasks: altitude-depth

## Metadata
- **Feature:** altitude-depth
- **Created:** 2026-01-21T02:30
- **Status:** implementation-complete
- **Based On:** 2026-01-21T02:30_plan.md

## Execution Rules

1. **TDD Order:** Write tests FIRST (Phase 2), then implementation (Phase 3+)
2. **Sequential by Default:** Complete tasks in order unless marked [P] (parallelizable)
3. **Completion Markers:** Check off subtasks as completed
4. **Verification:** Run tests after each task to confirm passing

---

## Phase 1: Setup

_No setup required - all dependencies exist._

---

## Phase 2: Tests (TDD - Write First, Expect Failures)

### Task 2.1: Create AltitudeLevel Unit Tests
- [x] Create test file `test/models/altitude_level_test.dart`
- [x] Test: `surface has displayName "Surface"`
- [x] Test: `midLevel has displayName "Cloud Level"`
- [x] Test: `jetStream has displayName "Jet Stream"`
- [x] Test: `metersAGL values are correct for all levels`
- [x] Test: `particleColor values are correct for all levels`
- [x] Test: `parallaxFactor decreases with altitude (1.0 > 0.6 > 0.3)`
- [x] Test: `trailScale decreases with altitude (1.0 > 0.7 > 0.5)`
- [x] Test: `particleSpeedMultiplier increases with altitude (1.0 < 1.5 < 3.0)`

**Files:** `test/models/altitude_level_test.dart`

**Acceptance Criteria:**
- [x] Test file compiles (import will fail until model exists)
- [x] 8 test cases defined

---

### Task 2.2: Create AltitudeSlider Widget Tests
- [x] Create test file `test/widgets/altitude_slider_test.dart`
- [x] Test: `renders without crashing`
- [x] Test: `displays all three segments`
- [x] Test: `shows correct labels (JET, MID, SFC or icons)`
- [x] Test: `highlights selected segment visually`
- [x] Test: `calls onChanged when segment tapped`
- [x] Test: `selects correct level based on tap position`
- [x] Test: `has minimum touch target size (48pt height per segment)`

**Files:** `test/widgets/altitude_slider_test.dart`

**Acceptance Criteria:**
- [x] Test file compiles (import will fail until widget exists)
- [x] 7 test cases defined

---

### Task 2.3: Add FakeWindService Tests for Altitude
- [x] Add test group `getWindForAltitude()` to existing test file
- [x] Test: `returns WindData for surface altitude`
- [x] Test: `returns WindData for midLevel altitude`
- [x] Test: `returns WindData for jetStream altitude`
- [x] Test: `wind speed increases with altitude level`
- [x] Test: `returns correct altitude value in WindData`

**Files:** `test/services/fake_wind_service_test.dart`

**Acceptance Criteria:**
- [x] Tests added to existing file
- [x] 5 new test cases defined

---

### Task 2.4: Add ParticleOverlay Tests for Altitude [P]
- [x] Add test group `Altitude Integration` to existing test file
- [x] Test: `accepts altitudeLevel parameter`
- [x] Test: `accepts previousHeading parameter`
- [x] Test: `defaults to surface altitude when not specified`
- [x] Test: `defaults to 0.0 previousHeading when not specified`

**Files:** `test/widgets/particle_overlay_test.dart`

**Acceptance Criteria:**
- [x] Tests added to existing file
- [x] 4 new test cases defined

---

### Task 2.5: Add ARViewScreen Tests for Altitude [P]
- [x] Add test for: `contains AltitudeSlider widget`
- [x] Add test for: `displays altitude in debug overlay`

**Files:** `test/screens/ar_view_screen_test.dart`

**Acceptance Criteria:**
- [x] Tests added to existing file
- [x] 2 new test cases defined

---

## Phase 3: Core Implementation

### Task 3.1: Create AltitudeLevel Model
- [x] Create file `lib/models/altitude_level.dart`
- [x] Define `enum AltitudeLevel { surface, midLevel, jetStream }`
- [x] Create `extension AltitudeLevelProperties on AltitudeLevel`
- [x] Implement `String get displayName` (Surface, Cloud Level, Jet Stream)
- [x] Implement `double get metersAGL` (10, 1500, 10500)
- [x] Implement `Color get particleColor` (white, cyan, purple with 0xAA alpha)
- [x] Implement `double get particleSpeedMultiplier` (1.0, 1.5, 3.0)
- [x] Implement `double get parallaxFactor` (1.0, 0.6, 0.3)
- [x] Implement `double get trailScale` (1.0, 0.7, 0.5)
- [x] Run `flutter test test/models/altitude_level_test.dart`

**Files:** `lib/models/altitude_level.dart`

**Acceptance Criteria:**
- [x] All 8 unit tests pass
- [x] Enum and extension compile without errors

---

### Task 3.2: Create AltitudeSlider Widget
- [x] Create file `lib/widgets/altitude_slider.dart`
- [x] Create `AltitudeSlider` StatelessWidget with:
  - `AltitudeLevel value` (required)
  - `ValueChanged<AltitudeLevel> onChanged` (required)
- [x] Implement glassmorphism container (BackdropFilter + blur)
- [x] Add three vertical segments for JET, MID, SFC (top to bottom)
- [x] Highlight selected segment with different background
- [x] Add tap detection with GestureDetector for each segment
- [x] Add HapticFeedback.lightImpact() on selection change
- [x] Ensure minimum 48pt height per segment for touch targets
- [x] Run `flutter test test/widgets/altitude_slider_test.dart`

**Files:** `lib/widgets/altitude_slider.dart`

**Acceptance Criteria:**
- [x] All 7 widget tests pass
- [x] Widget renders correctly in isolation

---

### Task 3.3: Update FakeWindService for Altitude
- [x] Add import for `altitude_level.dart`
- [x] Add method `WindData getWindForAltitude(AltitudeLevel level)`
- [x] Return wind with speed multiplied by `level.particleSpeedMultiplier`
- [x] Return wind with altitude set to `level.metersAGL`
- [x] Keep existing `getWind()` method unchanged (backward compatible)
- [x] Run `flutter test test/services/fake_wind_service_test.dart`

**Files:** `lib/services/fake_wind_service.dart`

**Acceptance Criteria:**
- [x] All existing tests still pass
- [x] All 5 new tests pass
- [x] getWind() unchanged for backward compatibility

---

### Task 3.4: Update ParticleOverlay for Altitude
- [x] Add import for `altitude_level.dart`
- [x] Add `AltitudeLevel altitudeLevel` parameter (default: surface)
- [x] Add `double previousHeading` parameter (default: 0.0)
- [x] In `_onTick()`: Calculate heading delta for parallax
- [x] In `_onTick()`: Apply parallax offset to particle x position
- [x] In `_onTick()`: Scale trail length by `altitudeLevel.trailScale`
- [x] In `build()`: Pass `altitudeLevel.particleColor` to Painter
- [x] Update `ParticleOverlayPainter` to use passed color
- [x] Run `flutter test test/widgets/particle_overlay_test.dart`

**Files:** `lib/widgets/particle_overlay.dart`

**Acceptance Criteria:**
- [x] All existing tests still pass
- [x] All 4 new tests pass
- [x] Parallax calculation uses normalized heading delta (-180 to 180)

---

## Phase 4: Integration

### Task 4.1: Integrate Altitude into ARViewScreen
- [x] Add import for `altitude_level.dart` and `altitude_slider.dart`
- [x] Add state variable `AltitudeLevel _altitudeLevel = AltitudeLevel.surface`
- [x] Add state variable `double _previousHeading = 0.0`
- [x] In `_onCompassUpdate()`: Update `_previousHeading` before updating `_heading`
- [x] In `_onCompassUpdate()`: Call `_windService.getWindForAltitude(_altitudeLevel)`
- [x] Add `AltitudeSlider` to Stack, positioned right edge center
- [x] Pass `_altitudeLevel` and `_previousHeading` to ParticleOverlay
- [x] Add altitude label to debug overlay
- [x] Run `flutter test test/screens/ar_view_screen_test.dart`

**Files:** `lib/screens/ar_view_screen.dart`

**Acceptance Criteria:**
- [x] All existing tests still pass
- [x] All 2 new tests pass
- [x] Slider visible on right edge
- [x] Altitude changes when slider tapped

---

## Phase 5: Polish and Verification

### Task 5.1: Visual Polish [P]
- [ ] Verify slider glassmorphism effect looks correct
- [ ] Test color visibility against sky backgrounds
- [ ] Verify haptic feedback works on iOS/Android
- [ ] Check slider positioning on different screen sizes

**Files:** None (manual verification)

**Acceptance Criteria:**
- [ ] Slider looks like frosted glass
- [ ] All three colors visible against typical sky
- [ ] Haptic feedback felt on level change

---

### Task 5.2: Parallax Verification [P]
- [ ] Test parallax effect responds to phone rotation
- [ ] Verify higher altitudes move less than lower
- [ ] Check for jitter or stuttering in parallax motion
- [ ] Confirm 60 FPS maintained

**Files:** None (manual verification on device)

**Acceptance Criteria:**
- [ ] Surface particles move most when rotating phone
- [ ] Jet stream particles barely move when rotating
- [ ] Motion is smooth without jitter
- [ ] FPS stays at or above 58

---

### Task 5.3: Run Full Test Suite
- [x] Run `flutter test` for all tests
- [x] Verify no regressions in existing tests
- [x] Confirm all new tests pass

**Files:** All test files

**Acceptance Criteria:**
- [x] All tests pass (0 failures)
- [x] No test warnings

---

### Task 5.4: Build Verification
- [x] Run `flutter analyze` for lint issues
- [ ] Run `flutter build ios --debug` (or android) - N/A (no SDK)
- [x] Verify no build errors in static analysis

**Files:** All source files

**Acceptance Criteria:**
- [x] No lint errors (warnings OK)
- [ ] Build succeeds - N/A (requires device SDK)

---

## Phase 6: Ready for Test Agent

### Handoff Checklist
- [x] All Phase 2 tests written and documented
- [x] All Phase 3 implementation complete
- [x] All Phase 4 integration complete
- [x] All Phase 5 verification passed (automated tests)
- [x] Full test suite passing (129 tests)
- [x] Static analysis clean

**Next Command:** `/test altitude-depth`

---

## Summary

| Phase | Tasks | Tests |
|-------|-------|-------|
| Phase 1: Setup | 0 | 0 |
| Phase 2: Tests | 5 | 26 |
| Phase 3: Core | 4 | - |
| Phase 4: Integration | 1 | - |
| Phase 5: Polish | 4 | - |
| **Total** | **14** | **26** |

## File Changes Summary

### New Files (4)
- `lib/models/altitude_level.dart`
- `lib/widgets/altitude_slider.dart`
- `test/models/altitude_level_test.dart`
- `test/widgets/altitude_slider_test.dart`

### Modified Files (5)
- `lib/services/fake_wind_service.dart`
- `lib/widgets/particle_overlay.dart`
- `lib/screens/ar_view_screen.dart`
- `test/services/fake_wind_service_test.dart`
- `test/widgets/particle_overlay_test.dart`
- `test/screens/ar_view_screen_test.dart`
