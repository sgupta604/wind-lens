import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/position_data.dart';
import 'package:wind_lens/core/models/wind_data.dart';
import 'package:wind_lens/core/services/wind_data_source.dart';
import 'package:wind_lens/models/altitude_level.dart';
import 'package:wind_lens/services/wind/cached_wind_source.dart';

/// A recording [WindDataSource] that tracks calls and returns configurable data.
class RecordingWindDataSource implements WindDataSource {
  final List<String> calls = [];
  WindData? nextResult;

  @override
  Future<WindData> getWind({
    required PositionData position,
    required AltitudeLevel altitude,
  }) async {
    calls.add('getWind(${position.latitude}, ${position.longitude}, $altitude)');
    return nextResult ??
        WindData(
          uComponent: 3.0,
          vComponent: 4.0,
          altitude: altitude,
          timestamp: DateTime.now(),
        );
  }

  @override
  bool get isSimulated => true;
}

void main() {
  final now = DateTime.now();
  final position = PositionData(
    latitude: 37.7749,
    longitude: -122.4194,
    altitude: 0.0,
    accuracy: 5.0,
    timestamp: now,
  );

  group('CachedWindDataSource', () {
    late RecordingWindDataSource delegate;
    late CachedWindDataSource cached;

    setUp(() {
      delegate = RecordingWindDataSource();
      cached = CachedWindDataSource(
        delegate: delegate,
        ttl: const Duration(minutes: 10),
      );
    });

    test('implements WindDataSource interface', () {
      expect(cached, isA<WindDataSource>());
    });

    test('delegates isSimulated to wrapped source', () {
      expect(cached.isSimulated, true);
    });

    test('delegates to wrapped source on cache miss', () async {
      final result = await cached.getWind(
        position: position,
        altitude: AltitudeLevel.surface,
      );

      expect(delegate.calls, hasLength(1));
      expect(result.speed, closeTo(5.0, 0.01)); // sqrt(3^2 + 4^2)
    });

    test('returns cached result on cache hit', () async {
      // First call: cache miss
      await cached.getWind(position: position, altitude: AltitudeLevel.surface);
      expect(delegate.calls, hasLength(1));

      // Second call: cache hit
      final result = await cached.getWind(
        position: position,
        altitude: AltitudeLevel.surface,
      );
      expect(delegate.calls, hasLength(1)); // Still only 1 call
      expect(result.speed, closeTo(5.0, 0.01));
    });

    test('cache miss when altitude changes', () async {
      // First call at surface
      await cached.getWind(position: position, altitude: AltitudeLevel.surface);
      expect(delegate.calls, hasLength(1));

      // Second call at mid-level: different altitude = cache miss
      await cached.getWind(position: position, altitude: AltitudeLevel.midLevel);
      expect(delegate.calls, hasLength(2));
    });

    test('cache miss when position changes significantly', () async {
      // First call at one location
      await cached.getWind(position: position, altitude: AltitudeLevel.surface);
      expect(delegate.calls, hasLength(1));

      // Second call ~1km away
      final farPosition = PositionData(
        latitude: 37.784,
        longitude: -122.410,
        altitude: 0.0,
        accuracy: 5.0,
        timestamp: now,
      );
      await cached.getWind(
        position: farPosition,
        altitude: AltitudeLevel.surface,
      );
      expect(delegate.calls, hasLength(2));
    });

    test('cache hit for nearby position (within rounding)', () async {
      // First call
      await cached.getWind(position: position, altitude: AltitudeLevel.surface);
      expect(delegate.calls, hasLength(1));

      // Second call ~10m away (within 2 decimal place rounding)
      final nearbyPosition = PositionData(
        latitude: 37.7750,
        longitude: -122.4195,
        altitude: 0.0,
        accuracy: 5.0,
        timestamp: now,
      );
      await cached.getWind(
        position: nearbyPosition,
        altitude: AltitudeLevel.surface,
      );
      expect(delegate.calls, hasLength(1)); // Cache hit
    });

    test('cache expires after TTL', () async {
      // Use a very short TTL for testing
      cached = CachedWindDataSource(
        delegate: delegate,
        ttl: Duration.zero, // Expires immediately
      );

      // First call: cache miss
      await cached.getWind(position: position, altitude: AltitudeLevel.surface);
      expect(delegate.calls, hasLength(1));

      // Second call: TTL expired, so cache miss
      await cached.getWind(position: position, altitude: AltitudeLevel.surface);
      expect(delegate.calls, hasLength(2));
    });

    test('cache does not expire before TTL', () async {
      // Use a long TTL
      cached = CachedWindDataSource(
        delegate: delegate,
        ttl: const Duration(hours: 1),
      );

      await cached.getWind(position: position, altitude: AltitudeLevel.surface);
      await cached.getWind(position: position, altitude: AltitudeLevel.surface);
      expect(delegate.calls, hasLength(1)); // Only 1 call
    });

    test('invalidateForAltitude clears cache entries for that altitude', () async {
      await cached.getWind(position: position, altitude: AltitudeLevel.surface);
      expect(delegate.calls, hasLength(1));

      // Invalidate surface cache
      cached.invalidateForAltitude(AltitudeLevel.surface);

      // Next call should be a cache miss
      await cached.getWind(position: position, altitude: AltitudeLevel.surface);
      expect(delegate.calls, hasLength(2));
    });

    test('invalidateForAltitude does not affect other altitudes', () async {
      // Cache surface and mid-level
      await cached.getWind(position: position, altitude: AltitudeLevel.surface);
      await cached.getWind(position: position, altitude: AltitudeLevel.midLevel);
      expect(delegate.calls, hasLength(2));

      // Invalidate only surface
      cached.invalidateForAltitude(AltitudeLevel.surface);

      // Mid-level should still be cached
      await cached.getWind(position: position, altitude: AltitudeLevel.midLevel);
      expect(delegate.calls, hasLength(2)); // No new call

      // Surface should be a miss
      await cached.getWind(position: position, altitude: AltitudeLevel.surface);
      expect(delegate.calls, hasLength(3));
    });

    test('invalidateAll clears entire cache', () async {
      await cached.getWind(position: position, altitude: AltitudeLevel.surface);
      await cached.getWind(position: position, altitude: AltitudeLevel.midLevel);
      expect(delegate.calls, hasLength(2));

      cached.invalidateAll();

      // Both should be cache misses now
      await cached.getWind(position: position, altitude: AltitudeLevel.surface);
      await cached.getWind(position: position, altitude: AltitudeLevel.midLevel);
      expect(delegate.calls, hasLength(4));
    });

    test('stores latest value from delegate', () async {
      delegate.nextResult = WindData(
        uComponent: 10.0,
        vComponent: 0.0,
        altitude: AltitudeLevel.surface,
        timestamp: now,
      );

      final result1 = await cached.getWind(
        position: position,
        altitude: AltitudeLevel.surface,
      );
      expect(result1.uComponent, 10.0);

      // Change delegate -- but cache should return old value
      delegate.nextResult = WindData(
        uComponent: 20.0,
        vComponent: 0.0,
        altitude: AltitudeLevel.surface,
        timestamp: now,
      );

      final result2 = await cached.getWind(
        position: position,
        altitude: AltitudeLevel.surface,
      );
      expect(result2.uComponent, 10.0); // Cached
      expect(delegate.calls, hasLength(1));
    });
  });
}
