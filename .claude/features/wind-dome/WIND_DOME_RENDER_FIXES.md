# Wind Dome — Rendering & Camera Sync Fix Brief

**Branch:** feature/wind-dome-homescreen  
**Type:** Rendering fix pass (no architectural changes)  
**Pipeline step:** /implement (diagnosis and plan already complete)

---

## Context

The Wind Dome feature is working architecturally — real wind data is fetching,
the slider is functional, the dome wireframe is rendering in 3D. The remaining
issues are all in the rendering and gesture layer. This brief covers exactly
what to fix and how.

---

## Issue 1 — Map and Dome Camera Are Not Synchronized

### Problem
The dome has its own 3D camera (theta, phi, camDist). The map has its own
camera (bearing, zoom). They do not talk to each other. When the user orbits
the dome, the map stays fixed. When the user zooms the dome, the map stays
fixed. They feel like two separate scenes.

### What We Want
One unified camera. A single source of truth drives both:

```
State: (theta, phi, camDist, userLatLng)
         ↓                    ↓
   DomePainter          MapController
   3D scene             bearing + zoom + tilt
```

### Fix A — Bearing Sync (horizontal orbit)
When theta changes (horizontal drag), call:
```dart
_mapController.rotate(-theta * 180 / pi);
```
This keeps map north aligned with dome north at all times. The minus sign is
because map bearing is clockwise-from-north but theta rotates counter-clockwise.

### Fix B — Zoom Behavior (IMPORTANT — camera zoom, not dome scale)

**The dome's real-world size never changes when zooming.**
DOME_R_RENDER is fixed. The dome always represents the same physical radius
(500m / 1km / 2km — whatever the preset is). Zooming moves the camera
closer or further. The dome appears larger on screen when zoomed in because
the camera is closer to it — exactly like a real camera, not because the
dome itself is growing.

Think of it like Google Earth: the city blocks don't get bigger when you zoom
in. Your viewpoint moves closer to them.

```dart
// WRONG — do not do this
void _onPinchUpdate(double scaleDelta) {
  DOME_R_RENDER *= scaleDelta;  // BAD: changes dome size
}

// CORRECT — move the camera, dome stays fixed
void _onPinchUpdate(double scaleDelta) {
  camDist = (camDist / scaleDelta).clamp(MIN_CAM_DIST, MAX_CAM_DIST);
  // DOME_R_RENDER is never touched here
}
```

The dome is anchored to the map at the user's GPS position. It doesn't float
or drift. Zoom only changes how close the camera is to that fixed anchor point.

### Fix C — Map Zoom Syncs with Camera Distance
As the camera pulls back (camDist increases), the map zooms out to show more
of the city around the dome. This makes the dome feel grounded — you're
literally pulling away from the map, not scaling a floating object.

```dart
void _onPinchUpdate(double scaleDelta) {
  camDist = (camDist / scaleDelta).clamp(MIN_CAM_DIST, MAX_CAM_DIST);
  
  // Map zoom derived from camera distance — they move together
  // As camDist doubles, map zooms out by 1 level
  final mapZoom = BASE_MAP_ZOOM - log(camDist / BASE_CAM_DIST) / log(2);
  _mapController.move(_mapController.camera.center, mapZoom.clamp(8.0, 16.0));
}
```

This means: zoom in on dome → map zooms in too. Zoom out past a threshold →
map starts showing the wider city. The dome stays the same visual size on
screen; the world around it gets smaller/larger.

### Fix C — Tilt Effect (vertical 2-finger drag)
`flutter_map` doesn't support true pitch natively. Fake it with a Transform:

```dart
// Wrap FlutterMap in a Transform widget
Transform(
  alignment: Alignment.center,
  transform: Matrix4.identity()
    ..setEntry(3, 2, 0.001)           // perspective
    ..rotateX(_mapTiltAngle),         // tilt forward as phi changes
  child: FlutterMap(...)
)
```

Derive `_mapTiltAngle` from phi:
```dart
// phi = pi/2 (top-down) → no tilt
// phi = pi/2.8 (angled) → tilt map forward
_mapTiltAngle = (pi / 2 - phi) * 0.6;
```

This makes the map recede toward the horizon as the user tilts into 3D view,
matching the dome's perspective angle visually.

---

## Issue 2 — Zoom Transition: Dome View ↔ Map View

### What We Want
Two natural zoom modes that flow into each other:

```
Close zoom (camDist < DOME_THRESHOLD):
  → Dome is prominent, fills most of screen
  → Map visible around edges
  → 3D perspective angle active

Far zoom (camDist > MAP_THRESHOLD):  
  → Dome shrinks toward center
  → Map takes over as primary view
  → phi transitions back toward pi/2 (top-down)
  → Feels like "landing back on the map"
```

### Fix
Add a zoom-driven phi auto-adjust. When camDist crosses thresholds, smoothly
animate phi:

```dart
const double DOME_THRESHOLD = 400.0;
const double MAP_THRESHOLD  = 700.0;

void _onCamDistChanged() {
  if (camDist > MAP_THRESHOLD) {
    // Transition to top-down map view
    final t = ((camDist - MAP_THRESHOLD) / 300.0).clamp(0.0, 1.0);
    phi = lerpDouble(phi, pi / 2.0, t * 0.05)!;  // smooth per frame
    _mapTiltAngle = lerpDouble(_mapTiltAngle, 0.0, t * 0.05)!;
  }
}
```

Call `_onCamDistChanged()` in the ticker loop so it animates smoothly rather
than snapping.

---

## Issue 3 — Ground Disc (the dark floor from the reference image)

### What We Want
The dome sits on a visible dark ground plane. You can see where the floor is.
The map shows around the outside. This is the key visual from the reference
image.

### Fix
In `DomePainter.paint()`, draw a filled dark ellipse BEFORE drawing particles
but AFTER the map renders (it's already after since it's in CustomPainter):

```dart
void _drawGroundDisc(Canvas canvas, Size size) {
  // Project the four cardinal points of the dome footprint
  final points = <Offset>[];
  for (int i = 0; i < 64; i++) {
    final angle = (i / 64) * 2 * pi;
    final p = _project(Vector3(
      cos(angle) * DOME_R_RENDER,
      0,                              // y=0 is ground
      sin(angle) * DOME_R_RENDER,
    ), size);
    points.add(p);
  }
  
  // Draw filled path
  final path = Path()..moveTo(points[0].dx, points[0].dy);
  for (final p in points.skip(1)) path.lineTo(p.dx, p.dy);
  path.close();
  
  canvas.drawPath(path, Paint()
    ..color = Colors.black.withOpacity(0.55)
    ..style = PaintingStyle.fill);
  
  // Draw edge ring (white, semi-transparent)
  canvas.drawPath(path, Paint()
    ..color = Colors.white.withOpacity(0.35)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0);
}
```

Call order in `paint()`:
1. `_drawGroundDisc(canvas, size)`   ← dark filled ellipse
2. `_drawDomeWireframe(canvas, size)`
3. `_drawParticles(canvas, size)`
4. `_drawUserMarker(canvas, size)`

---

## Issue 4 — Dome Radius Preset Buttons Not Updating the Dome

### Problem
Tapping 500m / 1km / 2km updates `domeSizeProvider` but the dome doesn't
visually change. `DOME_R_RENDER` is being read once at painter construction
time, not on every paint call.

### Fix
`DomePainter` must read the current render radius as a constructor parameter
that changes when the provider changes. In `WindDomeScreen`:

```dart
// Read provider value every build
final domeRadiusMeters = ref.watch(domeSizeProvider);
final DOME_R_RENDER = domeRadiusMeters / METERS_PER_RENDER_UNIT;
final DOME_H_RENDER = DOME_R_RENDER * 0.75;  // height = 75% of radius

// Pass to painter — triggers repaint when value changes
CustomPaint(
  painter: DomePainter(
    particles: _particles,
    domeR: DOME_R_RENDER,
    domeH: DOME_H_RENDER,
    theta: _theta,
    phi: _phi,
    ...
  ),
)
```

Also: when dome radius changes, re-initialize particles to spawn within the
new dome bounds. Add a `didUpdateWidget` or provider listener that calls
`_respawnAllParticles()` when `domeSizeProvider` changes.

---

## Issue 5 — GPS Offset

### Problem
The dome center is visually offset from the user's actual position on the map.

### Cause
The dome anchor is using the cache key coordinates
(`lat.toStringAsFixed(2)`, ~1.1km resolution) rather than the raw GPS fix.

### Fix
The map center AND dome visual center must both use the raw
`stablePositionProvider` coordinates, not rounded values.

In `WindDomeScreen.initState()` and wherever GPS updates are consumed:
```dart
// WRONG — do not use this for positioning
final cacheKey = "${lat.toStringAsFixed(2)}_${lng.toStringAsFixed(2)}";

// RIGHT — use raw position for map center
final pos = ref.read(stablePositionProvider);
if (pos != null) {
  _mapController.move(LatLng(pos.latitude, pos.longitude), currentZoom);
}
```

The cache key is only for the `DomeWindFetcher` cache lookup. It must never
be used to derive screen or map positions.

---

## Issue 6 — Multi-Touch Gesture System

### Problem
Currently only single-finger drag is handled. Need proper multi-touch:

| Gesture | Action |
|---------|--------|
| 1-finger drag horizontal | Orbit azimuth (theta) |
| 1-finger drag vertical | Orbit elevation (phi) |
| 2-finger pinch | Zoom (camDist + map zoom) |
| 2-finger drag up/down | Perspective tilt (phi) |
| 2-finger drag horizontal | Map bearing (theta) |

### Fix
Replace `GestureDetector` with `Listener` + pointer tracking:

```dart
// State
final Map<int, Offset> _activePointers = {};
double _lastPinchDistance = 0;

Listener(
  onPointerDown: (e) {
    _activePointers[e.pointer] = e.localPosition;
  },
  onPointerMove: (e) {
    final prev = _activePointers[e.pointer];
    if (prev == null) return;
    
    if (_activePointers.length == 1) {
      // Single finger: orbit
      final delta = e.localPosition - prev;
      setState(() {
        _theta -= delta.dx * 0.007;
        _phi = (_phi - delta.dy * 0.005).clamp(0.15, pi * 0.46);
      });
      _mapController.rotate(-_theta * 180 / pi);
    } else if (_activePointers.length == 2) {
      // Two fingers: pinch to zoom
      final pointers = _activePointers.values.toList();
      final currentDist = (pointers[0] - pointers[1]).distance;
      if (_lastPinchDistance > 0) {
        final scale = currentDist / _lastPinchDistance;
        _onPinchUpdate(scale);
      }
      _lastPinchDistance = currentDist;
    }
    
    _activePointers[e.pointer] = e.localPosition;
  },
  onPointerUp: (e) {
    _activePointers.remove(e.pointer);
    if (_activePointers.length < 2) _lastPinchDistance = 0;
  },
  child: CustomPaint(painter: DomePainter(...)),
)
```

---

## Constants to Define (dome_constants.dart)

```dart
// Real-world dimensions
const double DOME_R_METERS_SMALL  = 500.0;
const double DOME_R_METERS_MEDIUM = 1000.0;
const double DOME_R_METERS_LARGE  = 2000.0;

// Render space conversion
// 1 render unit = how many meters. Tune so dome fills ~40% of screen width.
const double METERS_PER_RENDER_UNIT = 5.0;

// Derived render dimensions (recompute when domeSizeProvider changes)
// DOME_R_RENDER = domeRadiusMeters / METERS_PER_RENDER_UNIT
// DOME_H_RENDER = DOME_R_RENDER * 0.75

// Camera
const double BASE_CAM_DIST = 300.0;
const double MIN_CAM_DIST  = 150.0;   // max zoom in
const double MAX_CAM_DIST  = 1200.0;  // max zoom out
const double DEFAULT_PHI   = pi / 2.8;
const double DEFAULT_THETA = pi / 6.0;

// Map zoom
const double BASE_MAP_ZOOM  = 14.0;
const double MIN_MAP_ZOOM   = 8.0;
const double MAX_MAP_ZOOM   = 16.0;

// Zoom transition thresholds
const double DOME_THRESHOLD = 400.0;   // below = dome view
const double MAP_THRESHOLD  = 700.0;   // above = transitioning to map view
```

---

## Draw Order (DomePainter.paint)

Must be exactly this order so depth reads correctly:

```
1. _drawGroundDisc()      // dark filled ellipse — occludes map behind dome floor
2. _drawDomeWireframe()   // latitude rings + longitude meridians
3. _drawParticles()       // wind streaks with trail fade
4. _drawUserMarker()      // white dot + pulsing ring at (0, 0, 0)
```

---

## Issue 7 — Forecast Slider Does Not Update Particle Simulation

### Problem
Moving the slider changes `hoursAheadProvider` and `currentDomeWindFieldProvider`
updates correctly — but the particles keep moving in the same direction as before.
The wind field change is not reaching the tick loop.

### Cause
The ticker loop in `WindDomeScreen` is almost certainly capturing the wind field
in a local variable at initialization and never updating it:

```dart
// WRONG — captured once, never updated
final _windField = ref.read(currentDomeWindFieldProvider);  // stale forever

void _onTick(Duration elapsed) {
  for (final p in _particles) {
    p.tick(_windField, dt, domeR, domeH);  // always uses initial field
  }
}
```

### Fix
The tick loop must read the current wind field on every frame, not cache it.
Since the ticker runs outside the build cycle, use `ref.read()` (not `ref.watch()`)
inside the tick callback:

```dart
void _onTick(Duration elapsed) {
  // Read current field every tick — instant, no network call
  final windField = ref.read(currentDomeWindFieldProvider);
  if (windField == null) return;

  final dt = _lastTickTime == null
      ? 0.016
      : (elapsed - _lastTickTime!).inMicroseconds / 1_000_000.0;
  _lastTickTime = elapsed;

  for (final p in _particles) {
    p.tick(windField, dt, domeR, domeH);
  }

  _frameCounter.value++;
}
```

`ref.read()` in a ticker is safe and correct — it reads the current value
without subscribing to rebuilds. The Riverpod docs explicitly recommend this
pattern for animation loops.

### Why particles should visually react immediately
When `hoursAheadProvider` changes (slider moved), `currentDomeWindFieldProvider`
recomputes synchronously (it's just an array index lookup on the cached 72-hour
profile — no async). On the very next ticker tick, `ref.read(currentDomeWindFieldProvider)`
returns the new field. Particles start moving in the new wind direction within
one frame (~16ms). No loading, no delay.

### Verification
To confirm the fix works, set the slider to +48h and watch:
- Particles should noticeably change direction within 1-2 seconds (trail history
  has to flush out the old direction before the new one is fully visible)
- `DomeInfoBar` wind speed readout should update immediately on slider move
  (this is a separate read of the same provider — if it updates but particles
  don't, the ticker capture bug is confirmed)

### Also check: slider feedback
The slider should feel responsive. If there's any lag between dragging and the
`hoursAheadProvider` updating, check that `DomeForecastSlider` is calling
`onChanged` continuously during drag (not just `onChangeEnd`). Use `onChanged`
for live updates, `onChangeEnd` only if you want to debounce network calls
(which you don't need here since data is already cached).

```dart
Slider(
  value: hoursAhead.toDouble(),
  min: 0, max: 72, divisions: 72,
  onChanged: (v) {   // ← onChanged not onChangeEnd
    ref.read(hoursAheadProvider.notifier).state = v.round();
  },
)
```

---

## What NOT to Change

- Data pipeline (DomeWindFetcher, WindApiClient, providers) — working correctly
- DomeWindField.sample() interpolation — working correctly  
- DomeParticle tick loop and boundary check — working correctly
- DomeForecastSlider — working correctly
- DomeInfoBar Live/Fcst badge — working correctly
- Trail rendering math (brightness, fade) — working correctly

Only touch: DomePainter, WindDomeScreen gesture handling, dome_constants.dart,
and the MapController calls in WindDomeScreen.

---

## Visual Reference

Image 2 (the React/Three.js prototype) is the target. Key things to match:
- Dome is clearly 3D — you see it from an angle, not top-down
- Dark ground disc visible as the dome floor
- Map visible around the outside of the dome footprint
- Particles stream through the dome in a clear wind direction
- User marker at center base
- Wireframe ellipsoid shell faintly visible
- Camera angle: roughly 50° down from zenith (phi = pi/2.8)
