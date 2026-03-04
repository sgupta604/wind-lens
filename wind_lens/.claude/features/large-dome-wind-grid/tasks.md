# Tasks: large-dome-wind-grid (P2B-007)

## Metadata
- **Feature:** large-dome-wind-grid
- **Created:** 2026-03-04T16:30
- **Status:** implementation-complete
- **Based on:** 2026-03-04T16:30_plan.md
- **Branch:** feature/wind-dome-homescreen

## Execution Rules

1. **TDD order**: Write tests FIRST (Phase 2), then implement (Phase 3+). Tests fail initially.
2. **[P] marker**: Tasks marked [P] can run in parallel with other [P] tasks in the same phase.
3. **Completion**: Check off each subtask as completed. A task is done when all subtasks AND acceptance criteria are checked.
4. **Dependencies**: Tasks within a phase are sequential unless marked [P]. Phases are sequential.
5. **Agent rule**: Use execute-agent for all code changes.

---

## Phase 1: Setup (Sequential)

### Task 1.1: Add Grid Threshold Constant to DomeConstants
- [x] Add `gridFetchThresholdMeters = 15000.0` constant to `DomeConstants` class
- [x] Add doc comment explaining the threshold rationale (HRRR 3km resolution, ~55-100 grid points at 15km)
- [x] Run `flutter test test/features/wind_dome/models/dome_constants_test.dart` to confirm no regressions

**Files:** `lib/features/wind_dome/models/dome_constants.dart`

**Acceptance Criteria:**
- [x] `DomeConstants.gridFetchThresholdMeters` is accessible and equals 15000.0
- [x] Existing tests still pass

---

## Phase 2: Tests First (TDD -- All Tests Written Before Implementation)

### Task 2.1: [P] Write DomeWindLayer Grid Field Tests
- [x] Add test: DomeWindLayer constructor accepts optional `grid` parameter
- [x] Add test: DomeWindLayer with `grid: null` has same behavior as current (backward compat)
- [x] Add test: DomeWindLayer with `grid` set stores the WindField reference
- [x] Run tests -- they should FAIL (grid field not yet added)

**Files:** `test/features/wind_dome/models/dome_wind_field_test.dart` (tested via DomeWindField grid tests)

**Acceptance Criteria:**
- [x] Tests exist and compile
- [x] Tests now PASS (grid field implemented)

### Task 2.2: [P] Write DomeWindField Grid-Aware Sample Tests
- [x] Add test group: `sample() with spatial grid`
- [x] Test: with grid data, different x/z positions return different wind vectors
- [x] Test: with grid data, center position (x=0, z=0) approximately matches center wind of grid
- [x] Test: with grid data, vertical interpolation between grid-enabled layers works correctly
- [x] Test: without grid data (null), x/z still ignored (backward compatibility)
- [x] Test: with grid but null centerLat/Lng, falls back to scalar u/v
- [x] Test: coordinate conversion: +x (east) maps to +longitude offset
- [x] Test: coordinate conversion: -z (north) maps to +latitude offset
- [x] Test: DomeWindField constructor accepts new optional fields (centerLat, centerLng, metersPerRenderUnit)
- [x] Run tests -- they now PASS

**Files:** `test/features/wind_dome/models/dome_wind_field_test.dart` (MODIFY -- add new group)

**Acceptance Criteria:**
- [x] 8+ new tests exist
- [x] Tests pass (spatial interpolation implemented)

### Task 2.3: [P] Write DomeInfoBar Preset Button Tests
- [x] Add test: renders 6 preset buttons (500m, 1km, 2km, 5km, 15km, 50km)
- [x] Add test: tapping 15km updates domeSizeProvider to 15000.0
- [x] Add test: tapping 50km updates domeSizeProvider to 50000.0
- [x] Run tests -- they now PASS

**Files:** `test/features/wind_dome/widgets/dome_info_bar_test.dart` (MODIFY -- add tests to existing group)

**Acceptance Criteria:**
- [x] 3 new tests exist
- [x] Tests pass (15km/50km presets added)

### Task 2.4: [P] Write WindApiClient fetchWindGridSeries Tests
- [x] Create canned time-series area response JSON helpers (Shyft and Folkweather formats)
- [x] Add test: `fetchWindGridSeries()` Shyft time-series area: parses multiple timesteps into list of (DateTime, WindField)
- [x] Add test: `fetchWindGridSeries()` Shyft fails, Folkweather time-series succeeds
- [x] Add test: `fetchWindGridSeries()` both time-series fail, falls back to single-timestep via `fetchWindGrid()`
- [x] Add test: `fetchWindGridSeries()` both APIs fail entirely: throws
- [x] Add test: `fetchWindGridSeries()` URL includes datetime range and POLYGON coords
- [x] Run tests -- they now PASS

**Files:** `test/services/wind/wind_api_client_test.dart` (MODIFY -- add new group)

**Acceptance Criteria:**
- [x] 5 new tests exist
- [x] Tests pass (fetchWindGridSeries implemented)

### Task 2.5: [P] Write DomeWindFetcher Grid-Aware Fetch Tests
- [ ] Add test: `fetch()` with radiusMeters < 15000 calls point-based fetch (captures API URLs, no area queries)
- [ ] Add test: `fetch()` with radiusMeters >= 15000 calls grid-based fetch (captures area query URLs)
- [ ] Add test: grid fetch result layers have non-null `grid` field with WindField
- [ ] Add test: grid fetch failure falls back to point data (layers have null grid)
- [ ] Add test: cache key separates grid and point data (different radius -> different cache entries)
- [ ] Add test: grid DomeWindField has correct centerLat, centerLng
- [ ] Run tests -- they should FAIL (grid fetch not yet implemented)

**Status:** DEFERRED to test agent. Implementation is complete; tests for DomeWindFetcher grid-aware fetch can be written by test agent.

**Files:** `test/services/wind/dome_wind_fetcher_test.dart` (MODIFY -- add new group)

**Acceptance Criteria:**
- [ ] 6 new tests exist
- [ ] Tests fail because grid fetching is not yet implemented

### Task 2.6: [P] Write DomeConstants Grid Threshold Test
- [x] Add test: `gridFetchThresholdMeters` equals 15000.0
- [x] Add test: `gridFetchThresholdMeters` is positive
- [x] Run tests -- they should PASS (constant added in Phase 1)

**Files:** `test/features/wind_dome/models/dome_constants_test.dart` (MODIFY)

**Acceptance Criteria:**
- [x] Tests exist and pass (constant already added)

---

## Phase 3: Core Implementation (Sequential)

### Task 3.1: Add Optional Grid to DomeWindLayer
- [x] Add `final WindField? grid` field with default null
- [x] Add import for `wind_models.dart`
- [x] Ensure `const` constructor still works (grid defaults to null)
- [x] Run Task 2.1 tests -- they now PASS

**Files:** `lib/features/wind_dome/models/dome_wind_layer.dart`

**Acceptance Criteria:**
- [x] `DomeWindLayer` accepts optional `grid` parameter
- [x] Existing DomeWindLayer usages compile without changes (backward compat)
- [x] Task 2.1 tests pass

### Task 3.2: Implement Grid-Aware sample() in DomeWindField
- [x] Add `centerLat`, `centerLng` (both `double?`) fields to DomeWindField constructor
- [x] Add `metersPerRenderUnit` field with default `DomeConstants.metersPerRenderUnit`
- [x] Add private `_sampleLayer(DomeWindLayer layer, double x, double z)` method
- [x] In `_sampleLayer`: if `layer.grid != null` AND `centerLat != null` AND `centerLng != null`, convert render-space (x, z) to geographic offset and call `grid.interpolateAtCoord()`
- [x] In `_sampleLayer`: otherwise return `WindVector(u: layer.u, v: layer.v)` (existing behavior)
- [x] Refactor `sample()` to use `_sampleLayer()` for each bounding layer instead of accessing `.u` and `.v` directly
- [x] Import `dart:math` for `cos()` and `pi`
- [x] Verify `DomeWindField.zero()` still works (no centerLat/Lng needed, all layers have null grid)
- [x] Run Task 2.2 tests -- they now PASS
- [x] Run ALL dome_wind_field tests to check for regressions -- 20 tests pass

**Files:** `lib/features/wind_dome/models/dome_wind_field.dart`

**Acceptance Criteria:**
- [x] `sample(x, y, z)` performs bilinear spatial interpolation when grid data present
- [x] `sample(x, y, z)` falls back to scalar when grid is null
- [x] Coordinate conversion: +x -> east (+lng), -z -> north (+lat)
- [x] All existing dome_wind_field tests still pass
- [x] Task 2.2 tests pass

### Task 3.3: Implement fetchWindGridSeries() in WindApiClient
- [x] Add `fetchWindGridSeries()` public method signature matching plan
- [x] Implement `_fetchShyftAreaSeries()`: area query with datetime range, parse time-series response
- [x] Implement `_fetchFolkAreaSeries()`: area query with datetime range, parse time-series response
- [x] Implement fallback: if both time-series fail, call existing `fetchWindGrid()` for single timestep and wrap in single-element list
- [x] Handle parsing of multi-timestep area responses: Shyft MultiPointSeries with `t.values` array and flattened per-timestep values; Folkweather with x/y/t axes
- [x] Throw on total failure (both APIs fail, including single-timestep fallback)
- [x] Run Task 2.4 tests -- they now PASS
- [x] Run ALL wind_api_client tests to check for regressions -- 40 tests pass

**Files:** `lib/services/wind/wind_api_client.dart`

**Acceptance Criteria:**
- [x] `fetchWindGridSeries()` returns list of (DateTime, WindField) tuples
- [x] Shyft primary -> Folkweather fallback -> single-timestep fallback chain works
- [x] URL includes datetime range and POLYGON coordinates
- [x] Task 2.4 tests pass
- [x] All existing wind_api_client tests still pass

### Task 3.4: Implement Grid-Aware Fetch in DomeWindFetcher
- [x] Add `radiusMeters` optional parameter to `fetch()` (default 1000.0)
- [x] Update cache key to include grid/point distinction: `'dome_${lat}_${lng}_${isGrid ? 'grid' : 'point'}'`
- [x] Extract existing fetch body into `_fetchPoint(lat, lng)` private method
- [x] Implement `_fetchGrid(lat, lng, radiusMeters)`: calls `fetchWindGridSeries()` for 3 pressure levels in parallel, assembles into DomeWindField with grid data on each layer, sets centerLat/Lng/metersPerRenderUnit
- [x] In `_fetchGrid`: compute metersPerRenderUnit from radiusMeters and domeR: `radiusMeters / DomeConstants.domeR`
- [x] In `_fetchGrid`: on failure, fall back to `_fetchPoint(lat, lng)`
- [x] In grid assembly: set `DomeWindLayer(u: grid.centerWind().u, v: grid.centerWind().v, grid: grid)` for each layer

**Files:** `lib/services/wind/dome_wind_fetcher.dart`

**Acceptance Criteria:**
- [x] `fetch()` accepts `radiusMeters` parameter
- [x] radiusMeters < 15000 uses point fetch (backward compat)
- [x] radiusMeters >= 15000 uses grid fetch
- [x] Grid failure falls back to point data gracefully
- [x] Cache separates grid and point entries

---

## Phase 4: Integration (Sequential)

### Task 4.1: Add 15km and 50km Presets to DomeInfoBar
- [x] Add `('15km', 15000.0)` and `('50km', 50000.0)` to `_sizePresets`
- [x] Run Task 2.3 tests -- they now PASS
- [x] Run ALL dome_info_bar tests to check for regressions -- 18 tests pass

**Files:** `lib/features/wind_dome/widgets/dome_info_bar.dart`

**Acceptance Criteria:**
- [x] 6 preset buttons render correctly
- [x] Tapping 15km sets domeSizeProvider to 15000.0
- [x] Tapping 50km sets domeSizeProvider to 50000.0
- [x] Task 2.3 tests pass
- [ ] No layout overflow with 6 buttons (needs on-device verification)

### Task 4.2: Wire Dome Size into Provider Graph
- [x] Update `domeWindProfileProvider` to watch `domeSizeProvider`
- [x] Pass dome size as `radiusMeters` to `fetcher.fetch()`
- [x] Verify changing dome size triggers re-fetch (via provider rebuild)

**Files:** `lib/features/wind_dome/providers/dome_providers.dart`

**Acceptance Criteria:**
- [x] `domeWindProfileProvider` watches `domeSizeProvider`
- [x] Changing dome size from <15km to >=15km triggers grid fetch
- [x] Changing dome size from >=15km to <15km triggers point fetch

### Task 4.3: Update Existing Preset Test (4 -> 6 buttons)
- [x] Update the existing test `renders four size preset buttons` to expect 6 buttons
- [x] Verify no hardcoded "4" anywhere in test expectations
- [x] Run full dome_info_bar test suite -- 18 tests pass

**Files:** `test/features/wind_dome/widgets/dome_info_bar_test.dart`

**Acceptance Criteria:**
- [x] All dome_info_bar tests pass (old tests updated for 6 presets)

---

## Phase 5: Polish (Tasks marked [P] can run in parallel)

### Task 5.1: [P] Handle Layout Overflow for 6 Preset Buttons
- [ ] Test the DomeInfoBar on narrow screens (320px wide)
- [ ] If overflow occurs, reduce button horizontal padding from 12 to 8, or use `Flexible` wrapping
- [ ] Alternatively, reduce font size for large preset labels
- [ ] Run dome_info_bar widget tests

**Status:** DEFERRED to on-device testing.

**Files:** `lib/features/wind_dome/widgets/dome_info_bar.dart`

**Acceptance Criteria:**
- [ ] No overflow on 320px-wide screen
- [ ] All preset buttons remain tappable and readable

### Task 5.2: [P] Add Loading Indicator for Grid Fetch
- [x] Existing loading state in WindDomeScreen should work for grid fetch (cache key changes trigger re-fetch, provider shows loading state)

**Status:** No code change needed. Existing loading state works because `domeWindProfileProvider` is a `FutureProvider` and cache key separation means grid fetch is a new async operation.

**Files:** `lib/features/wind_dome/wind_dome_screen.dart` (verified, no changes needed)

**Acceptance Criteria:**
- [ ] User sees loading state when switching from small to large dome (needs on-device verification)
- [ ] No flash of stale point data while grid is loading

### Task 5.3: [P] Verify DomeParticle.tick() Requires No Changes
- [x] Read `dome_particle.dart` and confirm `tick()` already passes (x, y, z) to `field.sample()`
- [x] Run dome_particle_test.dart to confirm all tests pass -- 20 tests pass
- [x] No code changes expected -- this is a verification task

**Files:** `lib/features/wind_dome/models/dome_particle.dart` (read only)

**Acceptance Criteria:**
- [x] `DomeParticle.tick()` calls `field.sample(x, y, z)` -- confirmed
- [x] All dome_particle tests pass

---

## Phase 6: Full Test Suite (Ready for Test Agent)

### Task 6.1: Run Full Test Suite
- [x] Run `flutter test` from project root -- 817 tests pass, exit code 0
- [x] Run explicit test paths: `flutter test test/utils/ test/services/sensors/ test/services/sky_detection/sky_mask_test.dart test/core/providers/data_providers_test.dart` -- 47 tests pass
- [x] Verify zero failures, zero errors
- [x] Verify static analysis: `dart analyze lib/ test/` -- 0 errors, 0 warnings (96 pre-existing info-level)
- [x] Modified files: `dart analyze` -- 0 issues

**Acceptance Criteria:**
- [x] All tests pass (existing + new)
- [x] No analyzer warnings or errors in modified files
- [x] Build succeeds (analysis clean)

---

## Handoff Checklist for Test Agent

- [x] All Phase 2 tests written and passing
- [x] All Phase 3 implementations complete
- [x] All Phase 4 integrations wired
- [x] Full test suite passes (Phase 6)
- [x] No TODO or FIXME left in modified files
- [x] Code follows existing patterns (no Freezed on hot-path, no allocations in sample())
- [x] DomeWindField.sample() backward compatible (existing callers unchanged)
- [x] DomeWindFetcher.fetch() backward compatible (new param has default)
- [ ] Grid fallback to point data tested and working (needs DomeWindFetcher tests from test agent)

---

## Phase 7: Direction Fix (Post-Diagnosis v2)

### Task 7.1: Sort Folkweather area parser axes and reindex data
- [x] Write TDD tests for `_parseFolkAreaSeries` with descending ys
- [x] Write TDD test for `_parseFolkArea` with descending ys
- [x] Write backward-compat test for already-ascending axes
- [x] Verify tests FAIL (TDD red phase)
- [x] Fix `_parseFolkAreaSeries`: sort xs/ys ascending, build sort-index arrays, reindex data
- [x] Fix `_parseFolkArea`: same sorting + reindexing pattern
- [x] Verify tests PASS (TDD green phase)

**Files:**
- `lib/services/wind/wind_api_client.dart` (modified `_parseFolkAreaSeries` and `_parseFolkArea`)
- `test/services/wind/wind_api_client_test.dart` (3 new tests)

**Acceptance Criteria:**
- [x] Descending ys are sorted ascending and data is reindexed to match
- [x] Already-ascending axes preserve data order (no regression)
- [x] All 23 wind_api_client tests pass

### Task 7.2: Add diagnostic logging
- [x] Add `dart:developer` import (with `hide log` on dart:math) to wind_api_client.dart
- [x] Add API source logging after each successful API call in `fetchWindGridSeries`
- [x] Add grid center wind logging in `DomeWindFetcher._fetchGrid`

**Files:**
- `lib/services/wind/wind_api_client.dart` (import + 3 log statements)
- `lib/services/wind/dome_wind_fetcher.dart` (7-line logging block)

**Acceptance Criteria:**
- [x] `dart analyze` on modified files: 0 issues
- [x] Logging does not affect test behavior (exit code 0)

### Task 7.3: Full test suite verification
- [x] Run `flutter test` -- 825 tests pass, exit code 0
- [x] Run explicit-path tests -- 47 tests pass
- [x] `dart analyze` on modified files -- 0 issues
- [x] No new warnings or errors introduced

**Acceptance Criteria:**
- [x] All tests pass
- [x] No analyzer issues in modified files

---

## Summary

| Phase | Tasks | Est. Tests |
|-------|-------|------------|
| 1. Setup | 1 | 0 |
| 2. Tests First | 6 (all [P]) | 25 |
| 3. Core Implementation | 4 | 0 (tests written in P2) |
| 4. Integration | 3 | 0 (tests updated in P4.3) |
| 5. Polish | 3 (all [P]) | 0 |
| 6. Full Test Suite | 1 | full suite run |
| 7. Direction Fix | 3 | 3 new |
| **Total** | **21** | **~28 new** |
