# SPEC-002 — Wind Dome

**Feature:** 3D wind dome visualization anchored to live GPS, rendered over a real map  
**Status:** Research complete — ready for `/plan`  
**Pipeline folder:** `.claude/features/wind-dome/`

---

## 1. What This Feature Is

Wind Dome is a full-screen mode in Wind Lens that renders a 3D ellipsoidal dome anchored to the user's real-time GPS location, overlaid on a live map. Inside the dome, animated wind particles move through a physically-derived 3D vector field built from real atmospheric data sampled at multiple altitudes and multiple horizontal positions inside the dome.

The experience looks like this: you open Wind Dome, the map loads centered on you, a wide dome appears above your position, and particles stream through it representing real wind at 10m, 80m, 300m, 800m, and 1500m altitude. If you walk or drive, the dome follows. A slider at the bottom lets you scrub forward up to 72 hours — particles update instantly to show forecast conditions.

**This is not a gimmick.** The goal is a scientifically valid simulation of the local wind field, not a decorative animation. Every particle vector is derived from real data. The engineering challenge is constructing a believable continuous 3D field from the sparse discrete measurements that weather APIs provide.

---

## 2. Core Requirements (Non-Negotiable)

| # | Requirement |
|---|-------------|
| R1 | Real map as ground plane — user sees actual streets, not a fake grid |
| R2 | Dome position follows live GPS — if user moves, dome moves |
| R3 | Wind data is real, fetched from Open-Meteo at multiple altitudes |
| R4 | Particles derive velocity from the wind vector field, not from fake animation |
| R5 | Forecast mode uses the same data source and same rendering pipeline as live mode |
| R6 | The dome is a wide half-ellipsoid (wider than tall) |
| R7 | Particles are strictly contained inside the dome boundary |
| R8 | User can drag to rotate the 3D view |

---

## 3. The Map (Required, Not Optional)

### 3.1 Why the map is load-bearing

The dome without a real map is a floating snow globe. The map is what makes it feel spatially real — you can see your street, your neighborhood, and understand what the dome is covering. It grounds the abstract wind data in a place you recognize.

### 3.2 Implementation: flutter_map + OpenStreetMap tiles

Use `flutter_map` (already commonly paired with Flutter apps, MIT license) with OpenStreetMap raster tiles. The map renders as a normal 2D map underneath the 3D dome overlay.

**Architecture:** Two-layer rendering:

```
Layer 1: flutter_map (2D, fills screen)
          └── Standard OSM tile map, follows GPS, zoom ~14
          
Layer 2: CustomPainter overlay (transparent, positioned on top)
          └── Dome wireframe, particles, user marker
          └── Projected into screen space using camera matrix
          └── Dome footprint circle aligned to map coordinates
```

This is simpler than trying to project a map tile into 3D — the map stays 2D and flat, the dome overlay renders in perspective on top. The result looks correct because at zoom level ~14 and a dome radius of ~1–2km, the map curvature is negligible and the flat-map + perspective-dome combination is visually coherent.

### 3.3 Coordinate alignment

The dome's ground-plane footprint circle must align with the map correctly:

```dart
// Convert dome radius (meters) to pixels at current map zoom
// flutter_map exposes a FlutterMapState with latLngToScreenPoint()

LatLng userLatLng = LatLng(lat, lng);
LatLng edgeLatLng = offsetLatLng(userLatLng, domeRadiusMeters, bearing: 0);

Offset centerPx = mapController.latLngToScreenPoint(userLatLng);
Offset edgePx   = mapController.latLngToScreenPoint(edgeLatLng);

double domeRadiusPx = (edgePx - centerPx).distance;
// Now draw dome footprint as ellipse on screen with radius = domeRadiusPx
```

The 3D dome render scale is derived from `domeRadiusPx` — this keeps the dome visually anchored to the correct geographic area as the user pans or zooms the map.

### 3.4 Map tile style

Use a dark-styled OSM tile provider (e.g. CartoDB Dark Matter, free and no API key required) so the monochrome dome particles read clearly against the map:

```
https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png
```

This matches the black/white visual language of the dome without clashing.

### 3.5 Dependencies

```yaml
# pubspec.yaml additions
flutter_map: ^6.0.0
latlong2: ^0.9.0   # flutter_map's coordinate type
```

---

## 4. Live GPS Tracking

### 4.1 The dome follows the user

The dome is not pinned to a fixed coordinate on launch. It continuously follows `stablePositionProvider` from the existing provider graph. When the user's GPS position changes by >100m (the existing Haversine debounce threshold), the dome re-centers and a new wind data fetch is triggered.

### 4.2 Map centering behavior

```dart
// WindDomeScreen watches stablePositionProvider
// On position change: re-center map + re-center dome
ref.listen(stablePositionProvider, (prev, next) {
  if (next == null) return;
  mapController.move(
    LatLng(next.latitude, next.longitude),
    mapController.zoom,
  );
  // domeWindProfileProvider auto-refetches via dependency chain
});
```

The map follows the user. The dome follows the map center. The wind data follows the dome center. This chain is already the pattern in your existing provider graph — `stablePositionProvider` → `windDataProvider`. Wind Dome just adds another consumer.

### 4.3 Smooth vs snapping movement

The existing `stablePositionProvider` debounces at >100m to avoid thrashing on GPS jitter. For Wind Dome this is fine — a 100m snap is imperceptible at zoom level 14 (where 100m = ~60px). No additional smoothing needed.

### 4.4 What "live" means

`hoursAhead == 0` means "use hour index 0 from the fetched forecast array." Open-Meteo's forecast endpoint includes the current hour as index 0 and the next 71 hours following. So live and forecast are literally the same data structure — live is just `forecastArray[0]`, and `+12h` is `forecastArray[12]`. There is no separate "live" API call. This is the key insight that makes the forecast slider trivially cheap.

---

## 5. The Core Engineering Problem: Building a Valid 3D Wind Field

This is the hardest part of the feature and needs to be thought through carefully.

### 5.1 What the API gives you

Open-Meteo returns wind data as **point measurements at discrete altitude levels** for a **single lat/lng coordinate**. At best you get:

```
One location → 5 altitude levels → 72 time steps
= 360 scalar pairs (speed, direction) total
```

What you need to drive a particle simulation is a **continuous 3D vector field** — for any arbitrary point (x, y, z) inside the dome, you need a wind vector (u, v, w). You cannot get this from a single point measurement. You have to engineer it.

### 5.2 The honest tradeoffs

| Approach | Accuracy | Complexity | MVP? |
|----------|----------|------------|------|
| Uniform layers (all particles at same altitude get same vector) | Low — ignores horizontal variation | Trivial | ✅ |
| Vertical interpolation at center point | Medium — smooth altitude gradient, no horizontal variation | Low | ✅ |
| Multi-point horizontal grid + trilinear interp | Higher — captures horizontal wind shear | Medium | ❌ Phase 2 |
| Numerical weather model data (ECMWF, NOAA HRRR) | High — full 3D field | Very high | ❌ Future |

**MVP uses vertical interpolation at the center point.** This is meteorologically defensible: within a 1–2km dome radius, horizontal wind variation is minimal in most conditions. The interesting variation is vertical (wind direction rotates and speed increases with altitude), which we DO capture. Label it clearly in the UI so users understand what they're seeing.

### 5.3 Vertical interpolation (MVP implementation)

Given the 5 altitude layers and a particle at height `y`:

```dart
WindVector sampleWindField(double x, double y, double z, List<AltitudeLayer> layers) {
  // Normalize y to [0, 1] within dome height
  double normY = y.clamp(0, domeHeightMeters) / domeHeightMeters;
  
  // Map to layer index space
  double layerIdx = normY * (layers.length - 1);
  int lo = layerIdx.floor().clamp(0, layers.length - 2);
  int hi = lo + 1;
  double frac = layerIdx - lo;
  
  // Lerp u and v components (not speed/direction — lerping direction causes 
  // wrap-around artifacts at 0/360 boundary)
  return WindVector(
    u: layers[lo].u * (1 - frac) + layers[hi].u * frac,
    v: layers[lo].v * (1 - frac) + layers[hi].v * frac,
  );
}
```

**Critical:** Always interpolate the u/v Cartesian components, never speed and direction directly. Lerping between 350° and 10° gives 180° (dead wrong). Lerping their u/v vectors gives the correct result.

### 5.4 Wind to particle velocity scaling

Real wind speeds (m/s) need to be mapped to render-space velocities (units/frame):

```dart
// DOME_R_METERS: real dome radius (e.g. 1200m)
// DOME_R_RENDER: render units (e.g. 18 units)
// TARGET_FPS: 60
// SPEED_SCALE: how fast particles should visibly move

double renderScale = DOME_R_RENDER / DOME_R_METERS;

double particleVx = wind.u * renderScale * SPEED_SCALE / TARGET_FPS;
double particleVz = wind.v * renderScale * SPEED_SCALE / TARGET_FPS;
```

`SPEED_SCALE` is a tunable constant (start at ~50). At 5 m/s real wind with SPEED_SCALE=50, a particle crosses the dome in roughly 4 seconds — visually readable and not too fast or slow. Tune this empirically on device.

### 5.5 Phase 2: Horizontal sampling grid

After MVP ships, add a 3×3 (or 5×5) horizontal grid of API fetch points covering the dome footprint:

```
•───•───•
│   │   │   Grid spacing = DOME_R * 0.6
•───C───•   C = center (user position)
│   │   │   9 lat/lng points total
•───•───•
```

```dart
// Convert grid offset (meters) to lat/lng delta
double latDelta(double meters) => meters / 111320.0;
double lngDelta(double meters, double lat) =>
    meters / (111320.0 * cos(lat * pi / 180));
```

Fetch all 9 in parallel with `Future.wait([...])`. Each returns a 72-hour × 5-altitude array. Trilinear interpolation between the 9×5 = 45 grid points gives a true 3D vector field. This captures horizontal wind shear and makes the simulation measurably more accurate.

### 5.6 The "vertical wind" component (w)

Real atmosphere has vertical wind (updrafts, downdrafts), but Open-Meteo doesn't provide it at consumer API tier. Our simulation uses an artificial gentle updraft that increases with altitude:

```dart
double w = 0.002 + (normY * 0.004);  // render units/frame
```

This keeps particles visually interesting (they don't just blow sideways and pile up at the dome wall) and loosely reflects real boundary layer behavior where air rises near the surface and spreads at altitude. It's an artistic approximation, not a physical measurement.

### 5.7 What the simulation is and isn't

Be honest in UI copy and documentation:

**What it is:**
- Real wind speed and direction at 5 altitudes from a verified meteorological source
- Physically correct vertical interpolation between layers
- Correct wind direction rotation with altitude (wind veer) when present in the data
- Correct relative speeds (faster at higher altitude)

**What it isn't:**
- A Navier-Stokes fluid simulation
- A real-time sensor measurement (data updates every hour)
- Spatially resolved within the dome horizontally (MVP)

---

## 6. Forecast Mode

### 6.1 Same API, same pipeline

OGC EDR with a datetime range returns the full GFS forecast in one call per pressure level. GFS provides 1-hour intervals for hours 0–120 and 3-hour intervals beyond. Index 0 = current hour, index N = N hours from now. There is no separate "live" endpoint — live is simply `forecastArray[0]`.

```
3 API calls (surface + 850hPa + 700hPa) → 72-hour arrays → [0] is now, [1] is +1h, [71] is +71h
```

The forecast slider sets `hoursAhead`. The wind field reads `forecastArray[hoursAhead]` for each altitude layer. No additional network call. Instant response.

### 6.2 Data freshness

GFS updates every 6 hours (00Z, 06Z, 12Z, 18Z). So:
- `hoursAhead = 0`: data is 0–6 hours old (latest model run's analysis)
- `hoursAhead = 24`: tomorrow's forecast as of the last model run

The 10-minute TTL cache on the fetcher means the app re-fetches at most every 10 minutes, keeping the "live" view reasonably fresh without hammering the API.

### 6.3 What changes when the slider moves

```
hoursAhead changes
  → currentDomeWindFieldProvider rebuilds (no network, reads from cached array)
  → DomeCanvas receives new wind field
  → On next Ticker tick, particles begin sampling the new vectors
  → Particle positions are NOT reset — they continue from where they are
  → Within a few seconds, particles "flow into" the new wind pattern
```

This continuity is intentional and looks good — the wind field smoothly transitions as particles advect through the new vectors.

### 6.4 Slider UI behavior

```
now  +12h  +24h  +36h  +48h  +60h  +72h
 ●────────────────────────────────────
 
 Live                          (hours == 0)
 +6h — Thu, Feb 26, 2:00 PM   (hours == 6)
```

Active tick label is white, others are dim. Badge in header: "● Live" (white border) or "▶ Fcst" (dim border).

---

## 7. Data Architecture

### 7.1 OGC EDR time-series request (reuses existing WindApiClient)

**No new API integration.** The dome uses the same Shyft + Folkweather OGC EDR infrastructure from P2B-006. The key insight: GFS is a forecast model (384 hours ahead), and OGC EDR exposes the full forecast via the `datetime` parameter. We've been pinning `datetime` to the current hour — loosening it gives us the forecast.

**New method on WindApiClient:** `fetchPointWindSeries(lat, lng, pressureLevel, {hours: 72})`

```
Shyft (primary):
GET https://ogc.shyftwx.com/collections/GFS_isobaric/position
  ?coords=POINT(-122.4194 37.7749)
  &parameter-name=u-component-of-wind,v-component-of-wind
  &datetime={now_utc}/{now_plus_72h_utc}   ← time RANGE, not single instant
  &z=850
  &apikey={key}
  &f=CoverageJSON

Folkweather (fallback):
GET https://edr.folkweather.com/collections/hrrr-isobaric/position
  ?coords=POINT(237.5806 37.7749)
  &parameter-name=UGRD,VGRD
  &datetime={now_utc}/{now_plus_72h_utc}
  &z=850
  &f=CoverageJSON
```

Response: same CoverageJSON format, but `t.values` has 72+ entries instead of 1. Each index in `u-component-of-wind.values` corresponds to the matching time in `t.values`.

**For 3 pressure levels (surface, 850hPa, 700hPa):** 3 requests to Shyft (or 3 to Folkweather on fallback), each returning 72 timesteps. Total: ~6 API calls worst case (all Shyft fail, all Folkweather succeed). Use `Future.wait` to parallelize.

### 7.2 Altitude layer mapping

| Layer | Pressure Level | Approx altitude | Dome Y position |
|-------|---------------|-----------------|-----------------|
| 0 | Surface (10m AGL) | 10 m | normY ≈ 0.006 |
| 1 | 850 hPa | ~1500 m | normY ≈ 0.83 (if dome H = 1800m) |
| 2 | 700 hPa | ~3000 m | Above dome — upper boundary for interpolation |

**Dome height recommendation:** Set `DOME_H_METERS = 1800m`. Layers 0–1 are inside the dome and visible; layer 2 (700hPa) is above the dome and used only as an upper boundary for interpolation. This keeps the visually interesting low-altitude wind shear inside the dome where users can see it.

**Note:** These are the same 3 pressure levels the AR view already uses (mapped from AltitudeLevel enum). The existing `WindApiConstants` already has the collection routing logic.

### 7.3 No direction→u/v conversion needed

OGC EDR returns u/v components directly (not speed/direction like Open-Meteo). No trigonometric conversion required — the data is already in the format particles need. This is cleaner and avoids the 0°/360° wraparound pitfall.

### 7.4 Data model

```dart
// Plain classes — NOT Freezed (rebuilt from cache, not hot-path per frame)

class DomeWindLayer {
  final double altitudeMeters;
  final double u;   // East component m/s (directly from EDR)
  final double v;   // North component m/s (directly from EDR)
  const DomeWindLayer({required this.altitudeMeters, required this.u, required this.v});
}

class DomeWindField {
  final DateTime validTime;            // Which hour this represents
  final List<DomeWindLayer> layers;    // 3 layers, sorted by altitude ascending

  // Core sampling function — vertical interpolation between layers
  WindVector sample(double x, double y, double z) { ... }
}

class DomeWindProfile {
  final List<DomeWindField> hourly;    // 72+ entries, index = hoursAhead
  final DateTime fetchedAt;
  final double lat, lng;

  DomeWindField fieldAt(int hoursAhead) =>
      hourly[hoursAhead.clamp(0, hourly.length - 1)];
}
```

### 7.5 Cache strategy

```dart
// DomeWindFetcher reuses WindApiClient internally
class DomeWindFetcher {
  final WindApiClient _apiClient;  // Same instance used by OgcEdrWindDataSource

  // In-memory cache: key = "dome_{lat2dp}_{lng2dp}"
  // TTL: 10 minutes (same as CachedWindDataSource)
  // On hit: return cached DomeWindProfile immediately
  // On miss: fetch 3 pressure levels × 72h, parse, cache, return

  Future<DomeWindProfile> fetch(double lat, double lng) async { ... }
}
```

Cache key uses 2 decimal places (~1.1km resolution) — wind fields don't vary meaningfully within 1km, and this prevents cache churn from GPS jitter.

### 7.6 Reuse summary

| Component | Already exists | Wind Dome reuses |
|-----------|---------------|-----------------|
| `WindApiClient` | ✅ P2B-006 | Adds `fetchPointWindSeries()` for time-range queries |
| `WindApiConstants` | ✅ P2B-006 | Same URLs, keys, collection routing |
| `WindVector` / `WindField` | ✅ P2B-006 | `WindVector` reused in `DomeWindLayer` |
| Shyft/Folkweather fallback | ✅ P2B-006 | Same dual-API pattern |
| CoverageJSON parsing | ✅ P2B-006 | Extended to handle multi-timestep `t.values` |
| `stablePositionProvider` | ✅ SPEC-001 | Drives dome position + data refetch |

---

## 8. Particle Physics

### 8.1 Particle state (mutable, NOT Freezed)

```dart
class DomeParticle {
  double x, y, z;                        // Render-space coords, dome-local
  final List<Vector3> history;           // Ring buffer of trail positions

  DomeParticle.random(Random rng, double domeR, double domeH)
      : x = 0, y = 0, z = 0,
        history = [] {
    _respawnRandom(rng, domeR, domeH);
  }
}
```

### 8.2 Tick loop

```dart
void tick(DomeWindField field, double dt, double domeR, double domeH) {
  final wind = field.sample(x, y, z);
  
  x += wind.u * RENDER_SCALE * SPEED_SCALE * dt;
  z += wind.v * RENDER_SCALE * SPEED_SCALE * dt;
  y += (0.002 + (y / domeH) * 0.004) * dt * 60;  // gentle updraft
  
  // Strict ellipsoid containment
  if (!_insideDome(x, y, z, domeR, domeH) || y < 0) {
    _respawnRandom(_rng, domeR, domeH);
    return;
  }
  
  history.insert(0, Vector3(x, y, z));
  if (history.length > TRAIL_LENGTH + 1) history.removeLast();
}

static bool _insideDome(double x, double y, double z, double r, double h) =>
    (x * x + z * z) / (r * r) + (y * y) / (h * h) <= 1.0;
```

### 8.3 Respawn strategy

Particles spawn at random points inside the dome distributed uniformly by volume:

```dart
void _respawnRandom(Random rng, double domeR, double domeH) {
  // Rejection sampling — simple and correct for an ellipsoid
  for (int attempt = 0; attempt < 500; attempt++) {
    double rx = (rng.nextDouble() * 2 - 1) * domeR;
    double ry = rng.nextDouble() * domeH;
    double rz = (rng.nextDouble() * 2 - 1) * domeR;
    if (_insideDome(rx, ry, rz, domeR, domeH)) {
      x = rx; y = ry; z = rz;
      for (int i = 0; i < history.length; i++) history[i] = Vector3(x, y, z);
      return;
    }
  }
  x = 0; y = domeH * 0.2; z = 0;  // fallback to center
}
```

### 8.4 Constants

| Constant | Default | Notes |
|----------|---------|-------|
| `PARTICLE_COUNT` | 2000 | Reduce to 1000 if <45 FPS |
| `TRAIL_LENGTH` | 10 | Trail segments per particle |
| `SPEED_SCALE` | 50 | Tune empirically — higher = faster particles |
| `DOME_R_METERS` | 1200 | Real-world dome radius |
| `DOME_H_METERS` | 1800 | Real-world dome height |
| `DOME_R_RENDER` | 18 | Render units (arbitrary) |
| `DOME_H_RENDER` | `DOME_H_METERS / DOME_R_METERS * DOME_R_RENDER` | Maintains real aspect ratio |

---

## 9. Rendering

### 9.1 Layer stack

```
WindDomeScreen (ConsumerStatefulWidget)
├── flutter_map (fills screen, dark tiles, follows GPS)
│   └── MapOptions(center: userLatLng, zoom: 14, interactiveFlags: none)
│       (map does not respond to user pan/zoom — only the dome orbits)
└── Positioned.fill → GestureDetector → CustomPaint
    └── DomePainter (CustomPainter)
        ├── _drawDomeFootprint()     // ellipse aligned to map
        ├── _drawMapOverlayFade()    // radial fade darkening outside dome
        ├── _drawDomeWireframe()     // latitude rings + meridians
        ├── _drawVerticalAxis()      // faint line center to apex
        ├── _drawUserMarker()        // pulsing dot at ground center
        └── _drawParticles()         // trail line segments
```

### 9.2 Projection

Use `vector_math`'s `Matrix4` (already a dependency):

```dart
Matrix4 _buildCameraMatrix() {
  final m = Matrix4.identity();
  m.rotateY(theta);   // azimuth (user horizontal drag)
  m.rotateX(phi);     // elevation (user vertical drag)
  m.translate(Vector3(0, -domeHRender * 0.25, -camDist));
  return m;
}

Offset _project(double x, double y, double z) {
  final v = _cameraMatrix.transform3(Vector3(x, y, z));
  final fov = 600.0;  // focal length in pixels
  final scale = fov / (fov + v.z.abs() + 1e-6);
  return Offset(
    size.width / 2 + v.x * scale,
    size.height * 0.45 - v.y * scale,  // shift up slightly so map visible below
  );
}
```

### 9.3 Dome footprint alignment to map

The footprint circle must match the map's geographic scale:

```dart
// Called when map zoom changes or dome radius changes
void _updateRenderScale(FlutterMapState mapState) {
  final centerPx = mapState.latLngToScreenPoint(userLatLng);
  final northPx  = mapState.latLngToScreenPoint(
    LatLng(userLatLng.latitude + latDelta(DOME_R_METERS), userLatLng.longitude)
  );
  domeRadiusPx = (northPx - centerPx).distance;
  
  // Scale the 3D render to match
  renderScale = domeRadiusPx / DOME_R_RENDER;
}
```

### 9.4 Particle rendering

```dart
void _drawParticles(Canvas canvas) {
  for (final p in _particles) {
    for (int seg = 0; seg < min(p.history.length - 1, TRAIL_LENGTH); seg++) {
      final a = _project(p.history[seg].x,     p.history[seg].y,     p.history[seg].z);
      final b = _project(p.history[seg+1].x,   p.history[seg+1].y,   p.history[seg+1].z);
      
      final altBright  = 0.4 + (p.history[seg].y / domeHRender) * 0.6;
      final trailFade  = 1.0 - (seg / TRAIL_LENGTH) * 0.93;
      final brightness = (trailFade * altBright).clamp(0.0, 1.0);
      
      canvas.drawLine(a, b, Paint()
        ..color = Colors.white.withOpacity(brightness)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true);
    }
  }
}
```

### 9.5 Animation loop

```dart
// In WindDomeScreen initState:
_ticker = createTicker((elapsed) {
  final dt = (elapsed - _lastElapsed).inMilliseconds / 1000.0;
  _lastElapsed = elapsed;
  
  final field = ref.read(currentDomeWindFieldProvider);
  if (field == null) return;
  
  for (final p in _particles) {
    p.tick(field, dt, DOME_R_RENDER, DOME_H_RENDER);
  }
  _frameCounter.value++;   // ValueNotifier triggers CustomPainter repaint
});
_ticker.start();
```

Zero widget rebuilds from the animation loop — same pattern as existing `ParticleOverlay`.

---

## 10. Flutter Architecture

### 10.1 New files

```
lib/features/wind_dome/
├── wind_dome_screen.dart            # ConsumerStatefulWidget, owns Ticker + particles
├── providers/
│   └── dome_providers.dart          # hoursAheadProvider, domeWindProfileProvider,
│                                    # currentDomeWindFieldProvider
├── widgets/
│   ├── dome_canvas.dart             # CustomPainter wrapper + GestureDetector
│   ├── dome_forecast_slider.dart    # Bottom slider widget
│   └── dome_altitude_panel.dart     # Top altitude bar strip
└── models/
    ├── dome_wind_layer.dart          # Single altitude layer (u, v, altitude)
    ├── dome_wind_field.dart          # One hour's 3D wind field + sample()
    ├── dome_wind_profile.dart        # 72-hour array + fetch metadata
    └── dome_particle.dart            # Mutable particle, NOT Freezed
    
lib/services/wind/
└── dome_wind_fetcher.dart            # Open-Meteo fetch + parse + cache
```

### 10.2 Provider graph

```dart
// dome_providers.dart

final hoursAheadProvider = StateProvider<int>((ref) => 0);

final domeWindProfileProvider = FutureProvider<DomeWindProfile?>((ref) async {
  final position = ref.watch(stablePositionProvider);
  if (position == null) return null;
  return DomeWindFetcher().fetch(position.latitude, position.longitude);
});

final currentDomeWindFieldProvider = Provider<DomeWindField?>((ref) {
  final profile = ref.watch(domeWindProfileProvider).valueOrNull;
  final hours   = ref.watch(hoursAheadProvider);
  return profile?.fieldAt(hours);
});
```

### 10.3 Integration with existing graph

```
Existing:                              Wind Dome additions:
──────────────────────────────────────────────────────────
stablePositionProvider ─────────────► domeWindProfileProvider
                                             │
                                      (auto-refetch on position change >100m)
                                             │
hoursAheadProvider ──────────────────► currentDomeWindFieldProvider
                                             │
                                       WindDomeScreen
                                             ├── flutter_map (real map)
                                             ├── DomeCanvas (3D overlay)
                                             └── DomeForecastSlider
```

No changes to existing providers. Wind Dome is a pure addition.

### 10.4 Navigation

New bottom tab or floating action button in `ARViewScreen`. Both modes exist independently.

```dart
// In app router
'/wind-dome': (_) => const WindDomeScreen(),
```

---

## 11. Camera Controls

No auto-rotation. User controls camera entirely.

```dart
onPanUpdate: (details) {
  setState(() {
    theta -= details.delta.dx * 0.007;
    phi = (phi - details.delta.dy * 0.005).clamp(0.15, pi * 0.46);
  });
},
```

Default view: `phi = pi/2.8` (looking down ~50° from zenith), `theta = pi/6`.

Pinch-to-zoom adjusts camera distance (stretch goal, not MVP blocker).

---

## 12. Performance

| Target | Value |
|--------|-------|
| Frame rate | 60 FPS |
| Max particles | 2000 (reduce to 1000 if <45 FPS via existing `PerformanceManager`) |
| Tick loop | <8ms |
| Paint time | <8ms |
| Wind fetch | One-time, <1s, cached 10 min |
| Slider response | Instant (no network) |

`DomeParticle` and `DomeWindField` are plain mutable classes. No Freezed in hot paths. No allocations inside the tick loop or paint call.

---

## 13. Implementation Phases

### Phase 1 — MVP (dev day)

- Real map ground via `flutter_map` + CartoDB Dark Matter tiles
- Live GPS → dome follows user
- Single-point Open-Meteo fetch (center only, 5 altitude layers)
- Vertical interpolation of wind field
- Particles with trail rendering
- Forecast slider (0–72h, instant)
- Drag-to-orbit camera
- `PerformanceManager` integration

### Phase 2 — Spatial accuracy

- 3×3 horizontal sampling grid (9 API calls, `Future.wait`)
- Trilinear interpolation of 3D wind field
- Particles show horizontal wind variation inside dome

### Phase 3 — Polish

- Pinch-to-zoom camera
- Adjustable dome radius (user can expand/shrink coverage area)
- Particle density control
- Compass-aligned dome (North always stays North on the 3D view)

### Phase 4 — Agent mode (drone / vehicles)

- Dome center follows an external coordinate feed (drone telemetry, vehicle GPS)
- Full sphere mode (not just half-dome) for aerial agents
- Multiple overlapping domes with shared wind data
- Fleet visualization: each agent has its own dome, data is crowd-sourced

---

## 14. Dependencies

| Package | Already present | Purpose |
|---------|----------------|---------|
| `http` | ✅ | OGC EDR requests (via existing WindApiClient) |
| `vector_math` | ✅ | Matrix4 projection, Vector3 |
| `flutter_riverpod` | ✅ | Provider graph |
| `geolocator` | ✅ | GPS position |
| `flutter_map` | ❌ Add | Real map tiles |
| `latlong2` | ❌ Add | flutter_map coordinate type |

```yaml
# pubspec.yaml
flutter_map: ^6.0.0
latlong2: ^0.9.0
```

**No Open-Meteo dependency.** All wind data flows through the existing Shyft/Folkweather OGC EDR infrastructure via `WindApiClient`.

---

## 15. Test Plan

| Test | File | What it verifies |
|------|------|-----------------|
| `DomeWindField.sample()` returns correct interpolation | `dome_wind_field_test.dart` | Vertical lerp, u/v not speed/direction |
| `DomeWindField.sample()` at boundaries | same | y=0, y=DOME_H, layer boundaries |
| `_insideDome()` boundary cases | same | Points on surface, inside, outside |
| `fromMeteo()` direction conversion | `dome_wind_fetcher_test.dart` | 0°, 90°, 180°, 270°, wraparound |
| `DomeWindFetcher.parse()` produces correct 72-entry array | same | Mock HTTP response |
| `DomeWindProfile.fieldAt()` clamping | `dome_wind_profile_test.dart` | hoursAhead=0, 72, -1, 100 |
| `hoursAheadProvider` state | `dome_providers_test.dart` | Read/write |
| `currentDomeWindFieldProvider` selects correct hour | same | Index selection |
| `DomeParticle` stays inside dome after N ticks | `dome_particle_test.dart` | Boundary enforcement |
| `DomeParticle` respawns on exit | same | Respawn resets history |
| `DomeForecastSlider` renders | `dome_forecast_slider_test.dart` | Widget smoke test |
| `WindDomeScreen` renders without crash | `wind_dome_screen_test.dart` | Integration smoke test |

---

## 16. Open Questions

1. **Dome radius:** 1200m or 500m? Smaller feels more intimate and the per-altitude variation is more visible. Larger covers more territory. Recommendation: 800m default, user-adjustable in Phase 3.

2. **flutter_map map interaction:** Should the user be able to pan/zoom the map, or is it locked to their GPS center? Recommendation: lock to GPS (simpler, avoids dome misalignment), add pan in Phase 3.

3. **Navigation entry point:** Tab bar alongside AR mode, or a button within the AR screen? Depends on final app IA.

4. **500hPa layer:** At 5500m, this is above any reasonable dome height. Use it as the upper boundary for interpolation but don't show particles that high. Or drop it and cap at 850hPa (~1500m) for cleaner data. Recommendation: cap at 850hPa for MVP.

5. **What to show while wind data is loading:** Show the map and dome wireframe immediately, particles appear once data resolves. Follow the existing `DataStatusBar` pattern.
