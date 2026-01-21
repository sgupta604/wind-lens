import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/models/compass_data.dart';

void main() {
  group('CompassData', () {
    test('should create instance with heading and pitch', () {
      const compassData = CompassData(heading: 127.3, pitch: 12.5);

      expect(compassData.heading, 127.3);
      expect(compassData.pitch, 12.5);
    });

    test('should handle zero values', () {
      const compassData = CompassData(heading: 0, pitch: 0);

      expect(compassData.heading, 0);
      expect(compassData.pitch, 0);
    });

    test('should handle negative pitch values', () {
      const compassData = CompassData(heading: 180.0, pitch: -45.0);

      expect(compassData.heading, 180.0);
      expect(compassData.pitch, -45.0);
    });

    test('should handle maximum heading value', () {
      const compassData = CompassData(heading: 359.9, pitch: 0);

      expect(compassData.heading, 359.9);
    });

    test('should be a const constructor', () {
      // This test verifies the const constructor works
      const compassData1 = CompassData(heading: 100.0, pitch: 20.0);
      const compassData2 = CompassData(heading: 100.0, pitch: 20.0);

      // Both should be valid const instances
      expect(compassData1.heading, compassData2.heading);
      expect(compassData1.pitch, compassData2.pitch);
    });
  });
}
