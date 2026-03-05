# V1 Retrospective: What Worked and What Went Wrong

## What Worked (keep these solutions)

### Font Fix
- Downloaded DMMono-Medium.ttf from Google Fonts GitHub
- Added to pubspec.yaml with `weight: 500`
- Replaced ALL `GoogleFonts.dmMono(...)` with `TextStyle(fontFamily: 'DM Mono', ...)`
- Replaced ALL `GoogleFonts.bebasNeue(...)` with `TextStyle(fontFamily: 'Bebas Neue', ...)`
- Removed `google_fonts` package from pubspec.yaml entirely
- Removed GoogleFonts config from main.dart

### Home Screen Cleanup
- Removed `home_particle_painter.dart` (GPU waste)
- Removed `home_layer_toggles.dart` (non-functional buttons)
- Removed AnimationController/TickerProviderStateMixin from HomeScreen
- HomeTerrainSection no longer needs particleController parameter
- Replaced toggles with static centered "TERRAIN" label

### UI Polish
- Altitude rail: inactive text `#282828`→`#555555`, inactive line `#222222`→`#444444`, font 8→10, active pill
- Compass bar: active `#666666`→`#AAAAAA`, inactive `#222222`→`#444444`, font 9→11
- Wind row: label font 8→10, value font 28→34, unit font 9→11

### Location Picker Fixes
- GPS fallback: `LatLng(0,0)` → `LatLng(39.8283, -98.5795)` (US center)
- `CancellableNetworkTileProvider` as `late final` field (not in build())
- `_mapController.dispose()` in dispose()
- Replaced AlertDialog coordinate input with `showModalBottomSheet` + separate lat/lng TextFields
- Inline validation with StatefulBuilder, proper controller disposal via `.whenComplete()`

### Navigation
- CupertinoPageRoute instead of MaterialPageRoute for iOS-native slide transitions
- Loading skeleton screen (LocationPickerLoadingScreen) before location picker

### Dome
- Start zoomed out: `_camR = DomeConstants.camRMax * scale`
- Anti-bunching jitter in `tick()` for domes >15km physical radius

## What Went Wrong (avoid these mistakes)

### 1. Worktree Merge Conflicts
- Ran 3 parallel agents in worktrees
- Worktrees branched from HEAD commit (before uncommitted V1 changes)
- When copying files from worktrees back, V1 changes were overwritten
- Had to manually re-apply V1 fixes on top of V2 changes — very error-prone

### 2. Manual Edits Instead of Subagents
- User explicitly wanted subagents to handle code changes
- I edited files directly multiple times, which led to errors and rework
- **LESSON: Always use execute-agent or similar for code changes**

### 3. Compass Heading Line Was Over-Engineered
- User said: "it should just be using the compass thing and the line should just be sliding along to whatever the heading is"
- The implementation used a CustomPainter with `super(repaint: headingNotifier)` — which is actually correct
- But user reports it was still laggy — need to investigate why
- Possibly: the CustomPainter repaints the entire terrain section, not just the line

### 4. Startup Lag Not Addressed
- V1 focused on individual screen fixes but didn't address the core issue: everything loads at once
- Provider graph fires all providers simultaneously on app start
- Wind API, terrain API, GPS, sensors all compete for resources
- User wants staged loading: UI → GPS → data → terrain

## Key Files Modified (for reference)
- pubspec.yaml, lib/main.dart
- lib/features/home/home_screen.dart
- lib/features/home/widgets/home_terrain_section.dart
- lib/features/home/widgets/home_wind_row.dart
- lib/features/home/widgets/home_altitude_rail.dart
- lib/features/home/widgets/home_compass_bar.dart
- lib/features/home/widgets/home_top_bar.dart
- lib/features/location_picker/location_picker_screen.dart
- lib/features/location_picker/location_picker_loading_screen.dart (NEW)
- lib/features/wind_dome/wind_dome_screen.dart
- lib/features/wind_dome/models/dome_particle.dart
- test/features/home/home_screen_test.dart

## Reference Diagnosis
- See `.claude/active-work/location-picker-lag-v2/diagnosis.md` for detailed root cause analysis of location picker freeze
