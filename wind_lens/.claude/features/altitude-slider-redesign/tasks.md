# Tasks: altitude-slider-redesign

## Metadata
- **Feature:** altitude-slider-redesign
- **Created:** 2026-03-03T04:00 UTC
- **Status:** implementation-complete
- **Based on:** `2026-03-03T04:00_plan.md`

## Execution Rules
- Tasks are numbered by phase (e.g., Task 1.1, Task 2.1)
- [P] marks tasks that CAN run in parallel within their phase
- Tasks within a phase are sequential unless marked [P]
- Phases must be completed in order (Phase 1 before Phase 2, etc.)
- Completion: check the box when done
- TDD: Phase 2 writes tests BEFORE Phase 3 implementation

---

## Phase 1: Enum Expansion + Codegen (Sequential -- foundation for everything else)

### Task 1.1: Expand AltitudeLevel Enum

- [x] Add 3 new enum values: `level700`, `level500`, `level300` (in order between `midLevel` and `jetStream`)
- [x] Add cases to `displayName`: `level700 => '700 hPa'`, `level500 => '500 hPa'`, `level300 => '300 hPa'`
- [x] Update `midLevel.displayName` from `'Cloud Level'` to `'850 hPa'`
- [x] Update `jetStream.displayName` from `'Jet Stream'` to `'250 hPa'`
- [x] Add cases to `metersAGL`: `level700 => 3000.0`, `level500 => 5500.0`, `level300 => 9000.0`
- [x] Add cases to `particleColor`: `level700 => Color(0xAA00AAFF)`, `level500 => Color(0xAA8855FF)`, `level300 => Color(0xAABB33FF)`
- [x] Add cases to `particleSpeedMultiplier`: `level700 => 1.8`, `level500 => 2.2`, `level300 => 2.7`
- [x] Add cases to `parallaxFactor`: `level700 => 0.5`, `level500 => 0.4`, `level300 => 0.35`
- [x] Add cases to `trailScale`: `level700 => 0.65`, `level500 => 0.6`, `level300 => 0.55`
- [x] Add cases to `streamlineTrailPoints`: `level700 => 20`, `level500 => 22`, `level300 => 24`
- [x] Update doc comments to reflect 6 levels instead of 3

**Files:** `lib/core/models/altitude_level.dart`

**Acceptance Criteria:**
- [x] Enum has exactly 6 values in order: `surface`, `midLevel`, `level700`, `level500`, `level300`, `jetStream`
- [x] All 7 extension properties have exhaustive switch expressions with 6 cases each
- [x] Doc comments updated to show all 6 levels

---

### Task 1.2: Run Freezed Codegen

- [x] Run `dart run build_runner build --delete-conflicting-outputs` from `wind_lens/` directory
- [x] Verify `wind_data.g.dart` has 6 entries in `_$AltitudeLevelEnumMap`
- [x] Verify `wind_data.freezed.dart` regenerated without errors
- [x] Verify `scene_state.freezed.dart` regenerated without errors
- [x] Verify `data_providers.g.dart` regenerated without errors
- [x] Run `dart analyze lib/` and confirm zero errors

**Files:** Auto-generated: `wind_data.g.dart`, `wind_data.freezed.dart`, `scene_state.freezed.dart`, `data_providers.g.dart`

**Acceptance Criteria:**
- [x] All generated files compile without errors
- [x] `dart analyze lib/` reports zero errors
- [x] `_$AltitudeLevelEnumMap` contains all 6 enum values

---

### Task 1.3: Fix Compile Errors in Production Code

- [x] `ogc_edr_wind_source.dart`: Add 3 cases to `_altitudeToPressure()`: `level700 => 700`, `level500 => 500`, `level300 => 300`
- [x] `home_wind_row.dart`: Add 3 cases to `_altitudeValue()`: `level700 => '9.8K'`, `level500 => '18K'`, `level300 => '29.5K'`
- [x] `altitude_slider.dart`: Add 3 cases to `_getLabel()`: `level700 => '700'`, `level500 => '500'`, `level300 => '300'`
- [x] `altitude_slider.dart`: Update `_levelFromY()` to handle 6 segments
- [x] Run `dart analyze lib/` and confirm zero errors

**Files:** `lib/services/wind/ogc_edr_wind_source.dart`, `lib/features/home/widgets/home_wind_row.dart`, `lib/features/ar_view/widgets/altitude_slider.dart`

**Acceptance Criteria:**
- [x] All production code compiles without errors
- [x] `dart analyze lib/` reports zero errors
- [x] `_altitudeToPressure()` returns correct pressure for all 6 levels

---

## Phase 2: Tests (TDD -- write tests before implementation)

### Task 2.1: Update Altitude Level Tests [P]

- [x] Update "has exactly 3 values" test to assert 6 values: `surface`, `midLevel`, `level700`, `level500`, `level300`, `jetStream`
- [x] Add `displayName` tests for new values: `'700 hPa'`, `'500 hPa'`, `'300 hPa'`
- [x] Update existing `midLevel.displayName` test: `'Cloud Level'` -> `'850 hPa'`
- [x] Update existing `jetStream.displayName` test: `'Jet Stream'` -> `'250 hPa'`
- [x] Add `metersAGL` tests for new values: 3000.0, 5500.0, 9000.0
- [x] Add `particleColor` tests for new values
- [x] Add `particleSpeedMultiplier` tests for new values: 1.8, 2.2, 2.7
- [x] Add `parallaxFactor` tests for new values: 0.5, 0.4, 0.35
- [x] Add `trailScale` tests for new values: 0.65, 0.6, 0.55
- [x] Add `streamlineTrailPoints` tests for new values: 20, 22, 24
- [x] Run tests: `flutter test test/models/altitude_level_test.dart` -- 25 passing

**Files:** `test/models/altitude_level_test.dart`

**Acceptance Criteria:**
- [x] All altitude level property tests pass for all 6 values
- [x] Value ordering test passes

---

### Task 2.2: Update OGC EDR Wind Source Tests [P]

- [x] Add test: `level700 maps to pressure 700`
- [x] Add test: `level500 maps to pressure 500`
- [x] Add test: `level300 maps to pressure 300`
- [x] Run tests: `flutter test test/services/wind/ogc_edr_wind_source_test.dart` -- 16 passing

**Files:** `test/services/wind/ogc_edr_wind_source_test.dart`

**Acceptance Criteria:**
- [x] All pressure level mapping tests pass
- [x] Existing surface (0), midLevel (850), jetStream (250) tests still pass

---

### Task 2.3: Write Altitude Slider Widget Tests [P]

- [x] Test: starts collapsed showing current level label
- [x] Test: renders all 6 stop labels when expanded ("SFC", "850", "700", "500", "300", "250")
- [x] Test: tapping collapsed pill expands the panel
- [x] Test: selecting a stop collapses the panel and calls onChanged
- [x] Test: tapping a stop calls onChanged with correct AltitudeLevel
- [x] Test: expanded panel has minimum 48px touch target height
- [x] Test: does not call onChanged when tapping already selected segment
- [x] Test: uses glassmorphism styling (BackdropFilter)
- [x] Test: has ClipRRect for rounded corners
- [x] Test: calls onChanged when dragging between segments
- [x] Test: initial value matches value parameter
- [x] Test: widget has correct width (60px)
- [x] Test: renders 6 colored dots when expanded
- [x] Test: shows altitude readout when expanded
- [x] Test: altitude readout not visible when collapsed
- [x] Test: has AnimatedSize for expand/collapse animation
- [x] Run tests: `flutter test test/widgets/altitude_slider_test.dart` -- 18 passing

**Files:** `test/widgets/altitude_slider_test.dart`

**Acceptance Criteria:**
- [x] All new slider tests pass
- [x] Tests cover tap, drag, rendering, expand/collapse, and accessibility

---

### Task 2.4: Update Home Wind Row Tests [P]

- [x] Add test for `level700` altitude display value ('9.8K')
- [x] Add test for `level500` altitude display value ('18K')
- [x] Add test for `level300` altitude display value ('29.5K')
- [x] Run tests: `flutter test test/features/home/widgets/home_wind_row_test.dart` -- 7 passing

**Files:** `test/features/home/widgets/home_wind_row_test.dart`

**Acceptance Criteria:**
- [x] All home wind row tests pass for all 6 altitude levels

---

### Task 2.5: Write Dome Info Bar Altitude Label Test [P]

- [x] Add test: dome info bar renders altitude range text ("Surface - 1800m")
- [x] Run tests: `flutter test test/features/wind_dome/widgets/dome_info_bar_test.dart` -- 10 passing

**Files:** `test/features/wind_dome/widgets/dome_info_bar_test.dart`

**Acceptance Criteria:**
- [x] Altitude range label test passes

---

## Phase 3: Core Implementation (Sequential)

### Task 3.1: Redesign Home Altitude Rail

- [x] Replace 5-tick `_ticks` list with 6 ticks (all mapping to real `AltitudeLevel` values)
- [x] Update tick labels to use pressure format (250 hPa, 300 hPa, ..., Surface)
- [x] Remove decorative ticks (no more null-level ticks)
- [x] Keep existing styling (DM Mono, white/dim colors, triangle indicator)
- [x] All 6 ticks are tappable (all have non-null `level`)
- [x] Add Semantics labels to ticks
- [x] Run tests to verify

**Files:** `lib/features/home/widgets/home_altitude_rail.dart`

**Acceptance Criteria:**
- [x] 6 ticks rendered, all tappable
- [x] Active tick shows white text + triangle + wider line
- [x] Tapping a tick updates `selectedAltitudeProvider`

---

### Task 3.2: Rewrite AR Altitude Slider as Collapsible Toggle

- [x] Convert to StatefulWidget (needs local `_isExpanded` state)
- [x] Collapsed (default): pill-shaped button ~60px wide showing current level dot + short label
- [x] Expanded: vertical panel with 6 stops (jetStream at top, surface at bottom)
- [x] Define `_levels` list: all 6 `AltitudeLevel` values in top-to-bottom order
- [x] Define `_getLabel()` for 6 values: `'250'`, `'300'`, `'500'`, `'700'`, `'850'`, `'SFC'`
- [x] Each stop: colored dot + label, selected stop highlighted
- [x] Tapping a stop: calls onChanged, collapses panel
- [x] Tapping collapsed button: toggles expanded/collapsed
- [x] Keep drag gesture support when expanded (haptic feedback on level transitions)
- [x] Keep glassmorphism styling (BackdropFilter + blur)
- [x] Animate expand/collapse with AnimatedSize
- [x] Show altitude readout when expanded: meters value (e.g., "5,500m")
- [x] Run tests: `flutter test test/widgets/altitude_slider_test.dart` -- 18 passing

**Files:** `lib/features/ar_view/widgets/altitude_slider.dart`

**Acceptance Criteria:**
- [x] Collapsed by default, shows current altitude
- [x] Tap toggles expanded/collapsed
- [x] 6 stops rendered when expanded with correct labels and colors
- [x] Selecting a stop collapses the panel
- [x] Haptic feedback on transitions
- [x] Altitude readout visible when expanded
- [x] All slider tests pass

---

### Task 3.3: Add Dome Altitude Range Label + Fix GPS Chip Overlap

- [x] Add a Text widget row below the size preset buttons in `DomeInfoBar`
- [x] Show altitude range: `'Surface - ${DomeConstants.maxAltitudeMeters.toInt()}m'` (evaluates to 'Surface - 1800m')
- [x] Style: small text, subdued color (white54), centered
- [x] Add Semantics label for accessibility
- [x] Fix GPS/location chip overlap: increased offset from `top + 56` to `top + 100` in wind_dome_screen.dart

**Files:** `lib/features/wind_dome/widgets/dome_info_bar.dart`, `lib/features/wind_dome/wind_dome_screen.dart`

**Acceptance Criteria:**
- [x] Altitude range label visible in dome info bar
- [x] Label reads "Surface - 1800m"
- [x] LocationIndicatorChip does NOT overlap the radius selector buttons
- [x] Dome info bar test passes

---

## Phase 4: Integration Verification (Sequential)

### Task 4.1: Run Full Test Suite

- [x] Run `flutter test` -- 775 passing, 0 failures
- [x] Run additional test paths -- 47 passing
- [x] Fix info_bar_test.dart ("Cloud Level" -> "850 hPa") -- fixed
- [x] Run `dart analyze lib/` -- zero errors
- [x] Run `dart analyze test/` -- zero errors

**Files:** All test files

**Acceptance Criteria:**
- [x] All 775 tests pass
- [x] `dart analyze lib/` reports zero errors
- [x] `dart analyze test/` reports zero errors

---

### Task 4.2: Verify Codegen Consistency

- [x] Run `dart run build_runner build --delete-conflicting-outputs` one final time
- [x] Verify no generated file diffs (codegen is idempotent) -- second run: "wrote 0 outputs"
- [x] All tests still pass after regeneration

**Files:** All generated files

**Acceptance Criteria:**
- [x] Codegen produces identical output (no diffs)
- [x] All tests still pass after regeneration

---

## Phase 5: Polish (Parallel OK)

### Task 5.1: Update Doc Comments [P]

- [x] Update `altitude_level.dart` class-level doc comment to list all 6 levels
- [x] Update `ogc_edr_wind_source.dart` class-level doc comment to list all 6 pressure mappings
- [x] Update `altitude_slider.dart` class-level doc comment for new collapsible slider design
- [x] Verify all public API doc comments are accurate

**Files:** `lib/core/models/altitude_level.dart`, `lib/services/wind/ogc_edr_wind_source.dart`, `lib/features/ar_view/widgets/altitude_slider.dart`

**Acceptance Criteria:**
- [x] Doc comments reflect 6-level system accurately

---

### Task 5.2: Verify Accessibility [P]

- [x] All 6 slider stops have 48px touch targets (segmentHeight = 48.0)
- [x] Altitude readout has Semantics label
- [x] Home altitude rail ticks have Semantics labels (with button + selected attributes)
- [x] Dome altitude range label has Semantics label

**Files:** `lib/features/ar_view/widgets/altitude_slider.dart`, `lib/features/home/widgets/home_altitude_rail.dart`, `lib/features/wind_dome/widgets/dome_info_bar.dart`

**Acceptance Criteria:**
- [x] All interactive elements meet 48px minimum touch target
- [x] Screen reader labels are meaningful

---

## Phase 6: Ready for Test Agent

### Pre-Handoff Checklist

- [x] All unit tests pass
- [x] All widget tests pass
- [x] `dart analyze lib/` zero errors
- [x] `dart analyze test/` zero errors
- [x] `flutter test` full suite passes (775 tests)
- [x] Codegen consistent (build_runner idempotent)
- [x] No TODO comments left in modified files

### What the Test Agent Should Verify

On a real device:
- [ ] AR slider shows collapsed pill by default, tap to expand to 6 stops
- [ ] Selecting a stop collapses the slider and updates wind data
- [ ] Drag and tap both work when expanded
- [ ] Altitude readout displays correct meters when expanded (e.g., "5,500m")
- [ ] Haptic feedback on each snap transition
- [ ] Wind data changes when selecting different altitudes (visible particle speed/color change)
- [ ] Home screen altitude rail shows 6 ticks, all tappable
- [ ] Home wind row shows correct altitude value for each level
- [ ] Dome info bar shows "Surface - 1800m" altitude range label
- [ ] Dome GPS chip no longer overlaps radius selector buttons
- [ ] No performance regression (particles still 60 FPS)
- [ ] No visual glitches on slider at top/bottom edges
