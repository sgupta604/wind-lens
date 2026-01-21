# Tasks: wind-animation

## Metadata
- **Feature:** wind-animation
- **Created:** 2026-01-21T02:15
- **Status:** implementation-complete
- **Based On:** 2026-01-21T02:15_plan.md

## Execution Rules

1. **TDD Order:** Write tests BEFORE implementation (tests fail initially, then pass after implementation)
2. **Sequential by Default:** Tasks within a phase run sequentially unless marked `[P]`
3. **Parallel Marker:** Tasks marked `[P]` can run in parallel with other `[P]` tasks in the same phase
4. **Completion Marker:** Mark `[x]` when task is complete
5. **Dependencies:** Complete all tasks in a phase before starting the next phase

---

## Phase 1: Setup

No setup tasks required. All dependencies (particle-system, compass-sensors) are already complete.

---

## Phase 2: Tests (TDD - Write Tests First)

### Task 2.1: Write WindData Model Tests [P]
- [x] Create test file `test/models/wind_data_test.dart`
- [x] Write test: constructor creates instance with u, v, altitude, timestamp
- [x] Write test: speed computed correctly (sqrt(u^2 + v^2))
- [x] Write test: directionRadians computed correctly (atan2(-u, -v))
- [x] Write test: directionDegrees computed correctly (normalized 0-360)
- [x] Write test: zero() factory creates zero-wind instance
- [x] Write test: edge case - zero wind (speed=0, direction=0)
- [x] Write test: edge case - negative components
- [x] Write test: meteorological convention verified (north wind = 0 degrees)
- [x] Run tests - expect failures (model not yet implemented)

**Files:** `test/models/wind_data_test.dart`

**Acceptance Criteria:**
- [x] Test file compiles (imports may fail until model exists)
- [x] 12 test cases defined (exceeded requirement)
- [x] Tests verify mathematical correctness

---

### Task 2.2: Write FakeWindService Tests [P]
- [x] Create test file `test/services/fake_wind_service_test.dart`
- [x] Write test: getWind() returns WindData instance
- [x] Write test: wind data has valid speed (> 0)
- [x] Write test: wind varies over time (two calls at different times differ)
- [x] Write test: wind speed in expected surface range (1-6 m/s)
- [x] Run tests - expect failures (service not yet implemented)

**Files:** `test/services/fake_wind_service_test.dart`

**Acceptance Criteria:**
- [x] Test file compiles (imports may fail until service exists)
- [x] 6 test cases defined (exceeded requirement)
- [x] Tests verify time-varying behavior

---

### Task 2.3: Write ParticleOverlay Wind Integration Tests
- [x] Add test group to `test/widgets/particle_overlay_test.dart`
- [x] Write test: accepts windData and compassHeading parameters
- [x] Write test: particles have position changes when wind is non-zero
- [x] Write test: trail length reflects wind speed
- [x] Write test: direction changes with compass heading
- [x] Run tests - expect failures (integration not yet implemented)

**Files:** `test/widgets/particle_overlay_test.dart`

**Acceptance Criteria:**
- [x] Tests added to existing test file
- [x] 5 new test cases defined (exceeded requirement)
- [x] Tests verify wind affects particle behavior

---

## Phase 3: Core Implementation

### Task 3.1: Implement WindData Model
- [x] Create `lib/models/wind_data.dart`
- [x] Add import `dart:math` for sqrt, atan2, pi
- [x] Create WindData class with final fields: uComponent, vComponent, altitude, timestamp
- [x] Add const constructor with required named parameters
- [x] Implement speed getter: `sqrt(uComponent * uComponent + vComponent * vComponent)`
- [x] Implement directionRadians getter: `atan2(-uComponent, -vComponent)`
- [x] Implement directionDegrees getter: `(directionRadians * 180 / pi + 360) % 360`
- [x] Add static zero() factory method
- [x] Run wind_data_test.dart - all tests should pass

**Files:** `lib/models/wind_data.dart`

**Acceptance Criteria:**
- [x] All wind_data_test.dart tests pass
- [x] No lint errors
- [x] Documentation comments on class and computed properties

---

### Task 3.2: Implement FakeWindService
- [x] Create `lib/services/fake_wind_service.dart`
- [x] Add imports: `dart:math`, `../models/wind_data.dart`
- [x] Create FakeWindService class
- [x] Implement getWind() method:
  - Get current time as seconds: `DateTime.now().millisecondsSinceEpoch / 1000`
  - Calculate u: `3.0 + sin(time * 0.1) * 2.0` (1-5 m/s range)
  - Calculate v: `2.0 + cos(time * 0.15) * 1.5` (0.5-3.5 m/s range)
  - Return WindData with altitude=10, timestamp=now
- [x] Run fake_wind_service_test.dart - all tests should pass

**Files:** `lib/services/fake_wind_service.dart`

**Acceptance Criteria:**
- [x] All fake_wind_service_test.dart tests pass
- [x] No lint errors
- [x] Documentation comments on class and method

---

### Task 3.3: Update ParticleOverlay for Wind-Driven Movement
- [x] Add import for WindData model
- [x] Replace `windAngle` parameter with `windData` (type: WindData)
- [x] Add `compassHeading` parameter (type: double, default: 0.0)
- [x] Update `_onTick()` method:
  - Calculate screenAngle: `windData.directionRadians - (compassHeading * pi / 180)`
  - Calculate speedFactor: `windData.speed * 0.002`
  - For each particle:
    - Update x: `p.x += cos(screenAngle) * speedFactor * dt`
    - Update y: `p.y -= sin(screenAngle) * speedFactor * dt` (Y inverted)
    - Update trailLength: `p.trailLength = windData.speed * 0.5`
    - Add screen wrapping (if x<0: x+=1, if x>1: x-=1, same for y)
- [x] Update ParticleOverlayPainter to receive screenAngle (rename windAngle internally)
- [x] Run particle_overlay_test.dart - all tests should pass

**Files:** `lib/widgets/particle_overlay.dart`

**Acceptance Criteria:**
- [x] All particle_overlay_test.dart tests pass
- [x] Particles move based on wind data
- [x] World-fixed behavior (direction adjusts for compass)
- [x] Trail length varies with wind speed

---

## Phase 4: Integration

### Task 4.1: Integrate Wind into ARViewScreen
- [x] Add imports for FakeWindService and WindData
- [x] Add state field: `late FakeWindService _windService`
- [x] Add state field: `WindData _windData = WindData.zero()` (or initialize in initState)
- [x] In initState(): create `_windService = FakeWindService()`
- [x] In `_onCompassUpdate()`: update `_windData = _windService.getWind()`
- [x] Update ParticleOverlay widget call:
  - Remove: `windAngle: 0.0`
  - Add: `windData: _windData`
  - Add: `compassHeading: _heading`
- [x] Update debug overlay to show wind info (speed, direction)
- [x] Run ar_view_screen_test.dart - verify no regressions

**Files:** `lib/screens/ar_view_screen.dart`

**Acceptance Criteria:**
- [x] No compilation errors
- [x] ParticleOverlay receives wind data and compass heading
- [x] Debug overlay shows wind speed and direction

---

### Task 4.2: Update Existing Tests for New API
- [x] Update any tests that use ParticleOverlay with old windAngle API
- [x] Ensure all tests pass after API changes
- [x] Run full test suite: `flutter test`

**Files:** `test/widgets/particle_overlay_test.dart`, `test/screens/ar_view_screen_test.dart`

**Acceptance Criteria:**
- [x] All existing tests updated for new API
- [x] Full test suite passes (96 tests)

---

## Phase 5: Polish

### Task 5.1: Add Verification Logging [P]
- [x] Add debug print in FakeWindService.getWind(): "Wind: {speed}m/s @ {direction}deg"
- [x] Verify logging appears in console during run

**Files:** `lib/services/fake_wind_service.dart`

**Acceptance Criteria:**
- [x] Wind data logged to console
- [x] Logs show varying values over time

---

### Task 5.2: Performance Verification [P]
- [ ] Run on real device (requires physical device - deferred to manual testing)
- [ ] Verify FPS remains at 60 (check existing FPS log)
- [ ] Verify no frame drops during particle movement
- [ ] Verify no GC stutters (check for allocation warnings)

**Files:** None (manual testing)

**Acceptance Criteria:**
- [ ] 60 FPS maintained with wind animation
- [ ] Smooth particle movement
- [ ] No visible stuttering

**Note:** Performance verification requires real device testing, not available in this environment.

---

### Task 5.3: Code Review Checklist [P]
- [x] No object allocation in _onTick() render loop
- [x] All new code has documentation comments
- [x] No lint warnings
- [x] Imports are minimal and specific

**Files:** All modified files

**Acceptance Criteria:**
- [x] Code review checklist passes
- [x] `flutter analyze` reports no issues

---

## Phase 6: Ready for Test Agent

### Task 6.1: Final Verification
- [x] Run full test suite: `flutter test` - 96 tests passing
- [x] Run analyzer: `flutter analyze` - no issues
- [ ] Build iOS: `flutter build ios --no-codesign` (not available in this environment)
- [ ] Build Android: `flutter build apk --debug` (not available in this environment)
- [x] Commit ready for test agent review

**Files:** None

**Acceptance Criteria:**
- [x] All 12+ unit tests pass (18 new tests for wind-animation)
- [x] All widget tests pass (15 particle overlay tests total)
- [x] No analyzer warnings
- [ ] Both platforms build successfully (deferred - requires SDK)

---

## Handoff Checklist for Test Agent

When Phase 6 is complete, verify:

- [x] `lib/models/wind_data.dart` - WindData model with speed/direction
- [x] `lib/services/fake_wind_service.dart` - Simulated wind data
- [x] `lib/widgets/particle_overlay.dart` - Wind-driven particle movement
- [x] `lib/screens/ar_view_screen.dart` - Integration with wind service
- [x] `test/models/wind_data_test.dart` - 12 passing tests
- [x] `test/services/fake_wind_service_test.dart` - 6 passing tests
- [x] `test/widgets/particle_overlay_test.dart` - Extended with 5+ new tests
- [x] All tests pass: `flutter test` - 96 tests passing
- [x] No analyzer issues: `flutter analyze`
- [ ] Builds succeed for iOS and Android (deferred - requires SDK)

---

## Summary

| Phase | Task Count | Parallelizable | Status |
|-------|------------|----------------|--------|
| Phase 1: Setup | 0 | - | Complete |
| Phase 2: Tests | 3 | 2 [P] | Complete |
| Phase 3: Implementation | 3 | 0 | Complete |
| Phase 4: Integration | 2 | 0 | Complete |
| Phase 5: Polish | 3 | 3 [P] | Complete (except device testing) |
| Phase 6: Verification | 1 | 0 | Complete (except builds) |
| **Total** | **12** | **5** | **Complete** |

Completed implementation: wind-animation feature is ready for test agent review.
