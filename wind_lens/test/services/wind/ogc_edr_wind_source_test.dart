import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/position_data.dart';
import 'package:wind_lens/core/models/wind_data.dart';
import 'package:wind_lens/core/services/wind_data_source.dart';
import 'package:wind_lens/models/altitude_level.dart';
import 'package:wind_lens/services/wind/cached_wind_source.dart';
import 'package:wind_lens/services/wind/ogc_edr_wind_source.dart';
import 'package:wind_lens/services/wind/wind_api_client.dart';

// ═══════════════════════════════════════════════════════════════
//  Fake WindApiClient for testing OgcEdrWindDataSource
// ═══════════════════════════════════════════════════════════════

/// A fake [WindApiClient] that returns configurable (u, v) values
/// and records the pressure levels it was called with.
class FakeWindApiClient extends WindApiClient {
  final double returnU;
  final double returnV;
  final List<int> capturedLevels = [];
  int callCount = 0;

  FakeWindApiClient({this.returnU = 5.0, this.returnV = -3.0})
      : super(client: null);

  @override
  Future<(double u, double v, String source)> fetchPointWind({
    required double lat,
    required double lng,
    required int pressureLevel,
  }) async {
    capturedLevels.add(pressureLevel);
    callCount++;
    return (returnU, returnV, 'fake');
  }
}

// ═══════════════════════════════════════════════════════════════
//  Tests
// ═══════════════════════════════════════════════════════════════

void main() {
  final testPosition = PositionData(
    latitude: 37.7749,
    longitude: -122.4194,
    altitude: 0.0,
    accuracy: 5.0,
    timestamp: DateTime.now(),
  );

  group('OgcEdrWindDataSource', () {
    test('implements WindDataSource interface', () {
      final source = OgcEdrWindDataSource(
        apiClient: FakeWindApiClient(),
      );
      expect(source, isA<WindDataSource>());
    });

    test('isSimulated returns false', () {
      final source = OgcEdrWindDataSource(
        apiClient: FakeWindApiClient(),
      );
      expect(source.isSimulated, false);
    });

    test('getWind with AltitudeLevel.surface passes pressureLevel 0', () async {
      final fakeClient = FakeWindApiClient();
      final source = OgcEdrWindDataSource(apiClient: fakeClient);

      await source.getWind(
        position: testPosition,
        altitude: AltitudeLevel.surface,
      );

      expect(fakeClient.capturedLevels, [0]);
    });

    test('getWind with AltitudeLevel.midLevel passes pressureLevel 850', () async {
      final fakeClient = FakeWindApiClient();
      final source = OgcEdrWindDataSource(apiClient: fakeClient);

      await source.getWind(
        position: testPosition,
        altitude: AltitudeLevel.midLevel,
      );

      expect(fakeClient.capturedLevels, [850]);
    });

    test('getWind with AltitudeLevel.jetStream passes pressureLevel 250', () async {
      final fakeClient = FakeWindApiClient();
      final source = OgcEdrWindDataSource(apiClient: fakeClient);

      await source.getWind(
        position: testPosition,
        altitude: AltitudeLevel.jetStream,
      );

      expect(fakeClient.capturedLevels, [250]);
    });

    test('getWind returns WindData with correct u/v from API', () async {
      final fakeClient = FakeWindApiClient(returnU: 7.5, returnV: -2.3);
      final source = OgcEdrWindDataSource(apiClient: fakeClient);

      final result = await source.getWind(
        position: testPosition,
        altitude: AltitudeLevel.midLevel,
      );

      expect(result.uComponent, 7.5);
      expect(result.vComponent, -2.3);
    });

    test('getWind returns WindData with correct altitude level', () async {
      final fakeClient = FakeWindApiClient();
      final source = OgcEdrWindDataSource(apiClient: fakeClient);

      final result = await source.getWind(
        position: testPosition,
        altitude: AltitudeLevel.jetStream,
      );

      expect(result.altitude, AltitudeLevel.jetStream);
    });

    test('getWind returns WindData with recent timestamp', () async {
      final fakeClient = FakeWindApiClient();
      final source = OgcEdrWindDataSource(apiClient: fakeClient);

      final before = DateTime.now();
      final result = await source.getWind(
        position: testPosition,
        altitude: AltitudeLevel.surface,
      );
      final after = DateTime.now();

      expect(result.timestamp.isAfter(before.subtract(const Duration(seconds: 1))), true);
      expect(result.timestamp.isBefore(after.add(const Duration(seconds: 1))), true);
    });

    test('getWind on API failure returns zero wind', () async {
      // FakeWindApiClient returning (0, 0) simulates the API client's
      // graceful degradation behavior
      final fakeClient = FakeWindApiClient(returnU: 0.0, returnV: 0.0);
      final source = OgcEdrWindDataSource(apiClient: fakeClient);

      final result = await source.getWind(
        position: testPosition,
        altitude: AltitudeLevel.surface,
      );

      expect(result.uComponent, 0.0);
      expect(result.vComponent, 0.0);
      expect(result.speed, 0.0);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  //  Integration Tests: CachedWindDataSource + OgcEdrWindDataSource
  // ═══════════════════════════════════════════════════════════════

  group('CachedWindDataSource wrapping OgcEdrWindDataSource', () {
    test('isSimulated is false when wrapping OgcEdr', () {
      final fakeClient = FakeWindApiClient();
      final cached = CachedWindDataSource(
        delegate: OgcEdrWindDataSource(apiClient: fakeClient),
        ttl: const Duration(minutes: 10),
      );
      expect(cached.isSimulated, false);
    });

    test('caches correctly - second call returns cached result', () async {
      final fakeClient = FakeWindApiClient(returnU: 3.0, returnV: 4.0);
      final cached = CachedWindDataSource(
        delegate: OgcEdrWindDataSource(apiClient: fakeClient),
        ttl: const Duration(minutes: 10),
      );

      // First call: cache miss
      final result1 = await cached.getWind(
        position: testPosition,
        altitude: AltitudeLevel.surface,
      );
      expect(fakeClient.callCount, 1);
      expect(result1.uComponent, 3.0);

      // Second call: cache hit (no new HTTP call)
      final result2 = await cached.getWind(
        position: testPosition,
        altitude: AltitudeLevel.surface,
      );
      expect(fakeClient.callCount, 1); // Still only 1 call
      expect(result2.uComponent, 3.0);
    });

    test('different altitude level triggers new HTTP call', () async {
      final fakeClient = FakeWindApiClient(returnU: 3.0, returnV: 4.0);
      final cached = CachedWindDataSource(
        delegate: OgcEdrWindDataSource(apiClient: fakeClient),
        ttl: const Duration(minutes: 10),
      );

      // First call at surface
      await cached.getWind(
        position: testPosition,
        altitude: AltitudeLevel.surface,
      );
      expect(fakeClient.callCount, 1);
      expect(fakeClient.capturedLevels, [0]);

      // Second call at midLevel: different altitude = cache miss
      await cached.getWind(
        position: testPosition,
        altitude: AltitudeLevel.midLevel,
      );
      expect(fakeClient.callCount, 2);
      expect(fakeClient.capturedLevels, [0, 850]);
    });

    test('returns WindData with correct values through full chain', () async {
      final fakeClient = FakeWindApiClient(returnU: 10.0, returnV: -5.0);
      final cached = CachedWindDataSource(
        delegate: OgcEdrWindDataSource(apiClient: fakeClient),
        ttl: const Duration(minutes: 10),
      );

      final result = await cached.getWind(
        position: testPosition,
        altitude: AltitudeLevel.jetStream,
      );

      expect(result.uComponent, 10.0);
      expect(result.vComponent, -5.0);
      expect(result.altitude, AltitudeLevel.jetStream);
      expect(result, isA<WindData>());
    });
  });
}
