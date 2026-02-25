# SPEC-001: Wind Lens Architectural Foundation Refactor

## Overview

Wind Lens needs an architectural refactor **before** building the remaining Phase 2b features (HeyWhatsThat client, terrain sky detection, OGC EDR wind data, photo capture). The goal is to establish a reactive data pipeline where all data sources stay in sync, downstream data automatically invalidates when upstream sources change, and new features plug in as modules behind stable interfaces — not as rewiring jobs.

This is NOT a rewrite. The app works end-to-end with 26 source files and 405 passing tests. This refactor wraps existing working code in proper abstractions and wires them into a dependency graph.

---

## Current App State (for context)

**Working features:**
- Camera feed with AR overlay
- Compass heading + pitch detection (flutter_compass)
- Sky detection (auto-calibrating HSV color-based — samples sky colors, builds HSV profile, masks particles to sky pixels)
- 2000 particles at 45+ FPS with speed-based color gradients (blue → purple)
- Altitude slider (Surface / Mid-level / Jet Stream) with depth parallax
- World-anchored wind animation (particles stay fixed to sky as you pan)
- Compass widget (glassmorphism, bottom-left corner)
- Debug panel showing all metrics
- GPS location service (just shipped, P2B-001)

**Coming soon (must be supported by this architecture):**
- HeyWhatsThat API client for terrain-based horizon profiles
- Horizon caching (HWT computation takes ~2 min)
- Terrain-based sky mask (maps horizon onto camera view)
- Detection mode toggle (HSV / Terrain / Combined)
- OGC EDR API for real wind data (replaces mock/fake wind)
- Photo capture + panoramic overlay (separate spec)

---

## Task 1: Add Freezed to All Core Models

### Why
Riverpod uses equality checks to decide whether to rebuild. Without proper equality (`==` and `hashCode`) on your data models, you'll get phantom rebuilds on every sensor tick, killing your 50fps. Freezed gives you immutability, `copyWith`, equality, and pattern matching for free.

### Dependencies to Add
```yaml
# pubspec.yaml
dependencies:
  freezed_annotation: ^2.4.1

dev_dependencies:
  freezed: ^2.4.5
  build_runner: ^2.4.6
  json_serializable: ^6.7.1  # for cache serialization later
```

### Models to Create/Convert

Create these in `lib/core/models/`. Every model gets a Freezed class:

#### `position_data.dart`
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'position_data.freezed.dart';
part 'position_data.g.dart';

@freezed
class PositionData with _$PositionData {
  const factory PositionData({
    required double latitude,
    required double longitude,
    required double altitude,
    required double accuracy,
    required DateTime timestamp,
  }) = _PositionData;

  factory PositionData.fromJson(Map<String, dynamic> json) =>
      _$PositionDataFromJson(json);
}
```

#### `wind_data.dart`
```dart
@freezed
class WindData with _$WindData {
  const factory WindData({
    required double speed,        // m/s
    required double direction,    // degrees (meteorological, where wind comes FROM)
    required double gustSpeed,    // m/s
    required AltitudeLevel altitude,
    required DateTime timestamp,
  }) = _WindData;

  factory WindData.fromJson(Map<String, dynamic> json) =>
      _$WindDataFromJson(json);
}

enum AltitudeLevel { surface, midLevel, jetStream }
```

#### `horizon_profile.dart`
```dart
@freezed
class HorizonProfile with _$HorizonProfile {
  const factory HorizonProfile({
    required double latitude,
    required double longitude,
    /// Map of bearing (0-360) to elevation angle in degrees
    /// Elevation angle = how many degrees above horizontal the terrain reaches
    required Map<double, double> elevationAngles,
    required DateTime fetchedAt,
  }) = _HorizonProfile;

  factory HorizonProfile.fromJson(Map<String, dynamic> json) =>
      _$HorizonProfileFromJson(json);

  /// Get interpolated elevation angle for any bearing
  double getElevationAtBearing(double bearing);
}
```

#### `sky_mask.dart`
```dart
@freezed
class SkyMask with _$SkyMask {
  const factory SkyMask({
    required int width,
    required int height,
    /// Row-major boolean array: true = sky, false = not sky
    required List<bool> pixels,
    required SkyDetectionMethod method,
  }) = _SkyMask;
}

enum SkyDetectionMethod { hsv, terrain, combined }
```

#### `sensor_state.dart`
```dart
@freezed
class SensorState with _$SensorState {
  const factory SensorState({
    required double compassHeading,  // degrees, 0 = north
    required double pitch,           // degrees, 0 = horizontal, 90 = straight up
    required DateTime timestamp,
  }) = _SensorState;
}
```

#### `scene_state.dart` — The big one. This is the composed state your renderer consumes.
```dart
@freezed
class SceneState with _$SceneState {
  const factory SceneState({
    required PositionData position,
    required HorizonProfile horizon,
    required WindData wind,
    required double compassHeading,
    required double pitch,
    required SkyMask skyMask,
    required AltitudeLevel selectedAltitude,
    required DateTime timestamp,
  }) = _SceneState;
}
```

### Run code generation
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Migration notes
- Find every place in the existing codebase where position, wind, compass, or pitch data is represented as raw doubles/maps/custom classes
- Replace with the Freezed models
- Existing tests should still pass after migration — the data shapes shouldn't change, just how they're constructed

---

## Task 2: Define Service Interfaces (Abstractions)

### Why
The app is about to have multiple implementations of the same capability (HSV vs terrain sky detection, mock vs real wind data). Coding against interfaces means swapping implementations is a provider-level change, not a surgery across the rendering pipeline.

### Rule: Nothing in `lib/core/services/` imports Flutter material or widgets.

These are pure Dart classes. They take data in, return data out. This makes them unit-testable without a device.

### `lib/core/services/sky_detector.dart`
```dart
/// Produces a SkyMask from a camera frame and sensor readings.
/// Implementations decide HOW to detect sky (color, terrain, ML, combined).
abstract class SkyDetector {
  Future<SkyMask> detect({
    required CameraFrame frame,
    required SensorState sensors,
    HorizonProfile? horizon,  // optional — only terrain/combined need this
  });

  /// Human-readable name for debug overlay
  String get name;
}
```

Implementations:
- `HsvSkyDetector` — wraps your existing auto-calibrating HSV logic
- `TerrainSkyDetector` — uses HorizonProfile + heading + pitch to compute sky boundary geometrically (to be built in Phase 2b feature #4)
- `CombinedSkyDetector` — terrain sets the horizon line, HSV catches foreground obstacles above the horizon (to be built in Phase 2b feature #5)

### `lib/core/services/wind_data_source.dart`
```dart
/// Provides wind field data for a given location and altitude.
abstract class WindDataSource {
  Future<WindData> getWind({
    required PositionData position,
    required AltitudeLevel altitude,
  });

  /// Whether this source provides real or simulated data
  bool get isSimulated;
}
```

Implementations:
- `MockWindDataSource` — what you have now (generated/hardcoded wind)
- `OgcEdrWindDataSource` — real wind from OGC EDR API (to be built in Phase 2b feature #6)

### `lib/core/services/horizon_provider.dart`
```dart
/// Fetches terrain horizon profiles for a given location.
abstract class HorizonProvider {
  Future<HorizonProfile> getHorizon({
    required double latitude,
    required double longitude,
  });
}
```

Implementations:
- `HeyWhatsThatHorizonProvider` — calls the HWT API (to be built in Phase 2b feature #2)
- `MockHorizonProvider` — returns a flat horizon (0° elevation at all bearings) for testing and indoor use
- `CachedHorizonProvider` — decorator that wraps any `HorizonProvider` with local caching (to be built in Phase 2b feature #3)

### `lib/core/services/sensor_service.dart`
```dart
/// Unified sensor access. Wraps platform-specific sensor APIs.
abstract class SensorService {
  Stream<SensorState> get sensorStream;
  Stream<PositionData> get positionStream;
  void pause();
  void resume();
  void dispose();
}
```

Implementation:
- `DeviceSensorService` — wraps flutter_compass + accelerometer + geolocator into unified streams
- `MockSensorService` — emits controllable fake data for testing

### Migration approach
- Wrap your existing HSV sky detection code inside `HsvSkyDetector implements SkyDetector`
- Wrap your existing wind generation code inside `MockWindDataSource implements WindDataSource`
- Wrap your existing compass/GPS code inside `DeviceSensorService implements SensorService`
- No behavior changes — just wrapping in interfaces

---

## Task 3: Set Up Riverpod Provider Dependency Graph

### Why
This is the core of the sync problem. When GPS updates, the horizon profile and wind data should automatically refetch, and the scene state should recompose when they resolve. No manual wiring, no callbacks, no event buses.

### Install Riverpod
```yaml
dependencies:
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3

dev_dependencies:
  riverpod_generator: ^2.3.9
  # build_runner already added for Freezed
```

### Provider Graph Structure

```
                    DATA FLOW DIAGRAM
                    =================

LAYER 1: Raw Sensor Streams (hardware-rate updates)
─────────────────────────────────────────────────────
  gpsPositionProvider (Stream<PositionData>)
  rawSensorProvider (Stream<SensorState>)  ← compass + pitch

LAYER 2: Stabilized/Debounced Values
─────────────────────────────────────────────────────
  stablePositionProvider (PositionData?)
    └── watches: gpsPositionProvider
    └── logic: only propagates if moved >100m from last emitted

LAYER 3: Derived API Data (refetches when position changes)
─────────────────────────────────────────────────────
  horizonProfileProvider (AsyncValue<HorizonProfile>)
    └── watches: stablePositionProvider
    └── auto-refetches when position changes significantly

  windDataProvider (AsyncValue<WindData>)
    └── watches: stablePositionProvider, selectedAltitudeProvider
    └── auto-refetches when position or altitude changes

LAYER 4: Sky Detection
─────────────────────────────────────────────────────
  skyDetectorProvider (SkyDetector)
    └── watches: detectionModeProvider
    └── returns the right SkyDetector implementation

  skyMaskProvider (AsyncValue<SkyMask>)
    └── watches: skyDetectorProvider, horizonProfileProvider, rawSensorProvider
    └── runs detection on each camera frame

LAYER 5: Composed Scene State
─────────────────────────────────────────────────────
  sceneStateProvider (SceneState?)
    └── watches: ALL of the above
    └── only emits when ALL required data is available
    └── null while any upstream is still loading

LAYER 6: UI State
─────────────────────────────────────────────────────
  selectedAltitudeProvider (AltitudeLevel)
    └── state: user's altitude slider selection

  detectionModeProvider (SkyDetectionMethod)
    └── state: user's detection mode toggle
```

### Provider Implementations

#### `lib/core/providers/sensor_providers.dart`
```dart
@riverpod
Stream<PositionData> gpsPosition(Ref ref) {
  final sensorService = ref.watch(sensorServiceProvider);
  return sensorService.positionStream;
}

@riverpod
Stream<SensorState> rawSensor(Ref ref) {
  final sensorService = ref.watch(sensorServiceProvider);
  return sensorService.sensorStream;
}

/// Debounced position — only propagates when user moves significantly.
/// Prevents thrashing the HeyWhatsThat and weather APIs on GPS jitter.
@riverpod
class StablePosition extends _$StablePosition {
  PositionData? _lastEmitted;

  @override
  PositionData? build() {
    final raw = ref.watch(gpsPositionProvider).valueOrNull;
    if (raw == null) return _lastEmitted;

    if (_lastEmitted == null || _distanceMeters(_lastEmitted!, raw) > 100) {
      _lastEmitted = raw;
      return raw;
    }
    return _lastEmitted;
  }

  double _distanceMeters(PositionData a, PositionData b) {
    // Use Geolocator.distanceBetween or haversine formula
    // Returns distance in meters
  }
}
```

#### `lib/core/providers/data_providers.dart`
```dart
@riverpod
Future<HorizonProfile> horizonProfile(Ref ref) async {
  final position = ref.watch(stablePositionProvider);
  if (position == null) throw StateError('No GPS fix yet');

  final provider = ref.watch(horizonProviderProvider);
  return provider.getHorizon(
    latitude: position.latitude,
    longitude: position.longitude,
  );
}

@riverpod
Future<WindData> windData(Ref ref) async {
  final position = ref.watch(stablePositionProvider);
  if (position == null) throw StateError('No GPS fix yet');

  final altitude = ref.watch(selectedAltitudeProvider);
  final source = ref.watch(windDataSourceProvider);
  return source.getWind(position: position, altitude: altitude);
}
```

#### `lib/core/providers/scene_provider.dart`
```dart
@riverpod
SceneState? sceneState(Ref ref) {
  final position = ref.watch(stablePositionProvider);
  final horizon = ref.watch(horizonProfileProvider).valueOrNull;
  final wind = ref.watch(windDataProvider).valueOrNull;
  final sensor = ref.watch(rawSensorProvider).valueOrNull;
  final skyMask = ref.watch(skyMaskProvider).valueOrNull;
  final altitude = ref.watch(selectedAltitudeProvider);

  // Only produce a scene when all critical data is available
  if (position == null || wind == null || sensor == null) return null;

  return SceneState(
    position: position,
    horizon: horizon ?? HorizonProfile.flat(position),  // fallback to flat if no terrain data yet
    wind: wind,
    compassHeading: sensor.compassHeading,
    pitch: sensor.pitch,
    skyMask: skyMask ?? SkyMask.fullSky(),  // fallback to "everything is sky" while loading
    selectedAltitude: altitude,
    timestamp: DateTime.now(),
  );
}
```

### Key decision: fallback vs. block

The `sceneState` provider above uses **fallback** for horizon and sky mask (show particles everywhere while terrain data loads) but **blocks** on position and wind (can't render anything without knowing wind direction). This means:
- App shows camera feed immediately on launch
- Particles appear as soon as wind data resolves (even with no terrain data)
- Particles refine to sky-only regions once terrain/sky detection kicks in
- This looks like the wind "fading in" — actually a nice UX

---

## Task 4: Directory Structure Refactor

### Target structure
```
lib/
├── core/
│   ├── models/                    # Freezed data classes
│   │   ├── position_data.dart
│   │   ├── wind_data.dart
│   │   ├── horizon_profile.dart
│   │   ├── sky_mask.dart
│   │   ├── sensor_state.dart
│   │   └── scene_state.dart
│   ├── services/                  # Pure Dart — NO Flutter imports
│   │   ├── sky_detector.dart      # Abstract interface
│   │   ├── wind_data_source.dart  # Abstract interface
│   │   ├── horizon_provider.dart  # Abstract interface
│   │   └── sensor_service.dart    # Abstract interface
│   ├── providers/                 # Riverpod provider graph
│   │   ├── sensor_providers.dart
│   │   ├── data_providers.dart
│   │   ├── scene_provider.dart
│   │   └── service_providers.dart # DI — binds interfaces to implementations
│   └── utils/                     # Shared helpers (math, conversions)
│       ├── geo_math.dart
│       └── angle_utils.dart
├── services/                      # Concrete implementations
│   ├── sky_detection/
│   │   ├── hsv_sky_detector.dart       # Existing HSV logic, wrapped
│   │   ├── terrain_sky_detector.dart   # Phase 2b feature #4
│   │   └── combined_sky_detector.dart  # Phase 2b feature #5
│   ├── wind/
│   │   ├── mock_wind_source.dart       # Existing fake wind, wrapped
│   │   └── ogc_edr_wind_source.dart    # Phase 2b feature #6
│   ├── horizon/
│   │   ├── mock_horizon_provider.dart
│   │   ├── hwt_horizon_provider.dart   # Phase 2b feature #2
│   │   └── cached_horizon_provider.dart # Phase 2b feature #3
│   └── sensors/
│       ├── device_sensor_service.dart  # Real device sensors
│       └── mock_sensor_service.dart    # For testing
├── features/
│   ├── ar_view/                   # Camera + particle rendering
│   │   ├── ar_view_screen.dart
│   │   ├── particle_renderer.dart # CustomPainter — consumes SceneState
│   │   └── widgets/
│   │       ├── altitude_slider.dart
│   │       ├── compass_widget.dart
│   │       └── debug_overlay.dart
│   ├── snapshot/                  # Photo capture (separate spec)
│   │   └── ...
│   └── settings/
│       └── ...
└── app.dart                       # ProviderScope + MaterialApp
```

### The critical rule
`lib/core/` should NEVER import from `lib/features/` or `lib/services/` (concrete implementations). Data flows one way: features import core, services implement core interfaces, providers wire them together.

### Service provider bindings (dependency injection)
```dart
// lib/core/providers/service_providers.dart

@riverpod
SkyDetector skyDetectorInstance(Ref ref) {
  final mode = ref.watch(detectionModeProvider);
  final horizon = ref.watch(horizonProfileProvider).valueOrNull;

  switch (mode) {
    case SkyDetectionMethod.hsv:
      return HsvSkyDetector();
    case SkyDetectionMethod.terrain:
      return TerrainSkyDetector(horizon: horizon);
    case SkyDetectionMethod.combined:
      return CombinedSkyDetector(
        hsv: HsvSkyDetector(),
        terrain: TerrainSkyDetector(horizon: horizon),
      );
  }
}

@riverpod
WindDataSource windDataSourceInstance(Ref ref) {
  // Swap this one line when OGC EDR is ready
  return MockWindDataSource();
}

@riverpod
HorizonProvider horizonProviderInstance(Ref ref) {
  // Swap this when HeyWhatsThat client is ready
  // Later: return CachedHorizonProvider(HwtHorizonProvider());
  return MockHorizonProvider();
}

@riverpod
SensorService sensorServiceInstance(Ref ref) {
  final service = DeviceSensorService();
  ref.onDispose(() => service.dispose());
  return service;
}
```

---

## Task 5: Handle App Lifecycle (Sensor Management)

### Why
AR apps that don't pause sensors when backgrounded drain battery and can crash on resume when streams pile up. This must be built in now before you have 6+ sensor streams.

### Implementation

```dart
// lib/core/providers/lifecycle_provider.dart
@riverpod
class AppLifecycleState extends _$AppLifecycleState
    with WidgetsBindingObserver {

  @override
  AppLifecycleState build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    return AppLifecycleState.resumed;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    this.state = state;
  }
}
```

Then in your sensor service provider:
```dart
@riverpod
SensorService sensorService(Ref ref) {
  final service = DeviceSensorService();
  final lifecycle = ref.watch(appLifecycleProvider);

  if (lifecycle == AppLifecycleState.paused ||
      lifecycle == AppLifecycleState.inactive) {
    service.pause();
  } else if (lifecycle == AppLifecycleState.resumed) {
    service.resume();
  }

  ref.onDispose(() => service.dispose());
  return service;
}
```

### What pause/resume should do
- **Pause**: Cancel compass, accelerometer, and GPS stream subscriptions. Stop camera preview if applicable.
- **Resume**: Re-subscribe to all sensor streams. The provider graph will automatically recompose with fresh data.
- **Do NOT** pause the horizon or wind data cache — that's just memory, no battery cost.

---

## Task 6: Caching Strategy

### Horizon Profile Cache

Horizon profiles are expensive (~2 min to compute on HWT servers) and terrain doesn't change. Cache aggressively.

```dart
class CachedHorizonProvider implements HorizonProvider {
  final HorizonProvider _inner;
  final HorizonCacheStore _store;

  CachedHorizonProvider(this._inner, this._store);

  @override
  Future<HorizonProfile> getHorizon({
    required double latitude,
    required double longitude,
  }) async {
    final key = _cacheKey(latitude, longitude);

    // Check memory cache first
    final cached = _store.get(key);
    if (cached != null) return cached;

    // Check disk cache
    final persisted = await _store.loadFromDisk(key);
    if (persisted != null) {
      _store.putMemory(key, persisted);
      return persisted;
    }

    // Fetch from API
    final result = await _inner.getHorizon(
      latitude: latitude,
      longitude: longitude,
    );
    _store.put(key, result);
    await _store.saveToDisk(key, result);
    return result;
  }

  /// Truncate to 3 decimal places (~111m resolution).
  /// If user walks 50m and comes back, reuses cached profile.
  String _cacheKey(double lat, double lng) =>
      '${lat.toStringAsFixed(3)}_${lng.toStringAsFixed(3)}';
}
```

### Wind Data Cache

Wind changes over time but not instantly. Cache with a short TTL.

```dart
class CachedWindDataSource implements WindDataSource {
  final WindDataSource _inner;
  final Duration ttl;
  final Map<String, (WindData, DateTime)> _cache = {};

  CachedWindDataSource(this._inner, {this.ttl = const Duration(minutes: 10)});

  @override
  Future<WindData> getWind({
    required PositionData position,
    required AltitudeLevel altitude,
  }) async {
    final key = '${position.latitude.toStringAsFixed(2)}_'
        '${position.longitude.toStringAsFixed(2)}_'
        '${altitude.name}';

    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.$2) < ttl) {
      return cached.$1;
    }

    final result = await _inner.getWind(
      position: position,
      altitude: altitude,
    );
    _cache[key] = (result, DateTime.now());
    return result;
  }
}
```

### Disk persistence
Use **Hive** or **Isar** for persisting horizon profiles. The user opens the app at the same location daily — horizon should load instantly from disk, not trigger a 2-minute API call every time.

---

## Task 7: High-Frequency Sensor Data Strategy

### The problem
Compass and pitch update at 50-100Hz. Pushing every reading through Riverpod's rebuild cycle would trigger 50-100 widget rebuilds per second, killing performance. But the particle renderer needs this data at full rate.

### Solution: ValueNotifier for rendering, Riverpod for everything else

```dart
class SensorNotifiers {
  final ValueNotifier<double> heading = ValueNotifier(0.0);
  final ValueNotifier<double> pitch = ValueNotifier(0.0);
}

// Provider that creates and manages the notifiers
@riverpod
SensorNotifiers sensorNotifiers(Ref ref) {
  final notifiers = SensorNotifiers();
  final sensorStream = ref.watch(rawSensorProvider);

  // Pipe sensor data to ValueNotifiers without triggering Riverpod rebuilds
  sensorStream.whenData((state) {
    notifiers.heading.value = state.compassHeading;
    notifiers.pitch.value = state.pitch;
  });

  return notifiers;
}
```

Your `ParticleRenderer` (CustomPainter) listens to these ValueNotifiers directly:
```dart
class ParticleRenderer extends CustomPainter {
  ParticleRenderer({
    required this.headingNotifier,
    required this.pitchNotifier,
    required this.sceneState,
  }) : super(repaint: Listenable.merge([headingNotifier, pitchNotifier]));

  final ValueNotifier<double> headingNotifier;
  final ValueNotifier<double> pitchNotifier;
  final SceneState sceneState;

  @override
  void paint(Canvas canvas, Size size) {
    final heading = headingNotifier.value;
    final pitch = pitchNotifier.value;
    // Use heading/pitch for rendering at full sensor rate
    // Use sceneState for everything else (wind, horizon, etc.)
  }
}
```

This means:
- Heading/pitch changes repaint the canvas at sensor rate (fast, no widget rebuild)
- Wind/horizon/position changes trigger a Riverpod rebuild that passes new `SceneState` to the painter (infrequent)

---

## Task 8: Error and Loading State Pattern

### Principle: Always show camera feed. Layer data in as it arrives.

Never show a full-screen loading spinner for an AR app. The camera feed should appear instantly.

```dart
class ArViewScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scene = ref.watch(sceneStateProvider);

    return Stack(
      children: [
        // ALWAYS show camera — this is layer 0
        CameraPreview(),

        // Particle overlay — only when we have enough data
        if (scene != null)
          CustomPaint(
            painter: ParticleRenderer(
              headingNotifier: ref.watch(sensorNotifiersProvider).heading,
              pitchNotifier: ref.watch(sensorNotifiersProvider).pitch,
              sceneState: scene,
            ),
          ),

        // Status indicator — subtle, non-blocking
        if (scene == null)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: DataStatusBar(
              gps: ref.watch(stablePositionProvider) != null,
              horizon: ref.watch(horizonProfileProvider).hasValue,
              wind: ref.watch(windDataProvider).hasValue,
              sensors: ref.watch(rawSensorProvider).hasValue,
            ),
          ),

        // Existing UI widgets (always visible)
        CompassWidget(),
        AltitudeSlider(),
        if (showDebug) DebugOverlay(),
      ],
    );
  }
}
```

### `DataStatusBar` — shows what's still loading
```dart
class DataStatusBar extends StatelessWidget {
  final bool gps, horizon, wind, sensors;

  String get statusText {
    if (!gps) return 'Acquiring GPS...';
    if (!sensors) return 'Calibrating sensors...';
    if (!wind) return 'Loading wind data...';
    if (!horizon) return 'Loading terrain...';
    return 'Ready';
  }
}
```

---

## Task 9: Debug Overlay Improvements

The existing debug panel should be wired to the provider graph so it reflects the same data the renderer uses.

```dart
class DebugOverlay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(stablePositionProvider);
    final horizon = ref.watch(horizonProfileProvider);
    final wind = ref.watch(windDataProvider);
    final sensor = ref.watch(rawSensorProvider).valueOrNull;
    final scene = ref.watch(sceneStateProvider);
    final detectionMode = ref.watch(detectionModeProvider);

    return Container(
      // glassmorphism styling
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GPS: ${position?.latitude.toStringAsFixed(4)}, ${position?.longitude.toStringAsFixed(4)}'),
          Text('GPS accuracy: ${position?.accuracy.toStringAsFixed(0)}m'),
          Text('Heading: ${sensor?.compassHeading.toStringAsFixed(1)}°'),
          Text('Pitch: ${sensor?.pitch.toStringAsFixed(1)}°'),
          Text('Horizon: ${horizon.when(
            data: (_) => "loaded",
            loading: () => "loading...",
            error: (e, _) => "error: $e",
          )}'),
          Text('Wind: ${wind.when(
            data: (w) => "${w.speed.toStringAsFixed(1)} m/s @ ${w.direction.toStringAsFixed(0)}°",
            loading: () => "loading...",
            error: (e, _) => "error: $e",
          )}'),
          Text('Detection: ${detectionMode.name}'),
          Text('Scene: ${scene != null ? "ready" : "incomplete"}'),
          Text('FPS: ...'),  // wire to your existing fps counter
        ],
      ),
    );
  }
}
```

Toggle with a shake gesture or long-press on the compass widget.

---

## Task 10: Testing Strategy

### What to test NOW (high ROI)

1. **Provider dependency graph integration tests** — the spine of the app
   - Emit a new GPS position → verify horizon and wind providers invalidate
   - Emit a position within 100m → verify stable position does NOT update
   - Change altitude slider → verify wind provider refetches with new altitude
   - Change detection mode → verify correct SkyDetector implementation is returned

2. **Model equality tests** — verify Freezed equality works as expected
   - Same data = same object (no phantom rebuilds)
   - Different data = different object (rebuilds when needed)

3. **Service interface contract tests** — test each implementation against the interface
   - Every `SkyDetector` implementation returns a `SkyMask` with correct dimensions
   - Every `WindDataSource` implementation returns `WindData` with valid ranges
   - Every `HorizonProvider` implementation returns profiles with 360° coverage

### What NOT to test now
- Individual widget rendering (UI will keep changing)
- Exact particle positions (visual, not logical)
- Platform-specific sensor behavior (mock it and move on)

---

## Execution Order

Do these in order. Each step should result in all existing tests still passing.

1. **Add Freezed + Riverpod dependencies** to pubspec.yaml
2. **Create Freezed models** in `lib/core/models/`
3. **Define service interfaces** in `lib/core/services/`
4. **Wrap existing implementations** behind the interfaces (no behavior changes)
5. **Create the Riverpod provider graph** (start with mocks for horizon)
6. **Restructure directories** to match the target layout
7. **Wire the AR view** to consume `sceneState` from the provider graph
8. **Add lifecycle management** (pause/resume sensors)
9. **Add caching layer** for horizon and wind
10. **Add integration tests** for the provider graph

Estimated effort: 2-3 focused sessions. After this, every Phase 2b feature is a module drop-in.
