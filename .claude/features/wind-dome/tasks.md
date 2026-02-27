# Wind Dome -- Task Breakdown

**Feature:** wind-dome (Phase 1 MVP)
**Timestamp:** 2026-02-27T12:00
**Status:** IMPLEMENTED
**Based-on:** 2026-02-27T12:00_plan.md

---

## Execution Rules

1. Tasks within a phase are **sequential** unless marked **[P]** (parallelizable)
2. TDD order: write tests FIRST (Phase 2), then implementation (Phase 3)
3. Mark completed tasks with `[x]`
4. Each task has acceptance criteria -- all must be checked before moving on
5. Run `flutter test` after each task to ensure no regressions

---

## Phase 1: Setup (Sequential)

### Task 1.1: Add flutter_map and latlong2 dependencies

- [x] Add `flutter_map: ^7.0.0` to `pubspec.yaml` dependencies
- [x] Add `latlong2: ^0.9.1` to `pubspec.yaml` dependencies
- [x] Run `flutter pub get` to verify resolution
- [x] If version conflict, fall back to `flutter_map: ^6.0.0` and `latlong2: ^0.9.0`
- [x] Run `flutter test` to verify no regressions

**Files:** `wind_lens/pubspec.yaml`

**Acceptance Criteria:**
- [x] `flutter pub get` succeeds without errors
- [x] All existing 628+ tests still pass
- [x] `import 'package:flutter_map/flutter_map.dart'` resolves

### Task 1.2: Create directory structure

- [x] Create `lib/features/wind_dome/`
- [x] Create `lib/features/wind_dome/models/`
- [x] Create `lib/features/wind_dome/providers/`
- [x] Create `lib/features/wind_dome/widgets/`
- [x] Create `test/features/wind_dome/models/`
- [x] Create `test/features/wind_dome/providers/`
- [x] Create `test/features/wind_dome/widgets/`

**Files:** Directory creation only

**Acceptance Criteria:**
- [x] All directories exist
- [x] No files created yet (just directories)

---

## Phase 2: Tests (TDD -- Write Tests BEFORE Implementation)

Tests in this phase will FAIL initially. That is expected and correct.

### Task 2.1: [P] Write DomeWindLayer, DomeWindField, DomeWindProfile model tests

- [x] Create `test/features/wind_dome/models/dome_wind_field_test.dart`
- [x] Test: sample() returns exact layer values when y matches a layer altitude
- [x] Test: sample() interpolates u/v linearly between two layers
- [x] Test: sample() at y=0 returns bottom layer
- [x] Test: sample() at y=DOME_H returns top visible layer (clamp)
- [x] Test: sample() interpolates u/v components, NOT speed/direction
- [x] Test: sample() with single layer returns that layer's values
- [x] Test: sample() with layers at different altitudes picks correct pair
- [x] Create `test/features/wind_dome/models/dome_wind_profile_test.dart`
- [x] Test: fieldAt(0) returns first hourly entry
- [x] Test: fieldAt(71) returns last hourly entry (72-hour forecast)
- [x] Test: fieldAt(-1) clamps to 0
- [x] Test: fieldAt(100) clamps to last index
- [x] Test: fieldAt() on single-entry hourly always returns that entry

**Files:**
- `test/features/wind_dome/models/dome_wind_field_test.dart`
- `test/features/wind_dome/models/dome_wind_profile_test.dart`

**Acceptance Criteria:**
- [x] ~12 tests in dome_wind_field_test.dart (all fail -- no implementation yet)
- [x] ~5 tests in dome_wind_profile_test.dart (all fail -- no implementation yet)

### Task 2.2: [P] Write DomeParticle model tests

- [x] Create `test/features/wind_dome/models/dome_particle_test.dart`
- [x] Test: insideDome() returns true for origin (0,0,0)
- [x] Test: insideDome() returns false for point outside dome
- [x] Test: insideDome() returns true for point on surface (boundary)
- [x] Test: insideDome() returns false for y < 0
- [x] Test: respawn() places particle inside dome (verify 100 respawns)
- [x] Test: tick() moves particle position
- [x] Test: tick() with zero wind only applies updraft
- [x] Test: tick() particle stays inside dome after 1000 ticks (or respawns)
- [x] Test: trail ring buffer records positions after tick
- [x] Test: trail ring buffer wraps at TRAIL_LENGTH capacity
- [x] Test: trail count does not exceed TRAIL_LENGTH
- [x] Test: respawn() clears trail

**Files:** `test/features/wind_dome/models/dome_particle_test.dart`

**Acceptance Criteria:**
- [x] ~12 tests (all fail -- no implementation yet)

### Task 2.3: [P] Write WindApiClient.fetchPointWindSeries() tests

- [x] Create `test/services/wind/wind_api_client_series_test.dart`
- [x] Test: Shyft time-series response parses correctly (3 timesteps)
- [x] Test: Folkweather time-series response parses correctly (3 timesteps)
- [x] Test: Shyft failure falls back to Folkweather (time-series)
- [x] Test: Both APIs fail returns empty list
- [x] Test: datetime range parameter format is correct (ISO 8601 range)
- [x] Test: surface collection used when pressureLevel=0
- [x] Test: isobaric collection used when pressureLevel=850
- [x] Test: response with 72 timesteps parses all entries
- [x] Test: mismatched u/v array lengths handled gracefully
- [x] Test: null values in response replaced with 0.0

**Files:** `test/services/wind/wind_api_client_series_test.dart`

**Acceptance Criteria:**
- [x] ~10 tests (all fail -- no implementation yet)

### Task 2.4: [P] Write DomeWindFetcher tests

- [x] Create `test/services/wind/dome_wind_fetcher_test.dart`
- [x] Create FakeDomeWindApiClient that returns canned series data
- [x] Test: fetch() returns DomeWindProfile with 3 layers per field
- [x] Test: fetch() returns 72 hourly fields
- [x] Test: cache hit returns same profile (no re-fetch)
- [x] Test: cache miss after TTL expiry triggers re-fetch
- [x] Test: cache key rounds lat/lng to 2 decimal places
- [x] Test: API failure returns zero-wind profile (graceful degradation)
- [x] Test: 3 pressure levels fetched in parallel
- [x] Test: altitude mapping correct (0->surface, 850->1500m, 700->3000m)
- [x] Test: layers sorted by altitude ascending

**Files:** `test/services/wind/dome_wind_fetcher_test.dart`

**Acceptance Criteria:**
- [x] ~10 tests (all fail -- no implementation yet)

### Task 2.5: [P] Write dome provider tests

- [x] Create `test/features/wind_dome/providers/dome_providers_test.dart`
- [x] Test: hoursAheadProvider defaults to 0
- [x] Test: hoursAheadProvider setter updates state
- [x] Test: currentDomeWindFieldProvider returns null when profile is null
- [x] Test: currentDomeWindFieldProvider selects correct hour from profile
- [x] Test: currentDomeWindFieldProvider updates when hoursAhead changes

**Files:** `test/features/wind_dome/providers/dome_providers_test.dart`

**Acceptance Criteria:**
- [x] ~5 tests (all fail -- no implementation yet)

### Task 2.6: [P] Write widget tests

- [x] Create `test/features/wind_dome/widgets/dome_forecast_slider_test.dart`
- [x] Test: slider renders without crash
- [x] Test: slider label shows "Live" when value is 0
- [x] Test: slider label shows "+12h" when value is 12
- [x] Test: slider onChanged callback fires with correct value
- [x] Create `test/features/wind_dome/widgets/dome_info_bar_test.dart`
- [x] Test: info bar renders without crash
- [x] Test: info bar shows "Live" badge when hoursAhead=0
- [x] Test: info bar shows "Fcst" badge when hoursAhead>0
- [x] Test: info bar shows wind speed from current field
- [x] Create `test/features/wind_dome/widgets/dome_painter_test.dart`
- [x] Test: DomePainter constructs without throwing
- [x] Test: DomePainter.paint() completes without throwing (with empty particle list)
- [x] Test: DomePainter.paint() completes with particles (smoke test)

**Files:**
- `test/features/wind_dome/widgets/dome_forecast_slider_test.dart`
- `test/features/wind_dome/widgets/dome_info_bar_test.dart`
- `test/features/wind_dome/widgets/dome_painter_test.dart`

**Acceptance Criteria:**
- [x] ~4 tests in slider test (all fail)
- [x] ~4 tests in info bar test (all fail)
- [x] ~3 tests in dome painter test (all fail)

---

## Phase 3: Core Implementation (Sequential unless marked [P])

### Task 3.1: Implement dome constants

- [x] Create `lib/features/wind_dome/models/dome_constants.dart`
- [x] Define DOME_R_METERS = 800.0
- [x] Define DOME_H_METERS = 1800.0
- [x] Define DOME_R_RENDER = 18.0
- [x] Define DOME_H_RENDER = DOME_H_METERS / DOME_R_METERS * DOME_R_RENDER (= 40.5)
- [x] Define RENDER_SCALE = DOME_R_RENDER / DOME_R_METERS
- [x] Define SPEED_SCALE = 50.0
- [x] Define TRAIL_LENGTH = 10
- [x] Define PARTICLE_COUNT = 2000
- [x] Define DEFAULT_THETA = pi / 6
- [x] Define DEFAULT_PHI = pi / 2.8
- [x] Define CAM_DIST = DOME_R_RENDER * 2.5

**Files:** `lib/features/wind_dome/models/dome_constants.dart`

**Acceptance Criteria:**
- [x] All constants accessible as `DomeConstants.xxx`
- [x] No Flutter imports needed (pure Dart)

### Task 3.2: [P] Implement DomeWindLayer model

- [x] Create `lib/features/wind_dome/models/dome_wind_layer.dart`
- [x] Implement DomeWindLayer with altitudeMeters, u, v fields
- [x] Constructor is const
- [x] No Freezed dependency

**Files:** `lib/features/wind_dome/models/dome_wind_layer.dart`

**Acceptance Criteria:**
- [x] Plain Dart class, no Flutter imports
- [x] const constructor

### Task 3.3: [P] Implement DomeWindField model

- [x] Create `lib/features/wind_dome/models/dome_wind_field.dart`
- [x] Implement DomeWindField with validTime, layers fields
- [x] Implement sample(x, y, z) method:
  - [x] Normalize y to [0, domeHMeters] using DOME_H_METERS
  - [x] Map normalized altitude to layer index space
  - [x] Find bounding layers (lo, hi)
  - [x] Lerp u and v components (NOT speed/direction)
  - [x] Return WindVector
- [x] Handle edge cases: y <= 0 returns bottom layer, y >= max returns top visible layer
- [x] Import WindVector from wind_models.dart (reuse, do not duplicate)
- [x] Run dome_wind_field_test.dart -- all tests should now pass

**Files:** `lib/features/wind_dome/models/dome_wind_field.dart`

**Acceptance Criteria:**
- [x] All dome_wind_field_test.dart tests pass
- [x] sample() interpolates u/v, not speed/direction
- [x] No object allocation inside sample() (reuse WindVector constructor only)

### Task 3.4: [P] Implement DomeWindProfile model

- [x] Create `lib/features/wind_dome/models/dome_wind_profile.dart`
- [x] Implement DomeWindProfile with hourly, fetchedAt, lat, lng fields
- [x] Implement fieldAt(hoursAhead) with clamping
- [x] Run dome_wind_profile_test.dart -- all tests should now pass

**Files:** `lib/features/wind_dome/models/dome_wind_profile.dart`

**Acceptance Criteria:**
- [x] All dome_wind_profile_test.dart tests pass
- [x] fieldAt() clamps correctly

### Task 3.5: Implement DomeParticle model

- [x] Create `lib/features/wind_dome/models/dome_particle.dart`
- [x] Implement DomeParticle with x, y, z, trail ring buffer
- [x] Trail storage: parallel arrays (trailX, trailY, trailZ) of fixed size TRAIL_LENGTH
- [x] Ring buffer: trailHead, trailCount for O(1) append
- [x] Implement static insideDome(x, y, z, r, h): ellipsoid check (x^2+z^2)/r^2 + y^2/h^2 <= 1 AND y >= 0
- [x] Implement respawn(rng, domeR, domeH): rejection sampling inside dome
- [x] Implement tick(field, dt, domeR, domeH):
  - [x] Sample wind field at (x, y, z)
  - [x] Update position: x += wind.u * RENDER_SCALE * SPEED_SCALE * dt
  - [x] Update position: z += wind.v * RENDER_SCALE * SPEED_SCALE * dt
  - [x] Apply gentle updraft: y += (0.002 + (y/domeH)*0.004) * dt * 60
  - [x] Check dome containment, respawn if outside
  - [x] Append to trail ring buffer (no allocation)
- [x] Implement DomeParticle.random(rng, domeR, domeH) factory
- [x] Run dome_particle_test.dart -- all tests should now pass

**Files:** `lib/features/wind_dome/models/dome_particle.dart`

**Acceptance Criteria:**
- [x] All dome_particle_test.dart tests pass
- [x] Zero object allocation in tick() (ring buffer, no List.insert/removeLast)
- [x] insideDome() is a static method (callable without instance)

### Task 3.6: Implement WindApiClient.fetchPointWindSeries()

- [x] Add fetchPointWindSeries() method to wind_api_client.dart
- [x] Implement _fetchShyftPointSeries() with datetime range parameter
- [x] Implement _parseShyftTimeSeriesResponse() -- extract t.values + u/v arrays
- [x] Implement _fetchFolkPointSeries() with datetime range parameter
- [x] Implement _parseFolkTimeSeriesResponse() -- extract t.values + u/v arrays
- [x] Add _dateTimeRangeUtc(int hours) helper -- returns "now/now+hours" ISO 8601
- [x] Shyft-fail falls back to Folkweather
- [x] Both-fail returns empty list (graceful degradation)
- [x] Run wind_api_client_series_test.dart -- all tests should now pass
- [x] Run existing wind_api_client_test.dart -- no regressions

**Files:** `lib/services/wind/wind_api_client.dart`

**Acceptance Criteria:**
- [x] All wind_api_client_series_test.dart tests pass
- [x] All existing wind_api_client_test.dart tests still pass
- [x] Datetime range format: "2026-02-27T12:00:00Z/2026-03-02T12:00:00Z"
- [x] Returns List<({DateTime time, double u, double v})>

### Task 3.7: Implement DomeWindFetcher

- [x] Create `lib/services/wind/dome_wind_fetcher.dart`
- [x] Constructor accepts WindApiClient (for testability)
- [x] Implement fetch(lat, lng):
  - [x] Check cache (key = "dome_{lat.toStringAsFixed(2)}_{lng.toStringAsFixed(2)}", TTL=10min)
  - [x] On miss: call fetchPointWindSeries() for 3 pressure levels (0, 850, 700) in parallel
  - [x] Assemble into DomeWindProfile: zip 3 series by time index into DomeWindFields
  - [x] Map pressure levels to altitudes: 0->10m, 850->1500m, 700->3000m
  - [x] Sort layers by altitude ascending in each DomeWindField
  - [x] Cache fields are static (survive fetcher recreation across provider lifecycle)
  - [x] Cache result
  - [x] On all-fail: return DomeWindProfile with zero-wind DomeWindFields
- [x] Run dome_wind_fetcher_test.dart -- all tests should now pass

**Files:** `lib/services/wind/dome_wind_fetcher.dart`

**Acceptance Criteria:**
- [x] All dome_wind_fetcher_test.dart tests pass
- [x] Cache key uses 2 decimal places
- [x] 3 levels fetched with Future.wait (parallel)
- [x] Graceful degradation on failure

### Task 3.8: Implement dome providers

- [x] Create `lib/features/wind_dome/providers/dome_providers.dart`
- [x] Implement domeWindFetcherProvider (DI swap-point for testing)
- [x] Implement hoursAheadProvider (StateProvider<int>, default 0)
- [x] Implement domeWindProfileProvider (FutureProvider, watches stablePositionProvider + domeWindFetcherProvider)
- [x] Implement currentDomeWindFieldProvider (Provider<DomeWindField?>, reads profile + hoursAhead)
- [x] Run dome_providers_test.dart -- all tests should now pass
- [x] Run codegen: `dart run build_runner build --delete-conflicting-outputs`

**Files:** `lib/features/wind_dome/providers/dome_providers.dart`

**Acceptance Criteria:**
- [x] All dome_providers_test.dart tests pass
- [x] Providers follow existing naming conventions
- [x] No modification to existing provider files
- [x] domeWindProfileProvider returns null when no GPS fix

---

## Phase 4: Integration (Sequential)

### Task 4.1: Implement DomePainter (CustomPainter)

- [x] Create `lib/features/wind_dome/widgets/dome_painter.dart`
- [x] Constructor takes: particles, theta, phi, domeR, domeH, mapCenterPx, domeRadiusPx
- [x] Implement _buildCameraMatrix(theta, phi, camDist) -> Matrix4
- [x] Implement _project(x, y, z, camera, size) -> Offset
- [x] Implement _drawDomeWireframe(canvas, size):
  - [x] 3 latitude rings at y = 0.25, 0.5, 0.75 of domeH
  - [x] 4 meridian arcs at theta = 0, pi/2, pi, 3pi/2
  - [x] Base ellipse at y = 0
  - [x] White with low opacity (0.08-0.15)
- [x] Implement _drawUserMarker(canvas, size): pulsing dot at dome center ground
- [x] Implement _drawParticles(canvas, size):
  - [x] Iterate particles, iterate trail segments
  - [x] Project each trail point
  - [x] Draw line segment with altitude-based brightness
  - [x] Trail fade: opacity decreases toward tail
  - [x] Single pass (no glow pass -- performance optimization for dome)
- [x] shouldRepaint returns true (controlled by ValueNotifier frame counter)

**Files:** `lib/features/wind_dome/widgets/dome_painter.dart`

**Acceptance Criteria:**
- [x] No object allocation in paint() (pre-create Paint objects)
- [x] Wireframe renders correctly at default camera angle
- [x] Particles render with trail segments

### Task 4.2: Implement DomeForecastSlider widget

- [x] Create `lib/features/wind_dome/widgets/dome_forecast_slider.dart`
- [x] Slider range 0-72, step 1
- [x] Label: "Live" when value=0, "+Nh - Day, Mon DD, H:MM AM/PM" when value>0
- [x] Dark theme styling (white on transparent)
- [x] onChanged callback updates hoursAheadProvider
- [x] Tick marks at 0, 12, 24, 36, 48, 60, 72
- [x] Run dome_forecast_slider_test.dart -- all tests should now pass

**Files:** `lib/features/wind_dome/widgets/dome_forecast_slider.dart`

**Acceptance Criteria:**
- [x] All dome_forecast_slider_test.dart tests pass
- [x] Slider is a ConsumerWidget (reads hoursAheadProvider)
- [x] Label updates instantly on drag

### Task 4.3: Implement DomeInfoBar widget

- [x] Create `lib/features/wind_dome/widgets/dome_info_bar.dart`
- [x] Show wind speed from current field's surface layer
- [x] Show "Live" badge (white border) when hoursAhead=0
- [x] Show "Fcst" badge (dim border) when hoursAhead>0
- [x] Show back button to return to home screen
- [x] Dark theme styling
- [x] Run dome_info_bar_test.dart -- all tests should now pass

**Files:** `lib/features/wind_dome/widgets/dome_info_bar.dart`

**Acceptance Criteria:**
- [x] All dome_info_bar_test.dart tests pass
- [x] ConsumerWidget (reads providers)

### Task 4.4: Implement WindDomeScreen

- [x] Create `lib/features/wind_dome/wind_dome_screen.dart`
- [x] ConsumerStatefulWidget with TickerProviderStateMixin
- [x] initState:
  - [x] Create PerformanceManager
  - [x] Create Ticker, start it
  - [x] Initialize _particles list (empty, populated when wind data arrives)
  - [x] Create ValueNotifier<int> _frameCounter
  - [x] Create MapController
  - [x] Initialize theta = DEFAULT_THETA, phi = DEFAULT_PHI
- [x] Ticker callback:
  - [x] Record frame on PerformanceManager
  - [x] Read currentDomeWindFieldProvider
  - [x] If field is null, return (show wireframe only)
  - [x] Adjust particle count from PerformanceManager
  - [x] Tick each particle
  - [x] Increment _frameCounter.value
- [x] build():
  - [x] Watch stablePositionProvider for map centering
  - [x] Watch domeWindProfileProvider for loading state
  - [x] Watch currentDomeWindFieldProvider for wind data
  - [x] Stack: FlutterMap + GestureDetector(CustomPaint) + DomeForecastSlider + DomeInfoBar
  - [x] FlutterMap: CartoDB Dark Matter tiles, zoom 14, locked to GPS, no interaction
  - [x] GestureDetector onPanUpdate: update theta/phi AND rotate map bearing in sync via mapController.rotate()
  - [x] CustomPaint wraps DomePainter with particles
  - [x] ValueListenableBuilder on _frameCounter triggers repaint
- [x] ref.listen(stablePositionProvider): re-center map on GPS change
- [x] dispose: dispose ticker, frameCounter, mapController, particles
- [x] Calculate domeRadiusPx from map controller for footprint alignment

**Files:** `lib/features/wind_dome/wind_dome_screen.dart`

**Acceptance Criteria:**
- [x] Screen renders without crash (verified on device)
- [x] Map loads with dark tiles
- [x] Wireframe visible while wind data loads
- [x] Particles appear once wind data resolves
- [x] Drag-to-orbit works (theta/phi update)
- [x] Forecast slider changes wind field instantly
- [x] PerformanceManager reduces particles below 45 FPS
- [x] Map bearing stays aligned with dome north during orbit

### Task 4.5: Add navigation from HomeScreen

- [x] Modify `lib/features/home/home_screen.dart`:
  - [x] Add _navigateToWindDome() method
  - [x] Pass callback to HomeTopBar
- [x] Modify `lib/features/home/widgets/home_top_bar.dart`:
  - [x] Add "WIND DOME" button next to "LIVE AR" button
  - [x] Accept onWindDomeTap callback
  - [x] Style: outlined button (dark bg, white border), matching "LIVE AR" style

**Files:**
- `lib/features/home/home_screen.dart`
- `lib/features/home/widgets/home_top_bar.dart`

**Navigation pattern:** Navigation uses Navigator.push (same as _navigateToAR pattern). WindDomeScreen does NOT get its own ProviderScope -- it shares the app-level scope. Back button pops the route.

**Acceptance Criteria:**
- [x] "WIND DOME" button visible on home screen
- [x] Tapping navigates to WindDomeScreen
- [x] Back button on WindDomeScreen returns to home
- [x] Existing "LIVE AR" button still works

---

## Phase 5: Polish (Parallel OK)

### Task 5.1: [P] Loading state and error handling

- [x] Show loading indicator while domeWindProfileProvider is loading
- [x] Show dome wireframe immediately (before wind data)
- [x] Map loads immediately (tiles are independent of wind data)
- [x] On wind data fetch failure: show toast/snackbar, dome wireframe stays visible
- [x] Handle null stablePositionProvider: show "Waiting for GPS..." message

**Files:** `lib/features/wind_dome/wind_dome_screen.dart`

**Acceptance Criteria:**
- [x] User sees map + wireframe immediately on screen open
- [x] Particles fade in once wind data arrives
- [x] No crash on GPS unavailable

### Task 5.2: [P] Performance tuning

- [x] Verify 60 FPS on real device with 2000 particles
- [x] Verify PerformanceManager reduces to 1000 if needed
- [x] Profile tick loop -- must be <8ms
- [x] Profile paint call -- must be <8ms
- [x] Ensure zero object allocation in tick/paint loops (no List.insert, no Vector3())
- [x] Verify trail ring buffer works correctly at capacity

**Files:** `lib/features/wind_dome/models/dome_particle.dart`, `lib/features/wind_dome/widgets/dome_painter.dart`

**Acceptance Criteria:**
- [x] 60 FPS on target device
- [x] PerformanceManager auto-adjusts correctly
- [x] No GC pauses from particle/trail allocation

### Task 5.3: [P] Accessibility

- [x] Add Semantics labels to slider ("Forecast time slider, currently showing live / +N hours")
- [x] Add Semantics to info bar elements
- [x] Add Semantics to Wind Dome button on home screen
- [x] Ensure sufficient contrast for UI elements

**Files:** Various widget files

**Acceptance Criteria:**
- [x] VoiceOver/TalkBack can identify all interactive elements
- [x] Slider value is announced on change

---

## Phase 6: Ready for Test Agent

### Pre-handoff Checklist

- [x] All unit tests pass: `flutter test`
- [x] All new tests pass (66+ tests)
- [x] All existing tests pass (628+ tests)
- [x] No regressions in existing features
- [x] Build succeeds: `flutter build ios --no-codesign` (or android)
- [x] No new lint warnings
- [x] Code follows project conventions (canonical paths, no old-path additions)
- [x] No Freezed on hot-path classes (DomeParticle, DomeWindField.sample)
- [x] CustomPainter state survival pattern used (particles owned by State)
- [x] ValueNotifier sidecar pattern used (frameCounter)

### Test Summary

| Test File | Expected Tests | Status |
|-----------|---------------|--------|
| dome_wind_field_test.dart | 12 | [x] |
| dome_wind_profile_test.dart | 7 | [x] |
| dome_particle_test.dart | 15 | [x] |
| wind_api_client_series_test.dart | 10 | [x] |
| dome_wind_fetcher_test.dart | 9 | [x] |
| dome_providers_test.dart | 5 | [x] |
| dome_forecast_slider_test.dart | 4 | [x] |
| dome_info_bar_test.dart | 4 | [x] |
| dome_painter_test.dart | 3 | [x] |
| **Total** | **69** | [x] |

### Files Created

| File | Purpose |
|------|---------|
| `lib/features/wind_dome/wind_dome_screen.dart` | Main screen |
| `lib/features/wind_dome/models/dome_constants.dart` | Constants |
| `lib/features/wind_dome/models/dome_wind_layer.dart` | Altitude layer model |
| `lib/features/wind_dome/models/dome_wind_field.dart` | Wind field + sample() |
| `lib/features/wind_dome/models/dome_wind_profile.dart` | 72-hour profile |
| `lib/features/wind_dome/models/dome_particle.dart` | Mutable particle |
| `lib/features/wind_dome/providers/dome_providers.dart` | Riverpod providers |
| `lib/features/wind_dome/widgets/dome_painter.dart` | CustomPainter |
| `lib/features/wind_dome/widgets/dome_forecast_slider.dart` | Slider widget |
| `lib/features/wind_dome/widgets/dome_info_bar.dart` | Info bar widget |
| `lib/services/wind/dome_wind_fetcher.dart` | Wind fetcher + cache |

### Files Modified

| File | Change |
|------|--------|
| `lib/services/wind/wind_api_client.dart` | Added fetchPointWindSeries() |
| `lib/features/home/home_screen.dart` | Added Wind Dome navigation |
| `lib/features/home/widgets/home_top_bar.dart` | Added Wind Dome button |
| `pubspec.yaml` | Added flutter_map + latlong2 |
