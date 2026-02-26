import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/services/wind/wind_models.dart';

void main() {
  group('WindVector', () {
    test('zero has u=0 and v=0', () {
      expect(WindVector.zero.u, 0.0);
      expect(WindVector.zero.v, 0.0);
    });

    test('speed computes sqrt(u^2 + v^2)', () {
      const wind = WindVector(u: 3.0, v: 4.0);
      expect(wind.speed, closeTo(5.0, 0.001));
    });

    test('speed for (1, 0) is 1.0', () {
      const wind = WindVector(u: 1.0, v: 0.0);
      expect(wind.speed, closeTo(1.0, 0.001));
    });
  });

  group('WindField', () {
    late WindField field;

    setUp(() {
      // 3x2 grid (3 columns, 2 rows)
      // Row 0: (0,0)=1,2  (0,1)=3,4  (0,2)=5,6
      // Row 1: (1,0)=7,8  (1,1)=9,10 (1,2)=11,12
      field = WindField(
        xs: [10.0, 11.0, 12.0],
        ys: [20.0, 21.0],
        us: [1.0, 3.0, 5.0, 7.0, 9.0, 11.0],
        vs: [2.0, 4.0, 6.0, 8.0, 10.0, 12.0],
        source: 'test',
        fetchedAt: DateTime(2026, 1, 1),
      );
    });

    test('width and height match xs/ys lengths', () {
      expect(field.width, 3);
      expect(field.height, 2);
    });

    test('getAt returns correct value at (row, col)', () {
      final v = field.getAt(0, 1);
      expect(v.u, 3.0);
      expect(v.v, 4.0);
    });

    test('getAt out of bounds returns WindVector.zero', () {
      final v = field.getAt(10, 10);
      expect(v.u, 0.0);
      expect(v.v, 0.0);
    });

    test('getAt negative index returns WindVector.zero', () {
      final v = field.getAt(-1, 0);
      expect(v.u, 0.0);
      expect(v.v, 0.0);
    });

    test('interpolateAtCoord returns interpolated value at grid center', () {
      // Center of grid: lng=11, lat=20.5
      final v = field.interpolateAtCoord(11.0, 20.5);
      // At center x (col=1), interpolated between rows:
      // Row 0, col 1: u=3, v=4
      // Row 1, col 1: u=9, v=10
      // Midpoint: u=6, v=7
      expect(v.u, closeTo(6.0, 0.1));
      expect(v.v, closeTo(7.0, 0.1));
    });

    test('interpolateAtCoord clamps at boundaries', () {
      // Far outside the grid -- should clamp to edge
      final v = field.interpolateAtCoord(100.0, 100.0);
      // Clamped to (normX=1, normY=1) -> bottom-right corner
      // Row 1, col 2: u=11, v=12
      expect(v.u, closeTo(11.0, 0.1));
      expect(v.v, closeTo(12.0, 0.1));
    });

    test('centerWind returns value at grid center', () {
      final v = field.centerWind();
      // Center normalized: (0.5, 0.5)
      // Interpolation at center of 3x2 grid
      expect(v.speed, greaterThan(0));
    });

    test('empty grid returns WindVector.zero from interpolation', () {
      final emptyField = WindField(
        xs: [],
        ys: [],
        us: [],
        vs: [],
        source: 'empty',
        fetchedAt: DateTime(2026, 1, 1),
      );
      final v = emptyField.interpolateAtCoord(0, 0);
      expect(v.u, 0.0);
      expect(v.v, 0.0);
    });

    test('isStale returns true for old data', () {
      final oldField = WindField(
        xs: [0.0],
        ys: [0.0],
        us: [1.0],
        vs: [1.0],
        source: 'old',
        fetchedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(oldField.isStale(const Duration(minutes: 30)), true);
    });

    test('isStale returns false for fresh data', () {
      final freshField = WindField(
        xs: [0.0],
        ys: [0.0],
        us: [1.0],
        vs: [1.0],
        source: 'fresh',
        fetchedAt: DateTime.now(),
      );
      expect(freshField.isStale(const Duration(minutes: 30)), false);
    });
  });
}
