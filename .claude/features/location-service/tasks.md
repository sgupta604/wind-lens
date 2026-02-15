# Tasks: location-service (P2B-001)

## Metadata
- **Feature:** location-service (P2B-001)
- **Created:** 2026-02-15T20:30
- **Status:** implement-complete
- **Based on:** 2026-02-15T20:30_plan.md
- **Complexity:** Low
- **Estimated new tests:** ~14
- **Actual new tests:** 14

## Execution Rules
- Tasks are numbered by phase (e.g., Task 1.1, 2.1)
- [P] = parallelizable with other [P] tasks in the same phase
- TDD: Phase 2 writes tests first (they fail), Phase 3 makes them pass
- Check off subtasks as completed
- Run `flutter test` after each task to verify no regressions

---

## Phase 1: Setup (Sequential)

### Task 1.1: Add geolocator dependency
- [x] Add `geolocator: ^14.0.2` to `pubspec.yaml` dependencies (after `http:` line)
- [x] Run `flutter pub get` in `wind_lens/` directory
- [x] Verify no dependency conflicts

**Files:** `wind_lens/pubspec.yaml`

**Acceptance Criteria:**
- [x] `flutter pub get` succeeds with zero errors
- [x] `geolocator` appears in `pubspec.yaml` dependencies
- [x] `flutter test` still passes all 391 tests

---

## Phase 2: Tests First (TDD)

### Task 2.1: Write LocationData model tests
- [x] Create `test/models/location_data_test.dart`
- [x] Test: creates with required fields (lat, lon, accuracy, timestamp)
- [x] Test: stores values correctly (all getters match constructor args)
- [x] Test: fields are final (immutable)
- [x] Test: handles edge values (equator 0/0, poles 90/-90, antimeridian 180/-180)

**Files:** `wind_lens/test/models/location_data_test.dart` (CREATE)

**Acceptance Criteria:**
- [x] 4 tests written
- [x] Tests verified after model implementation
- [x] No syntax errors in test file

### Task 2.2: Write LocationService unit tests
- [x] Create `test/services/location_service_test.dart`
- [x] Test: initial latitude is 0
- [x] Test: initial longitude is 0
- [x] Test: initial hasPermission is false
- [x] Test: provides broadcast stream (type check)
- [x] Test: stream allows multiple listeners
- [x] Test: setPosition updates latitude getter
- [x] Test: setPosition updates longitude getter
- [x] Test: setPosition sets hasPermission to true
- [x] Test: setPosition emits LocationData to stream
- [x] Test: dispose closes stream (no events after dispose)

**Files:** `wind_lens/test/services/location_service_test.dart` (CREATE)

**Acceptance Criteria:**
- [x] 10 tests written
- [x] Tests verified after service implementation
- [x] No syntax errors in test file

---

## Phase 3: Core Implementation (Sequential)

### Task 3.1: Create LocationData model
- [x] Create `lib/models/location_data.dart`
- [x] Implement immutable data class with: latitude, longitude, accuracy, timestamp
- [x] Use `const` constructor
- [x] Add doc comments following CompassData pattern
- [x] Run Task 2.1 tests -- all 4 pass

**Files:** `wind_lens/lib/models/location_data.dart` (CREATE)

**Acceptance Criteria:**
- [x] All 4 LocationData tests pass
- [x] All 391 existing tests still pass
- [x] `flutter analyze lib/models/location_data.dart` -- no issues

### Task 3.2: Create LocationService
- [x] Create `lib/services/location_service.dart`
- [x] Import geolocator and location_data
- [x] Implement broadcast StreamController<LocationData>
- [x] Implement `stream` getter
- [x] Implement `latitude`, `longitude`, `hasPermission` getters
- [x] Implement `start()` as `Future<void>`:
  - Check `Geolocator.isLocationServiceEnabled()`
  - Check `Geolocator.checkPermission()` / `requestPermission()`
  - If granted: get initial position via `getCurrentPosition()`, start `getPositionStream()`
  - If denied: set `_hasPermission = false`, log warning, return
- [x] Implement `dispose()`: cancel subscription, close controller
- [x] Implement `@visibleForTesting void setPosition(double lat, double lon)`:
  - Sets `_latitude`, `_longitude`, `_hasPermission = true`
  - Emits LocationData to stream
- [x] Add doc comments following CompassService pattern
- [x] Run Task 2.2 tests -- all 10 pass

**Files:** `wind_lens/lib/services/location_service.dart` (CREATE)

**Acceptance Criteria:**
- [x] All 10 LocationService tests pass
- [x] All 4 LocationData tests pass
- [x] All 391 existing tests still pass
- [x] `flutter analyze lib/services/location_service.dart` -- no issues

---

## Phase 4: Integration (Sequential)

### Task 4.1: Add lat/lon to DebugPanel
- [x] Add `final double? latitude;` parameter to DebugPanel (nullable, no default)
- [x] Add `final double? longitude;` parameter to DebugPanel (nullable, no default)
- [x] Add to constructor with `this.latitude, this.longitude`
- [x] Add GPS row in `_buildDetailsPanel()` after Mode row, before buttons:
  - Only show when both lat and lon are non-null
  - Format: `GPS: xx.xxxx, yy.yyyy` (4 decimal places)
- [x] Verify existing code compiles (all callers must add the new params or use null)
- [x] Run all tests

**Files:** `wind_lens/lib/widgets/debug_panel.dart` (MODIFY)

**Acceptance Criteria:**
- [x] DebugPanel accepts optional latitude/longitude params
- [x] GPS row appears in panel when values are non-null
- [x] GPS row hidden when values are null
- [x] All 391 existing tests still pass
- [x] `flutter analyze lib/widgets/debug_panel.dart` -- no issues

### Task 4.2: Wire LocationService into ARViewScreen
- [x] Import `location_service.dart` and `location_data.dart`
- [x] Add fields: `_locationService`, `_locationSubscription`, `_latitude` (nullable double?), `_longitude` (nullable double?)
- [x] In `initState()` after compass setup:
  - Create `_locationService = LocationService()`
  - Call `_locationService.start()` (fire-and-forget, no await)
  - Subscribe: `_locationSubscription = _locationService.stream.listen(_onLocationUpdate)`
- [x] In `dispose()` before compass disposal:
  - `_locationSubscription?.cancel()`
  - `_locationService.dispose()`
- [x] Add `_onLocationUpdate(LocationData data)` handler:
  - `setState(() { _latitude = data.latitude; _longitude = data.longitude; })`
- [x] Pass `latitude: _latitude` and `longitude: _longitude` to DebugPanel constructor
- [x] Run all tests

**Files:** `wind_lens/lib/screens/ar_view_screen.dart` (MODIFY)

**Acceptance Criteria:**
- [x] LocationService created, started, and disposed correctly
- [x] Stream subscription wired and cancelled on dispose
- [x] Lat/lon passed to DebugPanel
- [x] All 391 existing tests still pass
- [x] All 14 new tests pass (total: 405)
- [x] `flutter analyze lib/screens/ar_view_screen.dart` -- no issues

---

## Phase 5: Polish (Sequential)

### Task 5.1: Run full test suite and static analysis
- [x] Run `flutter test` -- all tests pass (405 total)
- [x] Run `flutter analyze lib/` -- no issues
- [x] Run `flutter analyze test/` -- 66 pre-existing info/warning issues (none from new code)
- [x] Verify total test count: 391 (existing) + 14 (new) = 405

**Acceptance Criteria:**
- [x] Zero test failures
- [x] Zero analyzer issues in lib/ and new test files
- [x] Test count documented: 405

---

## Phase 6: Ready for Test Agent

### Handoff Checklist
- [x] All new unit tests pass (LocationData: 4, LocationService: 10)
- [x] All 391 existing tests still pass
- [x] Static analysis clean (`flutter analyze lib/` -- no issues)
- [x] New files created:
  - `lib/models/location_data.dart`
  - `lib/services/location_service.dart`
  - `test/models/location_data_test.dart`
  - `test/services/location_service_test.dart`
- [x] Modified files:
  - `pubspec.yaml` (added geolocator)
  - `lib/widgets/debug_panel.dart` (added lat/lon params + GPS row)
  - `lib/screens/ar_view_screen.dart` (wired LocationService)
- [x] No platform file changes needed (permissions already configured)
- [x] Feature ready for device testing (GPS requires real device)
