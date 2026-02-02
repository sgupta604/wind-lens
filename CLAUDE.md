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
- **Key packages:** camera (^0.11.3), sensors_plus (^7.0.0), vector_math (^2.2.0), http (^1.6.0)

## Build & Run Commands

```bash
# Create project (if starting fresh)
flutter create wind_lens

# Install dependencies
flutter pub get

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

## Architecture

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── wind_data.dart          # WindData with u/v components
│   ├── altitude_level.dart     # Surface/MidLevel/JetStream enum
│   ├── particle.dart           # x, y, age, trailLength
│   └── sky_mask.dart           # SkyMask interface
├── services/
│   ├── wind_service.dart       # Facade: real vs fake data
│   ├── fake_wind_service.dart  # Simulated wind data
│   ├── compass_service.dart    # Magnetometer + accelerometer
│   └── sky_detection/
│       ├── sky_detector.dart          # Abstract interface
│       ├── pitch_based_detector.dart  # Level 1: simple pitch check
│       └── color_based_detector.dart  # Level 2: auto-calibrating HSV
├── providers/
│   └── wind_state.dart         # ChangeNotifier state
├── widgets/
│   ├── particle_overlay.dart   # CustomPainter for particles
│   ├── altitude_slider.dart    # Vertical altitude selector
│   └── camera_view.dart        # Camera preview
└── screens/
    └── ar_view_screen.dart     # Main composing screen
```

## Critical Implementation Order

**MUST follow this order - each step must work before proceeding:**

1. Camera feed working
2. Compass + Pitch detection working
3. **Sky detection working** ← DON'T SKIP
4. Particles rendered ONLY in sky regions
5. Animated particles with wind direction
6. Altitude levels and spatial depth
7. Polish (UI, haptics, debug panel)

## Sky Detection Levels

- **Level 1 (Pitch-based):** Simple - assume top of screen is sky when phone tilted up
- **Level 2a (Auto-calibrating):** RECOMMENDED - app samples sky colors and builds HSV profile
- **Level 2b (+Integral images):** O(1) uniformity check for excluding buildings
- **Level 3 (ML/TFLite):** Optional, complex - only if simpler levels insufficient

## Key Technical Details

### Wind Math
```dart
speed = sqrt(u² + v²)
direction = atan2(-u, -v)  // meteorological convention
screenAngle = windDirection - compassHeading
```

### Particle Rendering (2-pass glow)
1. Glow pass: width=4.0, opacity=0.3, MaskFilter.blur
2. Core pass: width=1.5, opacity=0.9

### Compass Tuning
- Smoothing factor: 0.1
- Heading dead zone: 1.0° (prevents jitter)
- Pitch dead zone: 2.0°

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

## Performance Warning

**NO object allocation in render loop!** Bilinear interpolation for 2000 particles at 60 FPS = 120,000 calculations/second. Pre-allocate grid data arrays, interpolate directly into reusable fields.

## Testing Requirements

**MUST test on real device** - iOS simulator has no camera, compass, or accelerometer. Build UI in simulator, but all sensor/camera work requires physical device.

## Verification Checkpoints

Add logging to verify each component works:
- Camera: "Camera initialized, resolution: 1920x1080"
- Compass: "Heading: 127.3°, Pitch: 12.5°"
- Sky Detection: "Sky fraction: 65.2%"
- Particles: "Rendering 2000 particles at 58 FPS"

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
