# User Feedback: App Performance Polish

## Device Testing Observations
- App is very laggy on startup
- DMMono-Medium font errors in console (font not bundled)
- google_fonts package adds cold-load latency
- Location picker map freezes/lags on first open
- Coordinate input dialog is buggy (AlertDialog layout issues)
- Screen transitions are not smooth (MaterialPageRoute fade vs iOS slide)

## User Requests

### Performance / Startup
1. **Staged startup loading** — App fetches everything at once (GPS, wind, terrain, sensors). Should load in steps:
   - Step 1: Load UI immediately
   - Step 2: Load GPS + sensor data
   - Step 3: Load wind data
   - Step 4: Load terrain
2. **Dome particles only on dome page** — Don't initialize dome particle system until user opens the dome screen
3. **General startup lag** — App feels frozen on first load, needs loading UX so it never feels stuck

### Home Screen
4. **Remove google_fonts** — Replace with bundled font TextStyle to eliminate cold-load lag
5. **Fix DMMono-Medium font** — Bundle the Medium weight .ttf file
6. **Remove home screen particles** — GPU waste, not adding value on home screen
7. **Remove non-functional layer toggles** — Remove Particles/Pressure/Clouds buttons, keep TERRAIN as static centered label (not a toggle)
8. **Brighten altitude rail** — Too dark/small, hard to read
9. **Brighten compass bar** — Too dark/small
10. **Enlarge wind data text** — Speed/direction/altitude values too small
11. **Compass heading line on terrain** — Vertical line tracking phone heading, sliding smoothly. Should be simple — just use the ValueNotifier heading and update line position. Don't over-engineer.

### Navigation
12. **CupertinoPageRoute** — Use iOS-native slide transitions instead of MaterialPageRoute fade
13. **Loading skeleton screen** — Show lightweight shimmer/skeleton before heavy screens (location picker map)

### Location Picker
14. **Fix coordinate input** — Replace buggy AlertDialog with bottom sheet + separate lat/lng fields
15. **CancellableNetworkTileProvider** — Cancel off-screen tile requests for map performance
16. **GPS fallback** — Use US center (39.8283, -98.5795) instead of (0,0) when no GPS

### Dome
17. **Start zoomed out** — Enter dome at max zoom-out so user sees the whole dome
18. **Particle anti-bunching** — Add jitter at large radii (35km/50km) to prevent particle clumping

### Splash/Loading Screen (added after initial feedback)
19. **Startup splash screen** — Show "ShyftLens" logo centered with a 0-100% progress bar. Load everything behind the scenes (GPS, wind, terrain) BEFORE entering the app. User sees clear progress instead of frozen UI. Once loaded, transition to home screen. This is the primary solution for startup lag — don't try to stage-load in the background while showing a half-working UI. Show a proper loading screen that waits for all critical data.

### Key User Quote on Compass Line
> "the compass line thingy is very inefficient... it should just be using the compass thing and the line should just be sliding along to whatever the heading is... don't need to reinvent the wheel there"
