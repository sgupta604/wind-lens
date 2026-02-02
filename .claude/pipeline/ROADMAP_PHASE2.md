# Wind Lens Phase 2 Roadmap

> **Purpose:** Features to implement after MVP bug fixes are complete.
> Each feature goes through the pipeline: `/research` → `/plan` → `/implement` → `/test` → `/finalize`

---

## Current Status

**MVP:** Complete (8/8 features)
**Post-MVP Bugs:** Complete (6/6 fixed)
**Tests:** 254 passing
**Ready for:** Phase 2 features

---

## Phase 2 Feature Summary

| # | Feature | Priority | Complexity | Description |
|---|---------|----------|------------|-------------|
| 1 | location-awareness | **High** | Medium | GPS + heading for real data positioning |
| 2 | sky-viewport | **High** | High | Calculate visible sky cone/bounding box |
| 3 | compass-widget | Medium | Low | Small circular compass showing direction |
| 4 | particle-colors | Medium | Low | Improve particle visibility in various sky conditions |
| 5 | map-view | Medium | High | Toggle AR ↔ top-down weather map view |
| 6 | real-wind-data | High | High | Integrate EDR API for real wind data |
| 7 | altitude-input | Low | Medium | Input specific altitude in feet |
| 8 | performance-optimization | Medium | Medium | Fix FPS issues (currently 5, target 45-60) |

---

## Feature Details

### Feature 1: location-awareness

**Priority:** High
**Complexity:** Medium
**Blocked by:** None

**What to Build:**
- Get device GPS coordinates (latitude, longitude)
- Get compass heading (already have this via CompassService)
- Store current location for wind data queries
- Calculate which direction camera is pointing in world coordinates

**Why Needed:**
- Real wind data is location-specific
- Need to know WHERE user is to fetch correct data
- Need to know which DIRECTION they're looking to show correct wind patterns

**Technical Notes:**
- Use `geolocator` package for GPS
- Combine with existing CompassService heading
- Store as `UserPosition { lat, lon, heading, timestamp }`
- Request location permission (iOS: NSLocationWhenInUseUsageDescription)

**Acceptance Criteria:**
- [ ] App requests and receives GPS location
- [ ] Location updates as user moves
- [ ] Heading + location combined into world-space direction
- [ ] Debug panel shows lat/lon

---

### Feature 2: sky-viewport

**Priority:** High
**Complexity:** High
**Depends on:** location-awareness

**What to Build:**
- Calculate the "cone" of sky user is viewing based on:
  - Device pitch (how far up they're looking)
  - Device heading (compass direction)
  - Camera field of view (FOV)
- Determine bounding box of sky region in world coordinates
- Calculate how much sky data we need to fetch (radius/diameter)

**Why Needed:**
- When fetching real wind data, need to know WHICH part of the sky to get data for
- User looking North at 45° pitch sees different sky than looking East at 30° pitch
- Need to map screen pixels to real-world sky coordinates

**Technical Notes:**
- Camera FOV typically ~60-70° horizontal
- At 45° pitch, user sees sky from ~15° to ~75° elevation
- Need spherical geometry for accurate mapping
- Consider: altitude of wind data affects apparent position

**Key Calculations:**
```
Sky viewport center = (lat, lon, heading, pitch)
Horizontal FOV = ~60°
Vertical FOV = ~80° (phone aspect ratio)
Sky coverage radius = f(pitch, altitude_level)
```

**Acceptance Criteria:**
- [ ] Calculate sky viewport bounds from device orientation
- [ ] Map screen coordinates to world sky coordinates
- [ ] Determine data fetch radius for current view
- [ ] Debug panel shows viewport bounds

---

### Feature 3: compass-widget

**Priority:** Medium
**Complexity:** Low
**Blocked by:** None

**What to Build:**
- Small circular compass in corner of screen
- Shows N/S/E/W cardinal directions
- Rotates based on device heading
- Indicator showing which way camera is pointing

**Why Needed:**
- User feedback: want to know which direction they're facing
- Helps orient user when viewing wind patterns
- Common AR app convention

**Technical Notes:**
- Use existing CompassService heading
- Simple CustomPainter for compass dial
- Position in bottom-left or top-right corner (not obscuring altitude slider)
- Semi-transparent background (glassmorphism like other UI)

**Acceptance Criteria:**
- [ ] Compass widget visible in corner
- [ ] Rotates smoothly with device heading
- [ ] Shows N/S/E/W labels
- [ ] Doesn't obscure other UI elements

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

**Priority:** Medium
**Complexity:** Medium
**Blocked by:** None

**What to Build:**
- Investigate and fix low FPS (currently showing 5 FPS in screenshot)
- Profile render loop for bottlenecks
- Optimize sky detection frame processing
- Reduce particle count adaptively

**Why Needed:**
- Screenshot shows FPS: 5 (should be 45-60)
- Poor performance ruins AR experience
- May be sky detection or particle rendering issue

**Technical Notes:**
- PerformanceManager exists but may not be working
- Sky detection processFrame() should be <16ms
- Check if image downscaling is working
- Profile on release build, not debug

**Acceptance Criteria:**
- [ ] Maintain 45+ FPS on target devices
- [ ] Adaptive particle reduction when needed
- [ ] Sky detection under 16ms per frame
- [ ] No jank or stuttering

---

## Recommended Implementation Order

Based on dependencies:

```
Phase 2a: Foundation
  1. performance-optimization (fix FPS issue first)
  2. particle-colors (quick win for UX)
  3. compass-widget (quick win, no dependencies)

Phase 2b: Location & Data
  4. location-awareness (foundation for real data)
  5. sky-viewport (depends on location)
  6. real-wind-data (depends on location + viewport)

Phase 2c: Advanced Features
  7. map-view (depends on location + data)
  8. altitude-input (polish, low priority)
```

---

## Deferred / Future Features

These were mentioned but not prioritized for Phase 2:

- **ML-based sky detection (Level 3)** - Improve tree/building recognition
- **Weather projections** - Show future wind patterns
- **Better particle masking** - Improve edge detection at sky boundaries
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
