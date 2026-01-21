# Wind Lens MVP — Technical Specification

> **Purpose of this document:** This is the single source of truth for building the Wind Lens MVP. Any AI or developer implementing this app should follow this spec exactly.

---

## 1. Project Overview

### The Vision
Point your phone at the sky. The app detects where the sky is and overlays flowing wind particles ONLY in the sky region — not on buildings, trees, or ground. The particles should feel like they exist at real altitudes (surface winds at 100ft, jet streams at 34,000ft), not as a flat 2D sticker on your screen.

**Think:** earth.nullschool.net, but viewed from the ground looking up instead of from space looking down.

### What We're Building (Ordered by Priority)

**Phase 1: Sky Detection (MUST WORK FIRST)**
- Camera detects WHERE the sky is
- Creates a mask: sky = render particles, not-sky = transparent
- Without this, everything else looks fake

**Phase 2: Particle Rendering (In Sky Only)**
- Particles flow in wind direction
- Rendered ONLY within the sky mask
- 2D particles with glow effect

**Phase 3: Spatial Depth (Makes It Feel Real)**
- Particles at different altitudes feel "further away"
- Parallax effect when you move/rotate phone
- Higher altitude = more sky coverage, slower apparent motion

**Phase 4: Wind Data & Polish**
- Real wind data from EDR API (or fake for demo)
- Altitude slider
- Compass integration

### MVP Scope (What's IN)
- Camera feed as background
- Sky detection (start simple, upgrade to ML later)
- Particle system rendered ONLY in sky regions
- Altitude selector (Surface, Mid-level, Jet Stream)
- Compass integration (particles stay world-fixed)
- Fake/simulated wind data (real API optional)

### MVP Scope (What's OUT — but documented for later)
- ML-based sky segmentation (Phase 2 upgrade)
- Server-side compute offloading (documented as option)
- User accounts / persistence
- Weather forecasting
- App Store deployment

> ⚠️ **CRITICAL ORDERING**
> 
> Do NOT skip to particles before sky detection works.
> Particles covering the whole screen = looks fake = fails the demo.
> Sky detection FIRST, particles SECOND.

---

## 2. Technical Stack

### Core
| Component | Choice | Reason |
|-----------|--------|--------|
| Framework | Flutter 3.x | Cross-platform, good shader support |
| Language | Dart | Required for Flutter |
| Min iOS | 14.0 | ARKit compatibility |
| Min Android | API 24 | ARCore compatibility |

### Key Packages
```yaml
dependencies:
  flutter:
    sdk: flutter
  camera: ^0.10.5+9          # Camera feed access
  sensors_plus: ^4.0.2       # Compass/magnetometer
  vector_math: ^2.1.4        # Vector calculations
  http: ^1.2.0               # API calls for real wind data
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
```

### Why NOT using AR packages for MVP
Full AR (plane detection, anchoring) is overkill. We just need:
1. Camera feed (background)
2. Custom paint overlay (particles)
3. Compass heading (rotation)

This is simpler, faster, and has fewer device compatibility issues.

---

## 3. Sky Detection (PHASE 1 — Do This First)

> 🔴 **THIS IS THE FOUNDATION**
> 
> Without sky detection, particles cover the whole screen and look fake.
> Get this working BEFORE touching particle code.

### The Goal
Given a camera frame, produce a **mask** where:
- `1` (white) = this pixel is sky → render particles here
- `0` (black) = this pixel is NOT sky → don't render particles

### Approach: Start Simple, Upgrade Later

#### Level 1: Pitch-Based (Simplest — Start Here)
No ML, no image processing. Just assume:
- Phone tilted up > 20° → top portion of screen is sky
- Phone level or down → no sky visible

```dart
class SimpleSkyMask {
  final double pitchDegrees;
  
  SimpleSkyMask(this.pitchDegrees);
  
  /// Returns what fraction of screen (from top) is sky
  double get skyFraction {
    if (pitchDegrees < 10) return 0.0;        // Looking down/level
    if (pitchDegrees > 70) return 0.95;       // Looking almost straight up
    // Linear interpolation between 10° and 70°
    return ((pitchDegrees - 10) / 60).clamp(0.0, 0.95);
  }
  
  bool isPointInSky(double normalizedY) {
    // normalizedY: 0.0 = top of screen, 1.0 = bottom
    return normalizedY < skyFraction;
  }
}
```

**Pros:** Dead simple, works immediately, no dependencies
**Cons:** Doesn't know about buildings/trees blocking sky
**Use for:** Initial testing, getting particle pipeline working

#### Level 2: Multi-Condition Color Detection (Better — No ML)
Detect sky pixels based on multiple color profiles + brightness + uniformity.

**Why simple blue detection fails:**
- Cloudy/overcast → gray, not blue
- Sunset/sunrise → orange, pink, red
- Hazy days → washed out, low saturation
- Glass buildings → reflect blue (false positive)

---

### Level 2a: Auto-Calibrating Sky Detection (RECOMMENDED)

> 💡 **Better than manual tuning**
> 
> Instead of guessing HSV values, let the app LEARN from the current sky.
> User points phone up, app samples the sky colors, builds a dynamic profile.

```dart
class AutoCalibratingSkyDetector {
  // Learned sky color distribution
  HSVHistogram? _skyHistogram;
  DateTime? _lastCalibration;
  
  // Calibration settings
  static const Duration recalibrationInterval = Duration(minutes: 5);
  static const double sampleRegionTop = 0.1;    // Top 10-40% of screen
  static const double sampleRegionBottom = 0.4;
  
  /// Call this when user is pointing at sky (pitch > 45°)
  void calibrateFromCurrentFrame(CameraImage image, double pitchDegrees) {
    if (pitchDegrees < 45) {
      print('⚠️ Point phone more upward to calibrate');
      return;
    }
    
    // Sample colors from top portion of frame (most likely pure sky)
    final samples = <HSV>[];
    final width = image.width;
    final height = image.height;
    
    final startY = (height * sampleRegionTop).round();
    final endY = (height * sampleRegionBottom).round();
    
    // Sample every 10th pixel for speed
    for (int y = startY; y < endY; y += 10) {
      for (int x = 0; x < width; x += 10) {
        final idx = (y * width + x) * 4;
        final r = image.planes[0].bytes[idx];
        final g = image.planes[0].bytes[idx + 1];
        final b = image.planes[0].bytes[idx + 2];
        samples.add(rgbToHsv(r, g, b));
      }
    }
    
    // Build histogram from samples
    _skyHistogram = HSVHistogram.fromSamples(samples);
    _lastCalibration = DateTime.now();
    
    print('✅ Sky calibrated: ${samples.length} samples');
    print('   Hue range: ${_skyHistogram!.hueMin.toStringAsFixed(0)}° - ${_skyHistogram!.hueMax.toStringAsFixed(0)}°');
    print('   Sat range: ${(_skyHistogram!.satMin * 100).toStringAsFixed(0)}% - ${(_skyHistogram!.satMax * 100).toStringAsFixed(0)}%');
    print('   Val range: ${(_skyHistogram!.valMin * 100).toStringAsFixed(0)}% - ${(_skyHistogram!.valMax * 100).toStringAsFixed(0)}%');
  }
  
  /// Should we recalibrate? (lighting changes over time)
  bool get needsCalibration {
    if (_skyHistogram == null) return true;
    if (_lastCalibration == null) return true;
    return DateTime.now().difference(_lastCalibration!) > recalibrationInterval;
  }
  
  /// Detect sky using learned profile
  Uint8List detectSky(CameraImage image, double pitchDegrees) {
    // Auto-recalibrate if pointing up and it's been a while
    if (needsCalibration && pitchDegrees > 50) {
      calibrateFromCurrentFrame(image, pitchDegrees);
    }
    
    // Fallback to default profiles if not calibrated
    if (_skyHistogram == null) {
      return _detectWithDefaultProfiles(image, pitchDegrees);
    }
    
    return _detectWithLearnedProfile(image, pitchDegrees);
  }
  
  Uint8List _detectWithLearnedProfile(CameraImage image, double pitchDegrees) {
    final width = image.width;
    final height = image.height;
    final mask = Uint8List(width * height);
    
    final skyPrior = _calculateSkyPrior(pitchDegrees);
    
    for (int y = 0; y < height; y++) {
      final positionWeight = (1.0 - (y / height)) * skyPrior;
      if (positionWeight < 0.2) {
        // Skip bottom of frame entirely (optimization)
        continue;
      }
      
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final pixelIdx = idx * 4;
        
        final r = image.planes[0].bytes[pixelIdx];
        final g = image.planes[0].bytes[pixelIdx + 1];
        final b = image.planes[0].bytes[pixelIdx + 2];
        
        final hsv = rgbToHsv(r, g, b);
        
        // Check against LEARNED profile with tolerance
        final matchScore = _skyHistogram!.matchScore(hsv);
        
        // Combine match score with position
        final isSky = (matchScore * positionWeight) > 0.4;
        
        mask[idx] = isSky ? 255 : 0;
      }
    }
    
    return mask;
  }
  
  double _calculateSkyPrior(double pitchDegrees) {
    if (pitchDegrees < 0) return 0.2;
    if (pitchDegrees > 60) return 1.0;
    return 0.3 + (pitchDegrees / 60) * 0.7;
  }
}

class HSVHistogram {
  final double hueMin, hueMax, hueMean;
  final double satMin, satMax, satMean;
  final double valMin, valMax, valMean;
  final double hueStd, satStd, valStd;
  
  HSVHistogram._({
    required this.hueMin, required this.hueMax, required this.hueMean, required this.hueStd,
    required this.satMin, required this.satMax, required this.satMean, required this.satStd,
    required this.valMin, required this.valMax, required this.valMean, required this.valStd,
  });
  
  factory HSVHistogram.fromSamples(List<HSV> samples) {
    // Use percentiles to be robust to outliers
    final hues = samples.map((s) => s.h).toList()..sort();
    final sats = samples.map((s) => s.s).toList()..sort();
    final vals = samples.map((s) => s.v).toList()..sort();
    
    // 5th and 95th percentile for robustness
    final p5 = (samples.length * 0.05).round();
    final p95 = (samples.length * 0.95).round();
    
    double mean(List<double> list) => list.reduce((a, b) => a + b) / list.length;
    double std(List<double> list, double m) {
      final variance = list.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) / list.length;
      return sqrt(variance);
    }
    
    final hueMean = mean(hues);
    final satMean = mean(sats);
    final valMean = mean(vals);
    
    return HSVHistogram._(
      hueMin: hues[p5], hueMax: hues[p95], hueMean: hueMean, hueStd: std(hues, hueMean),
      satMin: sats[p5], satMax: sats[p95], satMean: satMean, satStd: std(sats, satMean),
      valMin: vals[p5], valMax: vals[p95], valMean: valMean, valStd: std(vals, valMean),
    );
  }
  
  /// Returns 0.0 - 1.0 how well this pixel matches the learned sky
  double matchScore(HSV pixel) {
    // Gaussian-like scoring based on distance from mean
    double hueScore = _gaussianScore(pixel.h, hueMean, hueStd * 2);
    double satScore = _gaussianScore(pixel.s, satMean, satStd * 2);
    double valScore = _gaussianScore(pixel.v, valMean, valStd * 2);
    
    // Also check if within learned range (hard boundary)
    bool inRange = pixel.s >= satMin && pixel.s <= satMax &&
                   pixel.v >= valMin && pixel.v <= valMax;
    
    if (!inRange) return 0.0;
    
    return (hueScore + satScore + valScore) / 3.0;
  }
  
  double _gaussianScore(double value, double mean, double std) {
    if (std < 0.01) std = 0.01; // Prevent division by zero
    final diff = (value - mean).abs();
    return exp(-(diff * diff) / (2 * std * std));
  }
}
```

**How it works:**
1. When user points phone up (pitch > 45°), app samples top 10-40% of frame
2. Builds statistical profile (mean, std dev, percentile ranges) of current sky
3. Uses learned profile to detect sky pixels with Gaussian scoring
4. Auto-recalibrates every 5 minutes (lighting changes)

**Benefits:**
- No manual HSV tuning needed
- Adapts to ANY sky condition automatically
- Handles transitions (clouds rolling in, sunset progressing)
- Percentile-based ranges are robust to outliers (birds, planes)

---

### Level 2b: Optimized Uniformity Check (Integral Image Method)

> 💡 **O(1) variance calculation per pixel using integral images**
> 
> Instead of checking each pixel's neighborhood (slow), pre-compute integral images
> that allow instant variance lookup for any rectangular region.

```dart
class OptimizedUniformityDetector {
  // Work on downscaled image for speed
  static const int processWidth = 128;
  static const int processHeight = 96;
  
  // Pre-computed integral images
  late List<int> _integralSum;      // Sum of pixel values
  late List<int> _integralSumSq;    // Sum of squared pixel values
  late int _scaledWidth;
  late int _scaledHeight;
  
  /// Pre-compute integral images (call once per frame)
  void precompute(CameraImage image) {
    // Downscale for speed
    final scaled = _downscale(image, processWidth, processHeight);
    _scaledWidth = processWidth;
    _scaledHeight = processHeight;
    
    final n = _scaledWidth * _scaledHeight;
    _integralSum = List.filled(n, 0);
    _integralSumSq = List.filled(n, 0);
    
    // Build integral images
    for (int y = 0; y < _scaledHeight; y++) {
      for (int x = 0; x < _scaledWidth; x++) {
        final idx = y * _scaledWidth + x;
        final gray = scaled[idx];
        
        int sum = gray;
        int sumSq = gray * gray;
        
        if (x > 0) {
          sum += _integralSum[idx - 1];
          sumSq += _integralSumSq[idx - 1];
        }
        if (y > 0) {
          sum += _integralSum[idx - _scaledWidth];
          sumSq += _integralSumSq[idx - _scaledWidth];
        }
        if (x > 0 && y > 0) {
          sum -= _integralSum[idx - _scaledWidth - 1];
          sumSq -= _integralSumSq[idx - _scaledWidth - 1];
        }
        
        _integralSum[idx] = sum;
        _integralSumSq[idx] = sumSq;
      }
    }
  }
  
  /// O(1) variance lookup for any region
  double getVariance(int x, int y, int radius) {
    final x1 = (x - radius).clamp(0, _scaledWidth - 1);
    final y1 = (y - radius).clamp(0, _scaledHeight - 1);
    final x2 = (x + radius).clamp(0, _scaledWidth - 1);
    final y2 = (y + radius).clamp(0, _scaledHeight - 1);
    
    final count = (x2 - x1 + 1) * (y2 - y1 + 1);
    if (count <= 1) return 0;
    
    // Get sum and sumSq for region using integral image (O(1)!)
    final sum = _getRectSum(_integralSum, x1, y1, x2, y2);
    final sumSq = _getRectSum(_integralSumSq, x1, y1, x2, y2);
    
    // Variance = E[X²] - E[X]²
    final mean = sum / count;
    final variance = (sumSq / count) - (mean * mean);
    
    return variance.abs(); // abs() to handle floating point errors
  }
  
  int _getRectSum(List<int> integral, int x1, int y1, int x2, int y2) {
    int sum = integral[y2 * _scaledWidth + x2];
    if (x1 > 0) sum -= integral[y2 * _scaledWidth + (x1 - 1)];
    if (y1 > 0) sum -= integral[(y1 - 1) * _scaledWidth + x2];
    if (x1 > 0 && y1 > 0) sum += integral[(y1 - 1) * _scaledWidth + (x1 - 1)];
    return sum;
  }
  
  /// Check if a normalized screen point is in a uniform (sky-like) region
  bool isUniform(double normalizedX, double normalizedY, {double threshold = 200}) {
    final x = (normalizedX * _scaledWidth).round().clamp(0, _scaledWidth - 1);
    final y = (normalizedY * _scaledHeight).round().clamp(0, _scaledHeight - 1);
    
    // Check variance in 5-pixel radius (at downscaled resolution)
    final variance = getVariance(x, y, 5);
    
    // Low variance = uniform = likely sky
    return variance < threshold;
  }
  
  Uint8List _downscale(CameraImage image, int targetW, int targetH) {
    final result = Uint8List(targetW * targetH);
    final scaleX = image.width / targetW;
    final scaleY = image.height / targetH;
    
    for (int y = 0; y < targetH; y++) {
      for (int x = 0; x < targetW; x++) {
        final srcX = (x * scaleX).round();
        final srcY = (y * scaleY).round();
        final srcIdx = (srcY * image.width + srcX) * 4;
        
        // Convert to grayscale
        final r = image.planes[0].bytes[srcIdx];
        final g = image.planes[0].bytes[srcIdx + 1];
        final b = image.planes[0].bytes[srcIdx + 2];
        final gray = ((r * 0.299) + (g * 0.587) + (b * 0.114)).round();
        
        result[y * targetW + x] = gray;
      }
    }
    return result;
  }
}
```

**Performance comparison:**
| Method | Per-pixel cost | For 1920×1080 |
|--------|---------------|---------------|
| Naive (check neighbors) | O(r²) per pixel | ~2 billion ops |
| Integral image | O(1) per pixel | ~2 million ops |
| Integral + downscale | O(1) on 128×96 | ~12,000 ops |

**That's ~160,000x faster!**

---

### Combined: Production-Ready Sky Detector

```dart
class ProductionSkyDetector implements SkyMask {
  final AutoCalibratingSkyDetector _colorDetector = AutoCalibratingSkyDetector();
  final OptimizedUniformityDetector _uniformityDetector = OptimizedUniformityDetector();
  
  // Cached results
  Uint8List? _cachedMask;
  int _cachedWidth = 0;
  int _cachedHeight = 0;
  double _cachedSkyFraction = 0;
  
  @override
  double get skyFraction => _cachedSkyFraction;
  
  /// Process a frame and update the sky mask
  void processFrame(CameraImage image, double pitchDegrees) {
    // Pre-compute uniformity integral images (fast, once per frame)
    _uniformityDetector.precompute(image);
    
    // Get color-based mask
    final colorMask = _colorDetector.detectSky(image, pitchDegrees);
    
    // Combine with uniformity check
    final width = image.width;
    final height = image.height;
    final finalMask = Uint8List(width * height);
    
    int skyPixels = 0;
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        
        // Must pass color check
        if (colorMask[idx] == 0) {
          finalMask[idx] = 0;
          continue;
        }
        
        // Must pass uniformity check
        final normX = x / width;
        final normY = y / height;
        if (!_uniformityDetector.isUniform(normX, normY)) {
          finalMask[idx] = 0;
          continue;
        }
        
        finalMask[idx] = 255;
        skyPixels++;
      }
    }
    
    _cachedMask = finalMask;
    _cachedWidth = width;
    _cachedHeight = height;
    _cachedSkyFraction = skyPixels / (width * height);
  }
  
  @override
  bool isPointInSky(double normalizedX, double normalizedY) {
    if (_cachedMask == null) return false;
    
    final x = (normalizedX * _cachedWidth).round().clamp(0, _cachedWidth - 1);
    final y = (normalizedY * _cachedHeight).round().clamp(0, _cachedHeight - 1);
    
    return _cachedMask![y * _cachedWidth + x] > 0;
  }
  
  /// Force recalibration (call when user taps "calibrate" button)
  void forceCalibrate(CameraImage image, double pitchDegrees) {
    _colorDetector.calibrateFromCurrentFrame(image, pitchDegrees);
  }
}
```

**Usage in the app:**
```dart
class ARViewScreen extends StatefulWidget {
  // ...
}

class _ARViewScreenState extends State<ARViewScreen> {
  final skyDetector = ProductionSkyDetector();
  
  void onCameraFrame(CameraImage image) {
    final pitch = compassService.pitch;
    
    // Process sky detection
    skyDetector.processFrame(image, pitch);
    
    // Update particle overlay
    setState(() {
      // Particles will use skyDetector.isPointInSky()
    });
  }
  
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CameraPreview(onFrame: onCameraFrame),
        ParticleOverlay(skyMask: skyDetector),
        
        // Debug: show sky fraction
        Positioned(
          top: 50,
          left: 20,
          child: Text(
            'Sky: ${(skyDetector.skyFraction * 100).toStringAsFixed(1)}%',
            style: TextStyle(color: Colors.white),
          ),
        ),
        
        // Calibration button
        Positioned(
          bottom: 100,
          right: 20,
          child: FloatingActionButton(
            onPressed: () => skyDetector.forceCalibrate(
              currentImage!, 
              compassService.pitch,
            ),
            child: Icon(Icons.tune),
            tooltip: 'Calibrate sky detection',
          ),
        ),
      ],
    );
  }
}
```

### Required Utility Functions

```dart
import 'dart:math' show sqrt, exp, pi;

class HSV {
  final double h; // 0-360
  final double s; // 0-1
  final double v; // 0-1
  HSV(this.h, this.s, this.v);
}

HSV rgbToHsv(int r, int g, int b) {
  double rd = r / 255.0;
  double gd = g / 255.0;
  double bd = b / 255.0;
  
  double maxVal = [rd, gd, bd].reduce((a, b) => a > b ? a : b);
  double minVal = [rd, gd, bd].reduce((a, b) => a < b ? a : b);
  double delta = maxVal - minVal;
  
  double h = 0;
  if (delta != 0) {
    if (maxVal == rd) {
      h = 60 * (((gd - bd) / delta) % 6);
    } else if (maxVal == gd) {
      h = 60 * (((bd - rd) / delta) + 2);
    } else {
      h = 60 * (((rd - gd) / delta) + 4);
    }
  }
  if (h < 0) h += 360;
  
  double s = maxVal == 0 ? 0 : delta / maxVal;
  double v = maxVal;
  
  return HSV(h, s, v);
}
```

#### Level 3: ML-Based (Best — Complex)
Use a semantic segmentation model (DeepLabV3) to detect sky pixels.

> ⚠️ **HIGH COMPLEXITY WARNING**
> 
> ML integration is notoriously fragile. Only attempt after Levels 1-2 work.
> See Section 3b for detailed ML implementation guide.

### Verification Checkpoint
Before proceeding to particles:

```dart
// Add this debug visualization
Widget buildDebugView() {
  return Stack(
    children: [
      CameraPreview(),
      // Overlay showing sky mask as semi-transparent red
      CustomPaint(
        painter: SkyMaskDebugPainter(skyMask),
      ),
      // Show sky percentage
      Text('Sky: ${(skyFraction * 100).toStringAsFixed(1)}%'),
    ],
  );
}
```

**STOP and verify:**
- [ ] Point at ground → Sky fraction ~0%
- [ ] Point at sky → Sky fraction 50-90%
- [ ] Red overlay covers ONLY sky region
- [ ] Buildings/trees are NOT covered (if using Level 2+)

**Do NOT proceed to particles until this works.**

---

## 3b. ML-Based Sky Segmentation (OPTIONAL — High Complexity)

> ⚠️ **Read All Warnings Before Attempting**
> 
> This section is OPTIONAL. Level 1 or 2 sky detection is fine for MVP.
> Only attempt ML after simpler approaches work.

### Why ML?
- Handles all sky colors (blue, gray, sunset, overcast)
- Properly masks buildings, trees, mountains
- More "magical" user experience

### The TFLite Trap (Read This First)

Based on real implementation experience, here are the gotchas:

| Problem | Symptom | Solution |
|---------|---------|----------|
| Wrong buffer shape | "Output shape mismatch" error | Log actual tensor shape first |
| IsolateInterpreter | Output buffer stays all zeros | Use synchronous `runForMultipleInputs` |
| Wrong buffer type | Crash or garbage values | Match tensor type (float32 → double) |
| Wrong sky class index | 0% sky everywhere | Check if model uses ADE20K (sky=2) |

### MANDATORY: Verification-First Approach

**Phase 1: Model Discovery (DO THIS FIRST)**
```dart
// In initialize(), BEFORE any buffer allocation:
final interpreter = await Interpreter.fromAsset('deeplabv3.tflite');

// Log input requirements
final inputTensors = interpreter.getInputTensors();
for (var tensor in inputTensors) {
  print('INPUT: shape=${tensor.shape}, type=${tensor.type}');
}

// Log output format
final outputTensors = interpreter.getOutputTensors();
for (var tensor in outputTensors) {
  print('OUTPUT: shape=${tensor.shape}, type=${tensor.type}');
}

// STOP HERE. Run the app. Look at the logs.
// Only proceed when you know the ACTUAL shapes.
```

**Common DeepLabV3 output shapes:**
| Model Variant | Output Shape | What It Means |
|---------------|--------------|---------------|
| metadata/1 | `[1, 257, 257]` | Direct class indices (int64) |
| metadata/2 | `[1, 257, 257, 21]` | Probability per class (float32) — needs argmax |

**Phase 2: Mock-First Development**
```dart
class MockSkyMask {
  /// Returns a mask where top 60% is sky
  Uint8List generateMockMask(int width, int height) {
    final mask = Uint8List(width * height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final isSky = y < height * 0.6;
        mask[y * width + x] = isSky ? 255 : 0;
      }
    }
    return mask;
  }
}
```

1. Wire mock mask to particle overlay
2. Verify particles only appear in top 60%
3. ONLY THEN proceed to real inference

**Phase 3: Real Inference (Only After Phases 1-2)**
```dart
// ❌ WRONG — IsolateInterpreter doesn't fill nested Lists properly
IsolateInterpreter isolate = ...;
await isolate.run(input, outputNestedList); // OUTPUT STAYS ALL ZEROS

// ✅ CORRECT — Use synchronous interpreter with output map
var outputBuffer = List.generate(1, (_) => 
  List.generate(257, (_) => 
    List.generate(257, (_) => 
      List.filled(21, 0.0))));

var outputMap = <int, Object>{0: outputBuffer};
interpreter.runForMultipleInputs([inputBuffer], outputMap);
```

**Phase 4: Incremental Checkpoints**
After each step, STOP and verify:

- [ ] **Checkpoint 1:** Model loads → logs show tensor shapes
- [ ] **Checkpoint 2:** Mock mask works → particles in top 60% only
- [ ] **Checkpoint 3:** Inference runs → logs show "inference complete"
- [ ] **Checkpoint 4:** Output has values → logs show non-zero probabilities
- [ ] **Checkpoint 5:** Argmax works → logs show class distribution
- [ ] **Checkpoint 6:** Sky detected → sky percentage > 0 when pointing at sky

**If ANY checkpoint fails, STOP. Do not proceed. Debug that checkpoint.**

### iOS TFLite Configuration
```ruby
# In ios/Podfile:
platform :ios, '14.0'  # TFLite requires iOS 14+

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
```

If you see "Framework not found" errors:
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
flutter clean
flutter build ios
```

---

## 4. Project Structure

```
wind_lens/
├── lib/
│   ├── main.dart                     # App entry point
│   ├── app.dart                      # MaterialApp configuration
│   │
│   ├── models/
│   │   ├── wind_data.dart            # Wind data model
│   │   ├── altitude_level.dart       # Altitude enum + properties
│   │   ├── particle.dart             # Single particle model
│   │   └── sky_mask.dart             # Sky mask model
│   │
│   ├── services/
│   │   ├── wind_service.dart         # Facade: picks real vs fake data
│   │   ├── edr_wind_service.dart     # Real data from OGC EDR API
│   │   ├── fake_wind_service.dart    # Generates simulated wind data
│   │   ├── compass_service.dart      # Wraps magnetometer stream
│   │   ├── location_service.dart     # Gets GPS (for API queries)
│   │   └── sky_detection/
│   │       ├── sky_detector.dart           # Abstract interface
│   │       ├── pitch_based_detector.dart   # Level 1: Simple
│   │       ├── color_based_detector.dart   # Level 2: HSV
│   │       └── ml_sky_detector.dart        # Level 3: TFLite (optional)
│   │
│   ├── providers/
│   │   └── wind_state.dart           # App state management (ChangeNotifier)
│   │
│   ├── widgets/
│   │   ├── camera_view.dart          # Camera preview widget
│   │   ├── sky_mask_overlay.dart     # Debug view for sky mask
│   │   ├── particle_overlay.dart     # CustomPainter for particles
│   │   ├── altitude_slider.dart      # Vertical altitude selector
│   │   ├── compass_indicator.dart    # Small compass rose UI
│   │   └── debug_panel.dart          # Shows raw values during dev
│   │
│   └── screens/
│       └── ar_view_screen.dart       # Main screen composing all widgets
│
├── assets/
│   └── models/
│       └── deeplabv3.tflite          # Optional: ML model for sky segmentation
│
├── ios/
│   └── Runner/Info.plist             # Camera + location permissions
│
├── android/
│   └── app/src/main/AndroidManifest.xml
│
├── pubspec.yaml
├── README.md
└── WIND_LENS_MVP_SPEC.md             # This file
```

---

## 5. Data Models

### 4.1 WindData
```dart
class WindData {
  final double uComponent;      // m/s, positive = eastward
  final double vComponent;      // m/s, positive = northward
  final double altitude;        // meters above sea level
  final DateTime timestamp;
  
  // Computed properties
  double get speed => sqrt(uComponent * uComponent + vComponent * vComponent);
  double get directionRadians => atan2(-uComponent, -vComponent); // meteorological convention
  double get directionDegrees => (directionRadians * 180 / pi + 360) % 360;
}
```

### 4.2 AltitudeLevel
```dart
enum AltitudeLevel {
  surface,    // 0-500ft / 0-150m
  midLevel,   // ~5,000ft / ~1,500m (850 hPa)
  jetStream,  // ~34,000ft / ~10,500m (250 hPa)
}

extension AltitudeLevelProperties on AltitudeLevel {
  String get displayName => switch (this) {
    AltitudeLevel.surface => 'Surface',
    AltitudeLevel.midLevel => 'Cloud Level',
    AltitudeLevel.jetStream => 'Jet Stream',
  };
  
  double get metersAGL => switch (this) {
    AltitudeLevel.surface => 10,
    AltitudeLevel.midLevel => 1500,
    AltitudeLevel.jetStream => 10500,
  };
  
  Color get particleColor => switch (this) {
    AltitudeLevel.surface => Color(0xAAFFFFFF),    // ghostly white
    AltitudeLevel.midLevel => Color(0xAA00DDFF),   // cyan
    AltitudeLevel.jetStream => Color(0xAADD00FF),  // magenta/purple
  };
  
  double get particleSpeedMultiplier => switch (this) {
    AltitudeLevel.surface => 1.0,
    AltitudeLevel.midLevel => 1.5,
    AltitudeLevel.jetStream => 3.0,
  };
}
```

### 4.3 Particle
```dart
class Particle {
  double x;           // 0.0 to 1.0 (normalized screen coordinates)
  double y;           // 0.0 to 1.0
  double age;         // 0.0 to 1.0 (for fade in/out)
  double trailLength; // pixels, based on wind speed
  
  void reset(Random random) {
    x = random.nextDouble();
    y = random.nextDouble();
    age = 0.0;
  }
}
```

---

## 6. Real Data Integration (OGC EDR API)

> 🟡 **THIS SECTION IS OPTIONAL — Post-MVP**
> 
> Do NOT start here. Complete Steps 1-5b (fake data + interpolation) first.
> Real API integration is a "Bonus Level" — don't let a 404 error block your UI progress.

### Overview
Instead of (or in addition to) fake data, the app can fetch real wind data from OGC Environmental Data Retrieval (EDR) APIs. Joe's team has two available endpoints:

| Endpoint | URL | Notes |
|----------|-----|-------|
| ShyftWx | `https://ogc.shyftwx.com/ogc/edr` | Primary |
| FolkWeather | `https://folkweather.com/edr` | Joe's service, backup |

Both follow the OGC EDR standard, so the integration code works for either.

### EDR API Crash Course

#### Discovery: What collections are available?
```
GET https://ogc.shyftwx.com/ogc/edr/collections
```
Returns JSON listing all available datasets. Look for collections with wind parameters like:
- `u-component-of-wind` (eastward velocity, m/s)
- `v-component-of-wind` (northward velocity, m/s)
- May also have: `wind-speed`, `wind-direction`, `edr` (turbulence)

#### Point Query: Get wind at a location
```
GET /collections/{collectionId}/position?
    coords=POINT(-122.4194 37.7749)     # lon lat (San Francisco)
    &parameter-name=u-component-of-wind,v-component-of-wind
    &z=850                               # pressure level (hPa)
    &datetime=2025-01-19T12:00:00Z       # optional, defaults to latest
    &f=CoverageJSON                      # response format
```

#### Pressure Levels (z parameter)
| Our Altitude | Pressure Level | z value |
|--------------|----------------|---------|
| Surface | ~1000 hPa | `1000` or `surface` |
| Mid-level (5000ft) | 850 hPa | `850` |
| Upper (18000ft) | 500 hPa | `500` |
| Jet Stream (34000ft) | 250 hPa | `250` |

### CoverageJSON Response Format
The API returns CoverageJSON, which looks like this:
```json
{
  "type": "Coverage",
  "domain": {
    "type": "Domain",
    "domainType": "Point",
    "axes": {
      "x": { "values": [-122.4194] },
      "y": { "values": [37.7749] },
      "z": { "values": [850] },
      "t": { "values": ["2025-01-19T12:00:00Z"] }
    }
  },
  "ranges": {
    "u-component-of-wind": {
      "type": "NdArray",
      "dataType": "float",
      "values": [12.5]
    },
    "v-component-of-wind": {
      "type": "NdArray", 
      "dataType": "float",
      "values": [-3.2]
    }
  }
}
```

### Dart Implementation

#### EDR Service
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class EdrWindService {
  // Toggle between endpoints
  static const String baseUrl = 'https://ogc.shyftwx.com/ogc/edr';
  // static const String baseUrl = 'https://folkweather.com/edr';
  
  // Cache to avoid hammering the API
  final Map<String, _CachedWind> _cache = {};
  static const Duration cacheTimeout = Duration(minutes: 5);
  
  /// Fetch wind data for a location at multiple pressure levels
  Future<Map<AltitudeLevel, WindData>> fetchWindProfile({
    required double latitude,
    required double longitude,
  }) async {
    final results = <AltitudeLevel, WindData>{};
    
    // Fetch all levels in parallel
    await Future.wait([
      _fetchWindAtLevel(latitude, longitude, 1000, AltitudeLevel.surface),
      _fetchWindAtLevel(latitude, longitude, 850, AltitudeLevel.midLevel),
      _fetchWindAtLevel(latitude, longitude, 250, AltitudeLevel.jetStream),
    ].map((future) async {
      final result = await future;
      if (result != null) {
        results[result.$1] = result.$2;
      }
    }));
    
    return results;
  }
  
  Future<(AltitudeLevel, WindData)?> _fetchWindAtLevel(
    double lat,
    double lon,
    int pressureLevel,
    AltitudeLevel level,
  ) async {
    final cacheKey = '$lat,$lon,$pressureLevel';
    
    // Check cache
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (DateTime.now().difference(cached.timestamp) < cacheTimeout) {
        return (level, cached.data);
      }
    }
    
    try {
      // TODO: Replace with actual collection ID from /collections discovery
      const collectionId = 'gfs-wind';  // Example - discover actual ID first!
      
      final uri = Uri.parse('$baseUrl/collections/$collectionId/position').replace(
        queryParameters: {
          'coords': 'POINT($lon $lat)',
          'parameter-name': 'u-component-of-wind,v-component-of-wind',
          'z': pressureLevel.toString(),
          'f': 'CoverageJSON',
        },
      );
      
      final response = await http.get(uri).timeout(Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        print('EDR API error: ${response.statusCode}');
        return null;
      }
      
      final json = jsonDecode(response.body);
      final ranges = json['ranges'] as Map<String, dynamic>;
      
      // Extract u and v components
      final uValues = ranges['u-component-of-wind']['values'] as List;
      final vValues = ranges['v-component-of-wind']['values'] as List;
      
      final windData = WindData(
        uComponent: (uValues.first as num).toDouble(),
        vComponent: (vValues.first as num).toDouble(),
        altitude: _pressureToAltitude(pressureLevel),
        timestamp: DateTime.now(),
      );
      
      // Cache it
      _cache[cacheKey] = _CachedWind(windData, DateTime.now());
      
      return (level, windData);
      
    } catch (e) {
      print('EDR fetch error: $e');
      return null;
    }
  }
  
  double _pressureToAltitude(int hPa) {
    // Approximate conversion
    return switch (hPa) {
      1000 => 10,
      850 => 1500,
      500 => 5500,
      250 => 10500,
      _ => 1000,
    };
  }
}

class _CachedWind {
  final WindData data;
  final DateTime timestamp;
  _CachedWind(this.data, this.timestamp);
}
```

#### Grid Query for Phase B (Spatial Variation)
For the interpolation discussed in Section 6, fetch a 3×3 grid:

```dart
/// Fetch wind grid around user for spatial interpolation
Future<List<List<WindData>>> fetchWindGrid({
  required double centerLat,
  required double centerLon,
  required int pressureLevel,
  double gridSpacing = 0.1,  // ~11km in degrees
}) async {
  final grid = <List<WindData>>[];
  
  for (int row = -1; row <= 1; row++) {
    final rowData = <WindData>[];
    for (int col = -1; col <= 1; col++) {
      final lat = centerLat + (row * gridSpacing);
      final lon = centerLon + (col * gridSpacing);
      
      // Could also use /area query for efficiency
      final wind = await _fetchSinglePoint(lat, lon, pressureLevel);
      rowData.add(wind ?? WindData.zero());
    }
    grid.add(rowData);
  }
  
  return grid;
}
```

### Discovery Script (MUST RUN FIRST — Before Any App Code)

> ⚠️ **CRITICAL: CRS (Coordinate Reference System) Mismatch**
> 
> If the API returns coordinates in `EPSG:3857` (Web Mercator) but you assume `CRS:84` (Lat/Lon),
> your wind directions will be **90 degrees wrong**. The discovery script below checks for this.
> 
> **Run this script BEFORE writing any Flutter app code that uses real data.**

Create a standalone Dart file (not Flutter — just `dart run discovery.dart`):

```dart
// discovery.dart — Run with: dart run discovery.dart
import 'dart:convert';
import 'dart:io';

const baseUrl = 'https://ogc.shyftwx.com/ogc/edr';
// const baseUrl = 'https://folkweather.com/edr';

void main() async {
  final client = HttpClient();
  
  print('🔍 Discovering EDR API collections...\n');
  
  try {
    // Step 1: Get all collections
    final collectionsUri = Uri.parse('$baseUrl/collections');
    final request = await client.getUrl(collectionsUri);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    
    if (response.statusCode != 200) {
      print('❌ API returned ${response.statusCode}');
      print(body);
      exit(1);
    }
    
    final json = jsonDecode(body);
    final collections = json['collections'] as List;
    
    print('Found ${collections.length} collections:\n');
    
    for (final c in collections) {
      final id = c['id'];
      final title = c['title'] ?? 'No title';
      final crs = c['crs'] ?? ['Unknown'];
      final params = c['parameter_names'] as Map<String, dynamic>? ?? {};
      
      // Check if this collection has wind data
      final hasWind = params.keys.any((k) => 
        k.toLowerCase().contains('wind') ||
        k.toLowerCase().contains('ugrd') ||
        k.toLowerCase().contains('vgrd') ||
        k == 'u' || k == 'v'
      );
      
      final windIcon = hasWind ? '💨' : '  ';
      
      print('$windIcon ID: $id');
      print('   Title: $title');
      print('   CRS: ${crs.join(', ')}');
      print('   Parameters: ${params.keys.take(10).join(', ')}${params.length > 10 ? '...' : ''}');
      
      // CRS WARNING
      if (crs.any((c) => c.toString().contains('3857'))) {
        print('   ⚠️  WARNING: Uses EPSG:3857 (Web Mercator) — requires coordinate transformation!');
      }
      if (crs.any((c) => c.toString().contains('CRS84') || c.toString().contains('4326'))) {
        print('   ✅ Uses CRS84/EPSG:4326 (Lat/Lon) — direct coordinate mapping OK');
      }
      
      print('');
    }
    
    // Step 2: Identify best wind collection
    print('─' * 50);
    print('\n🎯 RECOMMENDED: Look for collections with:');
    print('   • "u-component-of-wind" or "UGRD" parameter');
    print('   • "v-component-of-wind" or "VGRD" parameter');
    print('   • CRS84 or EPSG:4326 coordinate system');
    print('   • Multiple pressure levels (z values)');
    
    print('\n📋 Copy the collection ID to edr_wind_service.dart');
    
  } catch (e) {
    print('❌ Error: $e');
    print('\nMake sure you have network access and the API is up.');
  } finally {
    client.close();
  }
}
```

#### What to look for in the output:
| Field | Good Value | Bad Value (needs work) |
|-------|-----------|----------------------|
| CRS | `CRS84`, `EPSG:4326` | `EPSG:3857` (needs transform) |
| Parameters | `u-component-of-wind`, `v-component-of-wind` | Missing wind params |
| z levels | Multiple (1000, 850, 500, 250) | Single level only |

#### If API uses EPSG:3857
You'll need to add coordinate transformation. Skip this for MVP — just find a collection that uses CRS84.

### Fallback Strategy
```dart
class WindService {
  final EdrWindService _edrService = EdrWindService();
  final FakeWindService _fakeService = FakeWindService();
  
  bool _useRealData = true;
  
  Future<WindData> getWind(double lat, double lon, AltitudeLevel level) async {
    if (_useRealData) {
      try {
        final profile = await _edrService.fetchWindProfile(
          latitude: lat,
          longitude: lon,
        );
        if (profile.containsKey(level)) {
          return profile[level]!;
        }
      } catch (e) {
        print('Falling back to fake data: $e');
      }
    }
    
    // Fallback to fake data
    return _fakeService.getWindForAltitude(level);
  }
}
```

### Rate Limiting Considerations
- Cache aggressively (5-minute minimum)
- Don't fetch on every frame—fetch on app start + location change
- The particle system interpolates between fetches
- Consider fetching in background and updating state

### EDR vs Open-Meteo Comparison
| Aspect | OGC EDR (Joe's servers) | Open-Meteo |
|--------|-------------------------|------------|
| Auth | None (Joe's are open) | None (free tier) |
| Pressure levels | Full isobaric | Limited |
| Update frequency | Model-dependent | Hourly |
| Grid resolution | Varies (~25km GFS) | ~25km |
| Response format | CoverageJSON | JSON |
| **Best for** | Aviation-grade data | Simple prototyping |

### Implementation Order
1. **MVP:** Use `FakeWindService` (already specced)
2. **MVP+:** Run discovery script on Joe's endpoints to find collection IDs
3. **MVP+:** Implement `EdrWindService` with single-point queries
4. **Post-MVP:** Add grid queries for Phase B spatial interpolation

---

## 7. Fake Data Fallback

### Why Fake Data First
- No API key management
- Works offline
- Predictable for testing
- Instant iteration

### FakeWindService Implementation
```dart
class FakeWindService {
  // Returns wind data that slowly varies over time
  // to simulate realistic-ish conditions
  
  WindData getWindForAltitude(AltitudeLevel level) {
    final time = DateTime.now().millisecondsSinceEpoch / 1000;
    
    return switch (level) {
      AltitudeLevel.surface => WindData(
        uComponent: 3.0 + sin(time * 0.1) * 2.0,   // 1-5 m/s, varying
        vComponent: 2.0 + cos(time * 0.15) * 1.5,  // light breeze
        altitude: 10,
        timestamp: DateTime.now(),
      ),
      AltitudeLevel.midLevel => WindData(
        uComponent: 8.0 + sin(time * 0.08) * 4.0,  // 4-12 m/s
        vComponent: -5.0 + cos(time * 0.12) * 3.0, // moderate wind
        altitude: 1500,
        timestamp: DateTime.now(),
      ),
      AltitudeLevel.jetStream => WindData(
        uComponent: 45.0 + sin(time * 0.05) * 15.0, // 30-60 m/s (!!)
        vComponent: -10.0 + cos(time * 0.07) * 8.0, // strong westerlies
        altitude: 10500,
        timestamp: DateTime.now(),
      ),
    };
  }
}
```

### Fake Data Characteristics
| Level | Typical Speed | Direction | Visual Feel |
|-------|--------------|-----------|-------------|
| Surface | 2-6 m/s | Variable | Gentle drift |
| Mid-level | 5-15 m/s | More consistent | Steady flow |
| Jet Stream | 30-70 m/s | Predominantly West→East | FAST rivers |

---

## 8. Spatial Wind Variation (The "Sky Viewport" Problem)

### The Problem
The current fake data model returns ONE wind vector per altitude level. This means all particles at a given altitude flow in the exact same direction—visually flat and fake.

In reality, when you point your phone at the sky:
- Your viewport forms a **cone** that expands with altitude
- At surface level (10m), you're "seeing" maybe 50 feet of sky
- At jet stream (34,000 ft), that same viewing angle covers **4-5 miles** of atmosphere
- Wind can vary significantly across that distance

### The Math: How Big Is "The Sky"?
```
Phone camera FOV: ~70° (typical)
Half-angle: 35°

Viewport width at altitude = 2 × altitude × tan(35°)

Surface (10m):      ~14 meters across      → negligible variation
Mid-level (1500m):  ~2.1 km across         → minor variation  
Jet stream (10500m): ~14.7 km across       → significant variation
```

Weather grid resolution (Open-Meteo/GFS): ~25-30 km per cell

**Insight:** Even at jet stream, we're often within ONE grid cell. But near grid boundaries, or with finer data sources, spatial variation matters.

### Implementation Phases

#### Phase A: Single Point (Current MVP)
```
User GPS → Fetch 1 point × 3 altitudes → Same wind across entire screen
```
- **Pros:** Simple, fast, works offline with fake data
- **Cons:** Visually uniform, breaks immersion
- **Verdict:** Fine for initial testing, not for "wow" factor

#### Phase B: Grid Sampling + Bilinear Interpolation (MVP+)
```
User GPS → Fetch 3×3 grid × 3 altitudes → Interpolate per-particle based on screen position
```

Fetch wind data for 9 points in a grid around the user:
```
  NW -------- N -------- NE
   |          |          |
   |    [USER GPS]       |
   |          |          |
  SW -------- S -------- SE
   
Grid spacing: ~0.1° lat/lon (~11 km)
```

Then in the particle shader/painter:
```dart
WindData getWindAtScreenPosition(double screenX, double screenY, AltitudeLevel alt) {
  // Map screen position to world position based on altitude
  // Higher altitude = screen edges map to points further from user
  double worldOffsetScale = alt.metersAGL / 10000; // normalized
  
  double worldX = userLon + (screenX - 0.5) * 0.1 * worldOffsetScale;
  double worldY = userLat + (screenY - 0.5) * 0.1 * worldOffsetScale;
  
  // Bilinear interpolation between 4 nearest grid points
  return bilinearInterpolate(worldX, worldY, gridData[alt]);
}
```

**Visual Result:** Wind direction subtly shifts across the screen. Particles on the left might flow slightly different than the right. Feels organic.

#### Phase C: Cone Projection + Terrain (Future)
```
User GPS + Phone Orientation + Terrain Model → Calculate exact viewport frustum → 
Query precise coverage area → GPU-based flow field
```

This is "video game" level:
- Use phone pitch/yaw to calculate exact sky cone
- Factor in terrain (mountains block low-altitude view)
- Build a proper flow field texture on GPU
- Particles sample the texture for per-pixel accurate wind

**Not for MVP.** But architecturally, Phase B sets you up for this.

### Updated Fake Data Service (Phase B Ready)

```dart
class FakeWindService {
  // Grid of fake wind data (3x3 around user)
  // In real implementation, this comes from API
  
  Map<AltitudeLevel, List<List<WindData>>> _gridData = {};
  
  FakeWindService() {
    _generateFakeGrid();
  }
  
  void _generateFakeGrid() {
    final time = DateTime.now().millisecondsSinceEpoch / 1000;
    
    for (final level in AltitudeLevel.values) {
      _gridData[level] = List.generate(3, (row) {
        return List.generate(3, (col) {
          // Base wind for this altitude
          var base = _getBaseWind(level, time);
          
          // Add spatial variation (±20% based on grid position)
          double spatialNoise = sin(row * 1.5 + col * 2.3 + time * 0.05);
          
          return WindData(
            uComponent: base.uComponent * (1 + spatialNoise * 0.2),
            vComponent: base.vComponent * (1 + spatialNoise * 0.15),
            altitude: base.altitude,
            timestamp: DateTime.now(),
          );
        });
      });
    }
  }
  
  WindData getWindAtPosition(
    double normalizedX,  // 0.0 = left edge, 1.0 = right edge
    double normalizedY,  // 0.0 = top edge, 1.0 = bottom edge  
    AltitudeLevel level,
  ) {
    // Scale position influence by altitude (higher = more spread)
    double spread = level.metersAGL / 10000;
    double gridX = 1.0 + (normalizedX - 0.5) * spread; // Center of 3x3 grid
    double gridY = 1.0 + (normalizedY - 0.5) * spread;
    
    return _bilinearInterpolate(gridX, gridY, _gridData[level]!);
  }
  
  WindData _bilinearInterpolate(double x, double y, List<List<WindData>> grid) {
    int x0 = x.floor().clamp(0, 1);
    int y0 = y.floor().clamp(0, 1);
    int x1 = (x0 + 1).clamp(0, 2);
    int y1 = (y0 + 1).clamp(0, 2);
    
    double xFrac = x - x0;
    double yFrac = y - y0;
    
    // Interpolate u component
    double u = _bilerp(
      grid[y0][x0].uComponent, grid[y0][x1].uComponent,
      grid[y1][x0].uComponent, grid[y1][x1].uComponent,
      xFrac, yFrac,
    );
    
    // Interpolate v component
    double v = _bilerp(
      grid[y0][x0].vComponent, grid[y0][x1].vComponent,
      grid[y1][x0].vComponent, grid[y1][x1].vComponent,
      xFrac, yFrac,
    );
    
    return WindData(
      uComponent: u,
      vComponent: v,
      altitude: grid[0][0].altitude,
      timestamp: DateTime.now(),
    );
  }
  
  double _bilerp(double tl, double tr, double bl, double br, double x, double y) {
    double top = tl + (tr - tl) * x;
    double bottom = bl + (br - bl) * x;
    return top + (bottom - top) * y;
  }
}
```

### Particle Update (Phase B)

> ⚠️ **PERFORMANCE CRITICAL — Read This**
> 
> Bilinear interpolation for 2000 particles × 60 FPS = **120,000 interpolations/second**.
> 
> **DO NOT** create new `WindData` objects inside the render loop — this triggers
> Garbage Collection stutter and will kill your frame rate on older phones.
> 
> Instead, interpolate the raw `u` and `v` doubles directly.

```dart
// WRONG — Creates garbage, causes stutter
void updateParticleBad(Particle p, AltitudeLevel level, double dt) {
  WindData wind = windService.getWindAtPosition(p.x, p.y, level); // ❌ New object!
  // ... use wind
}

// RIGHT — No allocations in hot path
class ParticleSystem {
  // Pre-allocated grid data (set once per API fetch, not per frame)
  late List<List<double>> _gridU;  // 3x3 grid of u components
  late List<List<double>> _gridV;  // 3x3 grid of v components
  late double _altitudeSpread;
  
  // Reusable output — NEVER allocate in the loop
  double _interpU = 0;
  double _interpV = 0;
  
  void updateParticle(Particle p, double dt, double compassHeading) {
    // Interpolate directly into pre-allocated doubles
    _interpolateWind(p.x, p.y);
    
    // Calculate direction from raw components (no object creation)
    double windAngle = atan2(-_interpU, -_interpV);
    double adjustedAngle = windAngle - (compassHeading * pi / 180);
    
    double speed = sqrt(_interpU * _interpU + _interpV * _interpV);
    double speedFactor = speed * 0.002 * _currentLevel.particleSpeedMultiplier;
    
    p.x += cos(adjustedAngle) * speedFactor * dt;
    p.y -= sin(adjustedAngle) * speedFactor * dt;
    
    p.age += dt * 0.3;
    p.trailLength = speed * 0.5;
  }
  
  /// Bilinear interpolation — writes directly to _interpU, _interpV
  /// No object allocation!
  void _interpolateWind(double normX, double normY) {
    // Map screen position to grid position
    double gridX = 1.0 + (normX - 0.5) * _altitudeSpread;
    double gridY = 1.0 + (normY - 0.5) * _altitudeSpread;
    
    int x0 = gridX.floor().clamp(0, 1);
    int y0 = gridY.floor().clamp(0, 1);
    int x1 = (x0 + 1).clamp(0, 2);
    int y1 = (y0 + 1).clamp(0, 2);
    
    double xFrac = gridX - x0;
    double yFrac = gridY - y0;
    
    // Interpolate U component
    double topU = _gridU[y0][x0] + (_gridU[y0][x1] - _gridU[y0][x0]) * xFrac;
    double botU = _gridU[y1][x0] + (_gridU[y1][x1] - _gridU[y1][x0]) * xFrac;
    _interpU = topU + (botU - topU) * yFrac;
    
    // Interpolate V component
    double topV = _gridV[y0][x0] + (_gridV[y0][x1] - _gridV[y0][x0]) * xFrac;
    double botV = _gridV[y1][x0] + (_gridV[y1][x1] - _gridV[y1][x0]) * xFrac;
    _interpV = topV + (botV - topV) * yFrac;
  }
  
  /// Called when altitude changes or new data fetched (infrequent)
  void setGridData(AltitudeLevel level, List<List<WindData>> grid) {
    _currentLevel = level;
    _altitudeSpread = level.metersAGL / 10000;
    
    // Copy to flat arrays (one-time allocation)
    _gridU = grid.map((row) => row.map((w) => w.uComponent).toList()).toList();
    _gridV = grid.map((row) => row.map((w) => w.vComponent).toList()).toList();
  }
}
```

#### Performance Checklist
- [ ] No `new` or object literals inside `updateParticle()`
- [ ] No `List.map()` or `List.generate()` inside render loop
- [ ] Grid data copied to flat `double` arrays on altitude change (not per-frame)
- [ ] Interpolation writes to pre-allocated fields, not return values
- [ ] If FPS < 45, reduce particle count (1000 smooth > 2000 jittery)

### Visual Impact by Phase
| Phase | Screen Appearance | "Wow" Factor |
|-------|-------------------|--------------|
| A (Single Point) | All particles flow same direction | ⭐⭐ |
| B (Grid + Interp) | Subtle swirls, organic curves | ⭐⭐⭐⭐ |
| C (Full Cone) | Accurate viewport, terrain-aware | ⭐⭐⭐⭐⭐ |

### ⚠️ Phase B Performance Warning
Bilinear interpolation for 2000 particles × 60 FPS = **120,000 calculations/second**.

**Common Mistakes That Kill Performance:**
1. Creating `WindData` objects inside the render loop → GC stutter
2. Using `List.map()` or `List.generate()` per frame → GC stutter
3. Calling `sqrt()` when you don't need the actual speed (use squared comparisons)
4. Not pre-allocating the grid arrays

**If you see frame drops:** Reduce to 1000 particles first. 1000 smooth particles always beats 2000 choppy ones.

### Recommendation for MVP
1. **Build Phase A first** — get particles moving, camera working, slider working
2. **Upgrade to Phase B before showing anyone** — the interpolation makes it feel "real"
3. Phase B adds ~2 hours of work but 2× the visual impact

---

## 9. Particle System Specification

### The Problem: "Flat Screen" vs "In The Sky"
Without spatial depth, particles feel like a 2D sticker on your screen.
With spatial depth, particles feel like they exist at real altitudes in the sky.

### Making Particles Feel Spatial

#### Technique 1: Parallax Effect
When you rotate the phone, particles at different "depths" move at different speeds.

```dart
void updateParticleWithParallax(Particle p, double compassDelta, AltitudeLevel level) {
  // How much the phone rotated this frame (degrees)
  double rotation = compassDelta;
  
  // Parallax factor: higher altitude = further away = LESS apparent motion
  double parallaxFactor = switch (level) {
    AltitudeLevel.surface => 1.0,    // Close: moves a lot when you turn
    AltitudeLevel.midLevel => 0.6,   // Medium: moves moderately
    AltitudeLevel.jetStream => 0.3,  // Far: barely moves (like real clouds)
  };
  
  // Apply parallax offset
  p.x -= (rotation / 360.0) * parallaxFactor;
}
```

**Effect:** When you rotate your phone, surface winds visibly shift while jet streams barely move — just like looking at clouds at different heights.

#### Technique 2: Scale by Altitude
Particles "further away" (higher altitude) appear smaller.

```dart
double getParticleSize(AltitudeLevel level, double baseSize) {
  return switch (level) {
    AltitudeLevel.surface => baseSize * 1.0,    // Full size
    AltitudeLevel.midLevel => baseSize * 0.7,   // Smaller
    AltitudeLevel.jetStream => baseSize * 0.4,  // Much smaller
  };
}

double getTrailLength(AltitudeLevel level, double windSpeed) {
  // Same idea: higher = shorter trails (perspective)
  double perspectiveScale = switch (level) {
    AltitudeLevel.surface => 1.0,
    AltitudeLevel.midLevel => 0.7,
    AltitudeLevel.jetStream => 0.5,
  };
  return windSpeed * 0.5 * perspectiveScale;
}
```

#### Technique 3: Density by Altitude
Higher altitudes cover more area, so particles spread out more.

```dart
int getParticleCount(AltitudeLevel level, int baseCount) {
  // Higher altitude = same number of particles but covering MORE sky
  // So density appears lower (more spread out)
  return switch (level) {
    AltitudeLevel.surface => baseCount,           // 2000 particles
    AltitudeLevel.midLevel => (baseCount * 0.8).round(),  // 1600
    AltitudeLevel.jetStream => (baseCount * 0.5).round(), // 1000
  };
}
```

#### Technique 4: Speed Perception
Higher altitudes have faster winds, but appear to move slower due to distance.

```dart
double getApparentSpeed(AltitudeLevel level, double actualWindSpeed) {
  // Jet stream might be 50 m/s but looks slow because it's far away
  double distanceFactor = switch (level) {
    AltitudeLevel.surface => 1.0,
    AltitudeLevel.midLevel => 0.5,
    AltitudeLevel.jetStream => 0.25,
  };
  return actualWindSpeed * distanceFactor;
}
```

### Rendering Particles WITH Sky Mask

**Critical:** Particles should ONLY render where the sky mask says "sky."

```dart
class ParticleOverlayPainter extends CustomPainter {
  final List<Particle> particles;
  final Color color;
  final double windAngle;
  final double pitchDegrees;
  final SkyMask skyMask;  // NEW: Sky detection result
  
  @override
  void paint(Canvas canvas, Size size) {
    // FLOOR CHECK: Hide particles when looking at ground
    if (pitchDegrees < -10) return;
    
    final glowPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0);
    
    final corePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;
    
    for (final p in particles) {
      // SKY MASK CHECK: Only render if this point is in sky
      if (!skyMask.isPointInSky(p.x, p.y)) {
        continue;  // Skip particles over buildings/ground
      }
      
      double baseOpacity = sin(p.age * pi).clamp(0.0, 1.0);
      
      double startX = p.x * size.width;
      double startY = p.y * size.height;
      double endX = startX - cos(windAngle) * p.trailLength;
      double endY = startY + sin(windAngle) * p.trailLength;
      
      final start = Offset(startX, startY);
      final end = Offset(endX, endY);
      
      // PASS 1: The glow
      glowPaint.color = color.withOpacity(baseOpacity * 0.3);
      canvas.drawLine(start, end, glowPaint);
      
      // PASS 2: The core
      corePaint.color = color.withOpacity(baseOpacity * 0.9);
      canvas.drawLine(start, end, corePaint);
    }
  }
}
```

### SkyMask Interface
```dart
abstract class SkyMask {
  /// Returns true if the normalized point (0-1, 0-1) is in the sky
  bool isPointInSky(double normalizedX, double normalizedY);
  
  /// Returns what fraction of the screen is sky (for debug display)
  double get skyFraction;
}

class PitchBasedSkyMask implements SkyMask {
  final double pitchDegrees;
  
  PitchBasedSkyMask(this.pitchDegrees);
  
  @override
  double get skyFraction {
    if (pitchDegrees < 10) return 0.0;
    if (pitchDegrees > 70) return 0.95;
    return ((pitchDegrees - 10) / 60).clamp(0.0, 0.95);
  }
  
  @override
  bool isPointInSky(double normalizedX, double normalizedY) {
    return normalizedY < skyFraction;
  }
}
```

### Core Algorithm
The particle system uses the "%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%.%stream" technique used by earth.nullschool.net:

1. Maintain pool of N particles (start with N=2000)
2. Each frame:
   - Move each particle based on wind vector
   - Age each particle
   - If particle is off-screen OR too old → reset to random position
3. Draw each particle as a short line (trail) in direction of movement
4. Fade opacity based on age (fade in at birth, fade out at death)

### Movement Calculation
```dart
void updateParticle(Particle p, WindData wind, double dt, double compassHeading) {
  // Convert wind vector to screen-space movement
  // Account for compass heading so wind appears world-fixed
  
  double windAngle = wind.directionRadians;
  double adjustedAngle = windAngle - (compassHeading * pi / 180);
  
  // Speed scaling: m/s → screen fraction per second
  double speedFactor = wind.speed * 0.002 * currentAltitude.particleSpeedMultiplier;
  
  // Update position
  p.x += cos(adjustedAngle) * speedFactor * dt;
  p.y -= sin(adjustedAngle) * speedFactor * dt; // screen Y is inverted
  
  // Age particle
  p.age += dt * 0.3; // particles live ~3 seconds
  
  // Calculate trail length based on speed
  p.trailLength = wind.speed * 0.5; // pixels
}
```

### Rendering (CustomPainter)

#### The "Poor Man's Glow" Technique
Standard single-stroke lines look flat and boring. To get the glowing/cyberpunk/neon look, draw every particle TWICE:

1. **The Glow (first pass):** Thick line (width 4.0), low opacity (0.3)
2. **The Core (second pass):** Thin line (width 1.5), high opacity (1.0)

Result: Particles look like neon lights or lightsabers, not flat wireframes. Small performance cost, massive visual upgrade.

```dart
class ParticleOverlayPainter extends CustomPainter {
  final List<Particle> particles;
  final Color color;
  final double windAngle;
  final double pitchDegrees; // Phone tilt: negative = looking down
  
  @override
  void paint(Canvas canvas, Size size) {
    // FLOOR CHECK: Hide particles when looking at ground
    // This makes it feel like "real AR" not just a screen sticker
    if (pitchDegrees < -10) return; // Looking down, draw nothing
    
    final glowPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0); // Extra soft glow
    
    final corePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;
    
    for (final p in particles) {
      // Calculate opacity based on age (bell curve: fade in, fade out)
      double baseOpacity = sin(p.age * pi).clamp(0.0, 1.0);
      
      // Calculate trail endpoint
      double startX = p.x * size.width;
      double startY = p.y * size.height;
      double endX = startX - cos(windAngle) * p.trailLength;
      double endY = startY + sin(windAngle) * p.trailLength;
      
      final start = Offset(startX, startY);
      final end = Offset(endX, endY);
      
      // PASS 1: The glow (thick, transparent)
      glowPaint.color = color.withOpacity(baseOpacity * 0.3);
      canvas.drawLine(start, end, glowPaint);
      
      // PASS 2: The core (thin, bright)
      corePaint.color = color.withOpacity(baseOpacity * 0.9);
      canvas.drawLine(start, end, corePaint);
    }
  }
}
```

### Performance Targets
| Metric | Target | Fallback |
|--------|--------|----------|
| Particle count | 2000 | Auto-reduce to 1000 if <45fps |
| Frame rate | 60 fps | Acceptable at 30fps |
| Trail segments | 1 (simple line) | Could add more for smoothness |

### Adaptive Performance System
The particle count should be DYNAMIC, not fixed. Older phones (especially Android) may struggle with 2000 particles calculated in Dart.

```dart
// In wind_state.dart or a dedicated performance_manager.dart

class PerformanceManager {
  int _particleCount = 2000;  // Start optimistic
  final List<double> _recentFps = [];
  static const int _fpsWindowSize = 30;  // Average over 30 frames
  
  int get particleCount => _particleCount;
  
  void recordFrame(Duration frameDuration) {
    double fps = 1000 / frameDuration.inMilliseconds.clamp(1, 1000);
    _recentFps.add(fps);
    
    if (_recentFps.length > _fpsWindowSize) {
      _recentFps.removeAt(0);
    }
    
    // Only adjust after we have enough samples
    if (_recentFps.length == _fpsWindowSize) {
      double avgFps = _recentFps.reduce((a, b) => a + b) / _fpsWindowSize;
      _adjustParticleCount(avgFps);
    }
  }
  
  void _adjustParticleCount(double avgFps) {
    if (avgFps < 45 && _particleCount > 500) {
      // Performance struggling, reduce particles
      _particleCount = (_particleCount * 0.7).round().clamp(500, 3000);
      _recentFps.clear();  // Reset window after adjustment
    } else if (avgFps > 58 && _particleCount < 2000) {
      // Room for more particles, slowly increase
      _particleCount = (_particleCount * 1.1).round().clamp(500, 3000);
      _recentFps.clear();
    }
  }
}
```

**Philosophy:** Better to have 800 smooth particles than 2000 choppy ones. The user won't count particles, but they WILL notice stuttering.

---

## 10. UI Layout Specification

### Main Screen Composition
```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│         [CAMERA FEED]               │
│    with particle overlay on top     │
│                                     │
│                                     │
│                             ┌─────┐ │
│                             │ JET │ │
│                             │     │ │
│                             │ MID │ │  ← Altitude Slider
│                             │     │ │
│                             │ SFC │ │
│                             └─────┘ │
│                                     │
│  ┌──────────────────────────────┐   │
│  │ 🧭 N    Wind: 12 m/s NW      │   │  ← Info Bar
│  │        Alt: Jet Stream       │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
```

### Altitude Slider
- Position: Right edge, vertically centered
- Width: 60px
- Height: 200px
- Style: Glassmorphism (frosted glass effect)
- Interaction: Tap segment OR drag
- Haptic: Light impact on level change

### Info Bar
- Position: Bottom, above safe area
- Style: Frosted glass, rounded corners
- Content:
  - Compass direction indicator (small)
  - Wind speed in m/s (large text)
  - Wind cardinal direction (NW, SSE, etc.)
  - Current altitude level name

### Debug Panel (Dev Only)
- Toggle with 3-finger tap
- Shows:
  - Raw compass heading (degrees)
  - Raw u/v components
  - Particle count
  - FPS counter
  - Device orientation

---

## 11. Compass Integration

### Data Flow
```
Magnetometer (sensors_plus)          Accelerometer (sensors_plus)
    ↓                                     ↓
Raw heading (degrees from north)     Raw pitch (phone tilt)
    ↓                                     ↓
Smoothing filter (low-pass)          Smoothing filter
    ↓                                     ↓
compassHeading state                 pitchDegrees state
    ↓                                     ↓
    └──────────────┬──────────────────────┘
                   ↓
           Particle system
    (adjusts render angle + floor check)
```

### Smoothing Algorithm
```dart
class CompassService {
  double _smoothedHeading = 0;
  double _smoothedPitch = 0;
  static const double _smoothingFactor = 0.1; // Lower = smoother, more lag
  
  // DEAD ZONE: Ignore tiny movements to prevent "vibrating" particles
  static const double _headingDeadZone = 1.0;  // degrees
  static const double _pitchDeadZone = 2.0;    // degrees
  
  // Call this with magnetometer data
  void onMagnetometerEvent(MagnetometerEvent event) {
    double rawHeading = atan2(event.y, event.x) * 180 / pi;
    rawHeading = (rawHeading + 360) % 360;
    
    // Handle wraparound (359° → 1°)
    double delta = rawHeading - _smoothedHeading;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    
    // DEAD ZONE: If change is tiny, ignore it completely
    // This stops the wind from "vibrating" when you hold the phone still
    if (delta.abs() < _headingDeadZone) {
      return; // No update — hand tremor, not intentional movement
    }
    
    _smoothedHeading = (_smoothedHeading + delta * _smoothingFactor + 360) % 360;
  }
  
  // Call this with accelerometer data for pitch (floor check)
  void onAccelerometerEvent(AccelerometerEvent event) {
    // Calculate pitch: how much phone is tilted up/down
    // Negative = pointing down, Positive = pointing up
    double rawPitch = atan2(-event.z, event.y) * 180 / pi;
    
    double delta = rawPitch - _smoothedPitch;
    
    // DEAD ZONE for pitch too
    if (delta.abs() < _pitchDeadZone) {
      return;
    }
    
    _smoothedPitch += delta * _smoothingFactor;
  }
  
  double get heading => _smoothedHeading;
  double get pitch => _smoothedPitch;  // Used for floor check
}
```

> 💡 **Why Dead Zones Matter**
> 
> Raw magnetometer data is incredibly jittery. Even holding your phone "still," 
> you'll see readings fluctuate ±0.5° constantly due to:
> - Hand tremor
> - Electrical interference
> - Sensor noise
> 
> Without a dead zone, your particles will "vibrate" nervously. With a 1° dead zone,
> the particles only move when you intentionally rotate. Much more polished feel.

### Tuning Guide
| Symptom | Fix |
|---------|-----|
| Particles vibrate when holding still | Increase `_headingDeadZone` to 1.5° or 2° |
| Rotation feels laggy/delayed | Decrease `_smoothingFactor` to 0.15 or 0.2 |
| Rotation feels too sensitive | Increase `_smoothingFactor` to 0.05 |
| Floor check flickers on/off | Increase `_pitchDeadZone` to 3° or 5° |

### Floor Check Behavior
| Pitch Angle | User Posture | Particle Visibility |
|-------------|--------------|---------------------|
| > 10° | Looking up at sky | Full visibility |
| -10° to 10° | Phone roughly level | Full visibility |
| < -10° | Looking at ground | Particles hidden |

This simple check makes the app feel like "real AR" rather than a 2D sticker on the screen. Wind should only appear when you're looking at the sky.

> ⚠️ **IMPLEMENTATION GOTCHA — Read This First**
> 
> The pitch calculation can flip sign depending on Portrait vs Landscape orientation, and varies by device. **Do not assume the math above is correct for your setup.**
> 
> Before finalizing floor check logic:
> ```dart
> // In compass_service.dart, temporarily add:
> void onAccelerometerEvent(AccelerometerEvent event) {
>   double rawPitch = atan2(-event.z, event.y) * 180 / pi;
>   print('📐 Pitch: $rawPitch'); // REMOVE AFTER TESTING
>   // ...
> }
> ```
> Then physically test:
> 1. Point phone at ceiling → note the pitch value (should be positive?)
> 2. Point phone at floor → note the pitch value (should be negative?)
> 3. Adjust the `< -10` threshold accordingly
> 
> This takes 60 seconds and prevents an hour of "why is this backwards" debugging.

### Expected Behavior
When user rotates phone clockwise (turning right):
- Compass heading increases (0° → 90° → 180°...)
- Particles should appear to stay fixed in world space
- i.e., particles flow "left" across screen as user turns right

---

## 12. Development Environment & Device Testing

### Required Setup (Mac → iPhone)

#### One-Time Setup
1. **Install Xcode** from Mac App Store (required even for Flutter iOS builds)
2. **Install Flutter SDK** — follow flutter.dev instructions
3. **Apple Developer Account** — Free tier works for personal device testing
4. **Configure Xcode:**
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```

#### Per-Project Setup
```bash
# After creating the Flutter project
cd wind_lens
flutter pub get
cd ios
pod install      # Install iOS dependencies
cd ..
```

#### Running on Your iPhone
1. Connect iPhone via USB cable
2. On iPhone: Settings → Privacy & Security → Developer Mode → ON (restart required)
3. Trust your Mac: When prompted on iPhone, tap "Trust"
4. In terminal:
   ```bash
   flutter devices                    # Should show your iPhone
   flutter run -d <your-iphone-id>    # Run on device
   ```
5. First run: Xcode will prompt to sign the app. Select your Apple ID under "Team"
6. On iPhone: Settings → General → VPN & Device Management → Trust your developer certificate

#### Why You MUST Test on Real Device
| Feature | iOS Simulator | Real iPhone |
|---------|---------------|-------------|
| Camera | ❌ No | ✅ Yes |
| Compass/Magnetometer | ❌ No | ✅ Yes |
| Accelerometer | ⚠️ Fake data | ✅ Yes |
| AR Performance | ❌ N/A | ✅ Realistic |
| GPU Particle Performance | ⚠️ Different | ✅ Accurate |

**Bottom line:** You can build UI in the simulator, but ALL sensor/camera work must be tested on device.

#### Hot Reload Workflow
Once running on device:
- Press `r` in terminal → Hot reload (keeps state, updates UI)
- Press `R` in terminal → Hot restart (resets state)
- Press `q` to quit

### Simultaneous iOS + Android Support
The Flutter project structure already supports both platforms. To test Android:
1. Enable Developer Options on Android device
2. Enable USB Debugging
3. Connect via USB
4. `flutter run -d <android-device-id>`

No code changes needed—Flutter handles platform differences in the packages we're using (`camera`, `sensors_plus`).

---

## 13. Platform Configuration

### iOS (ios/Runner/Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>Wind Lens needs camera access to show AR wind overlay</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Wind Lens needs your location to show local wind conditions</string>

<key>NSMotionUsageDescription</key>
<string>Wind Lens uses motion sensors for compass orientation</string>

<key>UIRequiredDeviceCapabilities</key>
<array>
  <string>magnetometer</string>
  <string>accelerometer</string>
  <string>gyroscope</string>
</array>
```

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<uses-feature android:name="android.hardware.camera" android:required="true" />
<uses-feature android:name="android.hardware.sensor.compass" android:required="true" />
```

---

## 14. Implementation Order

> 🔴 **CRITICAL: Follow This Order Exactly**
> 
> The #1 cause of wasted time: Building on broken foundations.
> Each step must be VERIFIED before proceeding.

### Implementation Philosophy: Verify Before Proceeding

For EVERY component, follow this pattern:
1. **Implement** the minimal version
2. **Add logging** to verify it works
3. **Run on device** and check logs
4. **Only proceed** when logs confirm success

Example checkpoints:
```
✓ Camera: "Camera initialized, resolution: 1920x1080"
✓ Compass: "Heading: 127.3°, Pitch: 12.5°"
✓ Sky Detection: "Sky fraction: 65.2%"
✓ Particles: "Rendering 2000 particles at 58 FPS"
✓ Sky Mask: "Particles rendered: 1342 of 2000 (sky only)"
```

**If a checkpoint doesn't print what you expect, STOP and fix it.**

---

### PHASE 1: Foundation (Do NOT skip)

#### Step 1: Project Setup (30 min)
- [ ] Create Flutter project: `flutter create wind_lens`
- [ ] Add dependencies to pubspec.yaml
- [ ] Create folder structure
- [ ] Set up basic MaterialApp with dark theme
- [ ] **VERIFY:** App runs on device without crash

#### Step 2: Camera Feed (1 hour)
- [ ] Implement camera_view.dart
- [ ] Request camera permissions
- [ ] Display fullscreen camera preview
- [ ] **VERIFY on device:** "Camera initialized, resolution: X×Y"
- [ ] **MUST use real device** — simulator has no camera

#### Step 3: Compass + Pitch (1 hour)
- [ ] Implement compass_service.dart with smoothing
- [ ] Add pitch detection for sky/ground orientation
- [ ] Add dead zones to prevent jitter
- [ ] **VERIFY:** Logs show "Heading: X°, Pitch: Y°" updating smoothly
- [ ] **VERIFY:** Pitch positive when pointing up, negative when pointing down

---

### PHASE 2: Sky Detection (CRITICAL — Don't Skip)

#### Step 4: Simple Sky Mask (1 hour)
- [ ] Implement PitchBasedSkyMask (Level 1)
- [ ] Create SkyMaskDebugPainter to visualize mask
- [ ] Wire to camera view as overlay
- [ ] **VERIFY:** Red overlay shows ONLY where sky should be
- [ ] **VERIFY:** Point at ground → 0% sky, Point at sky → 60%+ sky

#### Step 4b: Auto-Calibrating Sky Detection (RECOMMENDED — 2 hours)
> No manual HSV tuning! App learns from current sky conditions.

- [ ] Implement AutoCalibratingSkyDetector
- [ ] Implement HSVHistogram with percentile-based ranges
- [ ] Add "Calibrate" button to UI
- [ ] **VERIFY:** Point at sky, tap calibrate, see learned ranges in logs
- [ ] **VERIFY on cloudy day:** Auto-calibrates to gray tones
- [ ] **VERIFY on clear day:** Auto-calibrates to blue tones
- [ ] Test auto-recalibration after 5 minutes

#### Step 4c: Add Optimized Uniformity Check (RECOMMENDED — 1.5 hours)
> O(1) variance using integral images — 160,000x faster than naive

- [ ] Implement OptimizedUniformityDetector with integral images
- [ ] Process at 128×96 resolution (downscaled)
- [ ] Combine with color detector in ProductionSkyDetector
- [ ] **VERIFY:** Buildings/glass excluded from mask
- [ ] **VERIFY:** Performance: processFrame() < 16ms (60 FPS capable)

**STOP HERE if sky detection doesn't work. Do not proceed to particles.**

---

### PHASE 3: Particles (Only After Sky Detection Works)

#### Step 5: Static Particles in Sky Only (1 hour)
- [ ] Create Particle model
- [ ] Create basic ParticleOverlayPainter
- [ ] Wire sky mask to painter (skip particles outside sky)
- [ ] Render 500 static random particles
- [ ] **VERIFY:** Particles appear ONLY in sky region (not over buildings/ground)

#### Step 6: Animated Particles (1.5 hours)
- [ ] Add animation loop (Ticker)
- [ ] Implement particle movement with fixed wind angle
- [ ] Implement age/fade lifecycle
- [ ] Reset particles when off-screen or too old
- [ ] **VERIFY:** "Rendering 2000 particles at 60 FPS"
- [ ] **VERIFY:** Particles flow smoothly within sky region only

#### Step 7: Glow Effect (30 min)
- [ ] Implement 2-pass rendering (glow + core)
- [ ] Add MaskFilter.blur for soft glow
- [ ] **VERIFY:** Particles look like neon lights, not flat lines

---

### PHASE 4: Wind Data + Polish

#### Step 8: Fake Wind Service (30 min)
- [ ] Create FakeWindService with 3 altitude levels
- [ ] Wire to particle system
- [ ] **VERIFY:** Particles move based on u/v components

#### Step 9: Spatial Depth Effects (1 hour)
- [ ] Add parallax (higher altitude = less motion when turning)
- [ ] Add scale variation (higher = smaller particles)
- [ ] **VERIFY:** Surface winds feel "close," jet streams feel "far"

#### Step 10: Altitude Slider (1 hour)
- [ ] Create AltitudeSlider widget
- [ ] Wire to state
- [ ] Change particle color by altitude
- [ ] Change particle speed by altitude
- [ ] **VERIFY:** Slider changes visual appearance clearly

#### Step 11: Compass Integration (1 hour)
- [ ] Wire compass heading to particle angle calculation
- [ ] **VERIFY:** Rotate phone → particles stay world-fixed

#### Step 12: Polish (1 hour)
- [ ] Info bar with wind stats
- [ ] Glassmorphism styling
- [ ] Haptic feedback
- [ ] Debug panel toggle

---

### PHASE 5: Optional Upgrades

#### Step 13: Grid Interpolation / Spatial Variation (1.5 hours)
> Makes particles vary across screen (organic swirls)

- [ ] Upgrade FakeWindService to 3×3 grid
- [ ] Implement bilinear interpolation (NO object allocation in render loop!)
- [ ] **VERIFY:** Particles on left vs right flow slightly differently

#### Step 14: Real Data Integration (2+ hours)
> ⚠️ Don't let this block you. Skip if problematic.

- [ ] Run discovery.dart on EDR API
- [ ] **PREREQUISITE:** Confirm CRS is CRS84 (not EPSG:3857)
- [ ] Implement EdrWindService
- [ ] **VERIFY:** Falls back to fake data on error

#### Step 15: ML Sky Segmentation (HIGH COMPLEXITY — 4+ hours)
> Only if Level 1/2 sky detection isn't sufficient

- [ ] See Section 3b for detailed steps
- [ ] Follow verification-first approach EXACTLY
- [ ] **If stuck for >2 hours, revert to Level 1/2**

---

### Checkpoint Summary

| Phase | Checkpoint | What to Verify |
|-------|------------|----------------|
| 1 | Camera | Logs show resolution |
| 1 | Compass | Heading/pitch update smoothly |
| 2 | Sky Mask | Red overlay = sky only |
| 3 | Particles | Appear in sky region ONLY |
| 3 | Animation | 60 FPS, smooth flow |
| 4 | Wind | Particles react to u/v |
| 4 | Altitude | Visual changes with slider |
| 4 | Compass | Particles world-fixed |

---

## 15. Testing Checklist

### Phase 1: Foundation Tests
- [ ] Camera preview fills screen
- [ ] Camera works in portrait AND landscape
- [ ] Compass heading updates smoothly (no jitter)
- [ ] Pitch detection: positive when up, negative when down
- [ ] Dead zones prevent micro-jitter

### Phase 2: Sky Detection Tests
- [ ] **Level 1 (Pitch):** Point up → sky fraction > 50%
- [ ] **Level 1 (Pitch):** Point down → sky fraction ~0%
- [ ] **Auto-calibration:** Tap calibrate while pointing at sky → logs show learned HSV ranges
- [ ] **Clear sky calibration:** Learned hue ~200-230° (blue)
- [ ] **Cloudy sky calibration:** Learned saturation < 20% (gray)
- [ ] **Sunset calibration:** Learned hue ~0-40° or 300-360° (orange/pink)
- [ ] **Auto-recalibration:** After 5 min, recalibrates automatically when pointing up
- [ ] **Uniformity check:** Buildings excluded (high variance)
- [ ] **Uniformity check:** Sky included (low variance)
- [ ] **Performance:** processFrame() < 16ms (logs show timing)
- [ ] Debug overlay shows mask correctly

### Phase 3: Particle Tests
- [ ] Particles render ONLY in sky region
- [ ] Particles do NOT appear over ground/buildings
- [ ] Particles have glow effect
- [ ] Animation is smooth (60 FPS)
- [ ] Particles reset when leaving sky region

### Phase 4: Wind + Spatial Tests
- [ ] Altitude slider changes particle color
- [ ] Altitude slider changes particle speed/size
- [ ] **Parallax test:** Rotate phone → surface winds move more than jet stream
- [ ] **Spatial depth:** Higher altitudes feel "further away"
- [ ] Compass: Particles stay world-fixed when rotating

### Phase 5: Integration Tests
- [ ] Real data (if enabled): Falls back on error
- [ ] Real data (if enabled): Caches responses
- [ ] App handles permission denial gracefully
- [ ] App works in bright sunlight
- [ ] App works in low light

### Edge Case Tests
- [ ] Compass uncalibrated → Show warning
- [ ] Camera permission denied → Show placeholder
- [ ] Pointing straight up → Sky fraction ~95%
- [ ] Pointing straight down → Sky fraction 0%

### Performance Tests
- [ ] 2000 particles at 60 FPS
- [ ] Auto-reduce particles if FPS drops
- [ ] No visible stutter when changing altitude
- [ ] No memory leaks over 5+ minutes of use

---

## 16. Future Enhancements (Post-MVP)

These are OUT OF SCOPE for MVP but documented for future:

1. **Server-Side Compute Offload (See Section 15b)**
   - Move heavy calculations to server
   - Phone just renders pre-computed data
   - Better for older devices

2. **EDR Grid Queries**
   - Use `/area` endpoint instead of multiple `/position` calls
   - More efficient for spatial interpolation

3. **Advanced Particle Rendering**
   - Fragment shaders for glow effect
   - Variable particle density by pressure
   - Curved trails (Bézier)

4. **Additional Data Layers**
   - Temperature gradient coloring
   - Precipitation probability overlay
   - Turbulence (EDR) warnings
   - Cloud layer visualization

5. **UX Enhancements**
   - Pinch-to-zoom altitude range
   - Historical playback
   - Location favorites
   - Smooth altitude transitions

6. **Phase C: Cone Projection**
   - Calculate exact viewport frustum from phone orientation
   - Factor in terrain (mountains block low-altitude view)
   - GPU flow field texture
   - Per-pixel accurate wind sampling

---

## 16b. Server Offload Architecture (OPTIONAL)

> 💡 **When to Consider This**
> 
> If the phone struggles with bilinear interpolation + sky detection + particle rendering,
> offloading compute to a server can help. This is also useful if you want more complex
> calculations (cone projection, terrain awareness) without killing battery.

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                              SERVER                                  │
│  ┌─────────────┐    ┌──────────────────┐    ┌───────────────────┐  │
│  │ Wind Data   │───▶│ Grid Interpolation│───▶│ Particle Positions │  │
│  │ (EDR API)   │    │ (Bilinear)        │    │ (Pre-computed)     │  │
│  └─────────────┘    └──────────────────┘    └─────────┬─────────┘  │
│                                                         │            │
│                                              WebSocket Stream        │
└─────────────────────────────────────────────────────────┼────────────┘
                                                          │
                                                          ▼
┌─────────────────────────────────────────────────────────────────────┐
│                              PHONE                                   │
│  ┌─────────────┐    ┌──────────────────┐    ┌───────────────────┐  │
│  │ Camera +    │───▶│ Sky Detection    │───▶│ Render Particles  │  │
│  │ Sensors     │    │ (Mask)           │    │ (from server data)│  │
│  └─────────────┘    └──────────────────┘    └───────────────────┘  │
│         │                                                            │
│         └──────── Send: GPS, Compass Heading, Altitude Level ────▶  │
└─────────────────────────────────────────────────────────────────────┘
```

### What Server Does
- Fetches wind data from EDR API
- Performs grid interpolation for spatial variation
- Computes particle positions for the user's location/heading
- Streams particle data to phone via WebSocket

### What Phone Does
- Camera feed + sky detection
- Reads compass/gyro for heading
- Sends location + heading to server
- Receives pre-computed wind vectors
- Renders particles (simple: just draw at positions given)

### Protocol Design
```typescript
// Phone → Server (every ~100ms)
interface ClientState {
  latitude: number;
  longitude: number;
  compassHeading: number;   // degrees
  pitchDegrees: number;     // for server to know viewport
  altitudeLevel: 'surface' | 'midLevel' | 'jetStream';
  viewportWidth: number;    // pixels
  viewportHeight: number;
}

// Server → Phone (every ~50ms)
interface WindFrame {
  timestamp: number;
  particles: Array<{
    x: number;           // 0-1 normalized screen position
    y: number;           // 0-1 normalized screen position
    angle: number;       // radians, wind direction
    speed: number;       // m/s, for trail length
    age: number;         // 0-1, for opacity
  }>;
  metadata: {
    windSpeed: number;   // average for display
    windDirection: number;
  };
}
```

### Server Implementation (Node.js Example)
```javascript
const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 8080 });

// Particle pool (managed server-side)
const particles = Array.from({ length: 2000 }, () => ({
  x: Math.random(),
  y: Math.random(),
  age: Math.random(),
}));

wss.on('connection', (ws) => {
  let clientState = null;
  
  ws.on('message', (data) => {
    clientState = JSON.parse(data);
  });
  
  // Send wind frames at 20fps
  const interval = setInterval(() => {
    if (!clientState) return;
    
    // Fetch/interpolate wind for client's location
    const wind = getInterpolatedWind(
      clientState.latitude,
      clientState.longitude,
      clientState.altitudeLevel
    );
    
    // Update particles
    updateParticles(particles, wind, clientState.compassHeading);
    
    // Send frame
    ws.send(JSON.stringify({
      timestamp: Date.now(),
      particles: particles.map(p => ({
        x: p.x,
        y: p.y,
        angle: wind.angle - clientState.compassHeading * Math.PI / 180,
        speed: wind.speed,
        age: p.age,
      })),
      metadata: {
        windSpeed: wind.speed,
        windDirection: wind.directionDegrees,
      },
    }));
  }, 50);
  
  ws.on('close', () => clearInterval(interval));
});
```

### Phone Rendering (Simplified)
```dart
class ServerDrivenParticleOverlay extends CustomPainter {
  final WindFrame frame;
  final SkyMask skyMask;
  final Color color;
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in frame.particles) {
      // Skip if not in sky
      if (!skyMask.isPointInSky(p.x, p.y)) continue;
      
      final opacity = sin(p.age * pi).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = color.withOpacity(opacity * 0.8)
        ..strokeWidth = 1.5;
      
      final start = Offset(p.x * size.width, p.y * size.height);
      final trailLength = p.speed * 0.5;
      final end = Offset(
        start.dx - cos(p.angle) * trailLength,
        start.dy + sin(p.angle) * trailLength,
      );
      
      canvas.drawLine(start, end, paint);
    }
  }
}
```

### When to Use Server Offload
| Scenario | Recommendation |
|----------|----------------|
| Demo/prototype | On-device (simpler) |
| Older phones struggling | Server offload |
| Complex spatial calculations | Server offload |
| Offline requirement | On-device only |
| Multi-user shared view | Server (can sync views) |

---

## 17. Reference Materials

### Inspiration
- earth.nullschool.net — The gold standard for wind visualization
- Windy.com — Mobile-friendly wind maps
- Ventusky — Clean altitude layer switching

### Technical References
- [Wind Vector Components Explained](https://www.weather.gov/media/ajk/brochures/WindDirection.pdf)
- [Atmospheric Pressure Levels](https://en.wikipedia.org/wiki/Pressure_altitude)
- [Flutter CustomPainter Docs](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)

### Meteorological Conventions
- Wind direction: The direction wind is coming FROM (North wind blows southward)
- u-component: Positive = eastward (wind blowing toward east)
- v-component: Positive = northward (wind blowing toward north)
- Pressure levels: Lower hPa = higher altitude (250 hPa ≈ 34,000 ft)

---

## Appendix: Quick Reference Card

```
CRITICAL IMPLEMENTATION ORDER
─────────────────────────────
1. Camera working ✓
2. Compass + Pitch working ✓
3. SKY DETECTION working ✓  ← DON'T SKIP!
4. Particles IN SKY ONLY ✓
5. Animated particles ✓
6. Wind data + altitude ✓
7. Polish ✓
─────────────────────────────
OPTIONAL: ML sky detection, Real API, Server offload

SKY DETECTION LEVELS
────────────────────
Level 1:  Pitch-based       → Simple, start here
Level 2a: Auto-calibrating  → RECOMMENDED — learns from current sky
Level 2b: + Integral images → O(1) uniformity check, 160,000x faster
Level 3:  ML (TFLite)       → Best accuracy, but complex

AUTO-CALIBRATION (Level 2a)
───────────────────────────
• Point phone up (pitch > 45°)
• App samples top 10-40% of frame
• Builds HSV histogram (percentile-based)
• Uses Gaussian scoring for soft matching
• Auto-recalibrates every 5 minutes

INTEGRAL IMAGE OPTIMIZATION (Level 2b)
──────────────────────────────────────
• Downscale to 128×96 (once per frame)
• Build integral sum + sumSq images
• O(1) variance lookup for any region
• 160,000x faster than naive per-pixel check

ALTITUDE LEVELS
───────────────
Surface    →  10m      →  White   →  ~5 m/s    → 1000 hPa  → parallax: 1.0
Mid-level  →  1,500m   →  Cyan    →  ~10 m/s   → 850 hPa   → parallax: 0.6
Jet Stream →  10,500m  →  Purple  →  ~50 m/s   → 250 hPa   → parallax: 0.3

SPATIAL DEPTH (Makes It Feel Real)
──────────────────────────────────
Higher altitude = smaller particles
Higher altitude = less parallax motion
Higher altitude = slower apparent speed
Higher altitude = fewer particles (spread out)

EDR API ENDPOINTS (Joe's servers) — OPTIONAL
────────────────────────────────────────────
Primary:  https://ogc.shyftwx.com/ogc/edr
Backup:   https://folkweather.com/edr

⚠️  Run discovery.dart FIRST to check CRS

WIND MATH
─────────
Speed = √(u² + v²)
Direction = atan2(-u, -v)  // meteorological convention
Screen angle = wind_direction - compass_heading

PARTICLE RENDERING
──────────────────
1. Check sky mask: if (!skyMask.isPointInSky(x, y)) skip
2. Pass 1: Glow (width=4.0, opacity=0.3, blur)
3. Pass 2: Core (width=1.5, opacity=0.9)

COMPASS TUNING
──────────────
Smoothing factor: 0.1
Heading dead zone: 1.0°
Pitch dead zone: 2.0°

KEY NUMBERS
───────────
Particles: 2000 target, reduce if <45 FPS
Lifespan: ~3 seconds
Floor check: pitch < -10°
API cache: 5 minutes
Sky recalibration: every 5 minutes
Uniformity process size: 128×96

VERIFICATION CHECKPOINTS
────────────────────────
Camera: "resolution: 1920x1080"
Compass: "Heading: X°, Pitch: Y°"
Calibration: "Hue: 200-220°, Sat: 5-20%, Val: 60-90%"
Sky: "Sky fraction: 65%"
Performance: "processFrame: 12ms"
Particles: "2000 particles at 58 FPS"
Mask: "Rendered: 1342 of 2000 (sky only)"
```

---

*Last updated: January 2025*
*Version: MVP 1.0*
