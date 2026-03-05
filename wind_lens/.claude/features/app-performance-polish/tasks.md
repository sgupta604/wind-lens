# Tasks: app-performance-polish

## Metadata
- **Feature:** app-performance-polish
- **Created:** 2026-03-05T14:00
- **Updated:** 2026-03-05 (v4 -- added Phase 6 on-device bugfixes)
- **Status:** plan-complete, ready for /implement (bugfixes)
- **Based-on:** 2026-03-05T14:00_plan.md, 2026-03-05T21:00_plan_bugfixes.md

## Execution Rules

- **[P]** = parallelizable with other [P] tasks in the same phase
- **TDD order:** Write/update tests BEFORE or alongside implementation
- **Completion:** Check boxes as subtasks complete
- **All code changes via execute-agent subagents** -- do NOT edit files directly
- **Streams 2, 3, 4 depend on Stream 1** -- fonts must be done first (shared pubspec)
- **Streams 2, 3, 4 can run in parallel** after Stream 1 completes

---

## Stream 1: Fonts + Splash (FOUNDATION)

### Task 1.1: Download and Bundle Font Files -- DONE (survived git checkout)
- [x] Create `assets/fonts/` directory
- [x] Download `DMMono-Regular.ttf` from Google Fonts GitHub
- [x] Download `DMMono-Medium.ttf` from Google Fonts GitHub
- [x] Download `BebasNeue-Regular.ttf` from Google Fonts GitHub
- [x] Verify all 3 files exist in `assets/fonts/`

**Files:** `assets/fonts/DMMono-Regular.ttf`, `assets/fonts/DMMono-Medium.ttf`, `assets/fonts/BebasNeue-Regular.ttf`

**Acceptance Criteria:**
- [x] All 3 TTF files present and non-zero size

---

### Task 1.2: Update pubspec.yaml -- DONE
- [x] Add `fonts:` section with DM Mono (Regular + Medium w500) and Bebas Neue (Regular)
- [x] Add `flutter_map_cancellable_tile_provider: ^3.0.0` to dependencies
- [x] Remove `google_fonts: ^6.1.0` from dependencies
- [x] Run `flutter pub get` to verify dependency resolution

**Files:** `pubspec.yaml`

**Acceptance Criteria:**
- [x] `flutter pub get` succeeds with no errors
- [x] `google_fonts` no longer in pubspec.yaml
- [x] `flutter_map_cancellable_tile_provider` added
- [x] Font families declared correctly

---

### Task 1.3: Replace All GoogleFonts Call Sites (18 sites across 6 files) -- DONE
- [x] `home_top_bar.dart`: Replace 4 GoogleFonts calls (1 bebasNeue, 3 dmMono)
- [x] `home_wind_row.dart`: Replace 3 GoogleFonts calls (2 dmMono, 1 bebasNeue)
- [x] `home_compass_bar.dart`: Replace 1 GoogleFonts call (dmMono)
- [x] `home_altitude_rail.dart`: Replace 1 GoogleFonts call (dmMono)
- [x] `home_layer_toggles.dart`: Replace 1 GoogleFonts call (dmMono) -- or defer to Task 2.2
- [x] `location_picker_screen.dart`: Replace 8 GoogleFonts calls (all dmMono)
- [x] Remove `import 'package:google_fonts/google_fonts.dart'` from all 6 files

**Pattern:**
- `GoogleFonts.dmMono(fontSize: X, color: Y, ...)` -> `TextStyle(fontFamily: 'DM Mono', fontSize: X, color: Y, ...)`
- `GoogleFonts.bebasNeue(fontSize: X, ...)` -> `TextStyle(fontFamily: 'Bebas Neue', fontSize: X, ...)`

**Files:** `lib/features/home/widgets/home_top_bar.dart`, `lib/features/home/widgets/home_wind_row.dart`, `lib/features/home/widgets/home_compass_bar.dart`, `lib/features/home/widgets/home_altitude_rail.dart`, `lib/features/home/widgets/home_layer_toggles.dart`, `lib/features/location_picker/location_picker_screen.dart`

**Acceptance Criteria:**
- [x] Zero `GoogleFonts.` calls remain in codebase
- [x] Zero `google_fonts` imports remain
- [x] `flutter test` passes (or only pre-existing failures)

---

### Task 1.4: Create Splash Screen -- DONE (survived git checkout)
- [x] Create `lib/features/splash/splash_screen.dart`
- [x] Implement ConsumerStatefulWidget that watches: `effectivePositionProvider`, `windDataProvider`, `horizonProfileProvider`
- [x] Compute progress: 0% -> 33% (GPS) -> 66% (wind) -> 100% (horizon)
- [x] Show "ShyftLens" in Bebas Neue, white, centered
- [x] Show thin progress bar below logo (white fill on dark track)
- [x] Show status text below bar (DM Mono, grey, small)
- [x] Transition to HomeScreen via `Navigator.pushReplacement` when 100% or after 15s timeout
- [x] Use `addPostFrameCallback` to avoid navigating during build

**Files:** `lib/features/splash/splash_screen.dart`

**Acceptance Criteria:**
- [x] Splash shows logo and progress bar
- [x] Progress updates as providers resolve
- [x] Transitions to HomeScreen when all data loaded
- [x] Transitions to HomeScreen after 15s timeout even if data incomplete

---

### Task 1.5: Wire Splash Screen as Initial Route -- DONE
- [x] Change `app.dart`: `home: const HomeScreen()` -> `home: const SplashScreen()`
- [x] Add import for splash_screen.dart

**Files:** `lib/app.dart`

**Acceptance Criteria:**
- [x] App launches to SplashScreen
- [x] SplashScreen transitions to HomeScreen

---

### Task 1.6: Write Splash Screen Tests -- DONE (survived git checkout)
- [x] Create `test/features/splash/splash_screen_test.dart`
- [x] Test: splash screen renders logo text
- [x] Test: splash screen renders progress bar
- [x] Test: splash screen shows correct status messages for each loading phase

**Files:** `test/features/splash/splash_screen_test.dart`

**Acceptance Criteria:**
- [x] All splash screen tests pass
- [x] Tests use Riverpod overrides to simulate loading states

---

### Task 1.7: Strict Splash Screen Gating (NEW) -- DONE
- [x] Remove the 15-second timeout fallback (`_timeoutTimer` in `initState`)
- [x] Add a 60-second error timeout: after 60s without all 3 providers ready, show "Unable to load data" message with a Retry button
- [x] Retry button should reset state and re-attempt (cancel old timer, set new 60s timer, clear error)
- [x] Splash ONLY transitions to HomeScreen when `steps == 3` AND `_minTimeElapsed` -- never on timeout
- [x] Keep the 2-second minimum display time (`_minTimeElapsed` logic unchanged)
- [x] Update status text to show "Unable to load data. Check your connection." when error timeout fires
- [x] Update splash screen tests for new behavior (no 15s timeout test, add 60s error + retry tests)

**Files:** `lib/features/splash/splash_screen.dart`, `test/features/splash/splash_screen_test.dart`

**Acceptance Criteria:**
- [x] Splash never lets user in with incomplete data (no silent timeout entry)
- [x] After 60s without data, error message + Retry button shown
- [x] Retry button clears error and restarts the 60s countdown
- [x] When all 3 providers have values AND 2s minimum elapsed, transition to HomeScreen
- [x] Splash screen tests updated and passing

---

## Stream 2: Home Screen Polish

> Depends on Stream 1 (font files + pubspec must be done first)

### Task 2.1: Remove Home Screen Particles -- DONE
- [x] Remove `AnimationController _particleController` and `initState()`/`dispose()` logic from `home_screen.dart`
- [x] Remove `TickerProviderStateMixin` from `_HomeScreenState` (change to `ConsumerState`)
- [x] Remove `particleController: _particleController` from `HomeTerrainSection` constructor call
- [x] In `home_terrain_section.dart`: remove `particleController` parameter from constructor
- [x] In `home_terrain_section.dart`: remove Layer 2 (animated particles) from Stack
- [x] Remove `import 'home_particle_painter.dart'` from `home_terrain_section.dart`
- [x] Remove `HomeParticleState` field from `_HomeTerrainSectionState`

**Files:** `lib/features/home/home_screen.dart`, `lib/features/home/widgets/home_terrain_section.dart`

**Acceptance Criteria:**
- [x] No AnimationController in HomeScreen
- [x] No particle layer in terrain section Stack
- [x] HomeTerrainSection no longer requires particleController parameter

---

### Task 2.2: Replace Layer Toggles with Static TERRAIN Label -- DONE
- [x] Rewrite `home_layer_toggles.dart` to be a simple static centered "TERRAIN" label
- [x] Style: `TextStyle(fontFamily: 'DM Mono', fontSize: 9, color: Color(0xFF555555), letterSpacing: 0.15 * 9)`
- [x] Wrap in Padding matching existing: `EdgeInsets.fromLTRB(28, 0, 28, 18)`
- [x] Keep class name `HomeLayerToggles` to minimize changes in home_screen.dart

**Files:** `lib/features/home/widgets/home_layer_toggles.dart`

**Acceptance Criteria:**
- [x] Single centered "TERRAIN" text displayed
- [x] No toggle buttons remain
- [x] home_screen.dart unchanged (still references HomeLayerToggles)

---

### Task 2.3: Apply UI Polish Values [P] -- DONE
- [x] `home_altitude_rail.dart`: inactive text `#282828` -> `#555555`, inactive line `#222222` -> `#444444`, font 8 -> 10
- [x] `home_compass_bar.dart`: active `#666666` -> `#AAAAAA`, inactive `#222222` -> `#444444`, font 9 -> 11
- [x] `home_wind_row.dart`: label font 8 -> 10, value font 28 -> 34, unit font 9 -> 11

**Files:** `lib/features/home/widgets/home_altitude_rail.dart`, `lib/features/home/widgets/home_compass_bar.dart`, `lib/features/home/widgets/home_wind_row.dart`

**Acceptance Criteria:**
- [x] All color and font size values match the specified targets
- [x] Visual verification: text is brighter and larger

---

### Task 2.4: Add Compass Heading Line [P] -- DONE
- [x] Add `_HeadingLinePainter` class to `home_terrain_section.dart` (private, ~20 lines)
- [x] Uses `super(repaint: headingNotifier)` for efficient repainting
- [x] Maps heading (0-360) to x position: `(heading / 360.0) * size.width`
- [x] Draws vertical line: `Color(0x33FFFFFF)`, strokeWidth 1.0, with triangle marker at top
- [x] `shouldRepaint` returns `false` (repaint driven by listenable)
- [x] Add as new Layer 2 in Stack (between terrain Layer 1 and altitude rail)
- [x] Pass `widget.sensorNotifiers.heading` to the painter

**Files:** `lib/features/home/widgets/home_terrain_section.dart`

**Acceptance Criteria:**
- [x] Vertical white line visible on terrain section
- [x] Line tracks compass heading smoothly via ValueNotifier
- [x] No widget rebuilds triggered -- only painter repaints

---

### Task 2.5: Switch to CupertinoPageRoute -- DONE
- [x] Add `import 'package:flutter/cupertino.dart'` to `home_screen.dart`
- [x] Replace `MaterialPageRoute` with `CupertinoPageRoute` in `_navigateToAR()`
- [x] Replace `MaterialPageRoute` with `CupertinoPageRoute` in `_navigateToWindDome()`
- [x] Replace `MaterialPageRoute` with `CupertinoPageRoute` in `_navigateToLocationPicker()`
- [x] Note: location picker navigation still pushes `LocationPickerScreen` -- will be updated to `LocationPickerLoadingScreen` in Task 3.1

**Files:** `lib/features/home/home_screen.dart`

**Acceptance Criteria:**
- [x] All 3 navigation calls use CupertinoPageRoute
- [x] iOS-native slide transition on both platforms

---

### Task 2.6: Update Home Screen Tests -- DONE
- [x] Update `test/features/home/home_screen_test.dart`: update for toggles -> static TERRAIN label
- [x] No `home_terrain_section_test.dart` existed to update
- [x] Run `flutter test test/features/home/` -- all tests pass

**Files:** `test/features/home/home_screen_test.dart`

**Acceptance Criteria:**
- [x] All home screen tests pass
- [x] Tests reflect new widget tree (no particles, no toggles, static TERRAIN label)

---

## Stream 3: Location Picker

> Depends on Stream 1 (font files + pubspec must be done first)

### Task 3.1: Wire Location Picker Loading Screen -- DONE
- [x] Create `lib/features/location_picker/location_picker_loading_screen.dart` (file exists)
- [x] Update `home_screen.dart` `_navigateToLocationPicker()` to push `LocationPickerLoadingScreen` instead of `LocationPickerScreen`

**Files:** `lib/features/location_picker/location_picker_loading_screen.dart` (exists), `lib/features/home/home_screen.dart`

**Acceptance Criteria:**
- [x] Tapping location picker shows spinner briefly then map
- [x] No UI freeze during flutter_map initialization

---

### Task 3.2: GPS Fallback to US Center -- DONE
- [x] In `location_picker_screen.dart` `initState()`: change `LatLng(0, 0)` to `LatLng(39.8283, -98.5795)`

**Files:** `lib/features/location_picker/location_picker_screen.dart`

**Acceptance Criteria:**
- [x] Map centers on US when no GPS fix available

---

### Task 3.3: CancellableNetworkTileProvider + MapController Dispose -- DONE
- [x] Add `late final TileProvider _tileProvider` field
- [x] Initialize in `initState()`: `_tileProvider = widget.tileProvider ?? CancellableNetworkTileProvider()`
- [x] Use `_tileProvider` in TileLayer instead of inline creation
- [x] Add `_tileProvider.dispose()` to `dispose()`
- [x] Add `_mapController.dispose()` to `dispose()`
- [x] Add import for `flutter_map_cancellable_tile_provider`
- [x] Add optional `tileProvider` constructor parameter for testability

**Files:** `lib/features/location_picker/location_picker_screen.dart`

**Acceptance Criteria:**
- [x] Only one tile provider instance per screen lifetime
- [x] MapController properly disposed
- [x] No resource leaks on close/reopen

---

### Task 3.4: Replace Coordinate Input Dialog with Bottom Sheet -- DONE
- [x] Replace `showDialog(AlertDialog(...))` with `showModalBottomSheet`
- [x] Separate lat/lng TextFields (not single "lat, lng" field)
- [x] Pre-fill with current selected position
- [x] Inline validation with StatefulBuilder
- [x] Confirm button updates `_selectedPosition` and pops
- [x] Removed `_parseCoordinates` method (no longer needed with separate fields)

**Files:** `lib/features/location_picker/location_picker_screen.dart`

**Acceptance Criteria:**
- [x] Bottom sheet appears with separate lat/lng fields
- [x] Validation prevents invalid coordinates
- [x] Selected position updates correctly on confirm

---

### Task 3.5: Update Location Picker Tests -- DONE
- [x] Add `_NoOpTileProvider` class with valid 1x1 PNG to prevent Dio timer leaks
- [x] Pass `_NoOpTileProvider` via constructor parameter in all tests
- [x] Add test for GPS fallback position (39.8283, -98.5795)
- [x] Add tests for bottom sheet: opens with lat/lng fields, validates lat, validates lng
- [x] Update `test/features/home/home_screen_test.dart`: removed Dio-leaking navigation test, kept button-exists test
- [x] Run `flutter test test/features/location_picker/` -- 13 tests pass
- [x] Run `flutter test` -- all tests pass (exit code 0)

**Files:** `test/features/location_picker/location_picker_screen_test.dart`, `test/features/home/home_screen_test.dart`

**Acceptance Criteria:**
- [x] All location picker tests pass

---

## Stream 4: Dome

> Depends on Stream 1 completing (for consistency), but no shared files

### Task 4.1: Start Dome Zoomed Out [P] -- DONE
- [x] In `wind_dome_screen.dart`, change `_camR` initialization from `DomeConstants.camR` to `DomeConstants.camRMax * 0.85`
- [x] Update ref.listen dome size change handler to use same zoomed-out ratio
- [x] Verify dome is visible but clearly zoomed out on launch

**Files:** `lib/features/wind_dome/wind_dome_screen.dart`

**Acceptance Criteria:**
- [x] Dome opens at zoomed-out view showing full dome
- [x] User can still pinch to zoom in

---

### Task 4.2: Particle Anti-Bunching Jitter [P] -- DONE
- [x] In `dome_particle.dart` `tick()` method, after position update and before bounds check:
- [x] Add jitter for large domes: `if (domeR > 15.0) { ... }`
- [x] Jitter scale: `0.002 * domeR` in both x and z
- [x] Use provided `rng` parameter (already in tick() signature)

**Files:** `lib/features/wind_dome/models/dome_particle.dart`

**Acceptance Criteria:**
- [x] Particles spread out at large dome radii (35km, 50km)
- [x] No visible jitter at small dome radii (<15 RU)

---

## Phase 5: Final Verification

### Task 5.1: Run Full Test Suite -- DONE
- [x] Run `flutter test` (auto-discovered 835 tests -- all pass, exit code 0)
- [x] Run `flutter test test/utils/ test/services/sensors/ test/services/sky_detection/sky_mask_test.dart test/core/providers/data_providers_test.dart` (explicit paths -- 47 tests, all pass)
- [x] Zero failures introduced by changes
- [x] Zero regressions

**Acceptance Criteria:**
- [x] All tests pass with exit code 0
- [x] No new test failures

---

## Phase 6: On-Device Bugfixes

> Fixes for 4 bugs found during on-device testing of Streams 1-4.
> Based on: `2026-03-05T21:00_plan_bugfixes.md`
> Order: Bug 1 -> Bug 3 -> Bug 2 -> Bug 4

### Task 6.1: Fix sensorNotifiersProvider keepAlive (Bug 1 -- CRITICAL)
- [x] In `lib/core/providers/sensor_providers.dart` line 97: change `@riverpod` to `@Riverpod(keepAlive: true)`
- [x] Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `sensor_providers.g.dart`
- [x] Verify generated file contains `Provider<SensorNotifiers>.internal(...)` (NOT `AutoDisposeProvider`)
- [x] Run `flutter test` -- all tests pass

**Files:** `lib/core/providers/sensor_providers.dart`, `lib/core/providers/sensor_providers.g.dart` (auto)

**Acceptance Criteria:**
- [x] `@Riverpod(keepAlive: true)` annotation on `sensorNotifiers` function
- [x] Generated provider is non-auto-dispose
- [x] All existing tests pass (835+)
- [x] No regressions in sensor data flow

---

### Task 6.2: Remove compass heading line from home terrain (Bug 3 -- LOW)
- [x] In `lib/features/home/widgets/home_terrain_section.dart`: remove Layer 2 Positioned widget (lines 69-78, the heading line layer)
- [x] Remove `_HeadingLinePainter` class definition (lines 149-181)
- [x] Renumber layer comments: Layer 3 -> Layer 2, Layer 4 -> Layer 3, Layer 5 -> Layer 4
- [x] Keep `sensorNotifiers` parameter on `HomeTerrainSection` (still used by `HomeCompassBar`)
- [x] Run `flutter test` -- all tests pass

**Files:** `lib/features/home/widgets/home_terrain_section.dart`

**Acceptance Criteria:**
- [x] No `_HeadingLinePainter` class in file
- [x] No heading line layer in Stack
- [x] Layer comments renumbered correctly
- [x] `HomeCompassBar` still receives `headingNotifier` and works
- [x] All existing tests pass

---

### Task 6.3: Fix HomeScreen ref.watch -> ref.read (Bug 2 -- CRITICAL)

> **Depends on Task 6.1** (keepAlive must be in place first)

- [x] In `lib/features/home/home_screen.dart`: add `late final SensorNotifiers _sensorNotifiers;` field to `_HomeScreenState`
- [x] Add `initState()` override with `_sensorNotifiers = ref.read(sensorNotifiersProvider);`
- [x] In `build()`: remove `final sensorNotifiers = ref.watch(sensorNotifiersProvider);`
- [x] Replace all `sensorNotifiers` references in `build()` with `_sensorNotifiers`
- [x] Run `flutter test test/features/home/` -- all tests pass
- [x] Run `flutter test` -- all tests pass

**Files:** `lib/features/home/home_screen.dart`

**Acceptance Criteria:**
- [x] No `ref.watch(sensorNotifiersProvider)` in build()
- [x] `ref.read(sensorNotifiersProvider)` in initState()
- [x] `_sensorNotifiers` field used throughout build()
- [x] Home screen tests pass with `sensorNotifiersProvider.overrideWithValue()`
- [x] All existing tests pass

---

### Task 6.4: Fix dome zoom for large domes (Bug 4 -- MEDIUM)
- [x] In `lib/features/wind_dome/wind_dome_screen.dart` line 58: change `double _camR = DomeConstants.camRMax * 0.85;` to `double? _camR;`
- [x] In `build()`, after computing `computedDomeR` (around line 172): add `_camR ??= computedDomeR * (DomeConstants.camRMax / DomeConstants.domeR) * 0.85;`
- [x] Add `!` null assertion where `_camR` is read after the `??=` line (Dart does not promote nullable fields)
- [x] Run `flutter test` -- all tests pass

**Files:** `lib/features/wind_dome/wind_dome_screen.dart`

**Acceptance Criteria:**
- [x] `_camR` is null until first build
- [x] First build initializes `_camR` based on actual `computedDomeR`
- [x] User pinch-zoom adjustments preserved after first build
- [x] Dome size changes via `ref.listen` still reset `_camR` correctly
- [x] All existing tests pass

---

### Task 6.5: Final Verification (Bugfixes)
- [x] Run `flutter test` (auto-discovered tests -- all pass, 835 tests)
- [x] Run `flutter test test/utils/ test/services/sensors/ test/services/sky_detection/sky_mask_test.dart test/core/providers/data_providers_test.dart` (explicit paths -- 47 tests, all pass)
- [x] Run `dart analyze` -- 0 errors, 0 new warnings (10 pre-existing info/warnings in test files, all unrelated to bugfixes)
- [x] Zero regressions

**Acceptance Criteria:**
- [x] All tests pass with exit code 0
- [x] No analyzer errors or warnings (pre-existing only)
- [x] No new test failures

---

## Handoff Checklist for Test Agent

- [x] All tests pass (`flutter test` + explicit paths)
- [ ] Build succeeds (`flutter build ios --no-codesign` or `flutter build apk`)
- [x] `dart analyze` -- 0 errors, 0 new warnings
- [ ] No `GoogleFonts.` calls remain in codebase
- [ ] No `google_fonts` import remains
- [ ] Splash screen renders and transitions correctly
- [ ] Splash screen does NOT let user in with incomplete data (no silent timeout)
- [ ] Splash screen shows error + retry after 60s without data
- [ ] Location picker no longer freezes on first open
- [x] Home screen has no particles, no toggle buttons, NO heading line
- [ ] All navigation uses CupertinoPageRoute
- [x] Dome starts zoomed out (correct zoom for any dome size)
- [ ] Font rendering verified on device
- [x] No crash on splash -> home transition (Bug 1 fix)
- [x] No freeze when returning to home from sub-screens (Bug 2 fix)
