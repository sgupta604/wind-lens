import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/models/hsv.dart';
import 'package:wind_lens/services/sky_detection/hsv_histogram.dart';

void main() {
  group('HSVHistogram', () {
    group('isSkyLikeColor', () {
      // Blue sky tests
      test('returns true for clear blue sky HSV', () {
        // Typical clear blue sky: hue ~210, moderate saturation, bright
        final blueSky = const HSV(210.0, 0.45, 0.85);
        expect(HSVHistogram.isSkyLikeColor(blueSky), isTrue);
      });

      test('returns true for deep blue sky HSV', () {
        // Deep blue sky: hue ~220, higher saturation, bright
        final deepBlueSky = const HSV(220.0, 0.60, 0.75);
        expect(HSVHistogram.isSkyLikeColor(deepBlueSky), isTrue);
      });

      test('returns true for light blue sky HSV', () {
        // Light blue sky near horizon: hue ~195, low saturation, very bright
        final lightBlueSky = const HSV(195.0, 0.20, 0.95);
        expect(HSVHistogram.isSkyLikeColor(lightBlueSky), isTrue);
      });

      test('returns true for sky at boundary hue 180', () {
        // Lower boundary of blue sky range
        final boundaryLow = const HSV(180.0, 0.40, 0.80);
        expect(HSVHistogram.isSkyLikeColor(boundaryLow), isTrue);
      });

      test('returns true for sky at boundary hue 250', () {
        // Upper boundary of blue sky range
        final boundaryHigh = const HSV(250.0, 0.40, 0.80);
        expect(HSVHistogram.isSkyLikeColor(boundaryHigh), isTrue);
      });

      // Gray/overcast sky tests
      test('returns true for gray overcast sky HSV', () {
        // Overcast sky: low saturation, moderate-high brightness
        final overcastSky = const HSV(200.0, 0.05, 0.70);
        expect(HSVHistogram.isSkyLikeColor(overcastSky), isTrue);
      });

      test('returns true for white clouds HSV', () {
        // White clouds: very low saturation, very bright
        final whiteClouds = const HSV(0.0, 0.02, 0.95);
        expect(HSVHistogram.isSkyLikeColor(whiteClouds), isTrue);
      });

      test('returns true for light gray sky HSV', () {
        // Light gray overcast: low saturation, bright
        final lightGray = const HSV(180.0, 0.10, 0.60);
        expect(HSVHistogram.isSkyLikeColor(lightGray), isTrue);
      });

      // Brown/tan rejection tests (porch ceilings, wooden structures)
      test('returns false for brown/tan porch ceiling HSV', () {
        // Brown porch ceiling: hue ~30, moderate saturation, moderate brightness
        final brownPorch = const HSV(30.0, 0.50, 0.60);
        expect(HSVHistogram.isSkyLikeColor(brownPorch), isFalse);
      });

      test('returns false for tan wood HSV', () {
        // Tan wood: hue ~40, moderate saturation, moderate brightness
        final tanWood = const HSV(40.0, 0.45, 0.70);
        expect(HSVHistogram.isSkyLikeColor(tanWood), isFalse);
      });

      test('returns false for beige overhang HSV', () {
        // Beige overhang: hue ~35, low-moderate saturation, bright
        final beige = const HSV(35.0, 0.25, 0.85);
        expect(HSVHistogram.isSkyLikeColor(beige), isFalse);
      });

      // Green foliage rejection tests
      test('returns false for green foliage HSV', () {
        // Green leaves: hue ~120, high saturation, moderate brightness
        final greenLeaves = const HSV(120.0, 0.65, 0.60);
        expect(HSVHistogram.isSkyLikeColor(greenLeaves), isFalse);
      });

      test('returns false for dark green tree HSV', () {
        // Dark green tree: hue ~110, high saturation, lower brightness
        final darkGreen = const HSV(110.0, 0.70, 0.40);
        expect(HSVHistogram.isSkyLikeColor(darkGreen), isFalse);
      });

      test('returns false for light green foliage HSV', () {
        // Light green foliage: hue ~100, moderate saturation, bright
        final lightGreen = const HSV(100.0, 0.50, 0.75);
        expect(HSVHistogram.isSkyLikeColor(lightGreen), isFalse);
      });

      // Dark shadow rejection tests
      test('returns false for dark shadow HSV', () {
        // Dark shadow under overhang: any hue, low brightness
        final darkShadow = const HSV(200.0, 0.30, 0.20);
        expect(HSVHistogram.isSkyLikeColor(darkShadow), isFalse);
      });

      test('returns false for very dark area HSV', () {
        // Very dark area: brightness too low
        final veryDark = const HSV(210.0, 0.10, 0.15);
        expect(HSVHistogram.isSkyLikeColor(veryDark), isFalse);
      });

      test('returns false for black HSV', () {
        // Pure black: no brightness
        final black = const HSV(0.0, 0.0, 0.05);
        expect(HSVHistogram.isSkyLikeColor(black), isFalse);
      });

      // Saturated color rejection tests
      test('returns false for highly saturated blue HSV', () {
        // Over-saturated blue (not natural sky): too vivid
        final saturatedBlue = const HSV(210.0, 0.85, 0.90);
        expect(HSVHistogram.isSkyLikeColor(saturatedBlue), isFalse);
      });

      test('returns false for saturated red HSV', () {
        // Red brick or paint: wrong hue
        final red = const HSV(0.0, 0.80, 0.70);
        expect(HSVHistogram.isSkyLikeColor(red), isFalse);
      });

      test('returns false for saturated yellow HSV', () {
        // Yellow paint or material: wrong hue
        final yellow = const HSV(60.0, 0.75, 0.90);
        expect(HSVHistogram.isSkyLikeColor(yellow), isFalse);
      });

      // Edge case tests
      test('returns false for dark gray (shadow) HSV', () {
        // Dark gray that's too dark to be sky
        final darkGray = const HSV(0.0, 0.05, 0.25);
        expect(HSVHistogram.isSkyLikeColor(darkGray), isFalse);
      });

      test('returns true for borderline bright gray HSV', () {
        // Gray at the brightness threshold
        final borderlineGray = const HSV(0.0, 0.10, 0.35);
        expect(HSVHistogram.isSkyLikeColor(borderlineGray), isTrue);
      });

      test('returns false for purple/violet outside blue range HSV', () {
        // Purple outside the acceptable blue range
        final purple = const HSV(280.0, 0.50, 0.70);
        expect(HSVHistogram.isSkyLikeColor(purple), isFalse);
      });

      test('returns false for cyan-green at boundary HSV', () {
        // Cyan-green just outside blue range (hue < 180)
        final cyanGreen = const HSV(170.0, 0.50, 0.80);
        expect(HSVHistogram.isSkyLikeColor(cyanGreen), isFalse);
      });
    });

    group('fromSamples', () {
      test('creates histogram from uniform sky samples', () {
        // Uniform sky blue samples (typical clear sky)
        final samples = List.generate(
          100,
          (_) => const HSV(200.0, 0.4, 0.9),
        );

        final histogram = HSVHistogram.fromSamples(samples);

        expect(histogram.hueMean, closeTo(200.0, 1.0));
        expect(histogram.satMean, closeTo(0.4, 0.01));
        expect(histogram.valMean, closeTo(0.9, 0.01));
      });

      test('creates histogram with tight ranges for uniform samples', () {
        final samples = List.generate(
          100,
          (_) => const HSV(197.0, 0.43, 0.92),
        );

        final histogram = HSVHistogram.fromSamples(samples);

        // Tight ranges for uniform samples
        expect(histogram.hueMin, closeTo(197.0, 1.0));
        expect(histogram.hueMax, closeTo(197.0, 1.0));
        expect(histogram.satMin, closeTo(0.43, 0.01));
        expect(histogram.satMax, closeTo(0.43, 0.01));
      });

      test('creates histogram with appropriate spread for varied samples', () {
        // Sky samples with natural variation
        final samples = <HSV>[];
        for (int i = 0; i < 100; i++) {
          samples.add(HSV(190.0 + i * 0.2, 0.35 + i * 0.002, 0.85 + i * 0.001));
        }

        final histogram = HSVHistogram.fromSamples(samples);

        // Should have some spread
        expect(histogram.hueMax - histogram.hueMin, greaterThan(10.0));
        expect(histogram.satMax - histogram.satMin, greaterThan(0.1));
      });

      test('calculates percentiles excluding outliers', () {
        final samples = <HSV>[
          // Outlier low
          const HSV(100.0, 0.1, 0.3),
          // Normal sky samples
          ...List.generate(98, (_) => const HSV(200.0, 0.4, 0.9)),
          // Outlier high
          const HSV(300.0, 0.9, 1.0),
        ];

        final histogram = HSVHistogram.fromSamples(samples);

        // 5th and 95th percentiles should exclude extreme outliers
        expect(histogram.hueMin, greaterThan(100.0));
        expect(histogram.hueMax, lessThan(300.0));
      });

      test('handles single sample', () {
        final samples = [const HSV(200.0, 0.5, 0.8)];

        final histogram = HSVHistogram.fromSamples(samples);

        expect(histogram.hueMean, closeTo(200.0, 0.1));
        expect(histogram.satMean, closeTo(0.5, 0.01));
        expect(histogram.valMean, closeTo(0.8, 0.01));
      });

      test('handles many samples (1000+)', () {
        final samples = List.generate(
          1500,
          (i) => HSV(195.0 + (i % 10), 0.38 + (i % 10) * 0.01, 0.88 + (i % 10) * 0.01),
        );

        final histogram = HSVHistogram.fromSamples(samples);

        expect(histogram.hueMean, closeTo(199.5, 2.0));
        expect(histogram.satMean, closeTo(0.43, 0.02));
        expect(histogram.valMean, closeTo(0.93, 0.02));
      });

      test('computes standard deviation for h, s, v', () {
        final samples = <HSV>[
          const HSV(190.0, 0.35, 0.85),
          const HSV(200.0, 0.40, 0.90),
          const HSV(210.0, 0.45, 0.95),
        ];

        final histogram = HSVHistogram.fromSamples(samples);

        // Should have non-zero std dev for varied samples
        expect(histogram.hueStd, greaterThan(0.0));
        expect(histogram.satStd, greaterThan(0.0));
        expect(histogram.valStd, greaterThan(0.0));
      });

      test('computes zero standard deviation for identical samples', () {
        final samples = List.generate(
          50,
          (_) => const HSV(200.0, 0.4, 0.9),
        );

        final histogram = HSVHistogram.fromSamples(samples);

        expect(histogram.hueStd, closeTo(0.0, 0.001));
        expect(histogram.satStd, closeTo(0.0, 0.001));
        expect(histogram.valStd, closeTo(0.0, 0.001));
      });
    });

    group('matchScore', () {
      test('returns ~1.0 for exact mean match', () {
        final samples = List.generate(
          100,
          (_) => const HSV(200.0, 0.4, 0.9),
        );
        final histogram = HSVHistogram.fromSamples(samples);

        final score = histogram.matchScore(const HSV(200.0, 0.4, 0.9));

        expect(score, closeTo(1.0, 0.1));
      });

      test('returns 0.0 for completely out-of-range hue', () {
        final samples = List.generate(
          100,
          (_) => const HSV(200.0, 0.4, 0.9),
        );
        final histogram = HSVHistogram.fromSamples(samples);

        // Green is very far from sky blue (hue 200)
        final score = histogram.matchScore(const HSV(120.0, 0.4, 0.9));

        expect(score, lessThan(0.1));
      });

      test('returns 0.0 for completely out-of-range saturation', () {
        final samples = List.generate(
          100,
          (_) => const HSV(200.0, 0.4, 0.9),
        );
        final histogram = HSVHistogram.fromSamples(samples);

        // Very high saturation (pure color) vs low saturation sky
        final score = histogram.matchScore(const HSV(200.0, 1.0, 0.9));

        expect(score, lessThan(0.3));
      });

      test('returns 0.0 for completely out-of-range value', () {
        final samples = List.generate(
          100,
          (_) => const HSV(200.0, 0.4, 0.9),
        );
        final histogram = HSVHistogram.fromSamples(samples);

        // Very dark vs bright sky
        final score = histogram.matchScore(const HSV(200.0, 0.4, 0.1));

        expect(score, lessThan(0.1));
      });

      test('returns moderate score for close match', () {
        final samples = List.generate(
          100,
          (_) => const HSV(200.0, 0.4, 0.9),
        );
        final histogram = HSVHistogram.fromSamples(samples);

        // Slightly off from perfect match
        final score = histogram.matchScore(const HSV(195.0, 0.38, 0.88));

        expect(score, greaterThan(0.5));
        expect(score, lessThan(1.0));
      });

      test('score decreases as pixel diverges from mean', () {
        final samples = List.generate(
          100,
          (i) => HSV(195.0 + i * 0.1, 0.35 + i * 0.001, 0.88 + i * 0.001),
        );
        final histogram = HSVHistogram.fromSamples(samples);

        final scoreClose = histogram.matchScore(const HSV(200.0, 0.4, 0.9));
        final scoreFar = histogram.matchScore(const HSV(180.0, 0.5, 0.7));

        expect(scoreClose, greaterThan(scoreFar));
      });

      test('returns value in 0.0-1.0 range', () {
        final samples = List.generate(
          100,
          (i) => HSV(190.0 + i * 0.2, 0.3 + i * 0.003, 0.8 + i * 0.002),
        );
        final histogram = HSVHistogram.fromSamples(samples);

        // Test various pixels
        final testPixels = [
          const HSV(200.0, 0.4, 0.9),
          const HSV(0.0, 1.0, 1.0), // Red
          const HSV(120.0, 1.0, 1.0), // Green
          const HSV(0.0, 0.0, 0.0), // Black
          const HSV(0.0, 0.0, 1.0), // White
        ];

        for (final pixel in testPixels) {
          final score = histogram.matchScore(pixel);
          expect(score, greaterThanOrEqualTo(0.0));
          expect(score, lessThanOrEqualTo(1.0));
        }
      });

      test('handles histogram with low std dev gracefully', () {
        // Almost identical samples (very low std dev)
        final samples = List.generate(
          100,
          (_) => const HSV(200.0, 0.4, 0.9),
        );
        final histogram = HSVHistogram.fromSamples(samples);

        // Should not crash or return NaN/Infinity
        final score = histogram.matchScore(const HSV(200.0, 0.4, 0.9));
        expect(score.isFinite, true);
        expect(score, greaterThan(0.0));
      });
    });
  });
}
