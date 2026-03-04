import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:wind_lens/features/wind_dome/models/dome_constants.dart';
import 'package:wind_lens/features/wind_dome/models/dome_wind_field.dart';
import 'package:wind_lens/features/wind_dome/models/dome_wind_layer.dart';
import 'package:wind_lens/services/wind/wind_models.dart';

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

      test('x and z are ignored when no grid data', () {
        // Same y, different x/z should give same result when grid is null
        final wind1 = field.sample(0, 10, 0);
        final wind2 = field.sample(100, 10, -50);
        expect(wind1.u, wind2.u);
        expect(wind1.v, wind2.v);
      });
    });

    group('sample() with spatial grid', () {
      /// Creates a simple 3x3 wind grid with spatially varying wind.
      ///
      /// Center: (centerLng, centerLat), extent +/- ~0.05 degrees.
      /// U increases from west to east (1.0 to 9.0).
      /// V increases from south to north (10.0 to 18.0).
      WindField _makeTestGrid({
        double centerLng = -122.0,
        double centerLat = 37.0,
      }) {
        final dLng = 0.05;
        final dLat = 0.05;
        return WindField(
          xs: [centerLng - dLng, centerLng, centerLng + dLng],
          ys: [centerLat - dLat, centerLat, centerLat + dLat],
          // Row-major: [row0col0, row0col1, row0col2, row1col0, ...]
          // Row 0 (south): u = 1, 2, 3
          // Row 1 (center): u = 4, 5, 6
          // Row 2 (north): u = 7, 8, 9
          us: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0],
          // Row 0 (south): v = 10, 11, 12
          // Row 1 (center): v = 13, 14, 15
          // Row 2 (north): v = 16, 17, 18
          vs: [10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0],
          source: 'test-grid',
        );
      }

      test('different x/z positions return different wind vectors', () {
        final grid = _makeTestGrid();
        final gridField = DomeWindField(
          validTime: now,
          layers: [
            DomeWindLayer(altitudeMeters: 10, u: 5.0, v: 14.0, grid: grid),
            DomeWindLayer(altitudeMeters: 1500, u: 5.0, v: 14.0, grid: grid),
            DomeWindLayer(altitudeMeters: 3000, u: 5.0, v: 14.0, grid: grid),
          ],
          centerLat: 37.0,
          centerLng: -122.0,
          metersPerRenderUnit: DomeConstants.metersPerRenderUnit,
        );

        // Two different x positions at same y/z
        final windLeft = gridField.sample(-5, 0, 0);
        final windRight = gridField.sample(5, 0, 0);

        // Different x positions should return different u values
        expect(windLeft.u, isNot(closeTo(windRight.u, 0.001)));
      });

      test('center position (x=0, z=0) approximately matches center wind', () {
        final grid = _makeTestGrid();
        final gridField = DomeWindField(
          validTime: now,
          layers: [
            DomeWindLayer(altitudeMeters: 10, u: 5.0, v: 14.0, grid: grid),
            DomeWindLayer(altitudeMeters: 1500, u: 5.0, v: 14.0, grid: grid),
            DomeWindLayer(altitudeMeters: 3000, u: 5.0, v: 14.0, grid: grid),
          ],
          centerLat: 37.0,
          centerLng: -122.0,
          metersPerRenderUnit: DomeConstants.metersPerRenderUnit,
        );

        // At center (x=0, z=0), the grid interpolation should return
        // approximately the center of the grid: u~5, v~14
        final wind = gridField.sample(0, 0, 0);
        expect(wind.u, closeTo(5.0, 0.5));
        expect(wind.v, closeTo(14.0, 0.5));
      });

      test('vertical interpolation works between grid-enabled layers', () {
        final gridLo = _makeTestGrid();
        final gridHi = WindField(
          xs: [-122.05, -122.0, -121.95],
          ys: [36.95, 37.0, 37.05],
          us: [21.0, 22.0, 23.0, 24.0, 25.0, 26.0, 27.0, 28.0, 29.0],
          vs: [30.0, 31.0, 32.0, 33.0, 34.0, 35.0, 36.0, 37.0, 38.0],
          source: 'test-grid-hi',
        );

        final gridField = DomeWindField(
          validTime: now,
          layers: [
            DomeWindLayer(altitudeMeters: 10, u: 5.0, v: 14.0, grid: gridLo),
            DomeWindLayer(altitudeMeters: 1500, u: 25.0, v: 34.0, grid: gridHi),
            DomeWindLayer(altitudeMeters: 3000, u: 25.0, v: 34.0, grid: gridHi),
          ],
          centerLat: 37.0,
          centerLng: -122.0,
          metersPerRenderUnit: DomeConstants.metersPerRenderUnit,
        );

        // At halfway altitude between layers 0 and 1
        final midY = (750.0 / DomeConstants.maxAltitudeMeters) * DomeConstants.domeH;
        final wind = gridField.sample(0, midY, 0);

        // Should be a blend between the two grids' center values
        // Center of gridLo: u~5, v~14
        // Center of gridHi: u~25, v~34
        // At 750m between 10m and 1500m: frac = (750-10)/(1500-10) ~ 0.497
        // Expected u ~ 5 * 0.503 + 25 * 0.497 ~ 14.9
        expect(wind.u, greaterThan(5.0));
        expect(wind.u, lessThan(25.0));
      });

      test('without grid data (null), x/z still ignored (backward compat)', () {
        // Field with no grid data -- same as existing behavior
        final noGridField = DomeWindField(
          validTime: now,
          layers: [
            const DomeWindLayer(altitudeMeters: 10, u: 2.0, v: 3.0),
            const DomeWindLayer(altitudeMeters: 1500, u: 8.0, v: -1.0),
            const DomeWindLayer(altitudeMeters: 3000, u: 14.0, v: -5.0),
          ],
        );

        final wind1 = noGridField.sample(0, 0, 0);
        final wind2 = noGridField.sample(100, 0, -50);
        expect(wind1.u, wind2.u);
        expect(wind1.v, wind2.v);
      });

      test('with grid but null centerLat/Lng, falls back to scalar u/v', () {
        final grid = _makeTestGrid();
        final fieldWithGridButNoCenter = DomeWindField(
          validTime: now,
          layers: [
            DomeWindLayer(altitudeMeters: 10, u: 2.0, v: 3.0, grid: grid),
            DomeWindLayer(altitudeMeters: 1500, u: 8.0, v: -1.0, grid: grid),
            DomeWindLayer(altitudeMeters: 3000, u: 14.0, v: -5.0, grid: grid),
          ],
          // No centerLat/centerLng set -- should fall back to scalar
        );

        // Should use scalar u/v, not grid, because centerLat/Lng is null
        final wind1 = fieldWithGridButNoCenter.sample(0, 0, 0);
        final wind2 = fieldWithGridButNoCenter.sample(100, 0, -50);
        expect(wind1.u, wind2.u);
        expect(wind1.v, wind2.v);
      });

      test('coordinate conversion: +x (east) maps to +longitude offset', () {
        // Create a grid where u increases with longitude (west to east)
        final grid = WindField(
          xs: [-122.1, -122.0, -121.9],
          ys: [36.9, 37.0, 37.1],
          // East column has higher u values
          us: [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 10.0],
          vs: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
          source: 'test',
        );

        final gridField = DomeWindField(
          validTime: now,
          layers: [
            DomeWindLayer(altitudeMeters: 10, u: 1.0, v: 0.0, grid: grid),
            DomeWindLayer(altitudeMeters: 3000, u: 1.0, v: 0.0, grid: grid),
          ],
          centerLat: 37.0,
          centerLng: -122.0,
          metersPerRenderUnit: DomeConstants.metersPerRenderUnit,
        );

        // +x = east = +longitude direction
        // Positive x should sample from the east (higher u values)
        final windEast = gridField.sample(10, 0, -10); // +x (east), -z (north)
        final windCenter = gridField.sample(0, 0, 0);

        expect(windEast.u, greaterThan(windCenter.u));
      });

      test('coordinate conversion: -z (north) maps to +latitude offset', () {
        // Create a grid where v increases with latitude (south to north)
        final grid = WindField(
          xs: [-122.1, -122.0, -121.9],
          ys: [36.9, 37.0, 37.1],
          us: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
          // North row has higher v values
          vs: [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 10.0],
          source: 'test',
        );

        final gridField = DomeWindField(
          validTime: now,
          layers: [
            DomeWindLayer(altitudeMeters: 10, u: 0.0, v: 1.0, grid: grid),
            DomeWindLayer(altitudeMeters: 3000, u: 0.0, v: 1.0, grid: grid),
          ],
          centerLat: 37.0,
          centerLng: -122.0,
          metersPerRenderUnit: DomeConstants.metersPerRenderUnit,
        );

        // -z = north = +latitude direction
        // Negative z should sample from the north (higher v values)
        final windNorth = gridField.sample(10, 0, -10); // +x, -z = northeast
        final windCenter = gridField.sample(0, 0, 0);

        expect(windNorth.v, greaterThan(windCenter.v));
      });

      test('DomeWindField constructor accepts optional fields', () {
        final gridField = DomeWindField(
          validTime: now,
          layers: [
            const DomeWindLayer(altitudeMeters: 10, u: 0.0, v: 0.0),
          ],
          centerLat: 37.0,
          centerLng: -122.0,
          metersPerRenderUnit: 100.0,
        );

        expect(gridField.centerLat, 37.0);
        expect(gridField.centerLng, -122.0);
        expect(gridField.metersPerRenderUnit, 100.0);
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
