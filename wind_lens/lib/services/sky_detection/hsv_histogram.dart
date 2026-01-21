import 'dart:math' as math;
import '../../models/hsv.dart';

/// Statistical profile of sky colors in HSV color space.
///
/// Built from sampled sky pixels during calibration, this histogram provides
/// statistical measures (mean, std dev, percentile ranges) for matching new
/// pixels against the learned sky color profile.
///
/// The matching algorithm uses a combination of:
/// 1. Hard boundary check (within percentile range)
/// 2. Gaussian-like scoring based on distance from mean
class HSVHistogram {
  /// Range and statistical values for Hue channel.
  final double hueMin;
  final double hueMax;
  final double hueMean;
  final double hueStd;

  /// Range and statistical values for Saturation channel.
  final double satMin;
  final double satMax;
  final double satMean;
  final double satStd;

  /// Range and statistical values for Value channel.
  final double valMin;
  final double valMax;
  final double valMean;
  final double valStd;

  /// Private constructor - use [fromSamples] factory.
  const HSVHistogram._({
    required this.hueMin,
    required this.hueMax,
    required this.hueMean,
    required this.hueStd,
    required this.satMin,
    required this.satMax,
    required this.satMean,
    required this.satStd,
    required this.valMin,
    required this.valMax,
    required this.valMean,
    required this.valStd,
  });

  /// Creates a histogram from a list of HSV color samples.
  ///
  /// Calculates:
  /// - 5th and 95th percentiles for each channel (robust to outliers)
  /// - Mean and standard deviation for Gaussian matching
  ///
  /// Requires at least one sample. For single samples, std dev is set to
  /// a small default value to prevent division by zero.
  factory HSVHistogram.fromSamples(List<HSV> samples) {
    if (samples.isEmpty) {
      throw ArgumentError('samples cannot be empty');
    }

    // Extract channel values
    final hues = samples.map((s) => s.h).toList()..sort();
    final sats = samples.map((s) => s.s).toList()..sort();
    final vals = samples.map((s) => s.v).toList()..sort();

    // Calculate percentiles (5th and 95th)
    final hueMin = _percentile(hues, 0.05);
    final hueMax = _percentile(hues, 0.95);
    final satMin = _percentile(sats, 0.05);
    final satMax = _percentile(sats, 0.95);
    final valMin = _percentile(vals, 0.05);
    final valMax = _percentile(vals, 0.95);

    // Calculate means
    final hueMean = _mean(hues);
    final satMean = _mean(sats);
    final valMean = _mean(vals);

    // Calculate standard deviations
    final hueStd = _stdDev(hues, hueMean);
    final satStd = _stdDev(sats, satMean);
    final valStd = _stdDev(vals, valMean);

    return HSVHistogram._(
      hueMin: hueMin,
      hueMax: hueMax,
      hueMean: hueMean,
      hueStd: hueStd,
      satMin: satMin,
      satMax: satMax,
      satMean: satMean,
      satStd: satStd,
      valMin: valMin,
      valMax: valMax,
      valMean: valMean,
      valStd: valStd,
    );
  }

  /// Calculates how well a pixel matches this sky color profile.
  ///
  /// Returns a score from 0.0 (no match) to 1.0 (perfect match).
  ///
  /// The scoring combines:
  /// 1. Hard boundary check - returns 0 if outside percentile ranges
  /// 2. Gaussian scoring - higher score for closer to mean
  double matchScore(HSV pixel) {
    // Hard boundary check using percentile ranges (with some tolerance)
    final hueTolerance = (hueMax - hueMin) * 0.5 + 10; // Extra tolerance for hue
    final satTolerance = (satMax - satMin) * 0.3 + 0.1;
    final valTolerance = (valMax - valMin) * 0.3 + 0.1;

    if (pixel.h < hueMin - hueTolerance || pixel.h > hueMax + hueTolerance) {
      return 0.0;
    }
    if (pixel.s < satMin - satTolerance || pixel.s > satMax + satTolerance) {
      return 0.0;
    }
    if (pixel.v < valMin - valTolerance || pixel.v > valMax + valTolerance) {
      return 0.0;
    }

    // Gaussian scoring for each channel
    final hueScore = _gaussianScore(pixel.h, hueMean, hueStd, 30.0); // Hue needs wider std
    final satScore = _gaussianScore(pixel.s, satMean, satStd, 0.15);
    final valScore = _gaussianScore(pixel.v, valMean, valStd, 0.15);

    // Combine scores (geometric mean gives balanced weighting)
    final combined = math.pow(hueScore * satScore * valScore, 1.0 / 3.0);

    return combined.toDouble().clamp(0.0, 1.0);
  }

  /// Calculates Gaussian-like score for how close value is to mean.
  static double _gaussianScore(double value, double mean, double std, double minStd) {
    // Use minimum std dev to prevent division by zero
    final effectiveStd = math.max(std, minStd);
    final diff = (value - mean).abs();

    // Gaussian scoring: exp(-(diff^2)/(2*std^2))
    return math.exp(-(diff * diff) / (2 * effectiveStd * effectiveStd));
  }

  /// Calculates percentile value from sorted list.
  static double _percentile(List<double> sorted, double p) {
    if (sorted.length == 1) return sorted[0];

    final index = (sorted.length - 1) * p;
    final lower = index.floor();
    final upper = index.ceil();

    if (lower == upper) return sorted[lower];

    // Linear interpolation
    final fraction = index - lower;
    return sorted[lower] * (1 - fraction) + sorted[upper] * fraction;
  }

  /// Calculates arithmetic mean.
  static double _mean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Calculates population standard deviation.
  static double _stdDev(List<double> values, double mean) {
    if (values.length <= 1) return 0.0;

    final sumSquaredDiff = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b);
    return math.sqrt(sumSquaredDiff / values.length);
  }

  @override
  String toString() {
    return 'HSVHistogram('
        'H: ${hueMin.toStringAsFixed(1)}-${hueMax.toStringAsFixed(1)} mean=${hueMean.toStringAsFixed(1)}, '
        'S: ${satMin.toStringAsFixed(2)}-${satMax.toStringAsFixed(2)} mean=${satMean.toStringAsFixed(2)}, '
        'V: ${valMin.toStringAsFixed(2)}-${valMax.toStringAsFixed(2)} mean=${valMean.toStringAsFixed(2)})';
  }
}
