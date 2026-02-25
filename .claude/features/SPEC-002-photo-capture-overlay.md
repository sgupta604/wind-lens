# SPEC-002: Photo Capture & Wind Overlay on Captured Image

## Overview

This feature lets users take a photo of the sky and overlay animated (or static) wind particles onto it. The key technical challenge: once a photo is captured, the wind overlay must be computed from **frozen** sensor data at the moment of capture — not live sensors. The user's phone will move after taking the photo, but the overlay must remain anchored to the sky region shown in the captured image.

This spec assumes SPEC-001 (Architectural Foundation) has been implemented — specifically the Freezed models, service interfaces, and Riverpod provider graph.

---

## Prerequisites from SPEC-001

These must exist before starting this feature:
- `SceneState` Freezed model (position, horizon, wind, heading, pitch, skyMask, altitude)
- `HorizonProfile` model with `getElevationAtBearing(double bearing)` method
- `SkyDetector` interface + at least one working implementation (HSV)
- `WindDataSource` interface + at least one working implementation (mock or OGC EDR)
- Provider graph where `sceneStateProvider` composes all live data into a single state object
- `SensorNotifiers` for high-frequency heading/pitch access

---

## Core Concept: Frozen Scene State

The critical insight for this feature:

**Live AR mode** = watch reactive streams, everything updates continuously
**Photo review mode** = read a frozen snapshot, nothing updates

A captured photo represents a specific moment in time, a specific direction the phone was pointed, and a specific patch of sky. The overlay computation uses ONLY the frozen data, never live sensors.

```
CAPTURE MOMENT
==============
User taps shutter
        │
        ▼
┌──────────────────────────────────────────┐
│  Freeze all current values:              │
│  - Camera image bytes                    │
│  - GPS position (lat/lng/alt)            │
│  - Compass heading (e.g. 247.3°)        │
│  - Phone pitch (e.g. 38.5°)             │
│  - Horizon profile (full 360° terrain)   │
│  - Wind data (speed, direction, gusts)   │
│  - Sky mask (current frame's sky region) │
│  - Selected altitude level               │
│  - Timestamp                             │
└──────────────────────────────────────────┘
        │
        ▼
  CapturedScene (immutable, stored)
        │
        ▼
  Overlay computed from CapturedScene only
  (phone can be put in pocket, doesn't matter)
```

---

## Data Model

### `lib/core/models/captured_scene.dart`

```dart
@freezed
class CapturedScene with _$CapturedScene {
  const factory CapturedScene({
    /// Unique identifier for this capture
    required String id,

    /// The raw camera image
    required Uint8List imageBytes,

    /// Image dimensions
    required int imageWidth,
    required int imageHeight,

    /// Camera field of view at capture time (degrees)
    required double horizontalFov,
    required double verticalFov,

    /// Frozen sensor & data state at moment of capture
    required PositionData position,
    required double compassHeading,    // center of image points at this bearing
    required double pitch,             // center of image points at this elevation
    required HorizonProfile horizon,
    required WindData wind,
    required AltitudeLevel altitude,

    /// When the photo was taken
    required DateTime capturedAt,

    /// Optional: the sky mask computed at capture time
    SkyMask? skyMask,
  }) = _CapturedScene;

  factory CapturedScene.fromJson(Map<String, dynamic> json) =>
      _$CapturedSceneFromJson(json);
}
```

### Why every field matters

| Field | Why it's needed for the overlay |
|---|---|
| `imageBytes` | The photo itself to render behind the overlay |
| `imageWidth/Height` | Pixel dimensions for coordinate mapping |
| `horizontalFov / verticalFov` | Maps pixel columns/rows to compass bearings and elevation angles. Without this, you can't know which part of the sky each pixel represents. |
| `compassHeading` | The center of the image points at this bearing. Pixel column 0 = heading - (hFov/2), pixel column max = heading + (hFov/2). |
| `pitch` | The center of the image points at this elevation angle. Determines where the horizon line falls in the image. |
| `horizon` | The full 360° terrain profile. Combined with heading and hFov, tells you exactly which part of the horizon is visible and where sky begins in the image. |
| `wind` | Speed, direction, gusts — drives particle animation on the overlay. |
| `altitude` | Which altitude layer to visualize (surface, mid-level, jet stream). |

---

## Capture Flow

### Step 1: Capture Provider

```dart
// lib/features/snapshot/providers/capture_provider.dart

@riverpod
class CaptureController extends _$CaptureController {
  @override
  CapturedScene? build() => null;

  Future<CapturedScene?> capture(CameraController camera) async {
    // 1. Take the photo
    final image = await camera.takePicture();
    final bytes = await image.readAsBytes();
    final decoded = img.decodeImage(bytes);

    // 2. READ (not watch) current state — snapshot, not subscription
    final scene = ref.read(sceneStateProvider);
    if (scene == null) return null;  // can't capture without data

    // 3. Get camera FOV
    // On iOS: AVCaptureDevice.activeFormat.videoFieldOfView
    // On Android: CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS
    // + SENSOR_INFO_PHYSICAL_SIZE to compute FOV
    final fov = ref.read(cameraFovProvider);

    // 4. Freeze everything into an immutable CapturedScene
    final captured = CapturedScene(
      id: const Uuid().v4(),
      imageBytes: bytes,
      imageWidth: decoded.width,
      imageHeight: decoded.height,
      horizontalFov: fov.horizontal,
      verticalFov: fov.vertical,
      position: scene.position,
      compassHeading: scene.compassHeading,
      pitch: scene.pitch,
      horizon: scene.horizon,
      wind: scene.wind,
      altitude: scene.selectedAltitude,
      capturedAt: DateTime.now(),
      skyMask: scene.skyMask,
    );

    state = captured;
    return captured;
  }
}
```

### Key: `ref.read()` not `ref.watch()`

Using `read` grabs the current value without subscribing. This means the captured scene is truly frozen — if GPS updates a second later, the captured scene doesn't change.

### Step 2: Camera FOV

You need the camera's field of view to map pixels to sky coordinates. This is hardware-specific.

```dart
// lib/core/services/camera_fov_service.dart

class CameraFov {
  final double horizontal;  // degrees
  final double vertical;    // degrees

  const CameraFov({required this.horizontal, required this.vertical});
}

abstract class CameraFovService {
  Future<CameraFov> getFov();
}

class DeviceCameraFovService implements CameraFovService {
  @override
  Future<CameraFov> getFov() async {
    // Platform channel to get focal length + sensor size
    // hFov = 2 * atan(sensorWidth / (2 * focalLength)) * (180 / pi)
    // vFov = 2 * atan(sensorHeight / (2 * focalLength)) * (180 / pi)

    // Typical smartphone values (use as defaults if platform data unavailable):
    // iPhone: ~63° horizontal, ~50° vertical (wide lens)
    // Android varies: ~60-75° horizontal
  }
}
```

**Important**: FOV changes if the user zooms. Capture the FOV at the moment of capture, not a static default.

---

## Sky Boundary Computation for Captured Image

This is the core math: mapping the horizon profile onto the captured photo to determine which pixels are sky.

### The coordinate system

```
IMAGE COORDINATE SYSTEM
========================

(0,0) ─────────────────────── (width,0)
  │                               │
  │    ↑ higher elevation         │
  │    │                          │
  │    │    Sky region             │
  │    │                          │
  │    ├────── horizon line ──────│
  │    │                          │
  │    │    Ground/terrain        │
  │    │                          │
  │    ↓ lower elevation          │
  │                               │
(0,height) ──────────────── (width,height)

MAPPING:
- Pixel column → compass bearing
- Pixel row → elevation angle
- Horizon profile → row where sky begins for each column
```

### Pixel-to-bearing mapping

```dart
/// For a captured image, maps pixel column to compass bearing.
double pixelColumnToBearing({
  required int column,
  required int imageWidth,
  required double centerHeading,  // compass heading at capture
  required double horizontalFov,
}) {
  // Column 0 = left edge = centerHeading - hFov/2
  // Column max = right edge = centerHeading + hFov/2
  final degreesPerPixel = horizontalFov / imageWidth;
  final offsetFromCenter = (column - imageWidth / 2) * degreesPerPixel;
  return (centerHeading + offsetFromCenter) % 360;
}
```

### Pixel-to-elevation mapping

```dart
/// For a captured image, maps pixel row to elevation angle.
double pixelRowToElevation({
  required int row,
  required int imageHeight,
  required double centerPitch,  // phone pitch at capture
  required double verticalFov,
}) {
  // Row 0 = top of image = highest elevation
  // Row max = bottom = lowest elevation
  final degreesPerPixel = verticalFov / imageHeight;
  final offsetFromCenter = (imageHeight / 2 - row) * degreesPerPixel;
  return centerPitch + offsetFromCenter;
}
```

### Computing the horizon line in the image

```dart
/// Returns the pixel row where sky begins for each column.
/// Pixels ABOVE this row are sky, pixels BELOW are ground/terrain.
List<int> computeHorizonLineInImage(CapturedScene scene) {
  final horizonRow = List<int>.filled(scene.imageWidth, 0);

  for (int col = 0; col < scene.imageWidth; col++) {
    // What bearing does this column represent?
    final bearing = pixelColumnToBearing(
      column: col,
      imageWidth: scene.imageWidth,
      centerHeading: scene.compassHeading,
      horizontalFov: scene.horizontalFov,
    );

    // What's the terrain elevation at this bearing?
    final terrainElevation = scene.horizon.getElevationAtBearing(bearing);

    // What pixel row corresponds to this elevation?
    horizonRow[col] = elevationToPixelRow(
      elevation: terrainElevation,
      imageHeight: scene.imageHeight,
      centerPitch: scene.pitch,
      verticalFov: scene.verticalFov,
    );
  }

  return horizonRow;
}

int elevationToPixelRow({
  required double elevation,
  required int imageHeight,
  required double centerPitch,
  required double verticalFov,
}) {
  final degreesPerPixel = verticalFov / imageHeight;
  final offsetFromCenter = (elevation - centerPitch) / degreesPerPixel;
  // Elevation increases upward, but pixel rows increase downward
  return (imageHeight / 2 - offsetFromCenter).round().clamp(0, imageHeight - 1);
}
```

### Sky mask from horizon line

```dart
SkyMask computeSkyMaskForCapture(CapturedScene scene) {
  final horizonLine = computeHorizonLineInImage(scene);
  final pixels = List<bool>.filled(scene.imageWidth * scene.imageHeight, false);

  for (int col = 0; col < scene.imageWidth; col++) {
    final horizonRow = horizonLine[col];
    for (int row = 0; row < horizonRow; row++) {
      pixels[row * scene.imageWidth + col] = true;  // sky
    }
  }

  return SkyMask(
    width: scene.imageWidth,
    height: scene.imageHeight,
    pixels: pixels,
    method: SkyDetectionMethod.terrain,
  );
}
```

---

## Overlay Rendering

### Static Overlay (Simplest — start here)

Draw wind direction indicators and streamlines on the sky region of the captured image.

```dart
class CapturedSceneOverlayPainter extends CustomPainter {
  final CapturedScene scene;
  final SkyMask skyMask;

  CapturedSceneOverlayPainter({
    required this.scene,
    required this.skyMask,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw the captured photo as background
    final image = decodeImageFromBytes(scene.imageBytes);
    canvas.drawImage(image, Offset.zero, Paint());

    // 2. Compute wind direction in image coordinates
    //    Wind direction (meteorological) = where wind comes FROM
    //    Particle direction = where wind goes TO = windDir + 180
    final windBearingTo = (scene.wind.direction + 180) % 360;

    // 3. For each particle position in the sky region:
    //    - Check skyMask to confirm it's sky
    //    - Draw a streamline/arrow in the wind direction
    //    - Color based on wind speed (blue → purple gradient, matching live AR)
    _drawStreamlines(canvas, size, windBearingTo);
  }

  void _drawStreamlines(Canvas canvas, Size size, double windBearingTo) {
    // Generate streamline start points distributed across sky region
    // For each start point:
    //   - Step along wind direction in pixel space
    //   - Only draw while skyMask says current pixel is sky
    //   - Apply speed-based color gradient
    //   - Apply depth parallax based on altitude level
  }
}
```

### Animated Overlay (Enhanced — build after static works)

Same as static but particles flow. Since the image is frozen, this is actually simpler than live AR — no camera movement to compensate for.

```dart
class AnimatedCaptureOverlayPainter extends CustomPainter {
  final CapturedScene scene;
  final SkyMask skyMask;
  final Animation<double> animation;  // drives particle flow

  AnimatedCaptureOverlayPainter({
    required this.scene,
    required this.skyMask,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;  // 0.0 → 1.0, loops

    // Same as static, but particle positions offset by:
    // offset = windSpeed * t * pixelsPerMeterAtThisAltitude
    // This makes particles flow across the image in wind direction
  }
}
```

Wire with an `AnimationController` in the review screen:
```dart
class CaptureReviewScreen extends ConsumerStatefulWidget {
  @override
  _CaptureReviewScreenState createState() => _CaptureReviewScreenState();
}

class _CaptureReviewScreenState extends ConsumerState<CaptureReviewScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),  // one full cycle
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    final captured = ref.watch(captureControllerProvider);
    if (captured == null) return const SizedBox();

    final skyMask = computeSkyMaskForCapture(captured);

    return CustomPaint(
      painter: AnimatedCaptureOverlayPainter(
        scene: captured,
        animation: _controller,
        skyMask: skyMask,
      ),
    );
  }
}
```

---

## Panoramic Capture (Future Enhancement)

### Concept

Instead of a single photo, the user pans their phone across the sky and the app stitches together a wide panoramic view with a continuous wind overlay.

### How it works

```
PAN SEQUENCE
============
User starts panning →
  Frame 1: heading=200°, pitch=40° → capture
  Frame 2: heading=215°, pitch=40° → capture
  Frame 3: heading=230°, pitch=40° → capture
  ...
  Frame N: heading=320°, pitch=40° → capture

Each frame is a CapturedScene with its own heading.
Stitched together, they cover 200°-320° of sky = 120° panorama.
```

### Data model

```dart
@freezed
class PanoramicCapture with _$PanoramicCapture {
  const factory PanoramicCapture({
    required String id,

    /// Ordered list of captures from left to right (ascending heading)
    required List<CapturedScene> frames,

    /// Total angular coverage
    required double startBearing,
    required double endBearing,

    /// Common data (should be consistent across all frames)
    required PositionData position,
    required HorizonProfile horizon,
    required WindData wind,
    required AltitudeLevel altitude,

    required DateTime capturedAt,
  }) = _PanoramicCapture;
}
```

### Capture guidance UX

```
┌────────────────────────────────────────┐
│                                        │
│        [Camera Preview]                │
│                                        │
│  ◄ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ►   │
│    Pan slowly across the sky           │
│                                        │
│  Progress: ████████░░░░  67%           │
│  Coverage: 200° → 280° (of 320°)      │
│                                        │
│         [Stop Capture]                 │
└────────────────────────────────────────┘
```

### Implementation approach

1. Start capture session → record starting heading
2. As user pans, auto-capture frames at regular angular intervals (every ~15° of heading change)
3. Each frame freezes heading, pitch, and image at that moment
4. Position, horizon, and wind are read once at session start (they won't change meaningfully during a 20-second pan)
5. Stop capture → assemble PanoramicCapture
6. Stitch images using heading overlap
7. Overlay wind on the full panorama using the same bearing-to-pixel math, just applied across the wider image

### Stitching considerations

- Frames will overlap by ~5-10° of horizontal FOV. Use the heading data to compute exact overlap region.
- Simple approach: blend overlapping regions with linear alpha gradient
- Advanced: use OpenCV (via `opencv_dart` package) for feature-based stitching if heading data isn't precise enough
- The horizon line should be continuous across the panorama since all frames share the same `HorizonProfile`

---

## UI Flow

### Capture button in AR view

```
AR VIEW (live mode)
┌──────────────────────────┐
│                          │
│   [Camera + Particles]   │
│                          │
│  🧭 Compass    📷 ← capture button
│  ▒▒ Altitude slider      │
└──────────────────────────┘
        │
        │ tap 📷
        ▼
CAPTURE REVIEW SCREEN
┌──────────────────────────┐
│  ← Back                  │
│                          │
│  [Frozen photo +         │
│   animated wind overlay] │
│                          │
│  Wind: 12.3 m/s NW      │
│  Alt: Surface            │
│  Heading: 247°           │
│  Pitch: 38°              │
│                          │
│  [Save] [Share] [Retake] │
└──────────────────────────┘
```

### Review screen info panel

Show the frozen data as metadata on the review screen:
- Wind speed + direction (as arrow + text)
- Altitude level
- Compass heading (what direction the photo faces)
- Location (city/area name, geocoded from lat/lng)
- Timestamp

This metadata also embeds into the saved image as EXIF or as a watermark, so shared images carry context.

---

## Saving & Sharing

### Save options

1. **Image with overlay baked in** — render the CustomPaint to a `ui.Image`, encode as PNG/JPEG. The wind visualization becomes part of the image pixels. This is what gets shared on social media.

```dart
Future<Uint8List> renderOverlayToImage(CapturedScene scene, SkyMask skyMask) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Paint the scene (photo + overlay)
  final painter = CapturedSceneOverlayPainter(scene: scene, skyMask: skyMask);
  painter.paint(canvas, Size(scene.imageWidth.toDouble(), scene.imageHeight.toDouble()));

  final picture = recorder.endPicture();
  final image = await picture.toImage(scene.imageWidth, scene.imageHeight);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
```

2. **Original photo + metadata** — save the raw `CapturedScene` to local storage so the user can re-render the overlay with different altitude levels or detection modes later.

### Share flow

```dart
Future<void> shareCapture(CapturedScene scene) async {
  final overlayImage = await renderOverlayToImage(scene, computeSkyMaskForCapture(scene));

  // Save to temp file
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/windlens_${scene.id}.png');
  await file.writeAsBytes(overlayImage);

  // Share via platform share sheet
  await Share.shareXFiles(
    [XFile(file.path)],
    text: 'Wind at ${scene.wind.speed.toStringAsFixed(1)} m/s '
        '${_bearingToCardinal(scene.wind.direction)} '
        '— captured with Wind Lens',
  );
}
```

---

## Storage

### Local capture storage

Use Isar or Hive to persist captures locally. Store the `CapturedScene` JSON + image file separately (don't serialize large byte arrays into JSON).

```dart
class CaptureStore {
  final Directory _captureDir;

  Future<void> save(CapturedScene scene) async {
    // Save image file
    final imageFile = File('${_captureDir.path}/${scene.id}.jpg');
    await imageFile.writeAsBytes(scene.imageBytes);

    // Save metadata (everything except imageBytes)
    final metaFile = File('${_captureDir.path}/${scene.id}.json');
    final json = scene.toJson();
    json.remove('imageBytes');  // stored separately
    await metaFile.writeAsString(jsonEncode(json));
  }

  Future<CapturedScene?> load(String id) async {
    final imageFile = File('${_captureDir.path}/$id.jpg');
    final metaFile = File('${_captureDir.path}/$id.json');

    if (!await imageFile.exists() || !await metaFile.exists()) return null;

    final bytes = await imageFile.readAsBytes();
    final meta = jsonDecode(await metaFile.readAsString());
    meta['imageBytes'] = base64Encode(bytes);

    return CapturedScene.fromJson(meta);
  }

  Future<List<String>> listCaptures() async {
    return _captureDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .map((f) => basenameWithoutExtension(f.path))
        .toList();
  }
}
```

---

## Provider Graph for Capture Feature

```
CAPTURE FEATURE PROVIDERS
=========================

captureControllerProvider (CapturedScene?)
  └── reads: sceneStateProvider (snapshot at capture time)
  └── reads: cameraFovProvider

capturedSkyMaskProvider (SkyMask)
  └── watches: captureControllerProvider
  └── computes sky mask from frozen horizon + heading + pitch

captureOverlayProvider (AnimatedCaptureOverlayPainter)
  └── watches: captureControllerProvider
  └── watches: capturedSkyMaskProvider

captureStoreProvider (CaptureStore)
  └── manages persistence
```

These providers are **independent** from the live AR providers. The capture feature reads from the live graph once (at capture time) and then operates on its own frozen data. This means:
- Taking a photo doesn't affect the live AR view
- Reviewing a photo doesn't consume sensor resources
- The user can go back to live AR while a save/share is in progress

---

## Edge Cases & Gotchas

### 1. Camera FOV varies by device
Don't hardcode FOV. Query the platform for focal length and sensor size. Provide sensible defaults (63° horizontal for iPhone-like devices) as a fallback if the platform API fails.

### 2. Photo orientation
The image may be rotated based on device orientation (portrait vs landscape) and front/back camera. Store the EXIF orientation with the capture and account for it when mapping pixels to bearings.

### 3. Sky mask may disagree with terrain
The HSV sky mask (color-based) and terrain sky mask (geometry-based) may not align perfectly. For captures, prefer the terrain mask if a horizon profile is available — it's deterministic and doesn't depend on lighting conditions in the photo.

### 4. Wind data may be stale
If the wind data in the provider graph is from a cache that's 10 minutes old, the captured scene will have 10-minute-old wind. This is acceptable — display the wind data timestamp in the review screen metadata so the user knows.

### 5. No GPS fix or no horizon data
If the user captures before terrain data has loaded:
- Still allow capture (don't block on terrain)
- Use the HSV sky mask from the capture-time frame
- Display a note: "Terrain data unavailable — using color-based sky detection"
- Optionally: re-render the overlay later when terrain data arrives (since the capture stores position data, the horizon can be fetched retroactively)

### 6. Phone pointed at ground
If pitch is significantly negative (pointing down), there may be no sky in the frame. Detect this and show a message: "Point your camera at the sky to capture wind patterns."

### 7. Night / dark sky
HSV sky detection will struggle in low light. Terrain-based detection works regardless of lighting since it's purely geometric. This is another reason to prefer terrain mask for captures when available.

---

## Implementation Order

1. **CapturedScene model** — Freezed class, JSON serialization
2. **CameraFovService** — platform channel to get FOV
3. **CaptureController provider** — freezes SceneState on shutter tap
4. **Sky boundary math** — pixel ↔ bearing ↔ elevation mapping functions
5. **Static overlay painter** — draw wind on frozen photo (no animation)
6. **Capture review screen** — display photo + overlay + metadata
7. **Animated overlay** — add flowing particles on the frozen image
8. **Save/share** — render overlay to image, persist, share sheet
9. **CaptureStore** — local persistence for review later
10. **Panoramic capture** — multi-frame stitching (future enhancement)

Start with steps 1-6 to get a working end-to-end flow. Steps 7-9 polish the experience. Step 10 is a separate effort.

---

## Testing

### Unit tests
- `pixelColumnToBearing` and `pixelRowToElevation` — verify correct mapping at center, edges, and with various headings/pitches
- `computeHorizonLineInImage` — verify with known terrain profiles (flat = straight line, mountain = bump)
- `computeSkyMaskForCapture` — verify pixels above horizon are sky, below are ground
- Bearing wraparound — heading near 0°/360° should handle panoramic coverage across north correctly

### Integration tests
- Capture freezes the correct heading/pitch (not a value from 1 frame later)
- Capture works when horizon data is unavailable (falls back to HSV mask)
- Save + load roundtrip preserves all metadata accurately
- Overlay renders identically from saved capture as from fresh capture

### Visual tests (manual)
- Capture a photo of a known landmark with visible horizon → verify horizon line in overlay matches reality
- Capture facing north, south, east, west → verify wind direction arrows point correctly in all orientations
- Capture at different pitches (low, medium, straight up) → verify sky coverage looks right
