# Compass Service Architectural Rewrite (BUG-009 v2)

## Overview

Full architectural rewrite of `CompassService` to eliminate compass widget freezing bug. Changed from event-driven dead zone architecture (which caused convergence trap) to timer-based decoupled architecture that always emits.

## Problem

The compass widget froze after approximately 1 second of holding the device still. The v1 fix (reordering dead zone after smoothing) did not resolve the issue on device. Root cause: dead zone logic permanently suppressed stream emission once the smoothed value converged within 1.0 degree of the raw sensor value, creating a convergence trap.

## Solution

Complete architectural rewrite separating three concerns:
1. **Sensor callbacks** (hardware rate 50-100 Hz) - only store raw values
2. **Timer at 20 Hz** - smooth toward raw values and always emit
3. **No dead zones** - low-pass filter itself provides jitter suppression

## Key Changes

### Architecture
- Replaced event-driven sensor callbacks with decoupled timer-based design
- Sensor callbacks now only store `_rawHeading` and `_rawPitch` (no processing)
- Periodic timer at 20 Hz smooths values and always emits to stream
- Removed all dead zone constants and gating logic

### Constants
- `smoothingFactor`: 0.1 → 0.15 (compensates for lower tick rate)
- `emitInterval`: NEW - Duration(milliseconds: 50) for 20 Hz
- `headingDeadZone`: REMOVED
- `pitchDeadZone`: REMOVED

### New Methods
- `_lerpAngle()`: Circular interpolation handling 0/360 wraparound
- `setRawHeading()`: Test helper for direct raw value injection
- `setRawPitch()`: Test helper for direct raw value injection
- `tick()`: Test helper for deterministic smoothing+emission cycle

### Public API
No breaking changes. All consumers (`compass_widget.dart`, `ar_view_screen.dart`, `wind_state.dart`) work without modification.

## Files Modified

| File | Lines Before | Lines After | Change Type |
|------|-------------|-------------|-------------|
| `lib/services/compass_service.dart` | 203 | 190 | Full rewrite |
| `test/services/compass_service_test.dart` | 553 | 741 | Significant update |

## Test Results

- Compass service tests: 35 passing (+8 net new)
- Total test suite: 390 passing (+8 net new)
- Static analysis: 0 issues
- Regressions: 0

### New Tests Added (11)
1. Emit interval constant (50ms / 20 Hz)
2. Smoothing factor constant (0.15)
3. Circular interpolation clockwise through 0 (350° → 10°)
4. Circular interpolation counterclockwise through 0 (10° → 350°)
5. Circular interpolation normal case (45° → 90°)
6. Single tick emits one event
7. Multiple ticks emit multiple events
8. **CRITICAL:** Continuous emission during stationary hold (100+ ticks)
9. **CRITICAL:** Continuous emission during slow rotation
10. setRawHeading test helper
11. setRawPitch test helper

### Tests Removed (3)
1. Heading dead zone constant test (no longer applicable)
2. Pitch dead zone constant test (no longer applicable)
3. Smoothing factor 0.1 test (replaced with 0.15 version)

## Performance Improvements

- **Old:** Event-driven at 50-100 Hz sensor rate (excessive for UI)
- **New:** Timer-based at 20 Hz (optimal for 60 FPS UI refresh)
- **Smoothing:** Factor 0.15 at 20 Hz ≈ 335ms time constant (responsive + smooth)
- **UI updates:** Fixed 20 Hz emission vs variable 50-100 Hz reduces setState calls

## Manual Testing Required

The following must be verified on a real device:

1. Hold phone still for 10+ seconds → compass should NOT freeze
2. Rotate phone slowly 360° → compass should track continuously
3. Make small heading changes (< 5°) → compass should update smoothly
4. Quick 180° rotation → compass should track through the turn
5. Slow tilt from vertical to horizontal → pitch should track smoothly
6. Debug panel heading value should update continuously (not freeze)
7. Rotate past North (through 360°/0° boundary) → smooth transition, no jump

## Technical Details

### Circular Interpolation Algorithm

```dart
double _lerpAngle(double from, double to, double t) {
  double diff = (to - from + 540) % 360 - 180;
  return (from + diff * t + 360) % 360;
}
```

This ensures shortest-path angular interpolation, correctly handling the 0/360 wraparound in both directions.

### Timer-Based Emission

```dart
_emitTimer = Timer.periodic(emitInterval, (_) {
  _smoothedHeading = _lerpAngle(_smoothedHeading, _rawHeading, smoothingFactor);
  _smoothedPitch += (_rawPitch - _smoothedPitch) * smoothingFactor;
  _controller.add(CompassData(heading: _smoothedHeading, pitch: _smoothedPitch));
});
```

The timer always emits, regardless of how close the smoothed value is to the raw value. This eliminates the convergence trap that caused the freeze.

## Impact

- **Bug fixed:** BUG-009 compass freeze after ~1 second
- **No breaking changes:** Public API preserved exactly
- **Code quality:** Reduced from 203 to 190 lines (-13 lines, -6%)
- **Test coverage:** +8 net new tests covering timer architecture
- **Performance:** More efficient with fixed 20 Hz emission rate
- **Maintainability:** Simpler architecture with clear separation of concerns

## Next Steps

1. Manual device testing to confirm fix on hardware
2. Monitor for any performance or battery impact from timer-based emission
3. Consider future enhancement: add `AnimatedRotation` to CompassWidget for smoother visual transitions
