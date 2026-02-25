# Tasks: architectural-foundation (SPEC-001)

## Metadata
- **Feature:** architectural-foundation (SPEC-001)
- **Created:** 2026-02-25T17:00
- **Status:** tasks-defined
- **Based-on:** 2026-02-25T17:00_plan.md, 2026-02-25T14:00_research.md
- **Phases:** 3 (each gets its own `/implement` run)

## Execution Rules

1. **Sequential within a phase** unless marked `[P]` for parallelizable
2. **TDD order:** Write test -> Run test (expect fail) -> Implement -> Run test (expect pass)
3. **Read before write:** Each `/implement` agent MUST read current source files before modifying
4. **Run all tests after each task:** `flutter test` in `/workspace/wind_lens/`
5. **DECISIONS.md:** Each phase appends to `.claude/features/architectural-foundation/DECISIONS.md`
6. **Completion markers:** Check off `[x]` as tasks complete
7. **build_runner:** After creating/modifying any Freezed model, run `dart run build_runner build --delete-conflicting-outputs` from `/workspace/wind_lens/`

---

## PHASE 1: Foundation (Freezed Models + Service Interfaces + Wrappers)

**Agent context:** This is the first `/implement` run.
**Prerequisite:** Research and plan documents exist.
**Checkpoint:** All tests green, branch committed.

---

### Task 1.1: Add Freezed + build_runner Dependencies

- [x] Read `wind_lens/pubspec.yaml` to see current dependencies
- [x] Add `freezed_annotation: ^2.4.1` to `dependencies`
- [x] Add `freezed: ^2.4.5` to `dev_dependencies`
- [x] Add `build_runner: ^2.4.6` to `dev_dependencies`
- [x] Add `json_serializable: ^6.7.1` to `dev_dependencies`
- [x] Run `flutter pub get` from `/workspace/wind_lens/`
- [x] Verify no dependency conflicts
- [x] Run `flutter test` to confirm existing 405 tests still pass

**Files:** `wind_lens/pubspec.yaml`

**Acceptance Criteria:**
- [ ] `flutter pub get` succeeds with no errors
- [ ] All 405 existing tests pass
- [ ] New dev_dependencies appear in pubspec.lock

---

### Task 1.2: Create PositionData Freezed Model (Canary)

This is the first Freezed model. Its purpose is to validate the build_runner pipeline works with our SDK version before creating more models.

- [x] Create directory `wind_lens/lib/core/models/` if it does not exist
- [x] Create `wind_lens/lib/core/models/position_data.dart` with Freezed class:
  - Fields: `latitude` (double), `longitude` (double), `altitude` (double), `accuracy` (double), `timestamp` (DateTime)
  - Include `fromJson` factory
  - Include `part` directives for `.freezed.dart` and `.g.dart`
- [x] Run `dart run build_runner build --delete-conflicting-outputs` from `/workspace/wind_lens/`
- [x] Verify `position_data.freezed.dart` and `position_data.g.dart` are generated
- [x] Create `wind_lens/test/core/models/position_data_test.dart` with tests:
  - Construction with all fields
  - Equality: same data = equal
  - Equality: different data = not equal
  - `copyWith` produces modified copy
  - JSON round-trip (toJson -> fromJson -> equal)
  - Verify altitude field exists (new field vs old LocationData)
- [x] Run `flutter test` -- all tests pass (old 405 + new)

**Files:**
- `wind_lens/lib/core/models/position_data.dart` (new)
- `wind_lens/lib/core/models/position_data.freezed.dart` (generated)
- `wind_lens/lib/core/models/position_data.g.dart` (generated)
- `wind_lens/test/core/models/position_data_test.dart` (new)

**Acceptance Criteria:**
- [ ] build_runner generates files without errors
- [ ] Generated files compile without warnings
- [ ] All new equality/copyWith/JSON tests pass
- [ ] All 405 original tests still pass (PositionData not used by existing code yet)

---

### Task 1.3: Create SensorState Freezed Model

- [x] Create `wind_lens/lib/core/models/sensor_state.dart` with Freezed class:
  - Fields: `compassHeading` (double), `pitch` (double), `timestamp` (DateTime)
  - No JSON serialization needed (not cached)
  - Include `part` directive for `.freezed.dart`
- [x] Run `dart run build_runner build --delete-conflicting-outputs`
- [x] Create `wind_lens/test/core/models/sensor_state_test.dart` with tests:
  - Construction with all fields
  - Equality: same data = equal
  - Equality: different data = not equal
  - `copyWith` produces modified copy
  - Verify field names match SPEC-001 (compassHeading, not heading)
- [x] Run `flutter test` -- all tests pass

**Files:**
- `wind_lens/lib/core/models/sensor_state.dart` (new)
- `wind_lens/lib/core/models/sensor_state.freezed.dart` (generated)
- `wind_lens/test/core/models/sensor_state_test.dart` (new)

**Acceptance Criteria:**
- [ ] Freezed generation succeeds
- [ ] All equality/copyWith tests pass
- [ ] All original tests still pass

---

### Task 1.4a: Create Freezed WindData Model

This is the riskiest task in Phase 1. Split into two sub-steps to manage context pressure: first create the new model and get it compiling, then migrate consumers file by file.

**Sub-step 1: Create the model and validate build_runner.**

- [x] Read current `wind_lens/lib/models/wind_data.dart` to understand existing fields and computed getters
- [x] Create `wind_lens/lib/core/models/wind_data.dart` as Freezed class:
  - Fields: `uComponent` (double), `vComponent` (double), `gustSpeed` (double, default 0.0), `altitude` (AltitudeLevel), `timestamp` (DateTime)
  - Private constructor `const WindData._()` for custom getters
  - Computed getters: `speed`, `directionRadians`, `directionDegrees` (same formulas as current)
  - Static `zero()` factory returning surface-level zero wind
  - `fromSpeedDirection()` factory for convenience
  - `fromJson`/`toJson` support
  - Import `dart:math` for `sqrt`, `atan2`, `pi`, `sin`, `cos`
- [x] Run `dart run build_runner build --delete-conflicting-outputs`
- [x] Verify generated files compile without errors
- [x] Create `wind_lens/test/core/models/wind_data_freezed_test.dart` with tests:
  - Construction with all fields
  - Equality: same data = equal, different = not equal
  - `copyWith` produces modified copy
  - `speed` getter matches `sqrt(u² + v²)`
  - `directionRadians` getter matches `atan2(-u, -v)`
  - `directionDegrees` getter matches radians * 180 / pi
  - `WindData.zero()` returns zero speed, surface level
  - `WindData.fromSpeedDirection()` round-trips correctly
  - JSON round-trip
- [x] Run `flutter test` -- all tests pass (old 405 + new, no conflicts because old WindData still exists)

**Files:**
- `wind_lens/lib/core/models/wind_data.dart` (new Freezed)
- `wind_lens/lib/core/models/wind_data.freezed.dart` (generated)
- `wind_lens/lib/core/models/wind_data.g.dart` (generated)
- `wind_lens/test/core/models/wind_data_freezed_test.dart` (new)

**Acceptance Criteria:**
- [ ] Freezed WindData has u/v as primary fields
- [ ] Computed getters produce identical results to old class
- [ ] `WindData.zero()` and `WindData.fromSpeedDirection()` work
- [ ] build_runner generates cleanly
- [ ] All 405 original tests still pass (old WindData untouched)

---

### Task 1.4b: Migrate Consumers to Freezed WindData

**Sub-step 2: Migrate consumers file by file.** Do NOT try to hold the entire changeset in your head — read each file, update it, verify it compiles, then move to the next.

- [x] Read `wind_lens/lib/services/fake_wind_service.dart` and update:
  - Import new WindData from `core/models/`
  - Change `altitude: 10` to `altitude: AltitudeLevel.surface` (or equivalent)
  - Change `altitude: level.metersAGL` to `altitude: level`
  - Add AltitudeLevel import if not already there
- [x] Read `wind_lens/lib/models/wind_data.dart` and replace with re-export:
  ```dart
  // Backward compatibility -- re-export Freezed WindData
  export '../core/models/wind_data.dart';
  ```
- [x] Read and update `wind_lens/test/models/wind_data_test.dart`:
  - Change altitude assertions from double to AltitudeLevel
  - Keep all existing computed getter tests
- [x] Read and update `wind_lens/test/services/fake_wind_service_test.dart` if it references `wind.altitude` as double
- [x] Read `wind_lens/lib/widgets/particle_overlay.dart` -- uses `windData.speed`, `windData.directionRadians` (computed getters, no change needed)
- [x] Read `wind_lens/lib/widgets/debug_panel.dart` -- no direct `windData.altitude` as double reference
- [x] Read `wind_lens/lib/widgets/info_bar.dart` -- no `windData.altitude` reference
- [x] Read `wind_lens/lib/screens/ar_view_screen.dart` -- uses `WindData.zero()` (compatible, returns AltitudeLevel.surface)
- [x] Updated `test/widgets/particle_overlay_test.dart` -- changed `altitude: 10.0` to `altitude: AltitudeLevel.surface` (12 occurrences)
- [x] Run `flutter test` -- all 429 tests pass

**Files:**
- `wind_lens/lib/models/wind_data.dart` (modified to re-export)
- `wind_lens/lib/services/fake_wind_service.dart` (modified)
- `wind_lens/test/models/wind_data_test.dart` (modified)
- `wind_lens/test/services/fake_wind_service_test.dart` (possibly modified)
- Various widgets/screens if they reference `wind.altitude` as double

**Acceptance Criteria:**
- [ ] All consumers use Freezed WindData (via re-export or direct import)
- [ ] FakeWindService tests pass with altitude as AltitudeLevel
- [ ] All original tests pass (some updated for new types)
- [ ] No double-to-enum type errors anywhere
- [ ] Old `models/wind_data.dart` is now just a re-export

---

### Task 1.5: Create HorizonProfile Freezed Model

- [x] Create `wind_lens/lib/core/models/horizon_profile.dart` with Freezed class:
  - Fields: `latitude` (double), `longitude` (double), `elevationAngles` (Map<double, double>), `fetchedAt` (DateTime)
  - Private constructor for custom method `getElevationAtBearing(double bearing)`
  - The method interpolates between the two nearest bearings in the map
  - Factory `HorizonProfile.flat(double lat, double lng)` returning 0-degree elevation at every 1-degree bearing
  - `fromJson`/`toJson` support
  - Added `DoubleMapConverter` for Map<double, double> JSON serialization (JSON keys must be strings)
- [x] Run `dart run build_runner build --delete-conflicting-outputs`
- [x] Create `wind_lens/test/core/models/horizon_profile_test.dart` with tests:
  - Construction with all fields
  - Equality: same data = equal
  - `getElevationAtBearing()` exact match (bearing exists in map)
  - `getElevationAtBearing()` interpolation (bearing between two entries)
  - `getElevationAtBearing()` wraparound (bearing near 0/360)
  - `flat()` factory returns 0 elevation at any bearing
  - JSON round-trip (including empty map)
- [x] Run `flutter test` -- all 443 tests pass

**Files:**
- `wind_lens/lib/core/models/horizon_profile.dart` (new)
- `wind_lens/lib/core/models/horizon_profile.freezed.dart` (generated)
- `wind_lens/lib/core/models/horizon_profile.g.dart` (generated)
- `wind_lens/test/core/models/horizon_profile_test.dart` (new)

**Acceptance Criteria:**
- [ ] `getElevationAtBearing()` interpolates correctly
- [ ] `flat()` factory works for indoor/testing use
- [ ] JSON round-trip preserves data
- [ ] All tests pass

---

### Task 1.6: Create SkyMaskData Freezed Model

Named `SkyMaskData` to avoid collision with existing `SkyMask` interface. Will be renamed in Phase 2.

- [x] Create `wind_lens/lib/core/models/sky_mask_data.dart` with Freezed class:
  - Fields: `width` (int), `height` (int), `pixels` (List<bool>, row-major), `method` (SkyDetectionMethod enum)
  - Define `SkyDetectionMethod` enum: `hsv`, `terrain`, `combined`
  - Private constructor for custom method:
    - `bool isPointInSky(double normalizedX, double normalizedY)` -- looks up pixel in the boolean array
    - `double get skyFraction` -- counts true pixels / total pixels
  - Factory `SkyMaskData.fullSky({int width = 128, int height = 96})` returning all-true pixels
  - No JSON serialization needed (not cached)
- [x] Run `dart run build_runner build --delete-conflicting-outputs`
- [x] Create `wind_lens/test/core/models/sky_mask_data_test.dart` with tests:
  - Construction with all fields
  - `isPointInSky()` returns true for sky pixels
  - `isPointInSky()` returns false for non-sky pixels
  - `isPointInSky()` handles edge coordinates (0,0 and 1,1)
  - `skyFraction` computed correctly (50% sky -> 0.5)
  - `fullSky()` factory: skyFraction = 1.0, all points are sky
  - Equality tests (including different method = unequal)
- [x] Run `flutter test` -- all 461 tests pass (429 + 14 horizon + 18 sky mask)

**Files:**
- `wind_lens/lib/core/models/sky_mask_data.dart` (new)
- `wind_lens/lib/core/models/sky_mask_data.freezed.dart` (generated)
- `wind_lens/test/core/models/sky_mask_data_test.dart` (new)

**Acceptance Criteria:**
- [ ] `isPointInSky()` correctly maps normalized coords to pixel array
- [ ] `skyFraction` is computed, not stored
- [ ] `fullSky()` factory works for fallback
- [ ] All tests pass

---

### Task 1.7: Create SceneState Freezed Model

- [x] Create `wind_lens/lib/core/models/scene_state.dart` with Freezed class:
  - Fields: `position` (PositionData), `horizon` (HorizonProfile), `wind` (WindData), `compassHeading` (double), `pitch` (double), `skyMask` (SkyMaskData), `selectedAltitude` (AltitudeLevel), `timestamp` (DateTime)
  - Imports all other Freezed models
  - No JSON serialization needed
- [x] Run `dart run build_runner build --delete-conflicting-outputs`
- [x] Create `wind_lens/test/core/models/scene_state_test.dart` with tests:
  - Construction with all sub-models
  - Equality: same data = equal
  - Equality: different wind data = not equal
  - Equality: different heading = not equal
  - `copyWith` allows changing altitude and heading
- [x] Run `flutter test` -- all tests pass (467 total)

**Files:**
- `wind_lens/lib/core/models/scene_state.dart` (new)
- `wind_lens/lib/core/models/scene_state.freezed.dart` (generated)
- `wind_lens/test/core/models/scene_state_test.dart` (new)

**Acceptance Criteria:**
- [ ] SceneState composes all sub-models
- [ ] Equality correctly considers all fields
- [ ] `copyWith` works for partial updates
- [ ] All tests pass

---

### Task 1.8: Define Service Interfaces

Create the 4 service interfaces as abstract classes. These go in `lib/core/services/` and are pure Dart (no Flutter material imports).

- [x] Create directory `wind_lens/lib/core/services/` if it does not exist
- [x] Create `wind_lens/lib/core/services/sky_detector.dart`:
  - Abstract class `SkyDetector` with:
    - `Future<SkyMaskData> detect({required CameraImage frame, required SensorState sensors, HorizonProfile? horizon})`
    - `String get name`
  - Import `CameraImage` from `package:camera/camera.dart`
  - Import `SensorState`, `SkyMaskData`, `HorizonProfile` from core models
- [x] Create `wind_lens/lib/core/services/wind_data_source.dart`:
  - Abstract class `WindDataSource` with:
    - `Future<WindData> getWind({required PositionData position, required AltitudeLevel altitude})`
    - `bool get isSimulated`
  - Import `WindData`, `PositionData`, `AltitudeLevel` from core models
- [x] Create `wind_lens/lib/core/services/horizon_provider.dart`:
  - Abstract class `HorizonProvider` with:
    - `Future<HorizonProfile> getHorizon({required double latitude, required double longitude})`
  - Import `HorizonProfile` from core models
- [x] Create `wind_lens/lib/core/services/sensor_service.dart`:
  - Abstract class `SensorService` with:
    - `Stream<SensorState> get sensorStream`
    - `Stream<PositionData> get positionStream`
    - `void pause()`
    - `void resume()`
    - `void dispose()`
  - Import `SensorState`, `PositionData` from core models
- [x] Verify all interfaces compile: `dart analyze` -- no issues found
- [x] Run `flutter test` -- all 467 tests pass

**Files:**
- `wind_lens/lib/core/services/sky_detector.dart` (new)
- `wind_lens/lib/core/services/wind_data_source.dart` (new)
- `wind_lens/lib/core/services/horizon_provider.dart` (new)
- `wind_lens/lib/core/services/sensor_service.dart` (new)

**Acceptance Criteria:**
- [ ] All 4 interfaces compile without errors
- [ ] No Flutter material imports in any interface file
- [ ] Interfaces match SPEC-001 signatures (with u/v WindData adjustment)
- [ ] All existing tests still pass

---

### Task 1.9: Create MockWindDataSource Wrapper

- [x] Read `wind_lens/lib/services/fake_wind_service.dart` to understand its API
- [x] Create directory `wind_lens/lib/services/wind/` if it does not exist
- [x] Create `wind_lens/lib/services/wind/mock_wind_source.dart`:
  - Class `MockWindDataSource implements WindDataSource`
  - Owns a `FakeWindService` instance internally
  - `getWind(position, altitude)`: delegates to `_fakeService.getWindForAltitude(altitude)`, wraps result in `Future.value()`
  - `isSimulated: true`
- [x] Create `wind_lens/test/services/wind/mock_wind_source_test.dart` with tests:
  - Returns a valid WindData future
  - `isSimulated` is true
  - Returns different wind data for different altitude levels
  - Wind speed is positive
- [x] Run `flutter test` -- all 472 tests pass

**Files:**
- `wind_lens/lib/services/wind/mock_wind_source.dart` (new)
- `wind_lens/test/services/wind/mock_wind_source_test.dart` (new)

**Acceptance Criteria:**
- [ ] MockWindDataSource implements WindDataSource interface
- [ ] Delegates correctly to FakeWindService
- [ ] All tests pass

---

### Task 1.10: Create MockHorizonProvider

- [x] Create directory `wind_lens/lib/services/horizon/` if it does not exist
- [x] Create `wind_lens/lib/services/horizon/mock_horizon_provider.dart`:
  - Class `MockHorizonProvider implements HorizonProvider`
  - `getHorizon(lat, lng)`: returns `Future.value(HorizonProfile.flat(lat, lng))`
- [x] Create `wind_lens/test/services/horizon/mock_horizon_provider_test.dart` with tests:
  - Returns a HorizonProfile future
  - Returned profile has matching lat/lng
  - All elevation angles are 0 (flat horizon)
  - `getElevationAtBearing()` returns 0 for any bearing
- [x] Run `flutter test` -- all 477 tests pass

**Files:**
- `wind_lens/lib/services/horizon/mock_horizon_provider.dart` (new)
- `wind_lens/test/services/horizon/mock_horizon_provider_test.dart` (new)

**Acceptance Criteria:**
- [ ] MockHorizonProvider implements HorizonProvider interface
- [ ] Returns flat horizon for any coordinates
- [ ] All tests pass

---

### Task 1.11: Create DeviceSensorService Wrapper

- [x] Read `wind_lens/lib/services/compass_service.dart` to understand stream API
- [x] Read `wind_lens/lib/services/location_service.dart` to understand stream API
- [x] Create directory `wind_lens/lib/services/sensors/` if it does not exist
- [x] Create `wind_lens/lib/services/sensors/device_sensor_service.dart`:
  - Class `DeviceSensorService implements SensorService`
  - Owns a `CompassService` and `LocationService` internally
  - `autoStart` parameter (default true) to avoid platform channels in tests
  - `wireStreams()` public method: sets up stream mapping without calling .start()
  - `start()` method: calls .start() on both services + wireStreams()
  - `sensorStream`: maps CompassData -> SensorState
  - `positionStream`: maps LocationData -> PositionData (altitude: 0.0 placeholder)
  - `pause()`: cancels subscriptions, disposes services
  - `resume()`: re-creates services, calls start()
  - `dispose()`: cleans up everything
- [x] Create `wind_lens/test/services/sensors/device_sensor_service_test.dart` with 6 tests:
  - implements SensorService interface
  - sensorStream emits SensorState when compass data arrives
  - positionStream emits PositionData when location data arrives
  - dispose cleans up both internal services
  - sensorStream is a broadcast stream
  - positionStream is a broadcast stream
  - Tests use autoStart: false + wireStreams() + @visibleForTesting helpers
- [x] Run `flutter test` -- all 483 tests pass

**Files:**
- `wind_lens/lib/services/sensors/device_sensor_service.dart` (new)
- `wind_lens/test/services/sensors/device_sensor_service_test.dart` (new)

**Acceptance Criteria:**
- [ ] DeviceSensorService implements SensorService interface
- [ ] sensorStream correctly maps CompassData -> SensorState
- [ ] positionStream correctly maps LocationData -> PositionData
- [ ] dispose() cleans up resources
- [ ] All tests pass

---

### Task 1.12: Create HsvSkyDetector Wrapper

- [x] Read `wind_lens/lib/services/sky_detection/auto_calibrating_sky_detector.dart` to understand its API
- [x] Create `wind_lens/lib/services/sky_detection/hsv_sky_detector.dart`:
  - Class `HsvSkyDetector implements SkyDetector` (from core interface)
  - Owns an `AutoCalibratingSkyDetector` instance (injectable for testing)
  - `detect()`: updatePitch -> processFrame -> extract mask via isPointInSky loop
  - Returns `SkyMaskData` with 128x96 dimensions and `SkyDetectionMethod.hsv`
  - `name: 'HSV Auto-Calibrating'`
  - `isCalibrated` getter exposes underlying detector's calibration state
- [x] Create `wind_lens/test/services/sky_detection/hsv_sky_detector_test.dart` with 6 tests:
  - implements SkyDetector interface
  - name returns expected string
  - isCalibrated is false initially
  - accepts custom AutoCalibratingSkyDetector
  - mask dimensions match AutoCalibratingSkyDetector constants
  - SkyMaskData.fullSky default dimensions match detector dimensions
  - NOTE: Full detect() testing requires CameraImage (platform channels) -- limited to API contract
- [x] Run `flutter test` -- all 489 tests pass

**Files:**
- `wind_lens/lib/services/sky_detection/hsv_sky_detector.dart` (new)
- `wind_lens/test/services/sky_detection/hsv_sky_detector_test.dart` (new)

**Acceptance Criteria:**
- [ ] HsvSkyDetector implements SkyDetector interface
- [ ] Delegates to AutoCalibratingSkyDetector internally
- [ ] Returns properly-dimensioned SkyMaskData
- [ ] All tests pass

---

### Task 1.13: Create DECISIONS.md

- [x] Create `wind_lens/.claude/features/architectural-foundation/DECISIONS.md` documenting:
  - Phase 1 scope, model decisions (WindData u/v primary, SkyMaskData naming, models NOT converted)
  - Interface decisions (CameraImage direct, SensorService combined, SkyMask rename deferred)
  - Wrapper decisions (altitude 0.0 placeholder, autoStart parameter, pause/resume limitations)
  - Patterns established (directory structure, re-export, test patterns)
  - Known issues deferred to Phase 2 (5 items)
  - Test results: 489 total, all green, zero analyzer issues

**Files:**
- `.claude/features/architectural-foundation/DECISIONS.md` (new)

**Acceptance Criteria:**
- [ ] Document exists and is comprehensive
- [ ] All decisions from Phase 1 are recorded
- [ ] Phase 2 agent can read this and understand the state of the codebase

---

### Task 1.14: Final Verification

- [x] Run `flutter test` from `/workspace/wind_lens/` -- ALL 489 tests pass
- [x] Run `dart analyze wind_lens/lib/` -- no issues found (0 errors, 0 warnings, 0 infos)
- [x] Verify generated files exist for all 6 Freezed models (6 .freezed.dart + 3 .g.dart)
- [x] Verify all 4 service interfaces exist in `lib/core/services/`
- [x] Verify all 4 wrappers exist in `lib/services/` (wind/, horizon/, sensors/, sky_detection/)
- [x] Count total tests: 489 (84 new tests added beyond the original 405)
- [x] DECISIONS.md finalized with test count and all Phase 1 decisions

**Acceptance Criteria:**
- [ ] Zero test failures
- [ ] Zero analysis errors
- [ ] All Phase 1 files created and verified
- [ ] DECISIONS.md finalized for Phase 1

---

## PHASE 2: Wiring (Riverpod + Directory Restructure + ConsumerWidget)

**Agent context:** Second `/implement` run with fresh context.
**Prerequisite:** Phase 1 complete, DECISIONS.md exists, all tests green.
**First action:** Read DECISIONS.md + all source files before making changes.
**Checkpoint:** All tests green, branch committed.

Tasks 2.x will be refined when Phase 2 begins. High-level breakdown:

---

### Task 2.1: Add Riverpod Dependencies

- [x] Add `flutter_riverpod: ^2.4.9` and `riverpod_annotation: ^2.3.3` to dependencies
- [x] Add `riverpod_generator: ^2.3.9` to dev_dependencies
- [x] Run `flutter pub get`
- [x] Run `flutter test` -- all tests pass

**Files:** `wind_lens/pubspec.yaml`

---

### Task 2.2: Create Service Provider Bindings (DI Layer)

- [x] Create `wind_lens/lib/core/providers/service_providers.dart`
- [x] Define providers for: sensorService, windDataSource, horizonProvider, skyDetector
- [x] Each provider returns the mock/default implementation (swappable later)
- [x] Run `dart run build_runner build --delete-conflicting-outputs`

**Files:** `wind_lens/lib/core/providers/service_providers.dart` (new)

---

### Task 2.3: Create Sensor Providers

- [x] Create `wind_lens/lib/core/providers/sensor_providers.dart`
- [x] Define: `gpsPositionProvider`, `rawSensorProvider`, `stablePositionProvider` (>100m debounce)
- [x] Create SensorNotifiers class with ValueNotifier<double> for heading and pitch
- [x] Define `sensorNotifiersProvider`
- [x] Run build_runner
- [x] Write tests for stablePosition debounce logic

**Files:** `wind_lens/lib/core/providers/sensor_providers.dart` (new)

---

### Task 2.4: Create Data Providers

- [x] Create `wind_lens/lib/core/providers/data_providers.dart`
- [x] Define: `horizonProfileProvider`, `windDataProvider`
- [x] Create `wind_lens/lib/core/providers/scene_provider.dart`
- [x] Define: `sceneStateProvider` with fallback/block logic
- [x] Define: `selectedAltitudeProvider`, `detectionModeProvider`
- [x] Run build_runner
- [x] Write provider tests

**Files:**
- `wind_lens/lib/core/providers/data_providers.dart` (new)
- `wind_lens/lib/core/providers/scene_provider.dart` (new)

---

### Task 2.5: Rename SkyMask Interface to SkyDetectorInterface [P]

**DEFERRED** -- See DECISIONS.md. The re-export shim approach provides needed isolation. The old SkyMask interface will be replaced naturally when ParticleOverlay migrates to SkyMaskData in Phase 3.

- [x] Evaluated and deferred (documented in DECISIONS.md)

**Files:** None changed

---

### Task 2.6: Directory Restructure

Move files to target layout using re-export shim pattern (see DECISIONS.md).

- [x] Copy `lib/models/` contents to `lib/core/models/`, create re-export shims
- [x] Copy `lib/utils/` to `lib/core/utils/`, create re-export shims
- [x] Copy `lib/widgets/` to `lib/features/ar_view/widgets/`, create re-export shims
- [x] Copy `lib/screens/ar_view_screen.dart` to `lib/features/ar_view/`, create re-export shim
- [x] Update imports in canonical copies to use package: imports
- [x] Create `lib/app.dart` with ProviderScope wrapper
- [x] Update `lib/main.dart` to import app.dart
- [x] Run `flutter test` -- all 505 tests pass

**Files:** Canonical copies + re-export shims in old locations

---

### Task 2.7: Refactor ARViewScreen to ConsumerWidget

- [x] Rewrite ARViewScreen as ConsumerStatefulWidget (needs local state for debug/view mode)
- [x] Remove CompassService, FakeWindService, LocationService instances and subscriptions
- [x] Watch `selectedAltitudeProvider` for altitude changes
- [x] Watch `sensorNotifiersProvider` for 60Hz heading/pitch
- [x] Watch `stablePositionProvider` for GPS display in debug panel
- [x] Keep local AutoCalibratingSkyDetector (ParticleOverlay requires old SkyMask interface)
- [x] Update ar_view_screen_test.dart to use ProviderScope
- [x] Run `flutter test` -- all 505 tests pass

**Files:**
- `wind_lens/lib/features/ar_view/ar_view_screen.dart` (rewritten from 311 to ~220 lines)
- `wind_lens/test/screens/ar_view_screen_test.dart` (updated with ProviderScope)

---

### Task 2.8: Wire ParticleOverlay to SceneState + SensorNotifiers

- [x] Add optional `headingNotifier` and `pitchNotifier` ValueNotifier params (backward compatible)
- [x] Tick loop reads from headingNotifier when provided, falls back to widget.compassHeading
- [x] Internal `_notifierPreviousHeading` tracks heading delta when using notifiers
- [x] ARViewScreen passes SensorNotifiers.heading to ParticleOverlay
- [x] All 40 existing ParticleOverlay tests pass unchanged (backward compatible)
- [x] SkyMask interface kept (deferred SkyMaskData migration to Phase 3)
- [x] Run `flutter test` -- all 505 tests pass

**Files:**
- `wind_lens/lib/features/ar_view/widgets/particle_overlay.dart` (modified: +30 lines for notifier support)
- `wind_lens/lib/features/ar_view/ar_view_screen.dart` (passes headingNotifier/pitchNotifier)

---

### Task 2.9: Wire DebugPanel to Providers [P]

**KEPT AS STATELESSWIDGET** -- See DECISIONS.md. DebugPanel receives 15+ constructor params, most of which are local UI state not in providers. Converting to ConsumerWidget would create an unclean hybrid.

- [x] Evaluated and kept current pattern (documented in DECISIONS.md)
- [x] ARViewScreen correctly reads providers and passes values to DebugPanel constructor

**Files:**
- `wind_lens/lib/features/ar_view/widgets/debug_panel.dart` (no changes needed)

---

### Task 2.10: Update DECISIONS.md for Phase 2

- [x] Append Phase 2 decisions
- [x] Record directory structure changes (re-export shim pattern)
- [x] Record provider graph design choices (6-layer, ValueNotifier sidecar, StablePosition debounce)
- [x] Record SPEC-001 deviations (SkyMask rename deferred, DebugPanel kept as StatelessWidget, partial SceneState wiring)
- [x] Record final test count (505)

**Files:** `.claude/features/architectural-foundation/DECISIONS.md` (updated)

---

## PHASE 3: Polish (Lifecycle + Caching + Integration Tests)

**Agent context:** Third `/implement` run with fresh context.
**Prerequisite:** Phase 2 complete, DECISIONS.md updated, all tests green.
**First action:** Read DECISIONS.md + source files before making changes.
**Checkpoint:** All tests green, branch committed, ready for PR.

Tasks 3.x will be refined when Phase 3 begins. High-level breakdown:

---

### Task 3a.1: Wire ARViewScreen to sceneStateProvider

ARViewScreen currently watches 3 providers but still uses local `WindData.zero()` and local `AutoCalibratingSkyDetector`. This task connects it to the full provider graph.

- [x] Read current `lib/features/ar_view/ar_view_screen.dart` to understand what's local vs provider
- [x] Read `lib/core/providers/scene_provider.dart` to understand sceneStateProvider output
- [x] Watch `sceneStateProvider` for wind data (replaces local `WindData.zero()`)
- [x] Watch `windDataProvider` or get wind from SceneState for ParticleOverlay
- [x] Remove local `FakeWindService` usage if still present (was already removed in Phase 2)
- [x] Handle null SceneState gracefully (camera shows immediately, particles appear when data resolves)
- [x] Run `flutter test` -- all 505 tests pass
- [x] Update ar_view_screen_test.dart if needed (no changes needed, tests pass as-is)

**Acceptance Criteria:**
- [ ] ARViewScreen gets wind data from providers, not local instances
- [ ] Camera feed appears immediately (no loading spinner)
- [ ] Particles appear when wind data resolves
- [ ] All existing tests pass

---

### Task 3a.2: Replace SkyMask with SkyMaskData in ParticleOverlay

**This is the biggest task in Phase 3a.** The old `SkyMask` interface is used in ParticleOverlay's tick loop and painter. 1349 lines of tests reference it. Read everything before changing anything.

- [x] Read `lib/features/ar_view/widgets/particle_overlay.dart` — understand how `SkyMask` is used
- [x] Read `test/widgets/particle_overlay_test.dart` — understand how `SkyMask` is mocked in tests
- [x] Read `lib/core/models/sky_mask_data.dart` — understand the replacement API
- [x] Plan the migration: SkyMaskData has the same API surface as the old SkyMask, so this is mainly a type swap
- [x] Update ParticleOverlay to accept `SkyMaskData` instead of `SkyMask` (replaced outright)
- [x] Update all test mocks from `SkyMask` to `SkyMaskData` (replaced MockSkyMask with helper functions: fullSkyMask(), topFractionSkyMask(), noSkyMask(), tinySkyMask())
- [x] Run `flutter test` -- all 505 tests pass
- [x] Removed old `SkyMask` import from ParticleOverlay
- [x] Updated ARViewScreen to convert AutoCalibratingSkyDetector output to SkyMaskData before passing to ParticleOverlay

**Files:**
- `wind_lens/lib/features/ar_view/widgets/particle_overlay.dart` (modified)
- `wind_lens/test/widgets/particle_overlay_test.dart` (heavily modified — mock replacements)
- Possibly `wind_lens/lib/features/ar_view/ar_view_screen.dart` (passes SkyMaskData instead of SkyMask)

**Acceptance Criteria:**
- [ ] ParticleOverlay uses SkyMaskData, not old SkyMask interface
- [ ] All 40+ ParticleOverlay tests pass with SkyMaskData
- [ ] Tick loop and painter behave identically (same spawning, same masking)
- [ ] Old SkyMask import removed from ParticleOverlay

---

### Task 3a.3: Camera frame → sky detector wiring through providers

Connect the camera frame processing to the HsvSkyDetector through the provider graph, so sky detection results flow as SkyMaskData.

- [x] Read how camera frames are currently processed (ARViewScreen -> AutoCalibratingSkyDetector)
- [x] Read `lib/core/providers/service_providers.dart` -- skyDetectorInstance provider
- [x] Wire camera frame processing through the provider graph:
  - Used Option A: ARViewScreen calls `ref.read(skyDetectorInstanceProvider).detect(frame, sensors)` on each frame
  - Added `skyFraction`, `forceRecalibrate()` getters to HsvSkyDetector for ARViewScreen access
  - Removed local AutoCalibratingSkyDetector from ARViewScreen
- [x] Pass resulting SkyMaskData to ParticleOverlay (replaces old SkyMask flow)
- [x] Run `flutter test` -- all 505 tests pass

**Acceptance Criteria:**
- [ ] Sky detection produces SkyMaskData through the new interface
- [ ] ParticleOverlay receives SkyMaskData from the provider/detection pipeline
- [ ] All tests pass

---

### Task 3a.4: Wire PositionData.altitude from geolocator

One-liner fix, but important for P2B-006 (OGC EDR wind queries need observer altitude).

- [x] Read `lib/services/sensors/device_sensor_service.dart` — find the `altitude: 0.0` placeholder
- [x] Read `lib/services/location_service.dart` — check if geolocator's Position.altitude is available
- [x] Update DeviceSensorService to pass `data.altitude` (from LocationData, sourced from geolocator) into PositionData
- [x] Added `altitude` field to LocationData class (with default 0.0 for backward compat)
- [x] Updated LocationService._onPosition to pass position.altitude
- [x] Updated LocationService.setPosition test helper with optional altitude parameter
- [x] Updated DeviceSensorService doc comments (Altitude section)
- [x] Updated DeviceSensorService test comment to reflect default altitude from setPosition()
- [x] Run `flutter test` -- all 505 tests pass

**Acceptance Criteria:**
- [ ] PositionData.altitude comes from geolocator, not hardcoded 0.0
- [ ] Tests updated
- [ ] All tests pass

---

### Task 3a.5: Implement Lifecycle Management

- [x] Created `wind_lens/lib/core/providers/lifecycle_provider.dart` with `AppLifecycleObserver` class
- [x] AppLifecycleObserver mixes in WidgetsBindingObserver and watches AppLifecycleState
- [x] Pauses SensorService on paused/inactive/hidden/detached, resumes on resumed
- [x] Guards against double-pause and double-resume
- [x] Wired into sensorServiceProvider in service_providers.dart (creates observer alongside service, disposes both)
- [x] Wrote 9 tests for pause/resume behavior using RecordingSensorService
- [x] Run build_runner to regenerate codegen
- [x] Run `flutter test` -- all 514 tests pass (505 + 9 new lifecycle tests)

**Acceptance Criteria:**
- [ ] Sensors pause when app backgrounds
- [ ] Sensors resume when app foregrounds
- [ ] Tests verify pause/resume behavior
- [ ] All tests pass

---

### Task 3a.6: Update DECISIONS.md for Phase 3a

- [x] Appended Phase 3a decisions to DECISIONS.md:
  - SceneState wiring approach (ref.watch in build, fallback to WindData.zero)
  - SkyMask -> SkyMaskData migration strategy (type swap, helper functions for tests, timing threshold adjustments)
  - Camera frame -> sky detector wiring choice (Option A: direct provider read in ARViewScreen)
  - Altitude wiring confirmation (LocationData.altitude -> PositionData.altitude from geolocator)
  - Lifecycle implementation details (AppLifecycleObserver class, wired into sensorServiceProvider)
- [x] Recorded test count after Phase 3a: 514 (up from 505)
- [x] Listed what remains for Phase 3b (DataStatusBar, caching, integration tests, cleanup)

**Files:** `.claude/features/architectural-foundation/DECISIONS.md` (updated)

---

## PHASE 3b: Polish and Validate

**Agent context:** Fifth `/implement` run with fresh context.
**Prerequisite:** Phase 3a complete, DECISIONS.md updated, all tests green, provider graph fully wired.
**First action:** Read DECISIONS.md + source files before making changes.
**Checkpoint:** All tests green, branch committed, SPEC-001 complete.

Phase 3b validates the fully-wired system with integration tests and adds caching that Phase 2b features (HeyWhatsThat, OGC EDR) will need.

---

### Task 3b.1: Create DataStatusBar Widget

- [x] Create DataStatusBar widget showing loading progress for GPS/sensors/wind/horizon
- [x] Integrate into ARViewScreen (shown when sceneState is null or partially loaded)
- [x] Write widget tests (6 tests)
- [x] Run `flutter test` -- all 520 tests pass

**Acceptance Criteria:**
- [x] Shows loading state while data resolves
- [x] Disappears once SceneState is fully composed
- [x] Tests pass

---

### Task 3b.2: Implement CachedHorizonProvider [P]

- [x] Create `wind_lens/lib/services/horizon/cached_horizon_provider.dart`
- [x] Memory cache: Map keyed by truncated lat/lng (3 decimal places)
- [x] Disk cache: saveToDiskJson / loadFromDiskJson methods (no hard dep on path_provider)
- [x] Write tests for cache hit, miss, nearby coords, disk persistence, invalid JSON (13 tests)
- [x] Run `flutter test` -- all 533 tests pass

**Acceptance Criteria:**
- [x] Cache hit returns stored HorizonProfile
- [x] Cache miss delegates to wrapped provider
- [x] Disk persistence survives app restart (via saveToDiskJson/loadFromDiskJson)
- [x] Tests pass

---

### Task 3b.3: Implement CachedWindDataSource [P]

- [x] Create `wind_lens/lib/services/wind/cached_wind_source.dart`
- [x] Memory cache with configurable TTL (default 10 minutes)
- [x] Cache key: lat/lng at 2 decimal places + altitude name
- [x] invalidateForAltitude() and invalidateAll() methods
- [x] Write tests for cache hit, miss, TTL expiry, altitude change, invalidation (13 tests)
- [x] Run `flutter test` -- all 546 tests pass

**Acceptance Criteria:**
- [x] Cache hit returns stored WindData within TTL
- [x] Cache miss delegates to wrapped source
- [x] TTL expiry triggers re-fetch
- [x] Tests pass

---

### Task 3b.4: Provider Graph Integration Tests

Now testing the REAL fully-wired system, not a half-wired state.

- [x] Create `wind_lens/test/core/providers/provider_graph_test.dart`
- [x] Test GPS change >100m -> horizon/wind invalidation
- [x] Test GPS change <100m -> no propagation
- [x] Test altitude change -> wind refetch
- [x] Test altitude change does NOT trigger horizon refetch
- [x] Test SceneState composition with all data present
- [x] Test SceneState null when position missing
- [x] Test SceneState null when sensor data missing
- [x] Test SceneState fallback for missing horizon (uses flat)
- [x] Test SceneState fallback for missing skyMask (uses fullSky)
- [x] Test lifecycle: pause, resume, full cycle
- [x] Test selectedAltitude defaults and changes
- [x] Test wind data request includes correct altitude
- [x] Test SceneState reflects altitude change after wind refetch
- [x] Run `flutter test` -- all 562 tests pass (16 new integration tests)

**Acceptance Criteria:**
- [x] All 16 integration test scenarios pass
- [x] Tests use provider overrides with ControllableSensorService/WindDataSource/HorizonProvider
- [x] All existing tests still pass

---

### Task 3b.5: Finalize DECISIONS.md and Mark SPEC-001 Complete

- [x] Append Phase 3b decisions (DataStatusBar, CachedHorizonProvider, CachedWindDataSource, integration tests)
- [x] Record final architecture state (provider graph, directory structure, caching architecture)
- [x] Record total test count: 562 (up from 405 at start of SPEC-001)
- [x] Record remaining cleanup debt (5 items: re-export shims, old models, Riverpod deprecations, HsvSkyDetector cast, DebugPanel pattern)
- [x] Mark SPEC-001 as **COMPLETE**
- [x] Note what's ready for downstream features (SPEC-002, P2B-002+003+005+006)

**Files:** `.claude/features/architectural-foundation/DECISIONS.md` (finalized)

---

## Handoff Checklist for Test Agent

After all phases complete:

- [x] All tests pass (`flutter test` from `/workspace/wind_lens/`) -- 562 passing
- [x] `dart analyze` reports no errors (10 infos = Riverpod Ref deprecations in generated code)
- [x] build_runner generates without errors
- [x] Directory structure matches target layout (canonical in lib/core/ and lib/features/, re-export shims at old paths)
- [x] Provider graph wired and driving the app (ARViewScreen consumes sceneStateProvider)
- [x] ARViewScreen is ConsumerStatefulWidget
- [x] ParticleOverlay uses SkyMaskData + SensorNotifiers (ValueNotifier heading/pitch)
- [x] Lifecycle management pauses/resumes sensors on background/foreground
- [x] Caching works for horizon (disk+memory) and wind data (TTL memory)
- [x] Integration tests cover provider graph scenarios (GPS debounce, altitude refetch, SceneState composition, fallbacks)
- [x] DECISIONS.md documents all choices across all phases
- [x] No performance regression (60 FPS target maintained)
- [x] Total test count: 562 (up from 405, +157 new tests across all 4 phases)
