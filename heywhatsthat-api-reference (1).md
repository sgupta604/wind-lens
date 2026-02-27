# Wind Lens — HeyWhatsThat Terrain-Based Sky Detection

## Project Context: What is Wind Lens?

Wind Lens is an AR mobile app built in **Flutter** that creates the illusion of seeing invisible wind patterns in the real sky. The user points their phone's camera at the sky, and animated wind particles are rendered overlaid on the camera feed — but **only in sky regions**, not over buildings, trees, or ground. Think of it like viewing [earth.nullschool.net](https://earth.nullschool.net)'s wind visualization from the ground looking up, rather than from space looking down.

The visual reference / inspiration is earth.nullschool.net — flowing particle streams showing wind speed and direction, but rendered in AR on top of the real sky.

---

## The Core Technical Challenge: Sky Detection

The foundational problem that must be solved before anything else (particle rendering, wind data integration, etc.) is: **how does the app know which pixels in the camera feed are "sky" vs "not sky"?** Wind particles should only appear in sky regions. This is surprisingly hard to do well in real-time on a mobile device.

### Current Sky Detection Approaches (in the app)

**Approach 1: HSV Color Detection (currently implemented)**
- Samples the camera feed and identifies sky pixels based on HSV (Hue, Saturation, Value) color ranges
- Uses an auto-calibrating system that samples current sky colors to build adaptive HSV profiles rather than using hardcoded thresholds
- **Pros:** Works on every frame, catches local obstacles (buildings, trees), adapts to conditions
- **Cons:** Struggles with overcast/cloudy skies (especially relevant — Sanjay lives in a cloudy area), can misidentify blue-ish buildings or water as sky, requires per-frame processing

**Approach 2: ML Semantic Segmentation (explored but not implemented)**
- Models like DeepLabV3 (with CoreML optimization on iOS) can classify every pixel as sky/not-sky
- **Pros:** Most accurate, handles all sky conditions
- **Cons:** Computationally expensive on mobile — causes battery drain and frame drops. Mitigations include running at lower resolution/framerate and caching masks between frames, but it's still heavy.

**Approach 3: HeyWhatsThat Terrain-Based Detection (THIS DOCUMENT — proposed)**
- Uses real-world terrain elevation data to pre-compute a horizon profile: for every compass bearing, the exact elevation angle where terrain meets sky
- Combined with phone compass + accelerometer, this gives a sky mask with zero per-frame computation
- **Pros:** Zero runtime cost once data is fetched, accurate terrain boundaries, works regardless of sky color/weather
- **Cons:** Doesn't know about local obstacles (buildings, trees) — only terrain. Takes ~2 min to compute server-side on first use. Requires GPS + compass.

### The Plan: Toggle Between Methods

The app should offer these as selectable detection modes (and potentially combine them):
- **HSV Detection** — best for urban environments where buildings/trees matter
- **Terrain Detection (HeyWhatsThat)** — best for open/rural/mountainous areas
- **Combined** — use terrain as the coarse mask, HSV to refine local obstacles (future)
- **ML Segmentation** — most accurate but heaviest, optional for high-end devices (future)

### Other Relevant Architecture Decisions

- **Particle rendering:** Wind particles should feel like they exist at real altitudes in 3D space, not as flat screen overlays. This requires spatial depth perception tied to the camera's orientation.
- **Compass orientation:** At high pitch angles (looking straight up), compass bearing becomes unreliable due to gimbal lock — a known issue to be addressed.
- **Server-side compute:** The team has discussed offloading heavy calculations (like bilinear interpolation) to a server while the phone handles camera input and rendering.
- **Performance targets:** The app needs to maintain smooth framerates on a range of iPhone models.

---

## What is HeyWhatsThat? (TL;DR)

HeyWhatsThat ([heywhatsthat.com](https://www.heywhatsthat.com)) is a web tool originally designed to tell hikers which mountains they can see from a given location. You give it a GPS location + elevation, and it computes a **360° panoramic horizon profile** — for every compass bearing (0°–359°), it tells you the **elevation angle where terrain meets sky**.

It does this using **NASA SRTM elevation data** (Shuttle Radar Topography Mission, February 2000) — a digital elevation model covering 60°N to 54°S latitude with ~30m horizontal resolution in the US and ~100m elsewhere, with 1m vertical resolution.

For Wind Lens, this means: if you know the horizon angle at each bearing, anything in the camera view **above** that angle = sky → render wind particles. Anything **below** = terrain → no particles. No ML needed, no per-frame computation.

### Key Limitation

SRTM data captures **terrain** (mountains, ridges, valleys), but NOT individual buildings, trees, cranes, etc. In cities, the FAQ warns you'll get "shadowy bumps and gaps" because the elevation data accidentally picks up some rooftops, but it's not precise. Works best in open/rural/mountainous areas. This is why the HSV detection should remain as a complementary option.

### Other Technical Notes from HeyWhatsThat
- **Refraction:** They model atmospheric refraction (bending of light through air), adding ~3.6 arcseconds per mile. This slightly raises the apparent altitude of distant terrain. Default refraction coefficient is 0.14. Probably overkill for Wind Lens but available if needed.
- **Declination:** The result includes magnetic declination for the location, which may be useful for compass calibration.
- **Coverage:** Latitude 60°N to 54°S, plus Alaska and some European extensions. Does NOT cover the extreme Arctic or Antarctic.

---

## Discovered Endpoints

### 1. Submit a New Panorama

```
GET https://www.heywhatsthat.com/bin/query.cgi?
    lat={latitude}
    &lon={longitude}
    &elev={elevation_in_meters}
    &elev_is_absolute={0_for_above_ground_1_for_above_sea_level}
    &name={panorama_title}
    &public=0
    &return_data=1
    &refraction={optional, default 0.14}
```

**Response:** First line contains the panorama ID and metadata (space-delimited).
**Computation takes ~2 minutes server-side.**

### 2. Poll for Completion

```
GET https://www.heywhatsthat.com/results/{panorama_id}/data
```

**Response when ready:** `ok {lat} {lon} {elev_amsl} {elev_agl} {is_public} {queued_time} {end_time} ...`
**Response when not ready:** Empty or error.
Poll every ~10 seconds (that's what their frontend does).

### 3. Get Full Panorama Result (⭐ THE IMPORTANT ONE)

```
GET https://www.heywhatsthat.com/bin/result.json?id={panorama_id}
```

**Response:** JSON with the following structure:

```json
{
  "id": "battie",
  "lat": 44.2230556,
  "lon": -69.0691667,
  "elev_amsl": 241.83,
  "elev_agl": 1.83,
  "declination": -15,
  "refraction": 0.14,

  "limits": [
    [44.241389, -69.068889, 4.682898],
    [44.241389, -69.068889, 4.839022],
    ...
  ],

  "peaks": [
    {
      "name": "Bernard Mountain",
      "az": 80.74,
      "alt": -0.14,
      "elev": 322,
      "range": 56328,
      "lat": 44.3025,
      "lon": -68.3725
    },
    ...
  ],

  "image": {
    "alt_max": 5.14,
    "alt_min": -7,
    "az_min": 0,
    "az_max": 360,
    "width": 800,
    "height": 160
  }
}
```

**The `limits` array is the horizon profile:**
- **360 entries** — one per degree of bearing (index 0 = 0°/North, index 90 = 90°/East, etc.)
- Each entry: `[lat, lon, altitude_angle_degrees]`
- The **third value** is the elevation angle of the horizon at that bearing
- Positive = terrain above the horizontal plane, Negative = horizon dips below horizontal (e.g., looking out to sea)

### 4. Get Horizon Altitude at a Specific Bearing

```
GET https://www.heywhatsthat.com/bin/horizon-alt.cgi?id={panorama_id}&bearing={degrees}
```

**Response:** Single number — the elevation angle in degrees.

Example responses:
- Bearing 0° (North): `4.571415` (terrain is ~4.6° above horizontal)
- Bearing 90° (East): `-0.453624` (horizon dips slightly below horizontal)
- Bearing 180° (South): `-0.463161`

This is useful if you want finer resolution than the 360-entry `limits` array — you can query arbitrary bearings.

### 5. Line of Sight Between Two Points

```
GET https://www.heywhatsthat.com/bin/get-los.cgi?
    lat0={viewer_lat}&lon0={viewer_lon}&gnd0={ground_elev}&agl0={above_ground}
    &lat1={target_lat}&lon1={target_lon}&gnd1={target_elev}&agl1=0
    &refraction={refraction_value}
```

### 6. Path Elevation Profile

```
GET https://www.heywhatsthat.com/api/path-elev.csv?
    src={your_identifier}
    &pt0={lat},{lon}
    &pt1={lat},{lon}
    &n={num_points}
```

**Note:** This API requires authorization for non-demo use. Contact them to get a `src` identifier.

### 7. Visibility Polygon ("Up in the Air")

```
GET https://www.heywhatsthat.com/api/upintheair.json?id={panorama_id}&alts={altitude_in_meters}
```

Returns a JSON polygon of coordinates showing where an object at the given altitude would be visible from the panorama's location. Originally designed for tracking aircraft visibility.

---

## How to Reverse Engineer Further (What Joe Meant)

### Using Browser DevTools

1. Open `https://www.heywhatsthat.com/` in Chrome
2. Open DevTools → **Network** tab → check "Preserve log"
3. Click **New panorama** → enter a location → submit
4. Watch the Network tab — you'll see:
   - `query.cgi` — the submission
   - `data` — periodic status polling
   - `result.json` — the full result once ready
   - `.png` files — the panorama silhouette images
5. Click on any request to see the full URL, parameters, headers, and response

### Key JavaScript Files

- **`utils-angle-request6.js`** — Contains all the HTTP helper functions and utility code
- **Main HTML** — Contains the application logic including `handle_query()`, `check_pending_answers()`, `show_result()`, etc.

### Helper Function Pattern

All API calls in the frontend use these wrappers:
```javascript
// Synchronous
wt_request(url, error_label)

// Async
wt_async_request(url, error_label, callback)

// File path builder
results_file(id, filename) → '/results/' + id + '/' + filename
```

---

## Integration Plan for Wind Lens (Flutter)

### Overview

The integration has three phases: (1) fetch horizon data from HeyWhatsThat, (2) map it onto the camera view using device sensors, (3) use it as a sky mask for particle rendering.

### Phase 1: Fetch & Cache Horizon Data

**On app launch or significant location change (>100m):**

1. Get user's GPS coordinates via Flutter's location services
2. Submit a panorama request to `query.cgi` with lat/lon and a default elevation of ~2m above ground (phone held at eye level)
3. Poll `results/{id}/data` every 10 seconds until ready (~2 minutes)
4. Fetch `result.json` and extract the `limits` array (360 entries)
5. Cache locally — this data is static for a given location and doesn't expire

**Data to store per location:**
```dart
class HorizonProfile {
  final double lat;
  final double lon;
  final String panoramaId;
  final List<double> horizonAngles; // 360 values, index = bearing degree
  final double declination; // magnetic declination for compass correction
  final DateTime fetchedAt;
}
```

Extract horizon angles from the limits array:
```dart
List<double> horizonAngles = limits.map((entry) => entry[2] as double).toList();
// horizonAngles[0] = elevation angle at bearing 0° (true north)
// horizonAngles[90] = elevation angle at bearing 90° (east)
// etc.
```

### Phase 2: Map Horizon Profile onto Camera View

**Required sensor inputs:**
- **Compass heading** (magnetometer) — which direction the phone is pointing horizontally
- **Pitch angle** (accelerometer/gyroscope) — how far up/down the phone is tilted
- **Camera field of view** (FOV) — horizontal and vertical, from camera intrinsics

**Per-frame sky mask computation:**
```
For each pixel in the camera frame:
    1. Compute the pixel's bearing:
       pixel_bearing = compass_heading + (pixel_x - center_x) * (horizontal_FOV / frame_width)
       Normalize to 0-360°

    2. Compute the pixel's elevation angle:
       pixel_elevation = phone_pitch + (center_y - pixel_y) * (vertical_FOV / frame_height)
       (Note: y is inverted — top of frame = higher elevation)

    3. Look up the horizon angle at that bearing:
       horizon_alt = horizonAngles[floor(pixel_bearing)]
       (Or interpolate between adjacent degrees for smoother results)

    4. Compare:
       is_sky = pixel_elevation > horizon_alt
```

**Important compass correction:** The `limits` array uses **true north** bearings. Phone magnetometers report **magnetic north**. Use the `declination` value from the result.json to convert:
```dart
double trueBearing = magneticBearing + declination;
```

**Gimbal lock warning:** When the phone pitch approaches 90° (pointing straight up), compass heading becomes unreliable. This is a known issue in the app. At very high pitch angles, you may need to fall back to HSV detection or assume "everything is sky" since you're looking nearly straight up.

### Phase 3: Use as Sky Mask for Particle Rendering

Once you have `is_sky` for each region of the camera view, use it the same way the HSV detection currently gates particle rendering. Particles only spawn/render in sky regions.

The terrain mask is especially stable — unlike HSV which can flicker frame-to-frame as colors shift, the terrain mask only changes when the phone rotates. This should give very clean, stable sky boundaries for the particle system.

### Phase 4 (Future): Combine with HSV

A combined approach could use terrain as the primary mask (coarse but stable) and HSV to subtract local obstacles:
```
final_sky_mask = terrain_says_sky AND hsv_says_sky
```
Or use terrain as the ceiling and HSV as refinement — if terrain says "sky" but HSV says "not sky" (because there's a building in the way), trust HSV for that pixel.

### Things to Consider

- **Caching:** A panorama takes ~2 minutes to compute. Pre-compute and cache by location. You could even pre-compute a grid of panoramas covering a region.
- **Movement:** The horizon profile only changes meaningfully if the user moves a significant distance (100m+). No need to recompute constantly.
- **Interpolation:** The `limits` array gives 1° resolution. For smoother masking, interpolate between adjacent bearings, or use `horizon-alt.cgi` for arbitrary precision (but that's a network call per bearing — better to interpolate locally).
- **Rate limits / Terms:** The API docs note that high-volume unauthorized use is restricted. Contact HeyWhatsThat if you plan to use this in a shipping app. For prototyping, low-volume use is fine.
- **Offline / Self-hosted:** Consider downloading SRTM data directly from NASA/USGS (it's free) and computing horizon profiles on your own server, bypassing HeyWhatsThat entirely. This would eliminate the dependency on their service and rate limits. The math is well-documented — you'd ray-trace from the viewer position outward through the elevation grid at each bearing to find where terrain meets sky.
- **Loading UX:** The 2-minute initial compute means you need a loading state. Consider showing the app with HSV detection first, then switching to terrain detection once the panorama is ready. Or pre-compute for common locations.
