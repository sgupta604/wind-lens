# Wind Lens Phase 2 Roadmap

> **Purpose:** Features to implement after MVP bug fixes are complete.
> Each feature goes through the pipeline: `/research` → `/plan` → `/implement` → `/test` → `/finalize`

---

## Current Status

**MVP:** Complete (8/8 features)
**Post-MVP Bugs:** Complete (9/9 fixed - BUG-001 through BUG-009)
**Phase 2a Features:** 4/4 complete (performance-optimization, wind-streamlines, particle-colors, compass-widget DONE)
**Additional fixes:** compass-native (flutter_compass), code-cleanup (debug panel extraction)
**Tests:** 628+ passing (610 auto-discovered + explicit paths + 18 home-screen)
**Current Branch:** `feature/wind-dome-homescreen`
**Ready for:** home-screen test/finalize, then wind-dome implementation

---

## Phase 2 Feature Summary

| # | Feature | Priority | Complexity | Status | Description |
|---|---------|----------|------------|--------|-------------|
| P2A-001 | performance-optimization | ~~High~~ | ~~Medium~~ | **DONE** | Fix FPS (5 to 45+) |
| P2A-002 | wind-streamlines | ~~High~~ | ~~High~~ | **DONE** | Windy.com style flowing trails |
| P2A-003 | compass-widget | ~~Medium~~ | ~~Low~~ | **DONE** | Compass showing heading |
| P2A-004 | particle-colors | ~~Medium~~ | ~~Low~~ | **DONE** | Included in wind-streamlines |
| SPEC-001 | architectural-foundation | ~~Critical~~ | ~~High~~ | **DONE** | Freezed models, Riverpod, service interfaces, directory restructure. 606 tests. **Summary:** `.claude/features/architectural-foundation/SUMMARY.md` |
| SPEC-002 | photo-capture-overlay | Medium | High | **Backburner** | Capture photo + frozen wind overlay. **Spec:** `.claude/features/SPEC-002-photo-capture-overlay.md` |
| P2B-001 | location-service | ~~High~~ | ~~Low~~ | **DONE** | GPS coordinates + permission handling |
| P2B-002+003 | heywhatsthat-client | **High** | Medium | Waiting (needs SPEC-001) | API client + local horizon caching (merged) |
| P2B-004+005 | terrain-sky-mask | **High** | Medium | Waiting | Terrain sky detection + mode toggle (merged) |
| P2B-006 | real-wind-data | ~~High~~ | ~~High~~ | **DONE** | Real wind from OGC EDR APIs (Shyft/Folkweather). **Summary:** `.claude/features/real-wind-data/SUMMARY.md` |
| SPEC-003 | home-screen | **High** | Medium | **Implementing** | HomeScreen entry point with ShyftLens branding. **Spec:** `.claude/features/home-screen/SPEC-002_home_screen.md` |
| SPEC-004 | wind-dome | **High** | High | Planned | 3D wind dome visualization. **Spec:** `.claude/features/wind-dome/SPEC-002-wind-dome.md` |
| P2C-001 | map-view | Medium | High | Future | Toggle AR to top-down weather map view |
| P2C-002 | altitude-input | Low | Medium | Future | Input specific altitude in feet |

---

## Feature Details

---

### Phase 2b: Terrain Sky Detection & Location

> **Branch:** `feature/terrain-sky-detection`
> **Goal:** Use real-world terrain elevation data (via HeyWhatsThat) to pre-compute sky boundaries, replacing/complementing the current HSV color-based sky detection. Each step is independently testable and useful.
>
> **Reference docs:**
> - `/workspace/heywhatsthat-api-reference (1).md` — API endpoints, integration plan, data structures
> - `/workspace/sky-claculation.md` — FOV/frustum math, EDR query radius calculations

---

### P2B-001: location-service

**Priority:** High
**Complexity:** Low
**Blocked by:** None
**Why first:** Everything else (HeyWhatsThat, real wind data) needs GPS coordinates.

**What to Build:**
- LocationService class that provides GPS coordinates (lat, lon)
- Request location permission (iOS + Android)
- Stream-based updates when user moves
- Show lat/lon in debug panel

**Technical Notes:**
- Use `geolocator` package for GPS
- Combine with existing CompassService heading (already working)
- Only need coarse location (~10m accuracy is fine)
- Handle permission denied gracefully (fall back to HSV-only detection)

**Acceptance Criteria:**
- [ ] App requests and receives GPS location
- [ ] LocationService provides stream of position updates
- [ ] Debug panel shows lat/lon
- [ ] Handles permission denied without crashing
- [ ] All existing tests still pass

---

### P2B-002: heywhatsthat-client

**Priority:** High
**Complexity:** Medium
**Depends on:** P2B-001 (needs lat/lon to submit panorama)

**What to Build:**
- HeyWhatsThatService class that wraps the API
- Submit panorama: `query.cgi?lat=X&lon=Y&elev=2&public=0&return_data=1`
- Poll for completion: `results/{id}/data` every 10 seconds
- Fetch result: `result.json?id={id}` → extract `limits` array (360 horizon angles)
- Return a `HorizonProfile` model with 360 elevation angles + declination

**Key Data Structure:**
```dart
class HorizonProfile {
  final double lat, lon;
  final String panoramaId;
  final List<double> horizonAngles; // 360 values, index = bearing degree
  final double declination;         // magnetic declination for compass correction
  final DateTime fetchedAt;
}
```

**Technical Notes:**
- Server-side computation takes ~2 minutes — need loading state
- `limits` array: 360 entries, each `[lat, lon, elevation_angle_degrees]`
- `horizonAngles[0]` = elevation angle at true north, `[90]` = east, etc.
- Extract `declination` from result for compass correction later
- Handle network errors, timeouts gracefully

**Acceptance Criteria:**
- [ ] Can submit a panorama request and get back a panorama ID
- [ ] Polls until computation completes
- [ ] Parses result.json into HorizonProfile model
- [ ] Handles network errors without crashing
- [ ] All existing tests still pass

---

### P2B-003: horizon-cache

**Priority:** High
**Complexity:** Low
**Depends on:** P2B-002 (needs HorizonProfile to cache)

**What to Build:**
- Local persistence for HorizonProfile data
- Cache key: rounded lat/lon (to ~100m precision)
- Skip API call if cached profile exists within 100m of current location
- Cache doesn't expire (terrain doesn't change)

**Technical Notes:**
- Use `shared_preferences` or local JSON file
- Panorama computation is 2 minutes — caching avoids repeated waits
- 360 doubles + metadata = tiny storage footprint
- Consider pre-computing a few profiles for user's common locations (future)

**Acceptance Criteria:**
- [ ] HorizonProfile saved to local storage after fetch
- [ ] On app launch, loads cached profile if within 100m of current GPS
- [ ] Skips HeyWhatsThat API call when cache hit
- [ ] Cache miss triggers new panorama request
- [ ] All existing tests still pass

---

### P2B-004: terrain-sky-mask

**Priority:** High
**Complexity:** Medium
**Depends on:** P2B-003 (needs cached HorizonProfile), existing CompassService

> **⚠️ PREREQUISITE from SPEC-001:** ARViewScreen currently hard-casts `ref.read(skyDetectorInstanceProvider) as HsvSkyDetector` to access `skyFraction` and `forceRecalibrate()`. These methods are on the concrete class, NOT the `SkyDetector` interface. **Before implementing P2B-004**, either add `skyFraction`/`forceRecalibrate()` to the `SkyDetector` interface, or create a separate `SkyDetectorDebugInfo` provider. Otherwise the cast will break when TerrainSkyDetector is wired in. See `.claude/features/architectural-foundation/DECISIONS.md` Phase 3a section for full context.

**What to Build:**
- TerrainSkyDetector that implements the existing SkyDetector interface
- For each screen region, compute bearing + elevation angle from compass heading + pitch + camera FOV
- Look up horizon angle at that bearing from HorizonProfile
- If pixel elevation > horizon angle → sky, else → not sky
- Apply magnetic declination correction: `trueBearing = magneticBearing + declination`

**Per-frame sky mask computation:**
```
For each pixel/region:
  pixel_bearing = compass_heading + (pixel_x - center_x) * (hFOV / width)
  pixel_elevation = pitch + (center_y - pixel_y) * (vFOV / height)
  horizon_alt = horizonAngles[round(pixel_bearing) % 360]
  is_sky = pixel_elevation > horizon_alt
```

**Technical Notes:**
- Interpolate between adjacent horizon angles for smoother boundaries
- Camera FOV: ~60-70° horizontal, ~80° vertical (get from camera intrinsics or use defaults)
- At pitch ~90° (straight up), compass heading unreliable (gimbal lock) — assume all sky
- The mask only changes when phone rotates, so it's very stable compared to HSV
- Must implement same `SkyDetector` interface so particle overlay can use it seamlessly

**Acceptance Criteria:**
- [ ] TerrainSkyDetector produces sky mask from horizon profile + device orientation
- [ ] Correctly maps screen coordinates to bearing/elevation
- [ ] Applies magnetic declination correction
- [ ] Handles gimbal lock at high pitch angles
- [ ] Integrates with existing particle rendering (same interface as HSV detector)
- [ ] All existing tests still pass

---

### P2B-005: detection-mode-toggle

**Priority:** High
**Complexity:** Low
**Depends on:** P2B-004 (needs TerrainSkyDetector available)

**What to Build:**
- UI control to switch sky detection mode: HSV / Terrain / Combined
- HSV = current behavior (color-based, good for urban/buildings)
- Terrain = HeyWhatsThat horizon (good for rural/mountains, weather-independent)
- Combined = terrain AND HSV (terrain as coarse mask, HSV refines local obstacles)
- Show active mode in debug panel
- Default to HSV until terrain data loads, then auto-switch to Terrain (or Combined)

**Technical Notes:**
- Add to existing debug panel or as a small toggle near altitude slider
- Combined mode: `is_sky = terrain_says_sky AND hsv_says_sky`
- When terrain data not available (no GPS, no cache), gray out Terrain/Combined options
- Save preference to local storage

**Acceptance Criteria:**
- [ ] User can toggle between HSV / Terrain / Combined
- [ ] Default is HSV, auto-switches when terrain data ready
- [ ] Combined mode uses intersection of both masks
- [ ] Debug panel shows active detection mode
- [ ] Graceful fallback when terrain data unavailable
- [ ] All existing tests still pass

---

### P2B-006: real-wind-data

**Priority:** High
**Complexity:** High
**Depends on:** P2B-001 (needs GPS location)

**What to Build:**
- Integrate OGC EDR API for real wind data at user's location
- Fetch wind components (u, v) at pressure levels (1000hPa, 850hPa, 250hPa)
- Map to existing altitude levels (surface, mid, jet stream)
- Replace FakeWindService with real data when available
- Query radius: 10-20km centered on user position

**Technical Notes:**
- EDR supports `radius` and `bbox` queries
- Cache data — wind doesn't change second-to-second
- Refresh on significant location change or periodically (every 5-10 min)
- Fallback to fake data on network error
- FOV math from sky-calculation research: ~10-20km radius covers visible sky dome

**Acceptance Criteria:**
- [ ] Fetches real wind data from EDR API
- [ ] Updates particles with real wind direction/speed
- [ ] Handles API errors gracefully (falls back to fake data)
- [ ] Caches data to reduce API calls
- [ ] All existing tests still pass

---

### Feature 3: compass-widget

**Status:** ✅ **DONE** (2026-02-03)

**What Was Built:**
- Circular compass widget (68x68px) in bottom-left corner
- Shows N/S/E/W cardinal directions
- Rotates based on device heading from CompassService
- Red triangle indicator at top shows camera direction
- Glassmorphism styling matching AltitudeSlider and InfoBar
- N label is red and larger (14px) than other labels (12px)

**Technical Implementation:**
- StatelessWidget with heading parameter
- CompassPainter CustomPainter for dial rendering
- Positioned 60px above InfoBar as Layer 7 in ARViewScreen
- shouldRepaint optimization (only repaints when heading changes)
- Edge case handling (0°, 180°, 360°, negative, overflow)

**Acceptance Criteria:**
- [x] Compass widget visible in corner
- [x] Rotates smoothly with device heading
- [x] Shows N/S/E/W labels
- [x] Doesn't obscure other UI elements
- [x] All 375 tests passing (added 17 new tests)
- [x] No analyzer errors

**Summary:** Implemented circular compass widget showing device heading with rotating cardinal directions. See `.claude/features/compass-widget/SUMMARY.md`

**Commit:** 2c93e83 - feat(ui): add compass widget showing device heading

---

### Feature 4: particle-colors

**Priority:** Medium
**Complexity:** Low
**Blocked by:** None

**What to Build:**
- Improve particle visibility against various sky conditions
- Consider: cloudy (gray), clear (blue), sunset (orange), overcast (white)
- Options:
  - Adaptive colors based on detected sky color (inverse/complement)
  - Higher contrast colors (bright cyan, magenta)
  - Add particle outlines/glow for visibility
  - User setting to choose color scheme

**Why Needed:**
- User feedback: "colors we have chosen for the particles don't look great... kinda difficult to see in the sky"
- Current white particles hard to see on cloudy/overcast days
- Need particles to stand out regardless of sky conditions

**Technical Notes:**
- Current colors: White (surface), Cyan (mid), Purple (jet)
- Could sample average sky color and pick complementary
- Could add black outline to particles for contrast
- Could increase glow intensity

**Acceptance Criteria:**
- [ ] Particles clearly visible on cloudy sky
- [ ] Particles clearly visible on clear blue sky
- [ ] Different altitude levels still distinguishable
- [ ] Performance not impacted

---

### Feature 5: map-view

**Priority:** Medium
**Complexity:** High
**Depends on:** location-awareness, real-wind-data

**What to Build:**
- Toggle button to switch from AR view to top-down map view
- Map shows:
  - User's location (center)
  - Wind patterns as vectors/particles on map
  - Optional: radar/weather overlay
- Familiar weather map interface

**Why Needed:**
- AR is cool but sometimes you want traditional view
- Easier to see large-scale weather patterns
- Can show data from further away than visible sky

**Technical Notes:**
- Use `flutter_map` or `google_maps_flutter` package
- Overlay wind vectors on map tiles
- Button in corner to toggle views
- Preserve altitude selection between views

**Acceptance Criteria:**
- [ ] Toggle button switches AR ↔ Map view
- [ ] Map centered on user location
- [ ] Wind data displayed on map
- [ ] Smooth transition between views

---

### Feature 6: real-wind-data

**Priority:** High
**Complexity:** High
**Depends on:** location-awareness, sky-viewport

**What to Build:**
- Integrate real wind data API (EDR or similar)
- Fetch wind data for user's location and viewing direction
- Parse wind components (u, v) at different pressure levels
- Map to existing altitude levels (surface, mid, jet)

**Why Needed:**
- Currently using fake/simulated wind data
- Real data makes app actually useful
- Core value proposition of the app

**Technical Notes:**
- EDR API provides wind at pressure levels (1000hPa, 850hPa, 250hPa)
- Need to handle API rate limits, caching
- Fetch on location change or periodically
- Handle offline/error states gracefully

**Acceptance Criteria:**
- [ ] Fetches real wind data from API
- [ ] Updates particles with real wind direction/speed
- [ ] Handles API errors gracefully
- [ ] Caches data to reduce API calls

---

### Feature 7: altitude-input

**Priority:** Low
**Complexity:** Medium
**Blocked by:** None

**What to Build:**
- Allow user to input specific altitude in feet/meters
- Map altitude to nearest available data level
- Show actual altitude value, not just "Surface/Mid/Jet"

**Why Needed:**
- User feedback: "eventually it would be cool to input like how many feet i want"
- More precise control for aviation/meteorology use
- Professional feature for power users

**Technical Notes:**
- Add text input or picker to altitude slider
- Convert feet ↔ pressure levels
- Surface: ~0-1000ft, Mid: ~5000ft, Jet: ~35000ft
- May need more granular data levels

**Acceptance Criteria:**
- [ ] User can input altitude in feet
- [ ] Displays actual altitude value
- [ ] Maps to available data levels
- [ ] Graceful handling of out-of-range values

---

### Feature 8: performance-optimization

**Status:** ✅ **DONE** (2026-02-02)

**Summary:** Fixed FPS from 5 to 45+ through debugPrint removal, setState elimination, and memory allocation reduction. See `.claude/features/performance-optimization/SUMMARY.md`

---

### Feature 9: wind-streamlines

**Status:** ✅ **DONE** (2026-02-03)

**Priority:** High
**Complexity:** High
**Blocked by:** None (but combines well with particle-colors)

**What to Build:**
- Replace current dot/sprinkle particles with **flowing wind streamlines** like Windy.com
- Particles leave animated trails showing wind direction and flow
- Trail length varies by altitude (longer at jet stream, shorter at surface)
- Color gradient based on wind speed (blue→green→yellow→red→purple)
- Toggle option to switch between "Dots" and "Streamlines" view modes

**Reference:**
- Current: `/workspace/images/app_img.PNG` (dot sprinkles)
- Goal: `/workspace/images/windy_img_goal.png` (Windy.com flowing streamlines)

**Why Needed:**
- Current dots look like "sprinkles" - don't convey wind motion
- Streamlines show actual wind flow direction intuitively
- Windy.com style is industry standard for wind visualization
- Much more visually compelling and informative

**Technical Specifications:**

*Trail Length (by altitude):*
| Level | Trail Length | Rationale |
|-------|--------------|-----------|
| Jet Stream | 15-20% screen width | Fast winds = long dramatic trails |
| Mid-level | 8-12% screen width | Medium winds = medium trails |
| Surface | 4-6% screen width | Slow winds = shorter trails |

*Speed-Based Color Gradient:*
| Speed (m/s) | Color | Hex |
|-------------|-------|-----|
| 0-5 | Blue | #3B82F6 |
| 5-10 | Cyan | #06B6D4 |
| 10-20 | Green | #22C55E |
| 20-35 | Yellow | #EAB308 |
| 35-50 | Orange | #F97316 |
| 50+ | Red/Purple | #EF4444 → #A855F7 |

*Particle Trail Implementation:*
```dart
class StreamlineParticle {
  List<Offset> trailPoints;  // History of positions (10-30 points)
  double age;
  double speed;
  double direction;

  void update(double dt, WindData wind) {
    // Add current position to trail
    trailPoints.add(currentPosition);
    // Remove oldest point if trail too long
    if (trailPoints.length > maxTrailLength) {
      trailPoints.removeAt(0);
    }
    // Move particle based on wind
    currentPosition += windVelocity * dt;
  }
}
```

*Rendering:*
- Draw trail as curved path (not straight line)
- Trail fades from full opacity (head) to transparent (tail)
- Use quadratic bezier curves for smooth flow
- Optional: slight glow/blur on trail for visibility

*View Mode Toggle:*
- Add toggle in UI (or long-press altitude slider)
- Options: "Dots" | "Streamlines"
- Save preference to local storage

**Technical Notes:**
- May need to reduce particle count for performance (streamlines more expensive)
- Consider using `Path` and `drawPath` for smooth trails
- Pre-allocate trail point arrays to avoid GC
- Use `Float32List` for trail coordinates if needed
- Test on device - ensure 45+ FPS maintained

**Acceptance Criteria:**
- [x] Particles render as flowing streamlines (not dots)
- [x] Trail length varies by altitude level (surface=12, mid=18, jet=25 points)
- [x] Colors shift based on wind speed (blue→purple gradient)
- [x] Toggle to switch between Dots and Streamlines views
- [x] Performance maintained at 45+ FPS (1000 particles in streamlines mode)
- [x] Trails fade smoothly from head to tail
- [x] Direction of flow clearly visible

**Summary:** Implemented Windy.com-style flowing wind streamlines with speed-based color gradient (blue→cyan→green→yellow→orange→red→purple), altitude-specific trail lengths, and ViewMode toggle. Added 59 new tests (354 total). Uses efficient Float32List circular buffer for trail storage. See `.claude/features/wind-streamlines/SUMMARY.md`

**Commit:** 02f345a - feat(particles): add Windy.com-style wind streamlines

---

## Recommended Implementation Order

Each step is independently testable. Don't move to the next until the current one works on device.

```
Phase 2a: Foundation & Visuals (COMPLETE)
  ✅ P2A-001 performance-optimization (DONE - 2026-02-02)
  ✅ P2A-002 wind-streamlines (DONE - 2026-02-03)
  ✅ P2A-003 compass-widget (DONE - 2026-02-03)
  ✅ P2A-004 particle-colors (included in wind-streamlines)
  ✅ Additional: compass-native, code-cleanup, BUG-001 through BUG-009

SPEC-001: Architectural Foundation  <-- CURRENT (branch: feature/architectural-foundation)
  Phase 1: Freezed models + service interfaces + wrap existing code  ✅ DONE (489 tests)
  Phase 2: Riverpod provider graph + directory restructure + wire AR view  ✅ DONE (505 tests)
  Phase 3a: Complete wiring — SceneState, SkyMaskData, lifecycle  ✅ DONE (514 tests)
  Phase 3b: Polish — DataStatusBar, caching, integration tests  ← CURRENT

Phase 2b: Real Data & New Screens  (current focus)
  Step 1: P2B-001 location-service         ✅ DONE
  Step 2: P2B-006 real-wind-data           ✅ DONE (Shyft/Folkweather OGC EDR)
  Step 3: SPEC-003 home-screen             ← IMPLEMENTING (ShyftLens rebrand)
  Step 4: SPEC-004 wind-dome               ← Next (3D dome + Open-Meteo forecast)

Phase 2b (deferred): Terrain Sky Detection
  P2B-002+003 heywhatsthat-client          Deferred (terrain sky detection on backburner)
  P2B-004+005 terrain-sky-mask             Deferred
  SPEC-002 photo-capture-overlay           Backburner

Phase 2c: Advanced Features (future)
  P2C-001 map-view (depends on location + data)
  P2C-002 altitude-input / continuous slider (polish, low priority)
```

**Principle:** One step at a time. Each step should work and be testable before proceeding. If something breaks, we revert to master.

---

## Deferred / Future Features

- **ML-based sky detection (Level 3)** - Improve tree/building recognition (complement terrain detection)
- **Self-hosted SRTM** - Download NASA elevation data and compute horizons on own server (remove HeyWhatsThat dependency)
- **Google Street View mode** - Virtual "stand anywhere" mode for checking wind data remotely
- **Weather projections** - Show future wind patterns
- **Wind anchoring refinement** - Verify accuracy with real data
- **App Store deployment** - Prepare for release

---

## How to Use This Roadmap

When starting a new Claude session:

1. Read `.claude/pipeline/STATUS.md` for current state
2. Read this file (`ROADMAP_PHASE2.md`) for feature list
3. Pick the next feature based on priority/dependencies
4. Run the pipeline:
   ```
   /research <feature-name>
   /plan <feature-name>
   /implement <feature-name>
   /test <feature-name>
   /finalize <feature-name>
   ```
5. Update STATUS.md after each feature completes

---

## Notes from User Testing (2026-01-22)

**What's Working:**
- Sky detection calibrates and detects cloudy sky well
- Particles appear only in sky regions
- World anchoring feels correct
- Altitude slider drag gesture works
- Debug panel shows all metrics

**Issues Noted:**
- Particle colors hard to see against sky
- Trees not well recognized by sky detection
- FPS very low (5 instead of 45-60)
- Altitude slider feels like buttons (even with drag)

**User Screenshot:** `/workspace/IMG_4343.PNG`
