# Wind Lens MVP - Feature Roadmap

> **Claude: This is the ordered list of features to build.**
> Complete each feature's full pipeline before starting the next.
> DO NOT skip ahead. Each feature depends on the previous ones.

## Source of Truth

All requirements come from: `WIND_LENS_MVP_SPEC.md`

---

## Feature Order (MUST follow this sequence)

### Feature 0: `project-setup`
**MVP Spec Section:** 2. Technical Stack

**What to build:**
- Create Flutter project: `flutter create wind_lens`
- Configure `pubspec.yaml` with dependencies
- Set up iOS permissions (Info.plist)
- Set up Android permissions (AndroidManifest.xml)
- Verify project builds on simulator

**Acceptance Criteria:**
- [ ] `flutter run` works on simulator
- [ ] All dependencies in pubspec.yaml
- [ ] Platform permissions configured

**Depends on:** Nothing (first feature)

---

### Feature 1: `camera-feed`
**MVP Spec Section:** Implied prerequisite for all visual features

**What to build:**
- Camera preview widget
- Camera initialization service
- Handle camera permissions
- Display live camera feed as background

**Acceptance Criteria:**
- [ ] Camera feed displays on real device
- [ ] Handles permission denied gracefully
- [ ] Logs: "Camera initialized, resolution: WxH"

**Depends on:** `project-setup`

---

### Feature 2: `compass-sensors`
**MVP Spec Section:** Referenced in Critical Implementation Order

**What to build:**
- CompassService using sensors_plus
- Heading detection (magnetometer)
- Pitch detection (accelerometer)
- Smoothing (factor: 0.1)
- Dead zones (heading: 1.0°, pitch: 2.0°)

**Acceptance Criteria:**
- [ ] Heading updates as phone rotates
- [ ] Pitch updates as phone tilts
- [ ] Logs: "Heading: X°, Pitch: Y°"
- [ ] No jitter when stationary

**Depends on:** `project-setup`

---

### Feature 3: `sky-detection`
**MVP Spec Section:** 3. Sky Detection (PHASE 1)

**What to build:**
- Level 1: Pitch-based sky mask (SimpleSkyMask)
  - Phone tilted up > 20° → top of screen is sky
  - Returns skyFraction based on pitch
- SkyMask interface for future upgrades
- Integration with camera frame timing

**Acceptance Criteria:**
- [ ] Sky fraction changes with phone pitch
- [ ] skyFraction = 0 when looking down
- [ ] skyFraction increases when looking up
- [ ] Logs: "Sky fraction: X%"
- [ ] processFrame() < 16ms

**Depends on:** `camera-feed`, `compass-sensors`

---

### Feature 4: `particle-system`
**MVP Spec Section:** 4. Particle System (referenced in spec)

**What to build:**
- Particle model (x, y, age, trailLength)
- ParticleOverlay widget (CustomPainter)
- 2-pass glow rendering:
  - Glow pass: width=4.0, opacity=0.3, blur
  - Core pass: width=1.5, opacity=0.9
- Particles render ONLY in sky mask region
- Target: 2000 particles at 60 FPS

**Acceptance Criteria:**
- [ ] Particles visible only in sky region
- [ ] Particles stop at sky/ground boundary
- [ ] Glow effect visible
- [ ] Logs: "Rendering N particles at X FPS"
- [ ] No object allocation in render loop

**Depends on:** `sky-detection`

---

### Feature 5: `wind-animation`
**MVP Spec Section:** Wind math in spec

**What to build:**
- WindData model (u, v components)
- FakeWindService (simulated data)
- Wind math:
  - speed = sqrt(u² + v²)
  - direction = atan2(-u, -v)
  - screenAngle = windDirection - compassHeading
- Particles flow in wind direction
- Particles stay "world-fixed" (compass integration)

**Acceptance Criteria:**
- [ ] Particles flow in consistent direction
- [ ] Direction changes when phone rotates (world-fixed)
- [ ] Wind speed affects particle velocity
- [ ] Smooth animation at 60 FPS

**Depends on:** `particle-system`, `compass-sensors`

---

### Feature 6: `altitude-depth`
**MVP Spec Section:** Phase 3 - Spatial Depth

**What to build:**
- AltitudeLevel enum (Surface, MidLevel, JetStream)
- Altitude slider UI widget
- Per-altitude properties:
  | Level | Color | Speed | Parallax |
  |-------|-------|-------|----------|
  | Surface | White | ~5 m/s | 1.0 |
  | Mid-level | Cyan | ~10 m/s | 0.6 |
  | Jet Stream | Purple | ~50 m/s | 0.3 |
- Parallax effect based on phone movement
- Higher altitude = more sky coverage

**Acceptance Criteria:**
- [ ] Slider switches between altitude levels
- [ ] Each level has distinct color
- [ ] Higher altitudes feel "further away"
- [ ] Parallax responds to phone tilt

**Depends on:** `wind-animation`

---

### Feature 7: `polish`
**MVP Spec Section:** Phase 4 - Polish

**What to build:**
- Debug panel (toggle visibility)
  - Show FPS, particle count, heading, pitch, sky fraction
- Loading states
- Error handling UI
- Haptic feedback (optional)
- Performance auto-tuning (reduce particles if <45 FPS)

**Acceptance Criteria:**
- [ ] Debug panel shows all metrics
- [ ] App handles errors gracefully
- [ ] Performance stays above 45 FPS
- [ ] Clean, polished UI

**Depends on:** `altitude-depth`

---

## Progress Tracking

Update this as features complete:

| Feature | Status | Completed Date |
|---------|--------|----------------|
| project-setup | NOT STARTED | - |
| camera-feed | NOT STARTED | - |
| compass-sensors | NOT STARTED | - |
| sky-detection | NOT STARTED | - |
| particle-system | NOT STARTED | - |
| wind-animation | NOT STARTED | - |
| altitude-depth | NOT STARTED | - |
| polish | NOT STARTED | - |

---

## Critical Rules

1. **Complete one feature before starting the next**
2. **Each feature goes through full pipeline:** `/research` → `/plan` → `/implement` → `/test` → `/finalize`
3. **Test on real device** - simulator won't work for camera/sensors
4. **Sky detection MUST work before particles** - this is non-negotiable
5. **No skipping** - if you think you can skip, you're wrong

---

## For Claude

When starting work:
1. Check `STATUS.md` for current feature/phase
2. Check this `ROADMAP.md` for what feature comes next
3. Run the appropriate pipeline command
4. Update both files when done

**If user says "continue" or "next":**
- Look at STATUS.md for current feature's next command
- OR if feature complete, start next feature from ROADMAP.md
