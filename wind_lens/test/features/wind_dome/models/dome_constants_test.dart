import 'package:flutter_test/flutter_test.dart';

import 'package:wind_lens/features/wind_dome/models/dome_constants.dart';

void main() {
  group('DomeConstants', () {
    test('metersPerRenderUnit round-trip: 1000m produces domeR', () {
      // 1000m / metersPerRenderUnit should give domeR (18.0)
      final computedDomeR = 1000.0 / DomeConstants.metersPerRenderUnit;
      expect(computedDomeR, closeTo(DomeConstants.domeR, 0.001));
    });
  });
}
