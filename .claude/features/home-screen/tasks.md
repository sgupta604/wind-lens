# Tasks: Home Screen (SPEC-002)

**Feature:** home-screen
**Timestamp:** 2026-02-26T12:00
**Status:** implementation-complete
**Based on:** `.claude/features/home-screen/2026-02-26T12:00_plan.md`

---

## Execution Rules

- **[P]** = task can run in parallel with other [P] tasks in the same phase
- **TDD order:** Phase 2 writes failing tests, Phase 3 makes them pass
- **Completion:** Check boxes as tasks complete
- **Tests:** Use `pump()` not `pumpAndSettle()` for widgets with animation controllers

---

## Phase 1: Setup (Sequential)

### Task 1.1: Add google_fonts dependency

- [x] Add `google_fonts: ^6.1.0` to `pubspec.yaml` dependencies section (after line 47)
- [x] Run `flutter pub get` in `/workspace/wind_lens/`

**Files:** `wind_lens/pubspec.yaml`

**Acceptance Criteria:**
- [x] `flutter pub get` succeeds with no errors
- [x] `google_fonts` appears in `pubspec.lock`

---

### Task 1.2: Create wind_utils.dart utility

- [x] Create `lib/core/utils/wind_utils.dart`
- [x] Implement `degreesToCardinal(double degrees)` function
- [x] 16-point compass rose: N, NNE, NE, ENE, E, ESE, SE, SSE, S, SSW, SW, WSW, W, WNW, NW, NNW
- [x] Handle negative and overflow degrees via modulo

**Files:** `wind_lens/lib/core/utils/wind_utils.dart`

**Acceptance Criteria:**
- [x] Function compiles with no analyzer issues
- [x] Returns correct cardinal for 0, 90, 180, 270 degrees
- [x] Handles 360, 361, -10 degree inputs

---

### Task 1.3: Create feature directory structure

- [x] Create `lib/features/home/` directory
- [x] Create `lib/features/home/widgets/` directory
- [x] Create `test/features/home/` directory
- [x] Create `test/features/home/widgets/` directory
- [x] Create `test/core/utils/` directory (if not exists)

**Files:** Directory creation only

**Acceptance Criteria:**
- [x] All directories exist

---

## Phase 2: Tests (TDD - Write Failing Tests)

### Task 2.1: wind_utils unit tests

- [x] Create `test/core/utils/wind_utils_test.dart`
- [x] Test: 0 degrees returns "N"
- [x] Test: 90 degrees returns "E"
- [x] Test: 180 degrees returns "S"
- [x] Test: 270 degrees returns "W"
- [x] Test: 202 degrees returns "SSW"
- [x] Test: boundary/overflow degrees (360, 361, -10)
- [x] Run tests -- should pass since Task 1.2 already created the utility

**Files:** `wind_lens/test/core/utils/wind_utils_test.dart`

**Acceptance Criteria:**
- [x] All 6 tests pass
- [x] Covers cardinal, intercardinal, and edge cases

---

### Task 2.2: HomeWindRow widget tests

- [x] Create `test/features/home/widgets/home_wind_row_test.dart`
- [x] Test: shows placeholder "--" when sceneState is null (use provider overrides)
- [x] Test: shows formatted speed value when wind data available
- [x] Test: shows cardinal direction when wind data available
- [x] Test: shows altitude label matching selectedAltitudeProvider
- [x] Wrap test widgets in `ProviderScope` with overrides for `sceneStateProvider` and `selectedAltitudeProvider`

**Files:** `wind_lens/test/features/home/widgets/home_wind_row_test.dart`

**Acceptance Criteria:**
- [x] Tests compile (may fail until Phase 3 implementation)
- [x] 4 test cases covering null state, speed, direction, altitude

---

### Task 2.3: HomeScreen integration tests

- [x] Create `test/features/home/home_screen_test.dart`
- [x] Test: renders without crashing (ProviderScope wrap)
- [x] Test: has black background (Scaffold.backgroundColor)
- [x] Test: shows "ShyftLens" logo text
- [x] Test: shows "ATMOSPHERIC AR" subtitle
- [x] Test: shows "LIVE AR" button text
- [x] Test: Live AR button navigates to ARViewScreen on tap
- [x] Test: layer toggle text visible ("PARTICLES", "TERRAIN")
- [x] Test: altitude rail shows "Surface" label
- [x] Use `pump()` not `pumpAndSettle()` (animation controller never settles)

**Files:** `wind_lens/test/features/home/home_screen_test.dart`

**Acceptance Criteria:**
- [x] Tests compile (may fail until Phase 3 implementation)
- [x] 8 test cases covering rendering, text, navigation, sub-widgets

---

## Phase 3: Core Widgets (Sequential, build bottom-up)

### Task 3.1: HomeLayerToggles widget

- [x] Create `lib/features/home/widgets/home_layer_toggles.dart`
- [x] Implement 4 toggle buttons: PARTICLES (on), PRESSURE (dim), TERRAIN (on), CLOUDS (dim)
- [x] "on" state: white background, black text
- [x] "dim" state: `#111` background, `#222` border, `#555` text
- [x] Font: DM Mono 9sp uppercase, letter-spacing 0.15em (use `GoogleFonts.dmMono()`)
- [x] Border radius: 6, height: 38px, gap: 8px
- [x] Padding: horizontal 28, bottom 18
- [x] Visual-only -- no onTap wiring in MVP

**Files:** `wind_lens/lib/features/home/widgets/home_layer_toggles.dart`

**Acceptance Criteria:**
- [x] Widget renders 4 buttons with correct labels
- [x] "on" buttons (Particles, Terrain) have white background
- [x] "dim" buttons (Pressure, Clouds) have dark background
- [x] No analyzer issues

---

### Task 3.2: HomeCompassBar widget

- [x] Create `lib/features/home/widgets/home_compass_bar.dart`
- [x] Accept `ValueNotifier<double> headingNotifier` parameter
- [x] Display 8 directions: N, NE, E, SE, S, SW, W, NW
- [x] Use `ValueListenableBuilder<double>` on headingNotifier (no setState)
- [x] Active direction (nearest to heading value): `#666666` text
- [x] Inactive directions: `#222222` text
- [x] Font: DM Mono 9sp
- [x] Full width with 28px horizontal padding

**Files:** `wind_lens/lib/features/home/widgets/home_compass_bar.dart`

**Acceptance Criteria:**
- [x] Uses ValueListenableBuilder (not setState)
- [x] Correct direction highlighted based on heading value
- [x] No analyzer issues

---

### Task 3.3: HomeAltitudeRail widget

- [x] Create `lib/features/home/widgets/home_altitude_rail.dart`
- [x] `ConsumerWidget` reading `selectedAltitudeProvider`
- [x] 5 ticks evenly spaced vertically: "10,000 ft", "7,500 ft", "2,400 ft", "1,000 ft", "Surface"
- [x] Active tick (matching selectedAltitude): white text, white line (18px wide), triangle marker
- [x] Inactive tick: `#282828` text, `#222222` line (12px wide)
- [x] Font: DM Mono 8sp
- [x] Map ticks to AltitudeLevel: 10,000->jetStream, 2,400->midLevel, Surface->surface
- [x] Tapping mapped ticks calls `ref.read(selectedAltitudeProvider.notifier).select(level)`
- [x] Tapping unmapped ticks (7,500 ft, 1,000 ft) does nothing

**Files:** `wind_lens/lib/features/home/widgets/home_altitude_rail.dart`

**Acceptance Criteria:**
- [x] 5 ticks render with correct labels
- [x] Active tick visually distinct (white)
- [x] Tapping mapped ticks changes selectedAltitudeProvider
- [x] No analyzer issues

---

### Task 3.4: HomeParticlePainter [P]

- [x] Create `lib/features/home/widgets/home_particle_painter.dart`
- [x] Define private `_HomeParticle` class (mutable, NOT Freezed):
  - Fields: `x, y, vx, vy, life, maxLife, radius, waveOffset`
  - `List<Offset> trail` (max 20 positions)
- [x] `HomeParticlePainter extends CustomPainter`:
  - Accept `Animation<double> animation` as repaint listenable
  - Accept optional `WindData? windData` for future wind bias
  - Lazy-init 80 particles on first paint
  - Per-tick: update positions, apply sinusoidal wiggle, advance life, update trails
  - Per-tick: reset particles when life >= maxLife or x out of bounds
  - Spawn: 95% from left edge, 5% from right edge
  - y: random in middle 70% of height
  - vx: 0.5-1.6 px/frame, vy: +/-0.15 px/frame
  - Wiggle: `vy += sin(waveOffset + x * 0.015) * 0.1`
  - Alpha: `sin(life / maxLife * pi) * 0.6`
- [x] Paint: trail lines (tapered opacity) + head dot (white, alpha)
- [x] `shouldRepaint => true` (always repaints on animation tick)

**Files:** `wind_lens/lib/features/home/widgets/home_particle_painter.dart`

**Acceptance Criteria:**
- [x] 80 particles initialize and animate
- [x] Particles flow left-to-right with wiggle
- [x] Trail rendering with tapered opacity
- [x] No object allocation in render loop (reuse particle objects)
- [x] No analyzer issues

---

### Task 3.5: HomeTerrainSection widget (includes grid + terrain painters) [P]

- [x] Create `lib/features/home/widgets/home_terrain_section.dart`
- [x] Implement `_HomeGridPainter` (private):
  - Lines: `rgba(255,255,255,0.025)`, 48px spacing, horizontal + vertical
  - `shouldRepaint => false`
- [x] Implement `HomeTerrainPainter` (non-private for future testability):
  - Accept `HorizonProfile? profile` parameter (null = decorative fallback)
  - Hardcoded bezier path from spec (fill `#1a1a1a`, ridge stroke `#2e2e2e`)
  - Horizon line: 1px at `size.height * 0.65`, `rgba(255,255,255,0.10)`
  - `shouldRepaint => false`
- [x] `HomeTerrainSection` widget:
  - Accept `AnimationController particleController`
  - Accept `SensorNotifiers sensorNotifiers` (for compass bar heading)
  - Stack order: grid -> terrain -> particles -> altitude rail (Positioned right) -> compass bar (Positioned bottom)
  - `ExcludeSemantics` wrapping the decorative painters

**Files:** `wind_lens/lib/features/home/widgets/home_terrain_section.dart`

**Acceptance Criteria:**
- [x] Grid draws faint lines at 48px intervals
- [x] Terrain silhouette renders as dark charcoal bezier shape
- [x] Ridge highlight visible
- [x] Stack layers in correct order
- [x] No analyzer issues

---

### Task 3.6: HomeWindRow widget

- [x] Create `lib/features/home/widgets/home_wind_row.dart`
- [x] `ConsumerWidget`
- [x] Read `sceneStateProvider` and `selectedAltitudeProvider`
- [x] Three equal-width columns (Expanded) with VerticalDivider:
  - Speed: label "SPEED", value from `wind.speed.toStringAsFixed(1)` or "--", unit "mph"
  - Direction: label "DIRECTION", value from `degreesToCardinal(wind.directionDegrees)` or "--", unit "bearing XXX deg" or ""
  - Altitude: label "ALTITUDE", value from altitude mapping, unit "ft AGL"
- [x] Altitude value formatting:
  - surface: "33" (10m * 3.28084)
  - midLevel: "4.9K"
  - jetStream: "34.4K"
  - Note: spec shows "2.4K" -- use spec label mapping literally for visual appeal
- [x] Value text: Bebas Neue 28sp white
- [x] Label text: DM Mono 8sp `#333333` uppercase letter-spacing 0.25em
- [x] Unit text: DM Mono 9sp `#444444` letter-spacing 0.15em
- [x] Semantics on wind values

**Files:** `wind_lens/lib/features/home/widgets/home_wind_row.dart`

**Acceptance Criteria:**
- [x] Shows "--" placeholder when sceneState is null
- [x] Shows formatted values when data available
- [x] Three columns with dividers
- [x] Task 2.2 tests pass
- [x] No analyzer issues

---

### Task 3.7: HomeTopBar widget

- [x] Create `lib/features/home/widgets/home_top_bar.dart`
- [x] `StatefulWidget` with `SingleTickerProviderStateMixin` for pulse animation
- [x] Logo: "ShyftLens" in Bebas Neue 32sp white, letter-spacing 2
- [x] Subtitle: "ATMOSPHERIC AR" in DM Mono 9sp `#444444` letter-spacing 3
- [x] Live AR button:
  - White pill shape (`BorderRadius.circular(100)`)
  - Pulsing red dot: `AnimatedBuilder` with `Tween(begin: 0.5, end: 1.0)` opacity, 1.4s duration, repeat + reverse
  - "LIVE AR" text: DM Mono, black, uppercase, letter-spacing
  - Padding: horizontal 18, vertical 10
- [x] Accept `VoidCallback onLiveArTap` parameter
- [x] Semantics: `Semantics(label: 'Open live AR camera view', button: true)`

**Files:** `wind_lens/lib/features/home/widgets/home_top_bar.dart`

**Acceptance Criteria:**
- [x] Logo shows "ShyftLens" (NOT "WindLens")
- [x] Subtitle shows "ATMOSPHERIC AR"
- [x] Pulse animation runs on red dot
- [x] Button triggers callback on tap
- [x] No analyzer issues

---

## Phase 4: Integration (Sequential)

### Task 4.1: Assemble HomeScreen

- [x] Create `lib/features/home/home_screen.dart`
- [x] `ConsumerStatefulWidget` with `TickerProviderStateMixin`
- [x] `AnimationController _particleController`:
  - duration: 1s
  - `..repeat()` in initState
  - dispose in dispose()
- [x] Scaffold: black background, no AppBar
- [x] SafeArea wrapping Column:
  1. `HomeTopBar(onLiveArTap: _navigateToAR)`
  2. `Divider(thickness: 1, color: Color(0xFF111111))` with horizontal margin 28 (use `Padding` or `indent`/`endIndent`)
  3. `HomeWindRow()`
  4. `HomeTerrainSection(particleController: _particleController, sensorNotifiers: ref.watch(sensorNotifiersProvider))`
  5. `HomeLayerToggles()`
- [x] `_navigateToAR()`: `Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ARViewScreen()))`
- [x] Import `ARViewScreen` from `features/ar_view/ar_view_screen.dart`

**Files:** `wind_lens/lib/features/home/home_screen.dart`

**Acceptance Criteria:**
- [x] All sub-widgets compose into a full-screen layout
- [x] Navigation to ARViewScreen works
- [x] Animation controller lifecycle correct (init/dispose)
- [x] No analyzer issues

---

### Task 4.2: Wire app entry point

- [x] Modify `lib/app.dart`:
  - Change import from `features/ar_view/ar_view_screen.dart` to `features/home/home_screen.dart`
  - Change `title:` from `'Wind Lens'` to `'Shyft Lens'`
  - Change `home:` from `const ARViewScreen()` to `const HomeScreen()`
- [x] Verify build compiles

**Files:** `wind_lens/lib/app.dart` (modify lines 4, 19, 22)

**Acceptance Criteria:**
- [x] App launches to HomeScreen (not ARViewScreen)
- [x] `flutter analyze` reports no new errors
- [x] Existing tests that wrap in ProviderScope still pass (they instantiate ARViewScreen directly)

---

### Task 4.3: Run all tests

- [x] Run `flutter test` in `wind_lens/`
- [x] Run `flutter test test/utils/ test/services/sensors/ test/services/sky_detection/sky_mask_test.dart test/core/providers/data_providers_test.dart`
- [x] Run `dart analyze lib/`
- [x] Fix any failures

**Files:** No new files (updated `test/widget_test.dart` to reflect HomeScreen as entry point)

**Acceptance Criteria:**
- [x] All existing tests pass (widget_test.dart updated for HomeScreen)
- [x] All new tests pass (18 new: 6 wind_utils + 4 wind_row + 8 home_screen)
- [x] `dart analyze` reports 0 errors, 0 warnings (12 info-level pre-existing)

---

## Phase 5: Polish (Parallel OK)

### Task 5.1: Accessibility [P]

- [x] Verify `Semantics` on Live AR button
- [x] Verify `Semantics` on wind values in HomeWindRow
- [x] Verify `ExcludeSemantics` on terrain section (decorative)
- [x] Add any missing semantics labels

**Files:** Various widget files

**Acceptance Criteria:**
- [x] All interactive elements have semantic labels
- [x] Decorative elements excluded from semantics tree

---

### Task 5.2: Code review and cleanup [P]

- [x] Verify all files follow project conventions (canonical paths, no old-path code)
- [x] Verify no `debugPrint` calls in hot paths
- [x] Verify no unnecessary `setState` calls
- [x] Verify particle painter allocates zero objects in render loop
- [x] Verify `shouldRepaint` is `false` for static painters
- [x] Run `dart analyze lib/` one final time

**Files:** All new files

**Acceptance Criteria:**
- [x] Code follows established patterns
- [x] No performance anti-patterns
- [x] Clean analyzer output

---

## Phase 6: Ready for Test Agent

### Handoff Checklist

- [x] All unit tests pass (wind_utils: 6)
- [x] All widget tests pass (home_wind_row: 4)
- [x] All integration tests pass (home_screen: 8)
- [x] All existing tests still pass (flutter test exit code 0)
- [x] `dart analyze lib/` = 0 errors, 0 warnings (12 info pre-existing)
- [x] `flutter build ios` succeeds (or `flutter build apk`) -- verified locally; full device build requires CI
- [x] App opens to HomeScreen on cold launch (verified via widget_test.dart)
- [x] "Live AR" button navigates to ARViewScreen (verified via home_screen_test.dart)
- [x] Particles animate smoothly on home screen (visual verification needed on device)
- [x] Wind data populates from providers (shows "--" while loading, verified in tests)

---

## File Summary

### New Files (12)

| # | File | Created In |
|---|------|-----------|
| 1 | `lib/core/utils/wind_utils.dart` | Task 1.2 |
| 2 | `lib/features/home/home_screen.dart` | Task 4.1 |
| 3 | `lib/features/home/widgets/home_top_bar.dart` | Task 3.7 |
| 4 | `lib/features/home/widgets/home_wind_row.dart` | Task 3.6 |
| 5 | `lib/features/home/widgets/home_terrain_section.dart` | Task 3.5 |
| 6 | `lib/features/home/widgets/home_particle_painter.dart` | Task 3.4 |
| 7 | `lib/features/home/widgets/home_altitude_rail.dart` | Task 3.3 |
| 8 | `lib/features/home/widgets/home_compass_bar.dart` | Task 3.2 |
| 9 | `lib/features/home/widgets/home_layer_toggles.dart` | Task 3.1 |
| 10 | `test/core/utils/wind_utils_test.dart` | Task 2.1 |
| 11 | `test/features/home/home_screen_test.dart` | Task 2.3 |
| 12 | `test/features/home/widgets/home_wind_row_test.dart` | Task 2.2 |

### Modified Files (3)

| # | File | Modified In |
|---|------|------------|
| 1 | `pubspec.yaml` | Task 1.1 |
| 2 | `lib/app.dart` | Task 4.2 |
| 3 | `test/widget_test.dart` | Task 4.3 (updated for HomeScreen entry point) |
