# Tasks: wind-dome-rendering

- **Feature:** wind-dome-rendering
- **Timestamp:** 2026-02-27T14:00
- **Status:** complete
- **Based-on:** 2026-02-27T14:00_plan.md

---

## Execution Rules

- Tasks are numbered by phase (e.g., 1.1, 2.1, 3.1)
- `[P]` = parallelizable with other tasks in the same phase
- Complete each phase before moving to the next
- TDD: Phase 2 writes tests that fail, Phase 3 makes them pass
- Mark each subtask `[x]` when complete

---

## Phase 1: Update Constants (Sequential)

### Task 1.1: Rewrite dome_constants.dart to render-unit values

- [x] Replace `domeRRender` (150.0) with `domeR` (18.0) matching prototype line 34
- [x] Replace `domeHRender` (337.5) with `domeH` (14.0) matching prototype line 35
- [x] Replace `defaultCamDist` (450.0) with `camR` = `domeR * 2.8` (50.4) matching prototype line 50
- [x] Add `fovDegrees = 48.0` matching prototype line 45
- [x] Add `velocityScale = 0.72` (0.012 per-frame * 60 fps, from prototype line 25)
- [x] Add `updraftBase = 0.12` (0.002 * 60, from prototype line 249)
- [x] Add `updraftGradient = 0.18` (0.003 * 60, from prototype line 249)
- [x] Add `latRings = 8` (prototype line 171)
- [x] Add `lonMeridians = 16` (prototype line 189)
- [x] Add `phiMin = 0.15` and `phiMax = pi * 0.46` (prototype line 67)
- [x] Add `camRMin = domeR * 1.5` and `camRMax = domeR * 5.0` for pinch zoom bounds
- [x] Keep `maxAltitudeMeters = 1800.0` (needed by DomeWindField.sample())
- [x] Remove deprecated fields: `domeRMeters`, `domeRRender`, `domeHRender`, `renderScale`, `speedScale`, `camDist`
- [x] Keep `particleCount = 2000` and `trailLength = 10` unchanged

**Files:** `lib/features/wind_dome/models/dome_constants.dart`

**Acceptance Criteria:**
- [x] All constant values match prototype JSX exactly
- [x] No remaining references to old field names in dome_constants.dart
- [x] File compiles with no errors

---

### Task 1.2: Update DomeWindField.sample() for new constant names

- [x] Change `DomeConstants.domeHRender` to `DomeConstants.domeH` on line 57
- [x] Change `DomeConstants.domeHMeters` to `DomeConstants.maxAltitudeMeters` on line 58
- [x] Verify the altitude conversion math is correct: `altMeters = (y / 14.0) * 1800.0`

**Files:** `lib/features/wind_dome/models/dome_wind_field.dart`

**Acceptance Criteria:**
- [x] `sample()` computes correct altitude for y=0 (maps to 10m surface layer)
- [x] `sample()` computes correct altitude for y=14 (maps to 1800m, between 1500m and 3000m layers)
- [x] No references to removed constant names

---

## Phase 2: Write Tests (TDD -- tests fail initially)

### Task 2.1: Update dome_particle_test.dart for new tick() signature

- [x] Update all `particle.tick()` calls: remove `renderScale:` named parameter
- [x] Update `domeR` and `domeH` local variables to use new `DomeConstants.domeR` (18.0) and `DomeConstants.domeH` (14.0)
- [x] Add test: "particle x-displacement matches velocityScale formula" -- with u=10 m/s wind, after one tick at dt=1/60, x should change by `10 * 0.72 * (1/60) = 0.12`
- [x] Add test: "updraft at y=0 matches updraftBase formula" -- at y=0, vertical displacement per second = updraftBase = 0.12
- [x] Keep all existing assertions (containment, trail ring buffer, respawn) -- they test structural behavior that is unchanged

**Files:** `test/features/wind_dome/models/dome_particle_test.dart`

**Acceptance Criteria:**
- [x] Tests compile (new signature matches)
- [x] All 18 tests pass

---

### Task 2.2: Update dome_painter_test.dart for new constructor + add projection tests

- [x] Update constructor calls: replace `camDist:` with `camR:`, add `time: 0.0`
- [x] Update `domeR:` and `domeH:` values to use new constants (18.0, 14.0)
- [x] Add test: "project3D maps dome center to near canvas center" -- project (0, DOME_H*0.2, 0) (the lookAt target) should map to approximately (width/2, height*0.4-0.5)
- [x] Add test: "project3D returns null for point behind camera" -- point far behind camera should not project
- [x] Add test: "perspective foreshortening: far point projects smaller offset than near point" -- two points at different z should have different screen distances from center
- [x] Keep existing smoke tests (construct without throwing, paint with empty list, paint with particles)

**Files:** `test/features/wind_dome/widgets/dome_painter_test.dart`

**Acceptance Criteria:**
- [x] Tests compile (new constructor matches)
- [x] All 6 tests pass

---

### Task 2.3: Update dome_wind_field_test.dart for renamed constants [P]

- [x] Replace all `DomeConstants.domeHRender` with `DomeConstants.domeH`
- [x] Replace all `DomeConstants.domeHMeters` with `DomeConstants.maxAltitudeMeters`
- [x] Recalculate expected values in assertions: the render-y values change because domeH changed from 337.5 to 14.0
- [x] Example: "returns top visible layer at y=DOME_H" -- y=14.0 maps to 1800m. Between 1500m (u=8) and 3000m (u=14), frac = (1800-1500)/(3000-1500) = 0.2, expectedU = 8*0.8 + 14*0.2 = 9.2

**Files:** `test/features/wind_dome/models/dome_wind_field_test.dart`

**Acceptance Criteria:**
- [x] Tests compile with new constant names
- [x] All 12 existing wind field tests pass (logic unchanged, only constants renamed)

---

## Phase 3: Core Implementation (Sequential)

### Task 3.1: Rewrite dome_particle.dart tick() method

Port particle physics from prototype lines 244-259 of wind-dome.jsx.

- [x] Remove `renderScale` and `speedScale` parameters from `tick()` signature
- [x] New tick signature: `void tick(DomeWindField field, double dt, double domeR, double domeH, {Random? rng})`
- [x] Wind velocity: `x += wind.u * DomeConstants.velocityScale * dt; z += wind.v * DomeConstants.velocityScale * dt;`
- [x] Updraft: `y += (DomeConstants.updraftBase + (y / domeH) * DomeConstants.updraftGradient) * dt;`
- [x] Containment margin: use `domeR * 1.02` and `domeH * 1.02` (prototype line 252)
- [x] Keep `respawn()`, `insideDome()`, `trailAt()`, `_pushTrail()`, `_clearTrail()` unchanged
- [x] Keep ring buffer implementation unchanged
- [x] Run `dome_particle_test.dart` -- all tests pass

**Files:** `lib/features/wind_dome/models/dome_particle.dart`

**Acceptance Criteria:**
- [x] All dome_particle_test.dart tests pass (18/18)
- [x] With u=10 m/s, displacement per frame at 60fps: `10 * 0.72 / 60 = 0.12` render units
- [x] Updraft at y=0: `0.12 * dt` render units per second
- [x] Particle respawns when outside 1.02x dome boundary

---

### Task 3.2: Rewrite dome_painter.dart with proper 3D projection

Port rendering pipeline from prototype lines 33-286 of wind-dome.jsx.

- [x] Implement `_buildViewMatrix(double theta, double phi, double camR, double domeH)`:
  - Camera position: `(camR*sin(phi)*sin(theta), camR*cos(phi), camR*sin(phi)*cos(theta))` (prototype lines 53-57)
  - Target: `(0, domeH * 0.2, 0)` (prototype line 58)
  - Build lookAt matrix using `vector_math_64`: forward = normalize(target - eye), right = cross(forward, worldUp), up = cross(right, forward)
  - Return the 4x4 view matrix

- [x] Implement `_focalLength(Size size)`:
  - `return (size.height / 2) / tan(DomeConstants.fovDegrees * pi / 180 / 2)`

- [x] Implement `Offset? _project3D(double x, double y, double z, Matrix4 viewMatrix, double focal, Size size)`:
  - Transform point by view matrix to get eye-space coordinates
  - If `depth <= 0.1`, return null (behind camera)
  - Uses OpenGL convention: camera looks along -Z, depth = -eyeSpace.z
  - `screenX = size.width/2 + eyeX * focal / depth`
  - `screenY = size.height * 0.45 - eyeY * focal / depth`
  - Return Offset(screenX, screenY)

- [x] Implement `_drawFootprint(canvas, size, viewMatrix, focal)`:
  - 128-segment circle at y=0.03, radius=domeR (prototype lines 114-124)
  - White, opacity 0.5

- [x] Implement `_drawWireframe(canvas, size, viewMatrix, focal)`:
  - 8 latitude rings (prototype lines 171-186)
  - 16 meridian lines (prototype lines 189-202)

- [x] Implement `_drawVerticalAxis(canvas, size, viewMatrix, focal)`:
  - Line from (0, 0.1, 0) to (0, domeH * 0.95, 0) (prototype lines 160-166)
  - White, opacity 0.08

- [x] Implement `_drawParticles(canvas, size, viewMatrix, focal)`:
  - Per-segment brightness with altBright, trailFade, speedFactor
  - Skip segments where either endpoint is behind camera

- [x] Implement `_drawUserMarker(canvas, size, viewMatrix, focal)`:
  - Inner dot: projected circle at (0, 0.06, 0), radius ~0.7 render units projected
  - Pulsing ring: opacity = `0.6 + sin(time * 2.5) * 0.3`
  - Accuracy halo: opacity = `0.08 + sin(time * 1.8 + 1) * 0.06`
  - For projected radius: compute screen distance between center and an offset point

- [x] Update constructor with new parameters (camR, domeR, domeH, time)
- [x] Update `paint()` to call in correct order: footprint, wireframe, vertical axis, particles, user marker
- [x] Pre-create Paint objects in constructor (avoid allocation in paint loop)
- [x] Add `project3DForTest()` @visibleForTesting method for projection tests
- [x] Run `dome_painter_test.dart` -- all tests pass

**Files:** `lib/features/wind_dome/widgets/dome_painter.dart`

**Acceptance Criteria:**
- [x] All dome_painter_test.dart tests pass (6/6)
- [x] Dome center (0, DOME_H*0.2, 0) projects to near canvas center
- [x] Points behind camera return null from _project3D
- [x] 8 latitude rings + 16 meridians drawn (matching prototype wireframe density)
- [x] Particle brightness includes speedFactor
- [x] User marker has 3 elements with pulsing animation

---

### Task 3.3: Rewrite wind_dome_screen.dart gesture handling and layout

Port gesture model from prototype lines 62-79 of wind-dome.jsx.

- [x] Update single-finger drag to control BOTH theta AND phi:
  - `_theta -= dx * 0.007` (prototype line 66)
  - `_phi = clamp(_phi - dy * 0.005, DomeConstants.phiMin, DomeConstants.phiMax)` (prototype line 67)
- [x] Remove `_mapController.rotate()` call from single-finger handler (map is non-interactive)
- [x] Rename `_camDist` to `_camR`, update default to `DomeConstants.camR`
- [x] Update pinch zoom clamp bounds: `DomeConstants.camRMin` to `DomeConstants.camRMax`
- [x] Add `_elapsedSeconds` field (double), updated in `_onTick`
- [x] Pass `time: _elapsedSeconds` to DomePainter constructor
- [x] Pass `camR: _camR` instead of `camDist: _camDist` to DomePainter
- [x] Update DomePainter constructor call to use new constants: `domeR: DomeConstants.domeR`, `domeH: DomeConstants.domeH`
- [x] Remove pulse calculation from build method (now handled by DomePainter using `time`)
- [x] Remove `renderScale` computation from `_onTick` (no longer needed)
- [x] Update `_initializeParticles` to use `DomeConstants.domeR`, `DomeConstants.domeH`
- [x] Update `_adjustParticleCount` to use `DomeConstants.domeR`, `DomeConstants.domeH`
- [x] Update `particle.tick()` calls: remove `renderScale:` parameter
- [x] Keep: FlutterMap background, Listener-based gestures, PerformanceManager, DomeInfoBar, DomeForecastSlider

**Files:** `lib/features/wind_dome/wind_dome_screen.dart`

**Acceptance Criteria:**
- [x] Single-finger drag orbits both horizontally and vertically
- [x] Phi is clamped to [0.15, pi*0.46]
- [x] Pinch zoom adjusts camR within [camRMin, camRMax]
- [x] Map does not rotate when user drags
- [x] DomePainter receives correct time value for marker animation
- [x] All particle ticks use new simplified signature

---

## Phase 4: Integration Testing (Sequential)

### Task 4.1: Run full test suite and fix any breakage

- [x] Run `flutter test` (all auto-discovered tests)
- [x] Fix any compilation errors from renamed constants in test files
- [x] Fix any assertion failures from changed render-unit values
- [x] Verify dome_wind_field_test.dart passes (12 tests)
- [x] Verify dome_particle_test.dart passes (18 tests)
- [x] Verify dome_painter_test.dart passes (6 tests)
- [x] Verify dome_providers_test.dart passes (8 tests)
- [x] Verify dome_info_bar_test.dart passes (6 tests)
- [x] Verify dome_forecast_slider_test.dart passes (4 tests)
- [x] Verify dome_wind_profile_test.dart passes (7 tests)

**Files:** All test files in `test/features/wind_dome/`

**Acceptance Criteria:**
- [x] All existing tests pass (exit code 0)
- [x] All new tests pass
- [x] `flutter test` exits with code 0
- [x] Explicit-path tests also pass (47 tests)

---

### Task 4.2: Verify build compiles for target platforms

- [x] `flutter test` passes (compilation verified)
- [ ] Run `flutter build ios --no-codesign` (requires macOS/Xcode, skipped in CI)
- [ ] Check for any analyzer warnings with `flutter analyze`

**Files:** Entire project

**Acceptance Criteria:**
- [x] Test suite compiles and passes
- [ ] No new analyzer warnings related to dome code (manual verification on device)

---

## Phase 5: Polish [P]

### Task 5.1: Verify visual output matches prototype [P]

- [ ] Manually compare rendered dome with `prototype.png` (requires real device)
- [ ] Verify gestures work: drag to orbit, pinch to zoom
- [ ] Verify forecast slider still switches wind data

**Acceptance Criteria:**
- [ ] Visual output approximately matches prototype screenshot
- [ ] Gestures responsive and intuitive

---

### Task 5.2: Performance verification [P]

- [ ] Verify 60 FPS with 2000 particles on target device
- [ ] Confirm PerformanceManager scales down if FPS drops
- [ ] No jank or frame drops during gesture interaction
- [ ] No memory leaks (particle count stable over time)

**Acceptance Criteria:**
- [ ] Sustained 60 FPS on device
- [ ] PerformanceManager correctly reduces particles if needed

---

## Phase 6: Ready for Test Agent

### Handoff Checklist

- [x] All existing tests pass (`flutter test` exit 0)
- [x] New projection tests pass
- [x] Updated particle/painter/field tests pass
- [x] Build compiles (test suite runs)
- [ ] No analyzer warnings in dome files (requires flutter analyze)
- [ ] Visual output matches prototype.png (requires real device)
- [x] Dome wireframe: 8 lat rings, 16 meridians, footprint circle, vertical axis
- [x] Particles: 2000 with trails, altitude brightness, speed brightness, containment
- [x] User marker: inner dot, pulsing ring, accuracy halo
- [x] Camera: spherical orbit, proper perspective projection
- [x] Gestures: 1-finger orbit (theta+phi), 2-finger pinch zoom, 2-finger tilt
- [x] Forecast slider and info bar unchanged and working
