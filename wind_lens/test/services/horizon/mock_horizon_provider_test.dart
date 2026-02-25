import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/horizon_profile.dart';
import 'package:wind_lens/core/services/horizon_provider.dart';
import 'package:wind_lens/services/horizon/mock_horizon_provider.dart';

void main() {
  group('MockHorizonProvider', () {
    late MockHorizonProvider provider;

    setUp(() {
      provider = MockHorizonProvider();
    });

    test('implements HorizonProvider interface', () {
      expect(provider, isA<HorizonProvider>());
    });

    test('returns a HorizonProfile future', () async {
      final profile = await provider.getHorizon(
        latitude: 37.7749,
        longitude: -122.4194,
      );

      expect(profile, isA<HorizonProfile>());
    });

    test('returned profile has matching lat/lng', () async {
      final profile = await provider.getHorizon(
        latitude: 37.7749,
        longitude: -122.4194,
      );

      expect(profile.latitude, 37.7749);
      expect(profile.longitude, -122.4194);
    });

    test('all elevation angles are 0 (flat horizon)', () async {
      final profile = await provider.getHorizon(
        latitude: 37.7749,
        longitude: -122.4194,
      );

      // Check all values in the map are 0
      for (final entry in profile.elevationAngles.entries) {
        expect(entry.value, 0.0,
            reason: 'Elevation at bearing ${entry.key} should be 0');
      }
    });

    test('getElevationAtBearing returns 0 for any bearing', () async {
      final profile = await provider.getHorizon(
        latitude: 0,
        longitude: 0,
      );

      expect(profile.getElevationAtBearing(0), 0.0);
      expect(profile.getElevationAtBearing(45), 0.0);
      expect(profile.getElevationAtBearing(90), 0.0);
      expect(profile.getElevationAtBearing(180), 0.0);
      expect(profile.getElevationAtBearing(270), 0.0);
      expect(profile.getElevationAtBearing(359), 0.0);
    });
  });
}
