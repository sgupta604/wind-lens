# SPEC-002 — Wind Dome

**Feature:** 3D wind dome visualization anchored to user GPS position  
**Status:** Research complete — ready for `/plan`  
**Pipeline folder:** `.claude/features/wind-dome/`

---

## 1. Overview

Wind Dome is a new full-screen mode in Wind Lens that visualizes real atmospheric wind data in 3D space as an interactive dome anchored to the user's location. Unlike the AR view (which overlays particles on the live camera feed), Wind Dome renders a 3D scene where:

- The ground is a dark map plane with a street grid
- A wide, flat ellipsoidal dome sits above the user's GPS pin
- Wind particles stream inside the dome, their vectors derived from real multi-altitude wind data sampled at a grid of points inside the dome volume
- A forecast slider at the bottom lets users scrub up to 72 hours into the future

The visual reference is the existing React/Three.js prototype: black background, monochrome wind streaks with trail fade, white pulsing user position dot, wide dome wireframe (wider than tall), map grid extending beyond the dome footprint.

---

## 2. Visual Design Reference

### 2.1 What it looks like

```
┌─────────────────────────────────────────────────────┐
│  Wind Lens    WIND DOME         3.2 m/s   ● Live    │
│──────────────────────────────────────────────────────│
│  10m   80m   300m   800m  1500m  (altitude bars)    │
│──────────────────────────────────────────────────────│
│                                                      │
│         [3D scene — drag to rotate]                  │
│                                                      │
│    ··· map grid extends to edges ···                 │
│                                                      │
│         ○ dome footprint circle                      │
│     ╱‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾╲                   │
│    │   ~~~wind streaks inside~~~  │                  │
│    │        • user dot            │                  │
│     ╲_________________________╱                    │
│                                                      │
│──────────────────────────────────────────────────────│
│  now  +12h  +24h  +36h  +48h  +60h  +72h           │
│  ────●──────────────────────────────────            │
│                     +0h — Live                       │
└─────────────────────────────────────────────────────┘
```

### 2.2 Color scheme

Pure monochrome. Black background (`#000000`). All geometry and particles are white at varying opacity. No color is used for anything — speed and altitude are communicated through brightness and particle density, not hue.

### 2.3 Dome geometry

The dome is a **half-ellipsoid** (not a hemisphere):

- Radius (XZ): `DOME_R` — significantly wider than height (e.g. 1.2 km radius)  
- Height (Y): `DOME_H` — approximately `DOME_R * 0.75` so it reads as flat and wide
- This shape reflects meteorological reality: wind shear matters more horizontally than vertically at boundary-layer altitudes

Wireframe rendered as latitude rings + longitude meridians at very low opacity (~0.05–0.08).

### 2.4 Map ground

- Dark plane (`#0d0d0d`) extending 5× dome radius in all directions
- Faint street grid overlaid (30×30 grid lines at ~0.15 opacity, thicker block lines at ~0.20)
- Dome footprint circle on the ground (white, ~0.5 opacity) to clearly delineate the data boundary
- Slightly tinted fill inside footprint circle to distinguish "dome zone" from surrounding map

### 2.5 User position marker

- Filled white circle, ~0.7 unit radius
- Outer pulsing ring (~1.1–1.5 unit radius) that animates opacity via `sin(time)`
- Faint accuracy halo ring (~2.5–2.8 radius, very low opacity)
- Faint vertical axis line rising from center to dome apex (opacity ~0.08) — helps read altitude visually

### 2.6 Wind particles

- Line segments (not points), each particle has a trail of N segments
- Head of trail is brightest; tail fades to near-zero opacity (~0.93 fade over trail length)
- Brightness encodes both altitude (`0.4 + normY * 0.6`) and wind speed (`0.5 + speedNorm * 0.5`)
- Higher altitude = brighter overall (thinner air, faster jet-stream winds feel more prominent)
- Particles strictly contained inside the ellipsoid — hard boundary check on every frame

---

## 3. Data Architecture

### 3.1 Wind data source

**API: Open-Meteo Hourly Forecast**  
`https://api.open-meteo.com/v1/forecast`

Relevant parameters:
```
latitude, longitude
hourly=wind_speed_10m,wind_direction_10m,
       wind_speed_80m,wind_direction_80m,
       wind_speed_120m,wind_direction_120m,
       windspeed_1000hPa,winddirection_1000hPa,   // ~110m
       windspeed_850hPa,winddirection_850hPa,     // ~1500m
       windspeed_500hPa,winddirection_500hPa      // ~5500m
wind_speed_unit=ms
forecast_days=3
```

A single API call returns 72 hourly slices for all altitude levels at once. This is fetched once, cached client-side, and the forecast slider scrubs through the cached array — **no API call per slider tick**.

### 3.2 Altitude mapping

| Layer index | Open-Meteo field | Approx altitude | Role in dome |
|-------------|-----------------|-----------------|--------------|
| 0 | `wind_speed_10m` | 10 m | Ground surface particles |
| 1 | `wind_speed_80m` | 80 m | Low boundary layer |
| 2 | `wind_speed_120m` | 120 m | Mid boundary layer |
| 3 | `windspeed_850hPa` | ~1500 m | Upper boundary layer |
| 4 | `windspeed_500hPa` | ~5500 m | (only if dome height supports it) |

Map `wind_direction_*` (meteorological degrees, where wind is coming FROM) to Cartesian:
```dart
// Meteorological convention: 0° = from North, 90° = from East
// Convert to "wind blows TOWARD" direction for particle motion
double towardDeg = (fromDeg + 180) % 360;
double rad = towardDeg * pi / 180;
double u = speed * sin(rad);   // East component
double v = speed * cos(rad);   // North component
```

### 3.3 Spatial sampling grid inside the dome

To make particles feel like they're responding to a true 3D wind field rather than a uniform layer:

**Horizontal sampling:** Fetch wind data at a 3×3 grid of lat/lng points covering the dome footprint:

```
•───•───•
│   │   │   Grid spacing = DOME_R * 0.6 in meters
•───C───•   C = user center, 8 surrounding points
│   │   │
•───•───•
```

Convert dome radius from meters to degrees:
```dart
double latDelta = domeRadiusMeters / 111320.0;
double lngDelta = domeRadiusMeters / (111320.0 * cos(lat * pi / 180));
```

9 API calls total (or 1 call with a batch if Open-Meteo supports it — check batch endpoint). Cache all 9 by grid index key.

**Vertical sampling:** Use the 4–5 altitude layers from Section 3.2.

This gives a 3×3×5 = 45-point wind field grid. Particles interpolate their velocity using trilinear interpolation between the 8 surrounding grid corners at any position (x, y, z) inside the dome.

### 3.4 Trilinear interpolation

Given a particle at position (x, y, z) inside the dome:

```dart
// 1. Normalize to [0,1] in each axis
double nx = (x + DOME_R) / (2 * DOME_R);   // 0=left, 1=right
double nz = (z + DOME_R) / (2 * DOME_R);   // 0=front, 1=back
double ny = y / DOME_H;                      // 0=ground, 1=apex

// 2. Map to grid coordinates
double gx = nx * (GRID_X - 1);   // GRID_X = 3
double gz = nz * (GRID_Z - 1);   // GRID_Z = 3
double gy = ny * (GRID_Y - 1);   // GRID_Y = number of altitude layers

// 3. Get corner indices and fractional parts
int x0 = gx.floor(), x1 = min(x0+1, GRID_X-1);
int z0 = gz.floor(), z1 = min(z0+1, GRID_Z-1);
int y0 = gy.floor(), y1 = min(y0+1, GRID_Y-1);
double fx = gx - x0, fz = gz - z0, fy = gy - y0;

// 4. Trilinear interpolation of u/v components
WindVector lerp(WindVector a, WindVector b, double t) =>
    WindVector(u: a.u + (b.u - a.u) * t, v: a.v + (b.v - a.v) * t);

WindVector sample = lerp(
  lerp(lerp(grid[x0][y0][z0], grid[x1][y0][z0], fx),
       lerp(grid[x0][y0][z1], grid[x1][y0][z1], fx), fz),
  lerp(lerp(grid[x0][y1][z0], grid[x1][y1][z0], fx),
       lerp(grid[x0][y1][z1], grid[x1][y1][z1], fx), fz),
  fy
);
```

For MVP, a simpler 1D vertical interpolation (ignoring horizontal variation) is acceptable — just interpolate between the altitude layers at the user's center point. Add horizontal grid later.

### 3.5 Forecast slider

`hoursAheadProvider`: `StateProvider<int>`, range 0–72.

When `hoursAhead` changes:
- Read index `hoursAhead` from already-fetched 72-hour arrays
- Rebuild the wind field grid in memory (no network call)
- Particle physics continues uninterrupted — velocity field updates between frames

---

## 4. Particle Physics

### 4.1 Particle state

```dart
class DomeParticle {
  double x, y, z;                  // Current position (meters, dome-local coords)
  List<Vector3> history;            // Trail positions, length = TRAIL_LENGTH
  
  DomeParticle({required this.x, required this.y, required this.z,
                int trailLength = 10})
      : history = List.generate(trailLength + 1, (_) => Vector3(x, y, z));
}
```

Do NOT use Freezed — mutable, updated every frame. Same reasoning as `Particle` in the existing codebase.

### 4.2 Tick loop

```dart
void _tick(double dt) {
  for (final p in _particles) {
    // 1. Sample wind field at particle position
    final wind = _windField.sample(p.x, p.y, p.z);
    
    // 2. Advance position
    p.x += wind.u * dt * SPEED_SCALE;
    p.z += wind.v * dt * SPEED_SCALE;
    p.y += _riseRate(p.y) * dt;   // slow upward drift
    
    // 3. Boundary check (ellipsoid equation)
    if (!_insideDome(p.x, p.y, p.z)) {
      _respawn(p);
      continue;
    }
    
    // 4. Update trail history
    p.history.insert(0, Vector3(p.x, p.y, p.z));
    if (p.history.length > TRAIL_LENGTH + 1) p.history.removeLast();
  }
}

bool _insideDome(double x, double y, double z) {
  return (x*x + z*z) / (DOME_R * DOME_R) + (y*y) / (DOME_H * DOME_H) <= 1.0
      && y >= 0;
}

double _riseRate(double y) {
  // Gentle updraft — faster near top, slower at ground
  return 0.002 + (y / DOME_H) * 0.004;
}

void _respawn(DomeParticle p) {
  final pos = _randomInsideDome();
  p.x = pos.x; p.y = pos.y; p.z = pos.z;
  for (int i = 0; i <= TRAIL_LENGTH; i++) {
    p.history[i] = Vector3(pos.x, pos.y, pos.z);
  }
}
```

### 4.3 Tunable constants

| Constant | Default | Notes |
|----------|---------|-------|
| `PARTICLE_COUNT` | 2000 | Reduce to 1000 if <45 FPS |
| `TRAIL_LENGTH` | 10 | Segments per particle trail |
| `SPEED_SCALE` | 0.012 | Pixels-per-second per m/s of real wind |
| `DOME_R` | 1200 m | Real-world radius; convert to render units |
| `DOME_H` | 900 m | Real-world height (0.75 × radius) |
| `GRID_X/Z` | 3 | Horizontal sample grid dimension |
| `GRID_Y` | 5 | Number of altitude layers |

---

## 5. Rendering

### 5.1 Rendering approach

Flutter `CustomPainter` using `Canvas.drawLine` for trail segments. Each particle draws `TRAIL_LENGTH` lines per frame. Total draw calls = `PARTICLE_COUNT × TRAIL_LENGTH` = 20,000 per frame.

This is within Flutter's 2D canvas budget on modern phones. If profiling shows slowdown, migrate trail rendering to a fragment shader (extending the existing Layer 3 shader).

### 5.2 Projection (3D → 2D)

Implement a simple perspective projection in Dart — no 3D engine needed:

```dart
// Camera: orbits around dome center at fixed radius
// phi = vertical angle (elevation), theta = horizontal angle (azimuth)
// User drag updates theta and phi

Offset project(double x, double y, double z) {
  // Rotate around Y axis by theta
  double rx = x * cos(theta) - z * sin(theta);
  double rz = x * sin(theta) + z * cos(theta);
  
  // Rotate around X axis by phi (tilt down toward map)
  double ry = y * cos(phi) - rz * sin(phi);
  double rz2 = y * sin(phi) + rz * cos(phi);
  
  // Perspective divide
  double fov = 0.8;  // focal length
  double scale = fov / (fov + rz2 / CAM_DIST);
  
  return Offset(
    centerX + rx * scale * RENDER_SCALE,
    centerY - ry * scale * RENDER_SCALE,
  );
}
```

Alternatively: use Flutter's `Matrix4` from `vector_math` (already a dependency) and `MatrixUtils.transformPoint3`.

### 5.3 Map ground rendering

Draw the map plane as a series of projected `Canvas.drawLine` calls for the grid. The dome footprint circle projects to an ellipse in the camera view — compute via projecting 64 points around the circle and using `Canvas.drawPath`.

Optionally: use `flutter_map` with `MaplibreGL` or `google_maps_flutter` as the actual ground — see Section 8.

### 5.4 Particle trail rendering

```dart
void _drawParticle(Canvas canvas, DomeParticle p, Size size) {
  for (int seg = 0; seg < p.history.length - 1; seg++) {
    final p0 = project(p.history[seg]);
    final p1 = project(p.history[seg + 1]);
    
    final altBrightness = 0.4 + (p.history[seg].y / DOME_H) * 0.6;
    final trailFade = 1.0 - (seg / TRAIL_LENGTH) * 0.93;
    final brightness = trailFade * altBrightness;
    
    canvas.drawLine(p0, p1, Paint()
      ..color = Colors.white.withOpacity(brightness)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round);
  }
}
```

Depth sorting: sort particles by their projected Z (rz2) before drawing so far particles render behind near ones. Only needed if overdraw becomes visually distracting — skip for MVP.

### 5.5 Animation loop

Use a `Ticker` (via `SingleTickerProviderStateMixin` or `TickerProvider` from Riverpod). Each tick:

1. Run `_tick(dt)`
2. Call `setState(() {})` OR use a `ValueNotifier<int>` frame counter to trigger `CustomPainter.shouldRepaint` — same zero-rebuild pattern as the existing `ParticleOverlay`.

---

## 6. Flutter Architecture

### 6.1 New files

```
lib/features/wind_dome/
├── wind_dome_screen.dart           # ConsumerStatefulWidget
├── providers/
│   └── dome_providers.dart         # All new providers
├── widgets/
│   ├── dome_canvas.dart            # CustomPainter + gesture handling
│   ├── dome_forecast_slider.dart   # Bottom slider widget
│   └── dome_altitude_panel.dart    # Top altitude bar strip
├── models/
│   ├── dome_wind_field.dart        # 3D grid + trilinear interp (plain class)
│   └── dome_particle.dart          # Mutable particle (plain class, NOT Freezed)
└── services/
    └── dome_wind_fetcher.dart      # Fetches 9-point grid × 72 hours from Open-Meteo
```

### 6.2 New providers

```dart
// dome_providers.dart

// Hours ahead: 0 = live, 1–72 = forecast
final hoursAheadProvider = StateProvider<int>((ref) => 0);

// Full 72-hour wind field grid, fetched once per position
// Returns List<DomeWindField> — one per hour
final domeWindProfileProvider = FutureProvider<List<DomeWindField>>((ref) async {
  final position = ref.watch(stablePositionProvider);
  if (position == null) return [];
  return DomeWindFetcher().fetch(
    lat: position.latitude,
    lng: position.longitude,
    domeRadiusMeters: DOME_R_METERS,
    gridDim: GRID_XZ,
    altitudeLayers: ALTITUDE_LAYERS,
  );
});

// The wind field for the currently selected forecast hour
final currentDomeWindFieldProvider = Provider<DomeWindField?>((ref) {
  final profile = ref.watch(domeWindProfileProvider).valueOrNull;
  final hours = ref.watch(hoursAheadProvider);
  if (profile == null || profile.isEmpty) return null;
  return profile[hours.clamp(0, profile.length - 1)];
});
```

### 6.3 Integration with existing providers

`domeWindProfileProvider` watches `stablePositionProvider` from the existing provider graph — same GPS debounce, same >100m threshold before refetching. No new GPS logic needed.

`DomeWindFetcher` implements `WindDataSource` interface OR is a standalone service — either works. Standalone is simpler since dome wind data has a different shape (multi-point grid) than the existing single-point `WindData` model.

### 6.4 Navigation

Add Wind Dome as a new route alongside `ARViewScreen`:

```dart
// In app.dart or router
'/wind-dome': (context) => const WindDomeScreen(),
```

Add a button in `ARViewScreen` (or in a bottom tab) to navigate to Wind Dome. Keep both modes independent — no shared state except `stablePositionProvider`.

---

## 7. Camera Controls

The 3D scene is user-controlled — no auto-rotation.

### 7.1 Drag to orbit

`GestureDetector` on `dome_canvas.dart`:

```dart
onPanUpdate: (details) {
  setState(() {
    theta -= details.delta.dx * 0.007;    // horizontal drag = azimuth
    phi = (phi - details.delta.dy * 0.005)
        .clamp(0.15, pi * 0.46);          // vertical drag = elevation
  });
}
```

`phi` clamp: prevents camera from going below ground (`pi * 0.46` ≈ 83°) or flipping over top (`0.15` ≈ 9° above horizon).

### 7.2 Initial camera angle

Default: `phi = pi/2.8` (roughly 50° down from zenith), `theta = pi/6` (30° offset from North). This gives a nice isometric-ish view of the dome and map.

### 7.3 Pinch to zoom (stretch goal)

Adjust `CAM_DIST` on pinch gesture. Keep within `[DOME_R * 1.5, DOME_R * 4.0]` to prevent clipping inside dome or zooming too far out.

---

## 8. Map Ground — Two Approaches

### Approach A: Projected 3D grid (MVP — no new dependencies)

Draw the map entirely in `CustomPainter`. A 30×30 grid of lines projected through the same camera matrix as the particles. Dome footprint = 64 projected points connected with `drawPath`. Fast, no external deps, no network.

**Limitation:** Not a real map — looks like a reference grid, not actual streets.

### Approach B: Real map tile as ground plane (Phase 2)

Use `flutter_map` + a static map tile (MapLibre / OpenStreetMap) rendered to a `ui.Image` and then projected as a textured quad in the 3D scene. Steps:

1. Fetch a static map tile at the user's lat/lng, zoom level ~14
2. Decode to `ui.Image`
3. In `CustomPainter`, project the four corners of the map bounds to screen space
4. Use `Canvas.drawImageRect` or a custom `drawVertices` call with UV mapping to texture the ground plane

This gives real streets visible under the dome — matching the Apple Maps screenshot you shared.

**Recommendation:** Ship Approach A for the dev day demo (zero deps, works offline, looks clean). Add Approach B post-launch.

---

## 9. Forecast Slider

### 9.1 Widget

`dome_forecast_slider.dart`: StatelessWidget receiving `hours` and `onChanged` callback. Parent reads from `hoursAheadProvider`, passes value down.

```dart
Slider(
  value: hours.toDouble(),
  min: 0, max: 72, divisions: 72,
  onChanged: (v) => ref.read(hoursAheadProvider.notifier).state = v.round(),
)
```

### 9.2 Tick labels

Display `now`, `+12h`, `+24h`, `+36h`, `+48h`, `+60h`, `+72h` above the slider. Active tick (nearest to current value) is white; others are dim.

### 9.3 Current time display

Below slider: show absolute datetime for non-zero hours.

```dart
hours == 0 
  ? "Live"
  : "${formatOffset(hours)} — ${formatDateTime(DateTime.now().add(Duration(hours: hours)))}"
```

### 9.4 Live vs forecast badge

Top-right of screen header:
- `hours == 0`: "● Live" with white border
- `hours > 0`: "▶ Fcst" with dim border

---

## 10. Performance Budget

| Target | Value |
|--------|-------|
| Frame rate | 60 FPS |
| Max particle count | 2000 (auto-reduce to 1000 if <45 FPS) |
| Tick loop time | <8ms |
| `CustomPainter.paint` time | <8ms |
| Wind field fetch | One-time on position change, <1s |
| Slider response | Instant (no network call) |
| Memory (particle state) | ~2000 × 11 × 12 bytes ≈ ~265 KB |

Performance manager: reuse existing `PerformanceManager` — it already watches FPS and adjusts particle count.

**No Freezed objects in the render loop.** `DomeParticle` and `DomeWindField` are plain mutable classes.

---

## 11. Open-Meteo API Integration

### 11.1 Endpoint

```
GET https://api.open-meteo.com/v1/forecast
  ?latitude=47.2
  &longitude=-96.8
  &hourly=wind_speed_10m,wind_direction_10m,
          wind_speed_80m,wind_direction_80m,
          wind_speed_120m,wind_direction_120m,
          windspeed_850hPa,winddirection_850hPa,
          windspeed_500hPa,winddirection_500hPa
  &wind_speed_unit=ms
  &forecast_days=3
  &timezone=auto
```

### 11.2 Response shape

```json
{
  "hourly": {
    "time": ["2026-02-25T00:00", ...],           // 72 entries
    "wind_speed_10m": [3.2, 3.4, ...],
    "wind_direction_10m": [245, 248, ...],
    "wind_speed_80m": [...],
    ...
  }
}
```

### 11.3 Parsing

```dart
class DomeWindFetcher {
  static const _altitudeLayers = [
    _AltLayer('wind_speed_10m',       'wind_direction_10m',       10.0),
    _AltLayer('wind_speed_80m',       'wind_direction_80m',       80.0),
    _AltLayer('wind_speed_120m',      'wind_direction_120m',      120.0),
    _AltLayer('windspeed_850hPa',     'winddirection_850hPa',     1500.0),
    _AltLayer('windspeed_500hPa',     'winddirection_500hPa',     5500.0),
  ];

  Future<List<DomeWindField>> fetch({
    required double lat, required double lng,
    required double domeRadiusMeters, required int gridDim,
    List<_AltLayer> altitudeLayers = _altitudeLayers,
  }) async {
    // 1. Build 9 lat/lng points (3×3 grid)
    // 2. Fetch Open-Meteo for each point (or center-only for MVP)
    // 3. Parse 72-hour arrays per altitude layer per grid point
    // 4. Convert speed+direction → (u, v) components
    // 5. Return List<DomeWindField> of length 72
  }
}
```

For MVP: fetch center point only (1 API call). Horizontal spatial variation can be added in Phase 2.

### 11.4 Caching

`CachedWindDataSource` already handles TTL caching. `DomeWindFetcher` should use the same pattern:
- Cache key: `"dome_${lat3dp}_${lng3dp}"`
- TTL: 10 minutes (same as existing wind cache)
- On cache hit: rebuild `List<DomeWindField>` from cached JSON

---

## 12. Implementation Phases

### Phase 1 — MVP (dev day ready)

- Single-point wind fetch (center lat/lng only, no 9-point grid)
- Vertical interpolation between altitude layers
- `CustomPainter` rendering with projected 3D grid as ground
- User position marker
- Dome wireframe (ellipsoid, wide)
- Forecast slider (scrubs 72-hour cached array)
- Drag-to-orbit camera
- `PerformanceManager` integration

### Phase 2 — Spatial wind field

- 9-point horizontal sampling grid
- Trilinear interpolation of wind vectors
- Particles respond to horizontal wind variation inside dome

### Phase 3 — Real map ground

- Static map tile fetch + texture projection onto ground plane
- OR `flutter_map` integration with projected overlay

### Phase 4 — Drone / agent mode

- Dome follows a moving GPS coordinate (drone telemetry feed)
- Sphere mode (full sphere, not half-dome) for aerial agents
- Multiple overlapping domes sharing wind data
- Conflict zone visualization where domes intersect

---

## 13. Dart/Flutter Dependencies

No new dependencies required for Phase 1. All needed tools already in `pubspec.yaml`:

| Dependency | Already present | Used for |
|------------|----------------|----------|
| `http` | ✅ | Open-Meteo API calls |
| `vector_math` | ✅ | `Matrix4`, `Vector3`, projection |
| `flutter_riverpod` | ✅ | Provider graph |
| `geolocator` | ✅ | GPS position |

Optional for Phase 3:
- `flutter_map` (map tile ground plane)
- `cached_network_image` (static tile caching)

---

## 14. Wiring into Existing Provider Graph

```
Existing:                          New (Wind Dome):
─────────────────────────────────────────────────────
stablePositionProvider ──────────► domeWindProfileProvider
                                         │
hoursAheadProvider ──────────────► currentDomeWindFieldProvider
                                         │
                                   WindDomeScreen
                                   (ConsumerStatefulWidget)
                                         │
                                   DomeCanvas (CustomPainter)
                                   DomeForecastSlider
                                   DomeAltitudePanel
```

`WindDomeScreen` watches `currentDomeWindFieldProvider` and passes the field to `DomeCanvas`. The canvas owns the `Ticker`, the particle array, and the camera state.

---

## 15. Test Plan

Following the existing test patterns (559 tests, all passing):

| Test | File | Type |
|------|------|------|
| `DomeWindField.sample()` interpolation | `test/features/wind_dome/dome_wind_field_test.dart` | Unit |
| `_insideDome()` boundary check | same | Unit |
| `DomeWindFetcher.fetch()` parsing | `test/features/wind_dome/dome_wind_fetcher_test.dart` | Unit (mock HTTP) |
| `hoursAheadProvider` state | `test/features/wind_dome/dome_providers_test.dart` | Provider |
| `currentDomeWindFieldProvider` index selection | same | Provider |
| `DomeForecastSlider` renders | `test/features/wind_dome/dome_forecast_slider_test.dart` | Widget |
| `DomeCanvas` renders without error | `test/features/wind_dome/dome_canvas_test.dart` | Widget |

Particle rendering tests follow the same pattern as `particle_overlay_test.dart` — verify behavior (particles stay inside dome, respawn when exiting) not pixel-perfect output.

---

## 16. Known Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| CustomPainter 20,000 drawLine calls too slow | Batch into `drawVertices` or migrate to fragment shader |
| Open-Meteo 9-point grid = 9 concurrent API calls | Phase 1 uses 1 call; add grid in Phase 2 with `Future.wait` |
| Perspective projection drift on gimbal edge cases | Clamp `phi` strictly; add unit tests for degenerate angles |
| `flutter_map` projection complexity (Phase 3) | Start with Approach A (fake grid) — real map is Phase 3 stretch |
| Wind data stale at 72h edge | Open-Meteo free tier gives 16 days; cap slider at 72h to stay conservative |

---

## 17. Open Questions (Resolve Before /plan)

1. **Map tile provider for Phase 3:** MapLibre (open source) or Google Maps Static API (costs money, but already in many Flutter apps)? Recommendation: MapLibre.
2. **Dome radius in real world:** 1.2 km? 500 m? Affects how many city blocks are visible under the dome. Consider making this user-adjustable via a pinch gesture.
3. **Navigation entry point:** Bottom tab alongside AR view, or a floating button in ARViewScreen?
4. **Particle count on older devices:** The existing `PerformanceManager` threshold is 45 FPS → reduce to 1000. Same threshold for dome? Dome particles are simpler (no sky mask check), may be able to hold 2000 longer.
5. **Drone mode scope:** Confirm this is Phase 4 and not a dev day requirement.
