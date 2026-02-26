# Tasks: real-wind-data (P2B-006)

## Metadata
- **Feature:** real-wind-data (P2B-006)
- **Created:** 2026-02-26T12:00
- **Status:** implement-complete
- **Based on:** 2026-02-26T12:00_plan.md
- **Complexity:** Medium
- **Estimated new tests:** ~38

## Execution Rules
- Tasks are numbered by phase (e.g., Task 1.1, 2.1)
- [P] = parallelizable with other [P] tasks in the same phase
- TDD: Phase 2 writes tests first (they fail), Phase 3 makes them pass
- Check off subtasks as completed
- Run `flutter test` after each task to verify no regressions

---

## Phase 1: Setup (Sequential)

### Task 1.1: Verify http package available
- [x] Confirm `http: ^1.6.0` is already in `wind_lens/pubspec.yaml` (no changes needed)
- [x] Verify `package:http/http.dart` and `package:http/testing.dart` are importable
- [x] Run `flutter test` to confirm 569 auto-discovered tests pass (+ extra paths all pass)

**Files:** (no changes)

**Acceptance Criteria:**
- [x] `http` package confirmed in pubspec.yaml
- [x] `package:http/testing.dart` provides `MockClient` for test use
- [x] All existing tests pass (569 auto-discovered + extra paths)

---

## Phase 2: Tests First (TDD)

### Task 2.1: [P] Write WindVector and WindField tests
- [x] Create `test/services/wind/wind_models_test.dart`
- [x] Test: WindVector.zero has u=0 and v=0
- [x] Test: WindVector.speed computes sqrt(u^2 + v^2)
- [x] Test: WindVector speed for (1, 0) is 1.0
- [x] Test: WindField.getAt returns correct value at (row, col)
- [x] Test: WindField.getAt out of bounds returns WindVector.zero
- [x] Test: WindField.width and height match xs/ys lengths
- [x] Test: WindField.interpolateAtCoord returns interpolated value at grid center
- [x] Test: WindField.interpolateAtCoord clamps at boundaries
- [x] Test: WindField.centerWind returns value at grid center
- [x] Test: WindField with empty grid returns WindVector.zero from interpolation
- [x] Test: WindField.getAt negative index returns WindVector.zero (bonus)
- [x] Test: WindField.isStale returns true for old data (bonus)
- [x] Test: WindField.isStale returns false for fresh data (bonus)

**Files:** `wind_lens/test/services/wind/wind_models_test.dart` (CREATE)

**Acceptance Criteria:**
- [x] 13 tests written (10 planned + 3 bonus)
- [x] Tests compile and pass
- [x] No syntax errors in test file

### Task 2.2: [P] Write WindApiClient tests
- [x] Create `test/services/wind/wind_api_client_test.dart`
- [x] Create helper: `MockHttpClient` using `package:http/testing.dart` `MockClient`
- [x] Create helper: canned Shyft position JSON (CoverageCollection with separate U/V coverages)
- [x] Create helper: canned Folkweather position JSON (single Coverage with UGRD/VGRD)
- [x] Create helper: canned Shyft area JSON (MultiPointSeries with composite axis)
- [x] Create helper: canned Folkweather area JSON (standard x/y axes)
- [x] Test: fetchPointWind Shyft success parses U/V from CoverageCollection
- [x] Test: fetchPointWind Shyft surface uses GFS_height-above-ground_10 collection (no z param)
- [x] Test: fetchPointWind Shyft isobaric 850 uses GFS_isobaric with z=850
- [x] Test: fetchPointWind Shyft isobaric 300 uses GFS_isobaric with z=300
- [x] Test: fetchPointWind Shyft URL includes datetime parameter
- [x] Test: fetchPointWind Shyft fail (500) falls back to Folkweather
- [x] Test: fetchPointWind Folkweather success parses UGRD/VGRD
- [x] Test: fetchPointWind Folkweather 850 routes to hrrr-isobaric
- [x] Test: fetchPointWind Folkweather 300 routes to gfs-isobaric-latest
- [x] Test: fetchPointWind Folkweather surface routes to hrrr-height-agl with z=10
- [x] Test: fetchPointWind both APIs fail returns (0, 0)
- [x] Test: fetchWindGrid Shyft parses MultiPointSeries composite into WindField
- [x] Test: fetchWindGrid Folkweather parses x/y axes into WindField with longitude normalization
- [x] Test: fetchPointWind Shyft malformed JSON (missing coverages key) falls back to Folkweather
- [x] Test: fetchPointWind Folkweather malformed JSON (missing UGRD key) returns (0, 0)

**Files:** `wind_lens/test/services/wind/wind_api_client_test.dart` (CREATE)

**Acceptance Criteria:**
- [x] 15 tests written (covers all planned scenarios)
- [x] Canned JSON responses match real API formats from research doc
- [x] Tests compile and pass

### Task 2.3: [P] Write OgcEdrWindDataSource tests
- [x] Create `test/services/wind/ogc_edr_wind_source_test.dart`
- [x] Create helper: `FakeWindApiClient` that returns configurable (u, v) values
- [x] Test: implements WindDataSource interface
- [x] Test: isSimulated returns false
- [x] Test: getWind with AltitudeLevel.surface passes pressureLevel 0 to client
- [x] Test: getWind with AltitudeLevel.midLevel passes pressureLevel 850 to client
- [x] Test: getWind with AltitudeLevel.jetStream passes pressureLevel 300 to client
- [x] Test: getWind returns WindData with correct u/v from API
- [x] Test: getWind returns WindData with correct altitude level
- [x] Test: getWind returns WindData with recent timestamp
- [x] Test: getWind on API failure returns zero wind (bonus)

**Files:** `wind_lens/test/services/wind/ogc_edr_wind_source_test.dart` (CREATE)

**Acceptance Criteria:**
- [x] 9 tests written (8 planned + 1 bonus)
- [x] Tests use a fake API client (no real HTTP)
- [x] Tests compile and pass

---

## Phase 3: Core Implementation (Sequential)

### Task 3.1: Create WindApiConstants
- [x] Create `lib/services/wind/wind_api_constants.dart`
- [x] Define Shyft constants: baseUrl, apiKey, collections, param names, format
- [x] Define Folkweather constants: baseUrl, collections, param names, format
- [x] Define shared constants: timeout (12s), HRRR pressure levels set
- [x] Private constructor to prevent instantiation
- [x] Run `flutter analyze lib/services/wind/wind_api_constants.dart` -- no issues

**Files:** `wind_lens/lib/services/wind/wind_api_constants.dart` (CREATE)

**Acceptance Criteria:**
- [x] All API constants centralized in one file
- [x] No magic strings in other files
- [x] Static analysis clean

### Task 3.2: Create WindVector and WindField models
- [x] Create `lib/services/wind/wind_models.dart`
- [x] Implement `WindVector`: u, v, const constructor, zero static, speed getter
- [x] Implement `WindField`: xs, ys, us, vs, source, fetchedAt, width, height
- [x] Implement `WindField.getAt(row, col)` with bounds checking
- [x] Implement `WindField.interpolate(normX, normY)` bilinear interpolation
- [x] Implement `WindField.interpolateAtCoord(lng, lat)` geographic coordinates
- [x] Implement `WindField.centerWind()` returns WindVector at grid center
- [x] Implement `WindField.isStale([Duration maxAge])` staleness check
- [x] Add doc comments
- [x] Run Task 2.1 tests -- all 13 pass

**Files:** `wind_lens/lib/services/wind/wind_models.dart` (CREATE)

**Acceptance Criteria:**
- [x] All 13 WindVector/WindField tests pass
- [x] All existing tests still pass
- [x] `flutter analyze lib/services/wind/wind_models.dart` -- no issues
- [x] Classes are plain Dart (NOT Freezed)

### Task 3.3: Create WindApiClient
- [x] Create `lib/services/wind/wind_api_client.dart`
- [x] Constructor accepts optional `http.Client` (creates default if not provided)
- [x] Implement `fetchPointWind(lat, lng, pressureLevel)`:
  - Try Shyft position query first
  - On failure, try Folkweather position query
  - On both fail, return (0.0, 0.0, 'none')
- [x] Implement `_fetchShyftPoint()`:
  - Build URL: collection based on level (surface vs isobaric)
  - Include `datetime=<nearest_hour_utc>` for ALL queries (isobaric AND surface)
  - Include `apikey` param
  - Use `f=CoverageJSON` for position queries
  - Parse CoverageCollection response (U and V in separate coverages)
- [x] Implement `_fetchFolkPoint()`:
  - Build URL: route to correct collection (HRRR for 850/925/1000, GFS for others)
  - Surface uses hrrr-height-agl with z=10
  - Parse single Coverage response (UGRD/VGRD in ranges)
- [x] Implement `fetchWindGrid(lat, lng, radiusKm, pressureLevel)`:
  - Build POLYGON from bbox
  - Try Shyft area query (CoverageJSON_MultiPointSeries format)
  - Fallback to Folkweather area query (CoverageJSON format)
- [x] Implement `_parseShyftPositionResponse()`: iterate coverages for U/V
- [x] Implement `_parseFolkPositionResponse()`: read UGRD/VGRD from ranges
- [x] Implement `_parseShyftMultiPoint()`: composite axis to row-major grid
- [x] Implement `_parseFolkArea()`: x/y axes to grid with longitude normalization
- [x] Implement `_nearestHourUtc()`: round current time to nearest hour
- [x] Implement `_makeBbox()` and `_bboxToPoly()` geometry helpers
- [x] Implement `dispose()`: close http.Client
- [x] Add doc comments
- [x] Run Task 2.2 tests -- all 15 pass

**Files:** `wind_lens/lib/services/wind/wind_api_client.dart` (CREATE)

**Acceptance Criteria:**
- [x] All 15 WindApiClient tests pass
- [x] All 13 WindField/WindVector tests pass
- [x] All existing tests still pass
- [x] `flutter analyze lib/services/wind/wind_api_client.dart` -- no issues
- [x] Shyft is tried first, Folkweather is fallback
- [x] Both-fail returns zeros (no exceptions thrown to callers)
- [x] Malformed JSON from either API triggers fallback / returns zeros (no unhandled exceptions)

### Task 3.4: Create OgcEdrWindDataSource
- [x] Create `lib/services/wind/ogc_edr_wind_source.dart`
- [x] Implement `OgcEdrWindDataSource implements WindDataSource`
- [x] Constructor accepts optional `WindApiClient` (creates default if not provided)
- [x] Implement `isSimulated` returns `false`
- [x] Implement `getWind()`:
  - Map AltitudeLevel to pressure level (surface=0, midLevel=850, jetStream=300)
  - Call `_apiClient.fetchPointWind()`
  - Construct and return `WindData` with u, v, altitude, timestamp
- [x] Implement static `_altitudeToPressure()` mapping
- [x] Add doc comments
- [x] Run Task 2.3 tests -- all 9 pass

**Files:** `wind_lens/lib/services/wind/ogc_edr_wind_source.dart` (CREATE)

**Acceptance Criteria:**
- [x] All 9 OgcEdrWindDataSource tests pass
- [x] All 15 WindApiClient tests pass
- [x] All 13 WindField/WindVector tests pass
- [x] All existing tests still pass
- [x] `flutter analyze lib/services/wind/ogc_edr_wind_source.dart` -- no issues
- [x] Implements `WindDataSource` interface correctly

---

## Phase 4: Integration (Sequential)

### Task 4.1: Wire OgcEdrWindDataSource into service_providers.dart
- [x] Import `ogc_edr_wind_source.dart`, `wind_api_client.dart`, `cached_wind_source.dart`
- [x] Replace `MockWindDataSource()` with CachedWindDataSource wrapping OgcEdrWindDataSource
- [x] Run codegen: `dart run build_runner build --delete-conflicting-outputs`
- [x] Run full test suite -- all 606 tests pass
- [x] Verify no new analyzer issues (only pre-existing Riverpod Ref deprecation warnings)

**Files:** `wind_lens/lib/core/providers/service_providers.dart` (MODIFY)

**Acceptance Criteria:**
- [x] `windDataSourceProvider` returns `CachedWindDataSource` wrapping `OgcEdrWindDataSource`
- [x] `ref.onDispose()` closes the HTTP client
- [x] All existing tests still pass (no tests needed updates)
- [x] `flutter analyze lib/core/providers/service_providers.dart` -- only pre-existing Riverpod deprecation infos
- [x] Codegen completes successfully

### Task 4.2: Write integration tests for provider wiring
- [x] Add integration tests to `test/services/wind/ogc_edr_wind_source_test.dart`
- [x] Test: CachedWindDataSource.isSimulated is false when wrapping OgcEdr
- [x] Test: CachedWindDataSource wrapping OgcEdrWindDataSource caches correctly
- [x] Test: Different altitude level triggers new HTTP call
- [x] Test: Returns WindData with correct values through full chain
- [x] Run full test suite -- all pass

**Files:** `wind_lens/test/services/wind/ogc_edr_wind_source_test.dart` (MODIFY)

**Acceptance Criteria:**
- [x] 4 integration tests pass
- [x] Cache behavior verified with real delegate chain
- [x] All existing tests still pass
- [x] Total new tests: 37 (13 models + 15 API client + 9 data source unit)

---

## Phase 5: Polish (Sequential)

### Task 5.1: Run full test suite and static analysis
- [x] Run `flutter test` -- 610 tests pass (569 existing auto-discovered + 37 new + 4 integration)
- [x] Run `flutter test test/services/wind/` -- all 59 wind tests pass
- [x] Run `flutter analyze lib/services/wind/` -- no issues
- [x] Run `flutter analyze test/services/wind/` -- no issues (fixed 2 unused imports)
- [x] Total test count: 610 auto-discovered (+ extra paths all pass)
- [x] Review all new files for doc comments and code quality

**Acceptance Criteria:**
- [x] Zero test failures
- [x] Zero analyzer issues in new code
- [x] Test count documented: 610 total (37 new)

### Task 5.2: Verify graceful degradation
- [x] Confirm that when both APIs are unreachable, WindData with (0, 0) is returned
- [x] Confirm no exceptions propagate to the provider graph
- [x] Confirm app would render static particles (no crash) on API failure

**Acceptance Criteria:**
- [x] Tests cover both-APIs-fail scenario (3 tests: dual-fail, Shyft-malformed-fallback, Folk-malformed-zeros)
- [x] No uncaught exceptions in the wind data pipeline

---

## Phase 6: Ready for Test Agent

### Handoff Checklist
- [x] All new unit tests pass (WindModels: 13, WindApiClient: 15, OgcEdrWindDataSource: 9, Integration: 4)
- [x] All existing tests still pass (610 total auto-discovered)
- [x] Static analysis clean (`flutter analyze lib/services/wind/` -- no issues)
- [x] New files created:
  - `lib/services/wind/wind_api_constants.dart`
  - `lib/services/wind/wind_models.dart`
  - `lib/services/wind/wind_api_client.dart`
  - `lib/services/wind/ogc_edr_wind_source.dart`
  - `test/services/wind/wind_models_test.dart`
  - `test/services/wind/wind_api_client_test.dart`
  - `test/services/wind/ogc_edr_wind_source_test.dart`
- [x] Modified files:
  - `lib/core/providers/service_providers.dart` (swap MockWindDataSource -> CachedWindDataSource + OgcEdrWindDataSource)
  - `lib/core/providers/service_providers.g.dart` (codegen)
- [x] `implementation.md` created at `.claude/active-work/real-wind-data/implementation.md`
- [x] Feature ready for device testing (requires network connectivity for real API calls)
- [x] Graceful degradation verified (zero wind on API failure, no crashes)
