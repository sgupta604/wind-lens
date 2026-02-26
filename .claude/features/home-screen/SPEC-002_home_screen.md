# SPEC-002: Home Screen (HomeScreen Feature)

## Overview

Replace the current behavior where the app opens directly into the live camera AR view. Instead, show a **HomeScreen** as the app's entry point. The home screen gives context, shows current wind data at a glance, and lets the user tap into the live AR camera experience intentionally.

**Reference screenshot:** See `home_screen_mockup.png` provided alongside this spec.

---

## Problem Being Solved

Right now `main.dart` / `app.dart` routes directly to `ARViewScreen`. On cold launch, the user is immediately staring at a camera feed with no context. This is jarring — permissions dialogs fire immediately, the screen is black while the camera initialises, and there is no sense of "what is this app doing".

The home screen acts as a **landing layer**: it reads from the existing Riverpod provider graph (wind data, horizon profile, sensor state) and presents them in a calm, dashboard-style view. The user explicitly taps "Live AR" to enter the camera view.

---

## Design Specification

### Theme

- **Background:** Pure black (`#000000`)
- **Text:** White (`#FFFFFF`) and mid-grey (`#444444`) for secondary/label text
- **Accent:** None. Strictly monochrome. No colour except the white "Live AR" button.
- **Font (display):** `Bebas Neue` (Google Fonts). Used for logo wordmark and large numeric values.
- **Font (body/mono):** `DM Mono` (Google Fonts). Used for labels, unit text, compass points, layer buttons.
- **Grain / texture:** Optional subtle noise overlay (very low opacity ~0.04) on top of everything for depth.

### Layout (top → bottom, full screen)

```
┌─────────────────────────────────────┐
│  STATUS BAR (system)                │
│  DYNAMIC ISLAND / notch area        │
├─────────────────────────────────────┤
│  TOP BAR                            │
│   [WindLens logo]    [Live AR btn]  │
│    "Atmospheric AR" subtitle        │
├─────────────────────────────────────┤
│  DIVIDER (1px, #111111)             │
├─────────────────────────────────────┤
│  WIND DATA ROW                      │
│   Speed | Direction | Altitude      │
├─────────────────────────────────────┤
│                                     │
│  TERRAIN PANORAMA SECTION           │
│  (flex: fills remaining space)      │
│   • B&W terrain image centred       │
│   • Animated particle canvas        │
│   • Altitude rail (right edge)      │
│   • Compass bar (bottom edge)       │
│   • Faint grid overlay              │
│                                     │
├─────────────────────────────────────┤
│  LAYER TOGGLES                      │
│   [Particles] [Pressure] [Terrain] [Clouds] │
├─────────────────────────────────────┤
│  HOME INDICATOR                     │
└─────────────────────────────────────┘
```

---

## Component Details

### Top Bar

- **Logo (left):**
  - Large text: `"WindLens"` in Bebas Neue, size ~32sp, white.
  - Subtitle below: `"ATMOSPHERIC AR"` in DM Mono, size ~9sp, grey (`#444`), letter-spacing wide.
- **Live AR Button (right):**
  - White filled pill (`borderRadius: 100`).
  - Contains: pulsing red dot (animate opacity 1.0 → 0.5 → 1.0, duration 1.4s) + text `"LIVE AR"` in DM Mono, black, uppercase, letter-spacing 0.15em.
  - On tap: `Navigator.push` to `ARViewScreen`.
  - Padding: horizontal 18, vertical 10.

### Divider

- `Divider(thickness: 1, color: Color(0xFF111111))` with horizontal margin 28.

### Wind Data Row

Three equal-width columns separated by `VerticalDivider(color: Color(0xFF111111))`:

| Column | Label | Value source | Unit |
|--------|-------|-------------|------|
| Speed | `"SPEED"` | `sceneState?.wind.speed` → format to 1 decimal | `"mph"` |
| Direction | `"DIRECTION"` | `sceneState?.wind.directionDegrees` → cardinal (e.g. `"SSW"`) | `"bearing 202°"` |
| Altitude | `"ALTITUDE"` | `selectedAltitudeProvider` → display name | `"ft AGL"` |

- Value text: Bebas Neue, ~28sp, white.
- Label text: DM Mono, ~8sp, dark grey (`#333`), uppercase, letter-spacing 0.25em.
- Unit text: DM Mono, ~9sp, grey (`#444`), letter-spacing 0.15em.
- While `sceneState` is null: show `"—"` as placeholder values (do not show spinner here).
- Padding: 18 vertical, 28 horizontal on the outer row.

**Cardinal direction helper** (add to `core/utils/wind_utils.dart` or inline):
```dart
String degreesToCardinal(double degrees) {
  const directions = ['N','NNE','NE','ENE','E','ESE','SE','SSE',
                       'S','SSW','SW','WSW','W','WNW','NW','NNW'];
  final index = ((degrees % 360) / 22.5).round() % 16;
  return directions[index];
}
```

### Terrain Panorama Section

This is the centrepiece. It occupies all remaining vertical space (`Expanded`).

#### Background grid
- `CustomPaint` or `Container` with `DecorationImage` pattern, or just a `GridPaper`-style overlay.
- Lines: `rgba(255,255,255,0.025)`, 48px spacing, both horizontal and vertical.
- Sits behind everything else in this section.

#### Terrain silhouette (procedural, no external data)

Draw a decorative mountain/terrain silhouette using `CustomPainter`. This is **not** connected to `horizonProfileProvider` yet — it is a static procedural shape. When P2B-002 (HeyWhatsThat) lands, the path points will be replaced with real `HorizonProfile.elevationAngles` data using the same painter.

**Painter class:** `HomeTerrainPainter extends CustomPainter`

**Path construction:**
```dart
@override
void paint(Canvas canvas, Size size) {
  final paint = Paint()
    ..color = const Color(0xFF1a1a1a)   // dark charcoal silhouette
    ..style = PaintingStyle.fill;

  // Control points as fractions of size.width / size.height
  // y=0 is top of section, y=1 is bottom
  // Shape: flat approach from left, broad rise to ~40% height around x=0.25,
  //        dip to horizon at x=0.45, jagged peak cluster x=0.6–0.75, taper right
  final path = Path();
  path.moveTo(0, size.height);                              // bottom-left

  // Left flat ground → first rise
  path.lineTo(0, size.height * 0.72);
  path.quadraticBezierTo(
    size.width * 0.08, size.height * 0.70,
    size.width * 0.15, size.height * 0.62,
  );
  // Broad hill
  path.cubicTo(
    size.width * 0.20, size.height * 0.45,
    size.width * 0.28, size.height * 0.40,
    size.width * 0.35, size.height * 0.55,
  );
  // Valley / horizon dip
  path.quadraticBezierTo(
    size.width * 0.42, size.height * 0.65,
    size.width * 0.48, size.height * 0.60,
  );
  // First peak
  path.cubicTo(
    size.width * 0.52, size.height * 0.50,
    size.width * 0.56, size.height * 0.35,
    size.width * 0.60, size.height * 0.38,
  );
  // Jagged ridge cluster
  path.lineTo(size.width * 0.63, size.height * 0.48);
  path.lineTo(size.width * 0.66, size.height * 0.30);  // tallest peak
  path.lineTo(size.width * 0.69, size.height * 0.42);
  path.lineTo(size.width * 0.72, size.height * 0.34);
  path.lineTo(size.width * 0.75, size.height * 0.46);
  // Taper to right
  path.quadraticBezierTo(
    size.width * 0.85, size.height * 0.60,
    size.width * 1.0,  size.height * 0.68,
  );
  path.lineTo(size.width, size.height);                     // bottom-right
  path.close();

  canvas.drawPath(path, paint);

  // Thin ridge highlight line — 1px lighter stroke along the top of the silhouette
  final ridgePaint = Paint()
    ..color = const Color(0xFF2e2e2e)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  // Re-trace just the top edge (same path, open — don't close to bottom)
  final ridgePath = Path();
  ridgePath.moveTo(0, size.height * 0.72);
  ridgePath.quadraticBezierTo(
    size.width * 0.08, size.height * 0.70,
    size.width * 0.15, size.height * 0.62,
  );
  ridgePath.cubicTo(
    size.width * 0.20, size.height * 0.45,
    size.width * 0.28, size.height * 0.40,
    size.width * 0.35, size.height * 0.55,
  );
  ridgePath.quadraticBezierTo(
    size.width * 0.42, size.height * 0.65,
    size.width * 0.48, size.height * 0.60,
  );
  ridgePath.cubicTo(
    size.width * 0.52, size.height * 0.50,
    size.width * 0.56, size.height * 0.35,
    size.width * 0.60, size.height * 0.38,
  );
  ridgePath.lineTo(size.width * 0.63, size.height * 0.48);
  ridgePath.lineTo(size.width * 0.66, size.height * 0.30);
  ridgePath.lineTo(size.width * 0.69, size.height * 0.42);
  ridgePath.lineTo(size.width * 0.72, size.height * 0.34);
  ridgePath.lineTo(size.width * 0.75, size.height * 0.46);
  ridgePath.quadraticBezierTo(
    size.width * 0.85, size.height * 0.60,
    size.width * 1.0,  size.height * 0.68,
  );
  canvas.drawPath(ridgePath, ridgePaint);
}

@override
bool shouldRepaint(HomeTerrainPainter oldDelegate) => false; // static, never repaints
```

**Layering:** The terrain silhouette sits between the grid background and the particle canvas. Stack order (bottom → top):
1. Grid overlay (faint lines)
2. `HomeTerrainPainter` (silhouette fill)
3. `HomeParticlePainter` (animated particles — flow over AND in front of terrain)
4. Altitude rail overlay
5. Compass bar overlay

**Horizon line:** Draw a subtle 1px horizontal rule at ~`size.height * 0.65` in the terrain painter (colour `rgba(255,255,255,0.10)`) to suggest the horizon even when the silhouette dips below it.

**Future swap-in point:** When `HorizonProfile` data is available, replace the hardcoded control points with values derived from `profile.elevationAngles`. The bearing range (0–360°) maps to x (0–width), and elevation angle maps to y (inverted: higher elevation = lower y value). The painter signature should accept an optional `HorizonProfile? profile` parameter — if null, use the hardcoded decorative path; if non-null, generate the path from real data.

```dart
class HomeTerrainPainter extends CustomPainter {
  final HorizonProfile? profile; // null = decorative fallback
  HomeTerrainPainter({this.profile, required Listenable repaint}) : super(repaint: repaint);
  // ...
}
```

#### Animated wind particles

Use a `CustomPainter` driven by an `AnimationController` (ticker from `SingleTickerProviderStateMixin`).

**Particle model (local, not `Particle` class from core):**
```dart
class _HomeParticle {
  double x, y, vx, vy, life, maxLife, radius, waveOffset;
  List<Offset> trail = [];
}
```

**Spawn logic:**
- 80 particles total.
- Each spawns from left edge (vx positive) or right edge (vx negative) with 95%/5% probability.
- y position: random in middle 70% of section height.
- vx: 0.5–1.6 px/frame.
- vy: ±0.15 px/frame.
- Add sinusoidal wiggle: `vy += sin(waveOffset + x * 0.015) * 0.1` each tick.
- Life: 0 → maxLife (0.5–1.0). Alpha = `sin(life/maxLife * π) * 0.6`.
- Trail: keep last 20 positions, draw with tapered opacity.
- Reset when life >= maxLife or x out of bounds.

**Paint:**
```dart
// Trail
for (int i = 1; i < trail.length; i++) {
  final t = i / trail.length;
  paint.color = Colors.white.withOpacity(t * alpha * 0.4);
  paint.strokeWidth = radius * t * 0.8;
  canvas.drawLine(trail[i-1], trail[i], paint);
}
// Head dot
paint.color = Colors.white.withOpacity(alpha);
canvas.drawCircle(position, radius, paint);
```

**Wind influence (optional enhancement):** If `sceneState?.wind` is available, bias `vx` direction and magnitude proportionally to `windData.uComponent`. This makes the particles actually flow in the direction of real wind data.

#### Altitude rail (right edge, absolute positioned)

5 ticks, evenly spaced vertically:

| Label | State |
|-------|-------|
| `10,000 ft` | inactive |
| `7,500 ft` | inactive |
| `2,400 ft ◀` | **active** (matches `selectedAltitudeProvider`) |
| `1,000 ft` | inactive |
| `Surface` | inactive |

- Each tick: label text (DM Mono, 8sp) + horizontal line (12px wide).
- Active tick: label white, line white (18px, glow shadow), triangle marker `◀`.
- Inactive tick: label `#282828`, line `#222222`.
- Tapping a tick calls `ref.read(selectedAltitudeProvider.notifier).select(altitudeLevel)`.

#### Compass bar (bottom of terrain section, absolute positioned)

8 cardinal/intercardinal directions in a horizontal row:
`N  NE  E  SE  S  SW  W  NW`

- Text: DM Mono, 9sp.
- Active (heading nearest to `sensorNotifiersProvider.headingNotifier.value`): grey (`#666`).
- Inactive: `#222`.
- Positioned 14px from bottom of terrain section, full width with 28px horizontal padding.
- Update via `ValueListenableBuilder` on `headingNotifier` — **not** via `setState` — to avoid rebuilds.

### Layer Toggles

Four equal-width buttons in a horizontal row:

| Label | Default state |
|-------|--------------|
| Particles | `on` |
| Pressure | `dim` |
| Terrain | `on` |
| Clouds | `dim` |

**States:**
- `on`: `background: white`, `text: black`.
- `dim`: `background: #111`, `border: #222`, `text: #555`.
- `off`: transparent, border `#1a1a1a`, text `#2e2e2e`.

- Text: DM Mono, 9sp, uppercase, letter-spacing 0.15em.
- Border radius: 6.
- Height: ~38px.
- Gap between buttons: 8px.
- Outer padding: 0 28px, 18px bottom, 0 top (border-top from terrain section is the separator).
- In MVP these buttons can be visual-only (no functional wiring needed yet). Wire to `detectionModeProvider` in a follow-up.

---

## Navigation

```dart
// In Live AR button onTap:
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const ARViewScreen()),
);
```

`ARViewScreen` is unchanged — it still owns the camera, sky detection, and particle overlay.

---

## File Structure

```
lib/features/home/
├── home_screen.dart          # Main screen widget
└── widgets/
    ├── home_top_bar.dart         # Logo + Live AR button
    ├── home_wind_row.dart        # Speed/Direction/Altitude data row
    ├── home_terrain_section.dart # Panorama + particles + rails
    ├── home_particle_painter.dart # CustomPainter for particles
    ├── home_altitude_rail.dart   # Right-edge altitude ticks
    ├── home_compass_bar.dart     # Bottom compass row
    └── home_layer_toggles.dart   # Bottom button row
```

`home_screen.dart` should be a `ConsumerStatefulWidget` (needs `TickerProviderStateMixin` for the animation controller AND Riverpod reads).

---

## Provider Usage

| Provider | Used for |
|----------|---------|
| `sceneStateProvider` | Wind data (speed, direction, altitude label) |
| `selectedAltitudeProvider` | Active altitude level for rail + wind display |
| `sensorNotifiersProvider` | `headingNotifier` for compass bar active direction |
| `horizonProfileProvider` | Future: drive the terrain silhouette painter |
| `stablePositionProvider` | Future: coordinates for "Loading…" fallback |

Read pattern:
```dart
final sceneState = ref.watch(sceneStateProvider);
final sensorNotifiers = ref.watch(sensorNotifiersProvider);
final selectedAltitude = ref.watch(selectedAltitudeProvider);
```

---

## App Entry Point Change

In `lib/app.dart`, change `home:` from `ARViewScreen` to `HomeScreen`:

```dart
// Before
home: const ARViewScreen(),

// After
home: const HomeScreen(),
```

No other routing changes needed.

---

## Fonts Setup

Add to `pubspec.yaml` (if not already present):
```yaml
dependencies:
  google_fonts: ^6.1.0
```

Usage:
```dart
import 'package:google_fonts/google_fonts.dart';

// Display font
TextStyle(
  fontFamily: GoogleFonts.bebasNeue().fontFamily,
  fontSize: 32,
  color: Colors.white,
  letterSpacing: 2,
)

// Mono font
TextStyle(
  fontFamily: GoogleFonts.dmMono().fontFamily,
  fontSize: 9,
  color: const Color(0xFF444444),
  letterSpacing: 3,
)
```

Alternatively, bundle the fonts locally in `assets/fonts/` if offline support is needed.

---

## Assets

No new assets required. The terrain silhouette is fully procedural. No PNG, no network fetch, no external dependency.

---

## Animation Controller

```dart
late AnimationController _particleController;

@override
void initState() {
  super.initState();
  _particleController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();
}

@override
void dispose() {
  _particleController.dispose();
  super.dispose();
}
```

Pass `_particleController` to `HomeParticlePainter` as the `repaint` listenable:
```dart
CustomPaint(
  painter: HomeParticlePainter(
    animation: _particleController,
    windData: sceneState?.wind,
  ),
  child: const SizedBox.expand(),
)
```

The painter mutates particle state on each `paint()` call — this is intentional (same pattern as `ParticleOverlay`).

---

## Accessibility

- Live AR button: `Semantics(label: 'Open live AR camera view', button: true, child: ...)`.
- Wind values: `Semantics(label: 'Wind speed ${speed} miles per hour', child: ...)`.
- Terrain section: `ExcludeSemantics(child: ...)` — purely decorative animation.

---

## Tests

Create `test/features/home/home_screen_test.dart`:

1. **Renders without crashing** — wrap in `ProviderScope` with overridden service providers (same pattern as `ar_view_screen_test.dart`).
2. **Shows placeholder values** when `sceneState` is null (providers still loading).
3. **Shows wind values** when `sceneState` is non-null.
4. **Live AR button navigates** to `ARViewScreen` on tap.
5. **Altitude rail active tick** matches `selectedAltitudeProvider` value.
6. **Layer toggle state** — `on` buttons have white background.

Aim for 8–12 tests. Do NOT test particle animation behavior (platform rendering).

---

## MVP Scope (Phase 1 of this feature)

Build the complete UI with:
- [x] Procedural terrain silhouette (`HomeTerrainPainter`, bezier path, static decorative)
- [x] Animated particles (CustomPainter, 80 particles, trail rendering)
- [x] Wind data row reading from `sceneStateProvider`
- [x] Live AR button navigating to `ARViewScreen`
- [x] Altitude rail (visual only, tapping changes `selectedAltitudeProvider`)
- [x] Compass bar (reads `headingNotifier` via `ValueListenableBuilder`)
- [x] Layer toggles (visual only, no functional wiring)

**Deferred to follow-up:**
- [ ] Real terrain silhouette from `HorizonProfile.elevationAngles` (swap in when P2B-002 lands — `HomeTerrainPainter` already accepts optional `HorizonProfile? profile` param)
- [ ] Layer toggle wiring to `detectionModeProvider`
- [ ] Wind-influenced particle direction from real `windData.uComponent`
- [ ] Transition animation into `ARViewScreen` (fade or slide)

---

## Known Constraints from SPEC-001

- **Do NOT use Freezed for `_HomeParticle`** — it is a mutable hot-path object updated every frame.
- **Do NOT push sensor data through `setState`** — use `ValueListenableBuilder` on `sensorNotifiers.headingNotifier` for the compass bar.
- **The `AnimationController` rebuild loop** replaces `setState` for the particle canvas — the `CustomPainter` repaints via the controller's `repaint` listenable, not via widget rebuild.
- **`SkyMaskData` is not involved** — this screen has no camera and no sky detection.
- `HomeScreen` does NOT own any services. All data comes from the existing provider graph.
- The `as HsvSkyDetector` cast code smell (noted in SPEC-001) is in `ARViewScreen` — do not introduce any similar casts in `HomeScreen`.

---

## Definition of Done

- [x] `flutter test` passes all existing tests + new home screen tests (628 passing, 2026-02-26)
- [x] `dart analyze` reports 0 errors, 0 warnings (infos from Riverpod generated code are pre-existing and acceptable)
- [x] `build_runner` reports no issues
- [x] App opens to `HomeScreen` (not camera) on cold launch
- [x] "Live AR" button opens `ARViewScreen`
- [x] Wind data populates from real providers (shows `—` while loading, then real values)
- [x] Particles animate smoothly on screen
- [x] No visible jank or frame drops on the home screen itself
