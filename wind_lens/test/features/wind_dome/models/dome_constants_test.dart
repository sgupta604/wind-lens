import 'package:flutter_test/flutter_test.dart';

import 'package:wind_lens/features/wind_dome/models/dome_constants.dart';

void main() {
  group('DomeConstants', () {
    test('metersPerRenderUnit round-trip: 1000m produces domeR', () {
      // 1000m / metersPerRenderUnit should give domeR (18.0)
      final computedDomeR = 1000.0 / DomeConstants.metersPerRenderUnit;
      expect(computedDomeR, closeTo(DomeConstants.domeR, 0.001));
    });

    group('compass rose constants', () {
      test('compassLabelRadiusMultiplier places labels outside dome', () {
        expect(DomeConstants.compassLabelRadiusMultiplier, greaterThan(1.0));
      });

      test('compassTickLength is positive and less than domeR', () {
        expect(DomeConstants.compassTickLength, greaterThan(0));
        expect(DomeConstants.compassTickLength, lessThan(DomeConstants.domeR));
      });

      test('compassNorthFontSize >= compassCardinalFontSize', () {
        expect(DomeConstants.compassNorthFontSize,
            greaterThanOrEqualTo(DomeConstants.compassCardinalFontSize));
      });
    });
  });
}
