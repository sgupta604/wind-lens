# Research: app-performance-polish (On-Device Bugfixes)

## Metadata
- **Feature:** app-performance-polish (bugfix round)
- **Created:** 2026-03-05T21:00
- **Status:** research-complete
- **Researcher:** research-agent

## Feature Context

**From STATUS.md:**
- Feature: app-performance-polish (Streams 1-4 DONE, 4 on-device bugs found)
- Phase: diagnose-complete
- Branch: feature/app-performance-polish (uncommitted changes)
- Tests: 835 passing

**From diagnosis_v2.md:**
- 4 bugs found during on-device testing after Streams 1-4 implementation
- Bugs range from critical (crashes on every launch) to low (cosmetic removal)
- Diagnosis includes concrete fix plans with code snippets

## Requirements from Diagnosis

### Source
- `.claude/active-work/app-performance-polish/diagnosis_v2.md`

### Bug 1: Splash ValueNotifier Disposed Crash (CRITICAL)

- [ ] FR1: `sensorNotifiersProvider` must survive route transitions (splash -> home)
- [ ] FR2: ValueNotifiers (`heading`, `pitch`) must never be disposed while painters or ValueListenableBuilders still reference them
- [ ] TR1: Change `@riverpod` to `@Riverpod(keepAlive: true)` on `sensorNotifiers` function (line 97 of `sensor_providers.dart`)
- [ ] TR2: Regenerate `sensor_providers.g.dart` via `dart run build_runner build --delete-conflicting-outputs`
- [ ] TR3: Generated code must produce `Provider<SensorNotifiers>.internal(...)` (NOT `AutoDisposeProvider`)

#### Files to Modify
- `/workspace/wind_lens/lib/core/providers/sensor_providers.dart` -- line 97: annotation change
- `/workspace/wind_lens/lib/core/providers/sensor_providers.g.dart` -- auto-regenerated

#### Current Code (line 97-98)
```dart
@riverpod
SensorNotifiers sensorNotifiers(SensorNotifiersRef ref) {
```

#### Target Code
```dart
@Riverpod(keepAlive: true)
SensorNotifiers sensorNotifiers(SensorNotifiersRef ref) {
```

#### Consumers of `sensorNotifiersProvider` (must all continue working)
1. `lib/features/home/home_screen.dart:58` -- `ref.watch(sensorNotifiersProvider)` (will become `ref.read` in Bug 2 fix)
2. `lib/features/ar_view/ar_view_screen.dart:104` -- `ref.read(sensorNotifiersProvider).pitch.value`
3. `lib/features/ar_view/ar_view_screen.dart:168` -- `ref.watch(sensorNotifiersProvider)`
4. `test/features/home/home_screen_test.dart:23` -- `sensorNotifiersProvider.overrideWithValue(testNotifiers)`

#### Impact on ARViewScreen
- ARViewScreen also uses `ref.watch(sensorNotifiersProvider)` at line 168. This is inside `build()`, same pattern as HomeScreen. However, ARViewScreen is not the initial route and is pushed on top of HomeScreen, so the timing issue that causes Bug 1 (disposal during `pushReplacement` fade) does not apply to it. The keepAlive fix still benefits ARViewScreen by preventing accidental disposal if the user quickly exits and re-enters.

### Bug 2: HomeScreen Freeze on Return (CRITICAL)

- [ ] FR3: HomeScreen must not freeze when user returns from any sub-screen (Dome, AR, Map)
- [ ] FR4: No "setState() or markNeedsBuild() called during build" errors in console
- [ ] TR4: Replace `ref.watch(sensorNotifiersProvider)` with `ref.read(sensorNotifiersProvider)` in `initState()` of HomeScreen
- [ ] TR5: Store `SensorNotifiers` in a `late final` field, pass to `HomeTerrainSection` from there

#### Files to Modify
- `/workspace/wind_lens/lib/features/home/home_screen.dart` -- lines 36-58

#### Current Code (lines 36, 57-58)
```dart
class _HomeScreenState extends ConsumerState<HomeScreen> {
  // ...
  @override
  Widget build(BuildContext context) {
    final sensorNotifiers = ref.watch(sensorNotifiersProvider);
```

#### Target Code
```dart
class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final SensorNotifiers _sensorNotifiers;

  @override
  void initState() {
    super.initState();
    _sensorNotifiers = ref.read(sensorNotifiersProvider);
  }

  // ...
  @override
  Widget build(BuildContext context) {
    // _sensorNotifiers used directly, no ref.watch
```

#### Why `ref.read` Is Safe Here
- **Prerequisite:** Bug 1 fix makes `sensorNotifiersProvider` keepAlive, so the `SensorNotifiers` instance is stable for the app's lifetime.
- `SensorNotifiers` is a container for two `ValueNotifier<double>` objects -- it does not change identity. The individual notifiers' values change at 20-50Hz, but consumers read `.value` directly or use `ValueListenableBuilder`/`super(repaint:)`, not Riverpod rebuilds.
- `ref.watch` was causing Riverpod to mark HomeScreen for rebuild during provider flush, which collided with the framework's own build cycle.

#### Test Impact
- `test/features/home/home_screen_test.dart` uses `sensorNotifiersProvider.overrideWithValue(testNotifiers)` -- this continues to work because the override injects the value before `initState` runs. The `ref.read` in `initState` will pick up the overridden value.

#### Note on ARViewScreen
- ARViewScreen at line 168 also uses `ref.watch(sensorNotifiersProvider)` in `build()`. This does NOT need the same fix because:
  1. ARViewScreen is pushed on top of HomeScreen, not replacing it.
  2. When the user pops back from ARViewScreen, it is ARViewScreen that disposes, not HomeScreen.
  3. There have been no reports of freeze when returning FROM AR.
- If this becomes an issue later, the same `ref.read` pattern can be applied to ARViewScreen.

### Bug 3: Remove Compass Heading Line (LOW)

- [ ] FR5: Remove the vertical heading line from home terrain section
- [ ] FR6: Remove the `_HeadingLinePainter` class entirely
- [ ] TR6: Remove Layer 2 Positioned widget (lines 69-78 of `home_terrain_section.dart`)
- [ ] TR7: Remove `_HeadingLinePainter` class definition (lines 149-181 of `home_terrain_section.dart`)
- [ ] TR8: Renumber remaining layer comments (Layer 3 -> Layer 2, Layer 4 -> Layer 3, etc.)

#### Files to Modify
- `/workspace/wind_lens/lib/features/home/widgets/home_terrain_section.dart` -- two deletions

#### Code to Remove (lines 69-78)
```dart
          // Layer 2: Compass heading line
          Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: _HeadingLinePainter(
                  headingNotifier: widget.sensorNotifiers.heading,
                ),
              ),
            ),
          ),
```

#### Code to Remove (lines 149-181)
```dart
/// Vertical line tracking compass heading across terrain section.
/// ...
class _HeadingLinePainter extends CustomPainter {
  // entire class
}
```

#### Test Impact
- `test/features/home/widgets/home_terrain_section_test.dart` only tests `HomeTerrainPainter` (shouldRepaint). It does not reference `_HeadingLinePainter` (which is private). No test changes needed.
- However, the home_terrain_section test file and home_screen_test still reference `SensorNotifiers`. With keepAlive (Bug 1), the override still works.

#### Secondary Benefit
- Removing `_HeadingLinePainter` eliminates one consumer of `headingNotifier`, reducing the surface area for Bug 1. The `HomeCompassBar` still uses `headingNotifier` via `ValueListenableBuilder`, so the root fix (keepAlive) is still necessary.

### Bug 4: Dome Zoom Wrong for Large Domes (MEDIUM)

- [ ] FR7: When entering dome screen, camera zoom must match current dome size (not always default 1km)
- [ ] FR8: A 50km dome should show the full dome on entry, not super zoomed in
- [ ] TR9: Defer `_camR` initialization to first `build()` where `domeSizeProvider` is available
- [ ] TR10: Use nullable `_camR` or a `_camRInitialized` flag pattern

#### Files to Modify
- `/workspace/wind_lens/lib/features/wind_dome/wind_dome_screen.dart` -- lines 58, 166-178

#### Current Code (line 58)
```dart
double _camR = DomeConstants.camRMax * 0.85;  // Always 76.5
```

#### Problem Analysis
- `DomeConstants.camRMax` = `domeR * 5.0` = `18.0 * 5.0` = `90.0`
- Initial `_camR` = `90.0 * 0.85` = `76.5` (always)
- `domeSizeProvider` default = `1000.0` (1km)
- For 1km: computedDomeR = `1000 / 55.56` = `18.0`, camRMax should be `18.0 * 5.0 = 90.0`, so `76.5` is correct
- For 50km: computedDomeR = `50000 / 55.56` = `900.0`, camRMax should be `900.0 * 5.0 = 4500.0`, so `_camR` should be `~3825`, not `76.5`
- Camera at 76.5 render units inside a 900-unit dome is extremely close (inside the dome, zoomed to ~1.7% of what it should be)

#### Target Code Pattern
```dart
double? _camR;  // null until first build

// In build(), after computing computedDomeR:
_camR ??= computedDomeR * (DomeConstants.camRMax / DomeConstants.domeR) * 0.85;
```

Using `??=` is the cleanest approach: null-coalescing assignment only fires once (first build). After that, `_camR` keeps its value (which includes user pinch-zoom adjustments and `ref.listen` updates for dome size changes).

#### Gesture Handler Impact
- `_onPointerMove` at lines 326-329 uses `_camR` for pinch zoom. With nullable `_camR`, this code would need a null check. However, `_onPointerMove` can only fire after the first build (user must touch the screen, which means the widget is visible), so `_camR` will always be non-null by then.
- Safer approach: use `late double _camR` with a sentinel or the `??=` pattern in build(). The `??=` pattern is preferred because `late` would crash if accessed before first build (e.g., in an unexpected code path).

#### Test Impact
- No existing unit tests for `WindDomeScreen`'s camera initialization (it's a UI widget with a ticker). The fix is straightforward enough to verify by manual testing: enter dome with 50km preset, verify full dome is visible.

## Constraints

### Performance
- No performance impact from these fixes. Bug 1 (keepAlive) actually reduces overhead by preventing unnecessary provider recreation.
- Bug 3 (remove heading line painter) eliminates one CustomPainter from the home screen stack, reducing paint calls.

### Platform
- All fixes are pure Dart/Flutter -- no platform-specific changes needed.
- Bugs were observed on iOS real device; fixes apply to both iOS and Android.

### Build System
- Bug 1 requires `dart run build_runner build --delete-conflicting-outputs` to regenerate `sensor_providers.g.dart`.
- All other bugs are manual code changes with no codegen.

### Dependencies
- Bug 2 depends on Bug 1 (keepAlive must be in place before switching to `ref.read` in initState).
- Bug 3 is independent.
- Bug 4 is independent.

## Risk Assessment

### Technical Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| keepAlive prevents sensor cleanup on app background | Low | Low | `lifecycleProvider` already handles pause/resume of SensorService independently of provider disposal |
| `ref.read` in initState runs before override is set in tests | Medium | Low | Verified: `ProviderScope` overrides are applied before widget `initState` runs in `pumpWidget` |
| Removing heading line breaks tests | Low | Very Low | `_HeadingLinePainter` is private, no test references it directly |
| Nullable `_camR` causes null crash in gesture handler | Medium | Very Low | Gesture handlers can only fire after first build; `??=` ensures value is set by then |

### Complexity
- **Level:** Simple
- **Rationale:** All 4 bugs have clear root causes, concrete fix plans, and minimal code changes. No architectural redesign needed. Total changes: ~20 lines modified/removed across 3 files + 1 regenerated file.

## Open Questions

- [x] Q1: Should ARViewScreen also switch from `ref.watch` to `ref.read` for sensorNotifiers?
  - Resolution: No, not needed for MVP. ARViewScreen does not exhibit the same freeze bug. Can be done later if issues arise.

- [x] Q2: Should `gpsPositionProvider` and `rawSensorProvider` also be made keepAlive?
  - Resolution: No. These are stream providers that benefit from auto-dispose (they cancel subscriptions when unwatched). `sensorNotifiersProvider` is the only one that needs keepAlive because it owns ValueNotifier objects that external painters hold references to.

- [x] Q3: Does removing `_HeadingLinePainter` affect the `sensorNotifiers` parameter on `HomeTerrainSection`?
  - Resolution: No. `HomeCompassBar` (line 93-95 of home_terrain_section.dart) still uses `widget.sensorNotifiers.heading`, so the `sensorNotifiers` parameter must remain.

- [x] Q4: For Bug 4, should we also fix the initial `_theta` and `_phi` for large domes?
  - Resolution: No. `_theta` and `_phi` are view angles (radians), not distances. They are the same regardless of dome size. Only `_camR` (camera distance) needs to scale.

## Recommended Approach

### Implementation Strategy
Apply fixes in dependency order. All changes are small and well-understood from the diagnosis.

### Order of Work
1. **Bug 1 (keepAlive)** -- Single annotation change + codegen. Prerequisite for Bug 2.
2. **Bug 3 (remove heading line)** -- Pure deletion, independent. Doing it before Bug 2 reduces the number of headingNotifier consumers, making Bug 1's fix more complete.
3. **Bug 2 (ref.read in initState)** -- Depends on Bug 1. Small refactor in home_screen.dart.
4. **Bug 4 (dome zoom)** -- Independent. Small refactor in wind_dome_screen.dart.

### What to Defer (Not MVP Critical)
- ARViewScreen `ref.watch` -> `ref.read` conversion (no reported bug, can be done later)
- Memory leak audit for keepAlive provider (sensor streams are lightweight, no concern for MVP)

### Files Modified (Summary)
| File | Change | Bug |
|------|--------|-----|
| `lib/core/providers/sensor_providers.dart` | `@riverpod` -> `@Riverpod(keepAlive: true)` | Bug 1 |
| `lib/core/providers/sensor_providers.g.dart` | Regenerated (auto) | Bug 1 |
| `lib/features/home/home_screen.dart` | `ref.watch` -> `ref.read` in initState | Bug 2 |
| `lib/features/home/widgets/home_terrain_section.dart` | Remove `_HeadingLinePainter` class + usage | Bug 3 |
| `lib/features/wind_dome/wind_dome_screen.dart` | Deferred `_camR` init with `??=` | Bug 4 |

### Estimated Scope
- ~5 lines changed (Bugs 1, 2, 4)
- ~45 lines removed (Bug 3)
- 1 file regenerated (codegen)
- No new files

## Next Step

**All questions resolved.** Run `/plan app-performance-polish` to create the implementation plan for these 4 bugfixes.
