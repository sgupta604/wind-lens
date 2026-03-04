# Tasks: heywhatsthat-client

## Metadata
- **Feature:** heywhatsthat-client (P2B-002+003)
- **Created:** 2026-03-04T13:00
- **Status:** in-progress
- **Based On:** `2026-03-04T13:00_plan.md`
- **Total Tasks:** 14 across 6 phases
- **Estimated New Tests:** ~18

## Execution Rules

1. Tasks within a phase run sequentially unless marked `[P]` (parallelizable)
2. Each phase must complete before the next begins
3. TDD: Write tests (Phase 2) BEFORE implementation (Phase 3) -- tests fail initially
4. Mark tasks complete with `[x]` when done
5. Run `flutter test` after each task to verify no regressions
6. Run `dart analyze lib/` after implementation tasks to verify 0 errors

---

## Phase 1: Setup (Sequential)

### Task 1.1: Add declination and panoramaId fields to HorizonProfile

- [x] Open `lib/core/models/horizon_profile.dart`
- [x] Add `@Default(0.0) double declination` field to the factory constructor
- [x] Add `String? panoramaId` field to the factory constructor
- [x] Update `HorizonProfile.flat()` factory -- no changes needed (defaults handle it)
- [x] Run `dart run build_runner build --delete-conflicting-outputs` from `wind_lens/`
- [x] Verify generated files updated: `horizon_profile.freezed.dart`, `horizon_profile.g.dart`
- [x] Run `flutter test test/core/models/horizon_profile_test.dart` -- all existing tests should pass

**Files:** `lib/core/models/horizon_profile.dart` (modify), generated `.freezed.dart` and `.g.dart`

**Acceptance Criteria:**
- [x] `HorizonProfile(latitude: 0, longitude: 0, elevationAngles: {}, fetchedAt: DateTime.now())` still works (declination defaults to 0.0, panoramaId defaults to null)
- [x] `HorizonProfile.flat(0, 0)` still works
- [x] `HorizonProfile(..., declination: 15.0, panoramaId: 'ABC123')` works
- [x] All existing horizon_profile_test.dart tests pass
- [x] JSON serialization round-trip includes new fields

### Task 1.2: Create HWT API constants file

- [x] Create `lib/services/horizon/hwt_api_constants.dart`
- [x] Add static const for base URL: `https://www.heywhatsthat.com`
- [x] Add static const for submit path: `/bin/query.cgi`
- [x] Add static const for result path: `/bin/result.json`
- [x] Add static method for poll path: `/results/$id/data`
- [x] Add static consts for query parameters: elev, elev_is_absolute, name, public, return_data
- [x] Add static const for poll interval: `Duration(seconds: 10)`
- [x] Add static const for timeout: `Duration(minutes: 5)`
- [x] Add static const for HTTP timeout: `Duration(seconds: 15)`
- [x] Add private constructor to prevent instantiation

**Files:** `lib/services/horizon/hwt_api_constants.dart` (new)

**Acceptance Criteria:**
- [x] File follows `WindApiConstants` pattern exactly
- [x] All URL/timeout constants match verified API behavior from research
- [x] `dart analyze lib/services/horizon/hwt_api_constants.dart` -- 0 issues

---

## Phase 2: Tests (TDD -- write before implementation)

### Task 2.1: Write HwtHorizonProvider unit tests

- [x] Create `test/services/horizon/hwt_horizon_provider_test.dart`
- [x] Import `package:http/testing.dart` for `MockClient`
- [x] Write test: "submit parses panorama ID from first token"
- [x] Write test: "polls until response starts with ok"
- [x] Write test: "times out after max duration and returns flat"
- [x] Write test: "parses 360 limits entries correctly"
- [x] Write test: "extracts declination from result JSON"
- [x] Write test: "extracts panoramaId from result JSON"
- [x] Write test: "returns flat on HTTP error (submit 500)"
- [x] Write test: "returns flat on HTTP error (result fetch 500)"
- [x] Write test: "returns flat on network exception"
- [x] Write test: "returns flat on empty result body (invalid panorama ID)"
- [x] Write test: "returns flat on poll 404 (invalid panorama ID)"
- [x] All 11 tests pass

**Files:** `test/services/horizon/hwt_horizon_provider_test.dart` (new)

**Acceptance Criteria:**
- [x] 11 test cases written
- [x] Tests use `MockClient` from `http/testing.dart`
- [x] Tests use `Duration.zero` for poll interval (no real delays)
- [x] All 11 tests pass

### Task 2.2: Write HorizonProfile model tests for new fields [P]

- [x] Open `test/core/models/horizon_profile_test.dart`
- [x] Add test: "declination defaults to 0.0"
- [x] Add test: "panoramaId defaults to null"
- [x] Add test: "JSON round-trip preserves declination and panoramaId"
- [x] Add test: "flat() factory has declination 0.0 and panoramaId null"
- [x] Run tests -- all 18 pass

**Files:** `test/core/models/horizon_profile_test.dart` (modify)

**Acceptance Criteria:**
- [x] 4 new tests added
- [x] All tests pass (model fields added in Phase 1)

### Task 2.3: Write HomeTerrainPainter tests [P]

- [x] Open or create `test/features/home/widgets/home_terrain_section_test.dart`
- [x] Write test: "HomeTerrainPainter shouldRepaint returns true when profile changes"
- [x] Write test: "HomeTerrainPainter shouldRepaint returns false when profile is same reference"
- [x] Write test: "HomeTerrainPainter shouldRepaint returns true when null vs non-null"

**Files:** `test/features/home/widgets/home_terrain_section_test.dart` (new or modify)

**Acceptance Criteria:**
- [x] 3 tests written
- [x] Tests verify shouldRepaint behavior for profile changes

---

## Phase 3: Core Implementation (Sequential)

### Task 3.1: Implement HwtHorizonProvider

- [x] Create `lib/services/horizon/hwt_horizon_provider.dart`
- [x] Add imports: `dart:async`, `dart:convert`, `package:http/http.dart`
- [x] Import `HorizonProvider`, `HorizonProfile`, `HwtApiConstants`
- [x] Implement class with constructor accepting optional `http.Client` and `Duration pollInterval`
- [x] Implement `getHorizon()` with try/catch wrapping all 3 steps
- [x] Implement `_submitPanorama()` -- panorama ID from FIRST token
- [x] Implement `_waitForCompletion()` -- polling loop with deadline
- [x] Implement `_fetchProfile()` -- empty body guard, limits parsing, declination extraction
- [x] Implement `dispose()` method
- [x] All 11 tests pass, dart analyze 0 issues

**Files:** `lib/services/horizon/hwt_horizon_provider.dart` (new)

**Acceptance Criteria:**
- [x] All 11 tests from Task 2.1 pass
- [x] `dart analyze lib/services/horizon/hwt_horizon_provider.dart` -- 0 issues
- [x] Panorama ID parsed from FIRST token (not second)
- [x] Empty body guard on result.json
- [x] `HorizonProfile.flat()` returned on any failure
- [x] No unhandled exceptions can escape `getHorizon()`

### Task 3.2: Update HomeTerrainPainter with real data path

- [x] Open `lib/features/home/widgets/home_terrain_section.dart`
- [x] In `HomeTerrainPainter`, update `_buildTerrainPath()` to delegate to profile or procedural
- [x] Implement `_buildProfileTerrainPath(Size, HorizonProfile)` -- elevation-to-Y mapping, 360 lineTo
- [x] Implement `_buildProfileRidgePath(Size, HorizonProfile)` -- ridge-only path from profile
- [x] Rename old methods to `_buildProceduralTerrainPath()` and `_buildProceduralRidgePath()`
- [x] Update `shouldRepaint()` to compare `profile` references
- [x] All 3 HomeTerrainPainter tests pass

**Files:** `lib/features/home/widgets/home_terrain_section.dart` (modify)

**Acceptance Criteria:**
- [x] Procedural bezier path still renders when profile is null
- [x] Real data path renders when profile is non-null
- [x] shouldRepaint triggers on profile change
- [x] Tests from Task 2.3 pass

---

## Phase 4: Integration (Sequential)

### Task 4.1: Wire HwtHorizonProvider into service_providers.dart

- [x] Open `lib/core/providers/service_providers.dart`
- [x] Add imports for `HwtHorizonProvider` and `CachedHorizonProvider`
- [x] Replace `horizonProviderService` body with HWT + cached wrapper
- [x] Replaced `MockHorizonProvider` import with new imports
- [x] Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `.g.dart`
- [x] Run `flutter test` -- all 844 tests pass

**Files:** `lib/core/providers/service_providers.dart` (modify)

**Acceptance Criteria:**
- [x] `horizonProviderServiceProvider` returns `CachedHorizonProvider(delegate: HwtHorizonProvider())`
- [x] `ref.onDispose()` registered for HwtHorizonProvider
- [x] All existing tests pass (MockHorizonProvider still available for test files that use it)
- [x] `dart analyze lib/` -- 0 errors, 0 warnings (info only)

### Task 4.2: Convert HomeTerrainSection to ConsumerStatefulWidget

- [x] Open `lib/features/home/widgets/home_terrain_section.dart`
- [x] Add import for `flutter_riverpod`
- [x] Add import for `horizonProfileProvider` from data_providers
- [x] Change `StatefulWidget` to `ConsumerStatefulWidget`
- [x] Change `State<HomeTerrainSection>` to `ConsumerState<HomeTerrainSection>`
- [x] In `build()`, watch `horizonProfileProvider` and extract profile
- [x] Pass `profile` to `HomeTerrainPainter(profile: profile)`
- [x] Add loading indicator: "Computing terrain..." in DM Mono, #444444, fontSize 10
- [x] Loading indicator shown only during AsyncLoading state
- [x] All 844 tests pass
- [x] `dart analyze lib/` -- 0 errors, 0 warnings (info only)

**Files:** `lib/features/home/widgets/home_terrain_section.dart` (modify)

**Acceptance Criteria:**
- [x] HomeTerrainSection is a ConsumerStatefulWidget
- [x] Watches `horizonProfileProvider` and passes profile to painter
- [x] Loading indicator visible during AsyncLoading state
- [x] Loading indicator hidden when data arrives or on error
- [x] All existing tests pass
- [x] `dart analyze lib/` -- 0 errors, 0 warnings

---

## Phase 5: Polish (Parallelizable)

### Task 5.1: Verify full test suite passes [P]

- [x] Run `flutter test` (full suite) -- 797 tests pass
- [x] Run explicit-path tests -- 47 tests pass
- [x] Total: 844 tests pass (842 baseline + 2 dome tests on branch)
- [x] Run `dart analyze lib/` -- 0 errors, 0 warnings (13 info)
- [x] New tests: 11 HWT provider + 3 terrain painter + 4 model = 18

**Files:** None (verification only)

**Acceptance Criteria:**
- [x] All existing tests pass (844 total)
- [x] All new tests pass (18 new)
- [x] `dart analyze lib/` -- 0 errors, 0 warnings
- [x] No regressions

### Task 5.2: Verify data_providers integration [P]

- [x] Run `flutter test test/core/providers/data_providers_test.dart` -- 3 tests pass
- [x] horizonProfileProvider correctly watches the swapped provider

**Files:** `test/core/providers/data_providers_test.dart` (verify, no changes needed)

**Acceptance Criteria:**
- [x] data_providers tests pass
- [x] horizonProfileProvider correctly delegates to HwtHorizonProvider (via CachedHorizonProvider)

### Task 5.3: Verify cached_horizon_provider tests still pass [P]

- [x] Run `flutter test test/services/horizon/cached_horizon_provider_test.dart` -- 13 tests pass
- [x] JSON serialization round-trip works with new HorizonProfile fields

**Files:** `test/services/horizon/cached_horizon_provider_test.dart` (verify, no changes needed)

**Acceptance Criteria:**
- [x] All 13 cached_horizon_provider tests pass
- [x] JSON round-trip handles declination and panoramaId correctly

---

## Phase 6: Ready for Test Agent

### Task 6.1: Final verification and handoff

- [x] All 844 unit tests passing
- [x] `dart analyze lib/` -- 0 errors, 0 warnings (13 info, pre-existing)
- [x] `dart analyze test/` -- 0 errors, 0 warnings (80 info, pre-existing)
- [ ] Build: No Android/iOS SDK in CI environment; `dart analyze` confirms clean compilation
- [x] Document: total test count, files changed, files created (see implementation.md)

**Files:** None (verification + documentation)

**Acceptance Criteria:**
- [x] `dart analyze` clean (0 errors, 0 warnings)
- [x] All tests pass
- [x] Ready for on-device testing

---

## Handoff Checklist for Test Agent

- [x] All unit tests pass (`flutter test`) -- 844 total
- [ ] Build succeeds (`flutter build`) -- needs device SDK, dart analyze clean
- [x] `dart analyze lib/` -- 0 errors, 0 warnings
- [x] New files created:
  - `lib/services/horizon/hwt_api_constants.dart`
  - `lib/services/horizon/hwt_horizon_provider.dart`
  - `test/services/horizon/hwt_horizon_provider_test.dart`
  - `test/features/home/widgets/home_terrain_section_test.dart`
- [x] Modified files:
  - `lib/core/models/horizon_profile.dart` (2 new fields: declination, panoramaId)
  - `lib/core/models/horizon_profile.freezed.dart` (regenerated)
  - `lib/core/models/horizon_profile.g.dart` (regenerated)
  - `lib/core/providers/service_providers.dart` (swap MockHorizonProvider -> HwtHorizonProvider + CachedHorizonProvider)
  - `lib/core/providers/service_providers.g.dart` (regenerated)
  - `lib/features/home/widgets/home_terrain_section.dart` (ConsumerStatefulWidget + real terrain path + loading indicator)
  - `test/core/models/horizon_profile_test.dart` (4 new tests for declination/panoramaId)
- [ ] On-device testing checklist:
  - [ ] Open app with real GPS -- terrain section should show "Computing terrain..." text
  - [ ] After 5-15 seconds, real terrain silhouette should replace procedural one
  - [ ] Terrain shape should visibly match local geography
  - [ ] Kill and restart app -- terrain re-fetches (no disk cache yet, but memory cache works within session)
  - [ ] Airplane mode -- procedural terrain stays, no crash, no error dialog
  - [ ] Location picker override -- terrain updates when virtual location changes
