# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 🚨 MANDATORY PIPELINE - READ THIS FIRST 🚨

> **Claude MUST follow the development pipeline. No exceptions. No shortcuts.**

### 🔄 ON EVERY NEW SESSION

**Claude MUST do this FIRST, before ANY other work:**

1. Read `.claude/pipeline/STATUS.md` to see current state
2. Report to user: "Current feature: X, Phase: Y, Next step: /command"
3. Ask user: "Should I continue with /command?" or wait for instructions

**DO NOT start working until you know where we are in the pipeline.**

### 🤖 AUTO-INVOKE RULES

**Claude MUST automatically invoke the next pipeline command when:**

| Situation | Auto-Invoke |
|-----------|-------------|
| User says "start working on X" | `/research X` |
| User says "continue" or "next" | Whatever STATUS.md says is next |
| `/research` completes | Prompt: "Research done. Run `/plan <feature>`?" |
| `/plan` completes | Prompt: "Plan done. Run `/implement <feature>`?" |
| `/implement` completes | Prompt: "Implementation done. Run `/test <feature>`?" |
| `/test` passes | Prompt: "Tests passed! Run `/finalize <feature>`?" |
| `/test` fails | Prompt: "Tests failed. Run `/diagnose <feature>`?" |
| `/diagnose` completes | Prompt: "Diagnosis done. Run `/plan <feature>` to fix?" |
| User says "different approach" / "try another way" | `/rework <feature>` |

**After each command completes, Claude MUST:**
1. Update `.claude/pipeline/STATUS.md` with new phase
2. Tell user what was done
3. Suggest the next command

### The Pipeline

All feature work MUST go through this pipeline in order:

```
/research → /plan → /implement → /test → /finalize
```

If tests fail:
```
/test (fail) → /diagnose → /plan → /implement → /test → /finalize
```

### Pipeline Commands

| Step | Command | Agent | Purpose |
|------|---------|-------|---------|
| 1 | `/research <feature>` | research-agent | Gather context, extract requirements |
| 2 | `/plan <feature>` | plan-agent | Design architecture, create tasks |
| 3 | `/implement <feature>` | execute-agent | Build feature following TDD |
| 4 | `/test <feature>` | test-agent | Validate with full test suite |
| 5a | `/finalize <feature>` | finalize-agent | Commit and PR (on success) |
| 5b | `/diagnose <feature>` | diagnose-agent | Root cause analysis (on failure) |
| - | `/rework <feature>` | - | User wants different approach |

### What Claude CANNOT Do

❌ **FORBIDDEN ACTIONS:**
- Start coding without `/research` and `/plan` first
- Skip any pipeline step
- Make code changes outside of `/implement`
- Create PRs without going through `/finalize`
- Ignore test failures
- Work on multiple features simultaneously without completing the pipeline

### What Claude MUST Do

✅ **REQUIRED ACTIONS:**
- Check for required input files before each step
- Create output files at each step
- Use the appropriate agent for each phase
- Complete one feature's pipeline before starting another
- Ask user before proceeding if unsure

### Handoff Files

Each step reads from and writes to specific files:

```
.claude/features/<feature>/           # Committed - design docs
├── YYYY-MM-DDTHH:MM_research.md     # /research creates
├── YYYY-MM-DDTHH:MM_plan.md         # /plan creates
└── tasks.md                          # /plan creates

.claude/active-work/<feature>/        # NOT committed - working files
├── implementation.md                 # /implement creates
├── test-success.md                   # /test creates (on pass)
├── test-failure.md                   # /test creates (on fail)
└── diagnosis.md                      # /diagnose creates
```

### Pipeline Documentation

Full details: `.claude/pipeline/WORKFLOW.md`

---

## Project Overview

Wind Lens is a Flutter mobile app that visualizes wind patterns in augmented reality. Users point their phone at the sky, and the app overlays flowing wind particles ONLY in sky regions (not on buildings, trees, or ground). Particles appear at different altitude levels with spatial depth effects.

**Key concept:** Think earth.nullschool.net, but viewed from the ground looking up.

## Technical Stack

- **Framework:** Flutter 3.x with Dart
- **Platforms:** iOS 14.0+, Android API 24+
- **Key packages:** camera (^0.11.3), sensors_plus (^7.0.0), vector_math (^2.2.0), http (^1.6.0), flutter_riverpod (^2.4.9), freezed_annotation (^2.4.1), flutter_compass, geolocator

## Build & Run Commands

```bash
# Install dependencies
flutter pub get

# Run codegen (after modifying Freezed models or Riverpod providers)
dart run build_runner build --delete-conflicting-outputs

# iOS-specific setup
cd ios && pod install && cd ..

# Run on connected device (MUST use real device for camera/sensors)
flutter devices                    # List connected devices
flutter run -d <device-id>         # Run on specific device

# Clean build
flutter clean
flutter pub get

# iOS rebuild after pod issues
cd ios && rm -rf Pods Podfile.lock && pod install --repo-update && cd .. && flutter clean && flutter build ios
```

## Architecture (Post SPEC-001)

SPEC-001 introduced Riverpod + Freezed. The canonical layout is `lib/core/` and `lib/features/`. Old paths (`lib/models/`, `lib/widgets/`, `lib/screens/`, `lib/utils/`) are re-export shims pointing to canonical locations — do not add new code there.

```
lib/
├── main.dart                    # App entry point
├── app.dart                     # WindLensApp: ProviderScope + MaterialApp
├── core/
│   ├── models/                  # Freezed data models (canonical)
│   │   ├── wind_data.dart       # WindData: u/v primary, speed/direction computed, AltitudeLevel
│   │   ├── position_data.dart   # GPS fix (lat, lng, altitude, accuracy, timestamp)
│   │   ├── sensor_state.dart    # compassHeading + pitch snapshot
│   │   ├── horizon_profile.dart # Terrain elevation by bearing, getElevationAtBearing()
│   │   ├── sky_mask_data.dart   # Plain class (NOT Freezed): per-pixel sky mask + skyFraction
│   │   ├── scene_state.dart     # Composed snapshot of all app state
│   │   ├── altitude_level.dart  # Surface/MidLevel/JetStream enum
│   │   ├── particle.dart        # Mutable particle (NOT Freezed - hot path)
│   │   ├── hsv.dart             # Mutable HSV (NOT Freezed - hot path)
│   │   └── view_mode.dart       # Dots/Streamlines enum
│   ├── services/                # Abstract interfaces (pure Dart, no Flutter imports)
│   │   ├── sky_detector.dart    # SkyDetector: detect(frame, sensors, horizon?) -> SkyMaskData
│   │   ├── wind_data_source.dart # WindDataSource: getWind(position, altitude) -> WindData
│   │   ├── horizon_provider.dart # HorizonProvider: getHorizon(lat, lng) -> HorizonProfile
│   │   └── sensor_service.dart  # SensorService: sensorStream, positionStream, pause, resume
│   ├── providers/               # Riverpod provider graph (6 layers + sidecar)
│   │   ├── service_providers.dart  # Layer 1 DI: swap-points for each service impl
│   │   ├── sensor_providers.dart   # Layer 2/3: GPS, raw sensor, stablePosition (>100m), SensorNotifiers
│   │   ├── data_providers.dart     # Layer 4/5: horizon, wind, selectedAltitude, detectionMode
│   │   ├── scene_provider.dart     # Layer 6: sceneStateProvider (composed SceneState)
│   │   └── lifecycle_provider.dart # AppLifecycleObserver: pauses/resumes SensorService
│   └── utils/                   # Shared utilities (canonical)
│       ├── color_utils.dart     # Color helper functions
│       └── wind_colors.dart     # Speed-to-color gradient
├── features/
│   └── ar_view/                 # Main AR experience
│       ├── ar_view_screen.dart  # ConsumerStatefulWidget: reads sceneStateProvider
│       └── widgets/
│           ├── particle_overlay.dart  # CustomPainter: SkyMaskData + ValueNotifier heading/pitch
│           ├── camera_view.dart       # Camera preview
│           ├── altitude_slider.dart   # Vertical altitude selector
│           ├── compass_widget.dart    # Heading display
│           ├── info_bar.dart          # Wind speed/altitude display
│           ├── debug_panel.dart       # Debug overlay (3-finger tap)
│           └── data_status_bar.dart   # GPS/wind loading progress indicator
├── services/                    # Concrete implementations
│   ├── compass_service.dart     # Native heading via flutter_compass
│   ├── location_service.dart    # GPS via geolocator
│   ├── fake_wind_service.dart   # Simulated wind data
│   ├── performance_manager.dart # FPS-based particle count adjustment
│   ├── sensors/
│   │   └── device_sensor_service.dart  # DeviceSensorService implements SensorService
│   ├── wind/
│   │   ├── mock_wind_source.dart       # MockWindDataSource (wraps FakeWindService)
│   │   └── cached_wind_source.dart     # CachedWindDataSource (TTL=10min memory cache)
│   ├── horizon/
│   │   ├── mock_horizon_provider.dart  # Returns flat horizon
│   │   └── cached_horizon_provider.dart # Memory+disk cache (3 decimal key, no expiry)
│   └── sky_detection/
│       ├── auto_calibrating_sky_detector.dart  # HSV histogram sky detector
│       ├── hsv_sky_detector.dart               # HsvSkyDetector implements SkyDetector
│       ├── pitch_based_sky_mask.dart           # Fallback: assume sky = top of screen
│       ├── sky_mask.dart                       # Old interface (kept for compat)
│       └── hsv_histogram.dart
├── models/    # Re-export shims → core/models/ (do not add new code here)
├── widgets/   # Re-export shims → features/ar_view/widgets/ (do not add new code here)
├── screens/   # Re-export shim → features/ar_view/ (do not add new code here)
└── utils/     # Re-export shims → core/utils/ (do not add new code here)
```

## Provider Graph

The 6-layer Riverpod graph with a ValueNotifier sidecar:

```
Layer 1 DI:    sensorServiceProvider, windDataSourceProvider,
               horizonProviderServiceProvider, skyDetectorInstanceProvider
Layer 2 Raw:   gpsPositionProvider (Stream<PositionData>), rawSensorProvider (Stream<SensorState>)
Layer 3:       stablePositionProvider (debounces GPS, >100m Haversine threshold)
Layer 4 Data:  horizonProfileProvider (async), windDataProvider (async, depends on stablePosition + selectedAltitude)
Layer 5 User:  selectedAltitudeProvider (Notifier), detectionModeProvider (Notifier)
Layer 6:       sceneStateProvider (composes all data into SceneState; null while loading)
Sidecar:       sensorNotifiersProvider (ValueNotifier<double> heading + pitch at 20-50Hz)
```

**Key patterns:**
- **Swap-points:** To add a real wind API, implement `WindDataSource` and change one line in `service_providers.dart`.
- **SensorNotifiers sidecar:** Heading/pitch bypass Riverpod rebuilds. `ParticleOverlay` reads `headingNotifier.value` directly in its tick loop — zero widget rebuilds for sensor data.
- **SceneState null while loading:** Camera feed appears immediately. Particles appear once wind data resolves.
- **StablePosition debounce:** GPS jitter does not thrash horizon/wind providers.

## Key Technical Details

### Wind Math
```dart
speed = sqrt(u² + v²)
direction = atan2(-u, -v)  // meteorological convention
screenAngle = windDirection - compassHeading
```

### WindData Model
- Primary fields: `uComponent`, `vComponent` (doubles, from OGC EDR)
- Computed getters: `speed`, `directionRadians`, `directionDegrees`
- `altitude` field is `AltitudeLevel` enum (not a raw double)
- `WindData.zero()` factory for surface-level zero wind
- `WindData.fromSpeedDirection()` convenience factory

### SkyMaskData (Plain Class, NOT Freezed)
- Hot-path object recreated every camera frame. Freezed overhead would hurt FPS.
- `skyFraction` is a pre-computed `final double` (computed once at construction), NOT a getter that iterates pixels.
- `SkyMaskData.noSky()` is the initial state in ARViewScreen (prevents particles on black screen at startup).
- `SkyMaskData.fullSky()` is the fallback when no camera frame has been processed yet.

### Particle Rendering (2-pass glow)
1. Glow pass: width=4.0, opacity=0.3, MaskFilter.blur
2. Core pass: width=1.5, opacity=0.9

### Altitude Levels
| Level | Altitude | Color | Wind Speed | Pressure | Parallax |
|-------|----------|-------|------------|----------|----------|
| Surface | 10m | White | ~5 m/s | 1000 hPa | 1.0 |
| Mid-level | 1,500m | Cyan | ~10 m/s | 850 hPa | 0.6 |
| Jet Stream | 10,500m | Purple | ~50 m/s | 250 hPa | 0.3 |

### Performance Targets
- Particle count: 2000 (auto-reduce to 1000 if <45 FPS)
- Frame rate: 60 FPS target
- Sky detection: processFrame() < 16ms
- **NO object allocation in render loop** (Freezed copyWith is forbidden in hot paths)

## Adding New Features (Post SPEC-001)

Each downstream feature is a plug-in that implements an existing interface:

| Feature | What to implement | Where to wire |
|---------|-------------------|---------------|
| HeyWhatsThat client (P2B-002) | `HwtHorizonProvider implements HorizonProvider` | `horizonProviderServiceProvider` in service_providers.dart |
| Terrain sky mask (P2B-003/004) | `TerrainSkyDetector implements SkyDetector` | `skyDetectorInstanceProvider` in service_providers.dart |
| Real wind data (P2B-006) | `OgcEdrWindDataSource implements WindDataSource` | `windDataSourceProvider` in service_providers.dart |

**Before P2B-004:** Fix the `as HsvSkyDetector` cast in `ar_view_screen.dart` and `debug_panel.dart`. Add `skyFraction` and `forceRecalibrate()` to the `SkyDetector` interface, or use a separate debug info provider.

## Tech Debt (Known, Non-Blocking)

1. **Re-export shims:** 16 old-path files are single-line re-exports. Remove incrementally when imports are updated.
2. **Old model classes:** `CompassData` and `LocationData` still exist alongside `SensorState`/`PositionData`.
3. **Riverpod Ref deprecations:** 10 info-level warnings from generated code. Resolves with Riverpod 3.0 upgrade.
4. **HsvSkyDetector hard cast:** `as HsvSkyDetector` in ARViewScreen/DebugPanel. Must fix before adding other detector types.
5. **CachedWindDataSource not wired:** Exists + tested but `windDataSourceProvider` still returns bare `MockWindDataSource`. Wire alongside OGC EDR.

## Testing Requirements

**MUST test on real device** - iOS simulator has no camera, compass, or accelerometer.

**Test suite:** 559 tests auto-discovered by `flutter test`. Five additional test files require explicit paths:
```bash
flutter test test/utils/ test/services/sensors/ test/services/sky_detection/sky_mask_test.dart test/core/providers/data_providers_test.dart
```
Total: 606 tests, all passing.

## Sky Detection

- **Current:** HSV auto-calibrating (`HsvSkyDetector` wrapping `AutoCalibratingSkyDetector`)
- **Level 1 (Pitch-based):** Assume top of screen is sky when phone tilted up
- **Level 2a (Auto-calibrating):** App samples sky colors and builds HSV profile
- **Level 3 (Terrain):** Use HeyWhatsThat horizon data to pre-compute sky boundary (Phase 2b)

## Platform Permissions

### iOS (Info.plist)
- NSCameraUsageDescription
- NSLocationWhenInUseUsageDescription
- NSMotionUsageDescription

### Android (AndroidManifest.xml)
- android.permission.CAMERA
- android.permission.ACCESS_FINE_LOCATION
- android.hardware.camera (required)
- android.hardware.sensor.compass (required)
