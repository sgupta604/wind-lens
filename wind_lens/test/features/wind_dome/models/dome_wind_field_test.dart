import 'package:flutter_test/flutter_test.dart';

import 'package:wind_lens/features/wind_dome/models/dome_constants.dart';
import 'package:wind_lens/features/wind_dome/models/dome_wind_field.dart';
import 'package:wind_lens/features/wind_dome/models/dome_wind_layer.dart';

void main() {
  group('DomeWindField', () {
    late DomeWindField field;
    final now = DateTime.utc(2026, 2, 27, 12);

    setUp(() {
      field = DomeWindField(
        validTime: now,
        layers: [
          const DomeWindLayer(altitudeMeters: 10, u: 2.0, v: 3.0),
          const DomeWindLayer(altitudeMeters: 1500, u: 8.0, v: -1.0),
          const DomeWindLayer(altitudeMeters: 3000, u: 14.0, v: -5.0),
        ],
      );
    });

    group('sample()', () {
      test('returns bottom layer values when y=0', () {
        final wind = field.sample(0, 0, 0);
        expect(wind.u, closeTo(2.0, 0.01));
        expect(wind.v, closeTo(3.0, 0.01));
      });

      test('returns exact layer values when y matches surface altitude', () {
        // y=0 in render space maps to altitude ~0m, which clamps to 10m (bottom layer)
        final wind = field.sample(0, 0, 0);
        expect(wind.u, closeTo(2.0, 0.01));
        expect(wind.v, closeTo(3.0, 0.01));
      });

      test('returns top visible layer at y=DOME_H', () {
        // y=domeH (14.0) maps to maxAltitudeMeters (1800m)
        // At 1800m: between layer at 1500m (u=8, v=-1) and layer at 3000m (u=14, v=-5)
        // frac = (1800-1500)/(3000-1500) = 300/1500 = 0.2
        final wind = field.sample(0, DomeConstants.domeH, 0);
        final expectedU = 8.0 * 0.8 + 14.0 * 0.2; // 9.2
        final expectedV = -1.0 * 0.8 + -5.0 * 0.2; // -1.8
        expect(wind.u, closeTo(expectedU, 0.01));
        expect(wind.v, closeTo(expectedV, 0.01));
      });

      test('interpolates u/v linearly between two layers', () {
        // Mid-altitude: y that maps to 750m (between 10m and 1500m)
        // 750m => normalized = 750/1800, renderY = (750/1800) * domeH
        final renderY = (750.0 / DomeConstants.maxAltitudeMeters) *
            DomeConstants.domeH;
        final wind = field.sample(0, renderY, 0);
        // Between layer[0] (10m, u=2, v=3) and layer[1] (1500m, u=8, v=-1)
        // frac = (750-10)/(1500-10) = 740/1490 ~ 0.4966
        final frac = (750.0 - 10.0) / (1500.0 - 10.0);
        final expectedU = 2.0 * (1 - frac) + 8.0 * frac;
        final expectedV = 3.0 * (1 - frac) + -1.0 * frac;
        expect(wind.u, closeTo(expectedU, 0.01));
        expect(wind.v, closeTo(expectedV, 0.01));
      });

      test('interpolates u/v components, NOT speed/direction', () {
        // Create a field where lerping speed/direction would give wrong results
        // Opposing winds: one blowing east, one blowing west
        final opposingField = DomeWindField(
          validTime: now,
          layers: [
            const DomeWindLayer(altitudeMeters: 0, u: 10.0, v: 0.0),
            const DomeWindLayer(altitudeMeters: 1800, u: -10.0, v: 0.0),
          ],
        );
        // At midpoint y, u/v lerp gives (0, 0), which is correct
        // Speed/direction lerp would give speed=10 (wrong)
        final midY = DomeConstants.domeH / 2;
        final wind = opposingField.sample(0, midY, 0);
        expect(wind.u, closeTo(0.0, 0.1));
        expect(wind.speed, closeTo(0.0, 0.2));
      });

      test('returns that layer values with single layer', () {
        final singleField = DomeWindField(
          validTime: now,
          layers: [
            const DomeWindLayer(altitudeMeters: 500, u: 5.0, v: 7.0),
          ],
        );
        final wind = singleField.sample(0, 10, 0);
        expect(wind.u, 5.0);
        expect(wind.v, 7.0);
      });

      test('picks correct layer pair at different altitudes', () {
        // Test between layers 1 and 2 (1500m - 3000m)
        // Map 2000m to render space
        final renderY = (2000.0 / DomeConstants.maxAltitudeMeters) *
            DomeConstants.domeH;
        final wind = field.sample(0, renderY, 0);
        // Between layer[1] (1500m, u=8, v=-1) and layer[2] (3000m, u=14, v=-5)
        // frac = (2000-1500)/(3000-1500) = 500/1500 = 1/3
        final frac = (2000.0 - 1500.0) / (3000.0 - 1500.0);
        final expectedU = 8.0 * (1 - frac) + 14.0 * frac;
        final expectedV = -1.0 * (1 - frac) + -5.0 * frac;
        expect(wind.u, closeTo(expectedU, 0.01));
        expect(wind.v, closeTo(expectedV, 0.01));
      });

      test('returns zero wind vector for empty layers', () {
        final emptyField = DomeWindField(
          validTime: now,
          layers: [],
        );
        final wind = emptyField.sample(0, 10, 0);
        expect(wind.u, 0.0);
        expect(wind.v, 0.0);
      });

      test('clamps below bottom layer altitude', () {
        // Negative y should clamp to bottom layer
        final wind = field.sample(0, -5, 0);
        expect(wind.u, closeTo(2.0, 0.01));
        expect(wind.v, closeTo(3.0, 0.01));
      });

      test('x and z are ignored in MVP', () {
        // Same y, different x/z should give same result
        final wind1 = field.sample(0, 10, 0);
        final wind2 = field.sample(100, 10, -50);
        expect(wind1.u, wind2.u);
        expect(wind1.v, wind2.v);
      });
    });

    group('DomeWindField.zero()', () {
      test('creates a zero-wind field with 3 layers', () {
        final zeroField = DomeWindField.zero();
        expect(zeroField.layers.length, 3);
        for (final layer in zeroField.layers) {
          expect(layer.u, 0.0);
          expect(layer.v, 0.0);
        }
      });

      test('sample returns zero at any position', () {
        final zeroField = DomeWindField.zero();
        final wind = zeroField.sample(5, 10, 3);
        expect(wind.u, 0.0);
        expect(wind.v, 0.0);
      });
    });
  });
}
