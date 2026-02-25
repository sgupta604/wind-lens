import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/horizon_profile.dart';
import 'package:wind_lens/core/services/horizon_provider.dart';
import 'package:wind_lens/services/horizon/cached_horizon_provider.dart';

/// A recording [HorizonProvider] that tracks calls and returns configurable data.
class RecordingHorizonProvider implements HorizonProvider {
  final List<String> calls = [];
  HorizonProfile? nextProfile;

  @override
  Future<HorizonProfile> getHorizon({
    required double latitude,
    required double longitude,
  }) async {
    calls.add('getHorizon($latitude, $longitude)');
    return nextProfile ?? HorizonProfile.flat(latitude, longitude);
  }
}

void main() {
  group('CachedHorizonProvider', () {
    late RecordingHorizonProvider delegate;
    late CachedHorizonProvider cached;

    setUp(() {
      delegate = RecordingHorizonProvider();
      cached = CachedHorizonProvider(delegate: delegate);
    });

    test('delegates to wrapped provider on cache miss', () async {
      final result = await cached.getHorizon(latitude: 37.7749, longitude: -122.4194);

      expect(delegate.calls, hasLength(1));
      expect(result.latitude, closeTo(37.7749, 0.001));
      expect(result.longitude, closeTo(-122.4194, 0.001));
    });

    test('returns cached result on cache hit (same coordinates)', () async {
      // First call: cache miss, delegates to provider
      await cached.getHorizon(latitude: 37.7749, longitude: -122.4194);
      expect(delegate.calls, hasLength(1));

      // Second call: cache hit, should NOT delegate
      final result = await cached.getHorizon(latitude: 37.7749, longitude: -122.4194);
      expect(delegate.calls, hasLength(1)); // Still only 1 call
      expect(result.latitude, closeTo(37.7749, 0.001));
    });

    test('returns cached result for nearby coordinates (within ~100m)', () async {
      // First call at exact location
      await cached.getHorizon(latitude: 37.7749, longitude: -122.4194);
      expect(delegate.calls, hasLength(1));

      // Second call ~50m away (0.0005 degrees ~ 55m at this latitude)
      await cached.getHorizon(latitude: 37.7753, longitude: -122.4190);
      // Should still be 1 call because both round to the same cache key
      // (3 decimal places = ~111m resolution)
      expect(delegate.calls, hasLength(1));
    });

    test('cache miss for distant coordinates (>~111m)', () async {
      // First call
      await cached.getHorizon(latitude: 37.7749, longitude: -122.4194);
      expect(delegate.calls, hasLength(1));

      // Second call ~1km away
      await cached.getHorizon(latitude: 37.784, longitude: -122.410);
      expect(delegate.calls, hasLength(2));
    });

    test('cache key uses 3 decimal places for lat/lng', () async {
      // 37.7749 rounds to 37.775, -122.4194 rounds to -122.419
      await cached.getHorizon(latitude: 37.7749, longitude: -122.4194);
      // 37.7751 rounds to 37.775, -122.4196 rounds to -122.420 (different!)
      await cached.getHorizon(latitude: 37.7751, longitude: -122.4196);
      // Second call has different rounded longitude, so it's a cache miss
      expect(delegate.calls, hasLength(2));
    });

    test('implements HorizonProvider interface', () {
      expect(cached, isA<HorizonProvider>());
    });

    test('stores profile from delegate in memory cache', () async {
      final customProfile = HorizonProfile(
        latitude: 37.0,
        longitude: -122.0,
        elevationAngles: {0.0: 5.0, 90.0: 3.0, 180.0: 7.0, 270.0: 2.0},
        fetchedAt: DateTime.now(),
      );
      delegate.nextProfile = customProfile;

      final result1 = await cached.getHorizon(latitude: 37.0, longitude: -122.0);
      expect(result1.elevationAngles[0.0], 5.0);

      // Change delegate response -- but cache should return the first one
      delegate.nextProfile = HorizonProfile.flat(37.0, -122.0);

      final result2 = await cached.getHorizon(latitude: 37.0, longitude: -122.0);
      expect(result2.elevationAngles[0.0], 5.0); // Still cached
      expect(delegate.calls, hasLength(1));
    });

    group('disk persistence', () {
      test('serializes HorizonProfile to JSON correctly', () {
        final profile = HorizonProfile(
          latitude: 37.7749,
          longitude: -122.4194,
          elevationAngles: {0.0: 5.0, 180.0: 3.0},
          fetchedAt: DateTime(2026, 2, 25),
        );

        // Verify JSON round-trip via the built-in Freezed serialization
        final json = profile.toJson();
        final restored = HorizonProfile.fromJson(json);
        expect(restored.latitude, profile.latitude);
        expect(restored.longitude, profile.longitude);
        expect(restored.getElevationAtBearing(0), 5.0);
        expect(restored.getElevationAtBearing(180), 3.0);
      });

      test('can serialize and deserialize cache map to JSON string', () {
        final profile = HorizonProfile(
          latitude: 37.0,
          longitude: -122.0,
          elevationAngles: {0.0: 5.0, 90.0: 3.0},
          fetchedAt: DateTime(2026, 2, 25),
        );

        // Simulate what disk persistence would do
        final cacheMap = <String, dynamic>{
          '37.000_-122.000': profile.toJson(),
        };
        final jsonStr = jsonEncode(cacheMap);

        // Deserialize
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final restoredJson = decoded['37.000_-122.000'] as Map<String, dynamic>;
        final restored = HorizonProfile.fromJson(restoredJson);
        expect(restored.latitude, 37.0);
        expect(restored.longitude, -122.0);
        expect(restored.getElevationAtBearing(0), 5.0);
      });

      test('saveToDiskJson produces valid JSON', () {
        // Create provider (cache starts empty)
        cached = CachedHorizonProvider(delegate: delegate);

        // saveToDiskJson should produce valid JSON (even if empty)
        final json = cached.saveToDiskJson();
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('loadFromDiskJson restores cache entries', () async {
        final profile = HorizonProfile(
          latitude: 37.0,
          longitude: -122.0,
          elevationAngles: {0.0: 5.0, 90.0: 3.0},
          fetchedAt: DateTime(2026, 2, 25),
        );

        // Create a JSON string representing a persisted cache
        final cacheMap = <String, dynamic>{
          '37.000_-122.000': profile.toJson(),
        };
        final jsonStr = jsonEncode(cacheMap);

        // Load from JSON
        cached.loadFromDiskJson(jsonStr);

        // Now fetching should hit the cache
        final result = await cached.getHorizon(latitude: 37.0, longitude: -122.0);
        expect(delegate.calls, isEmpty); // No delegate call!
        expect(result.getElevationAtBearing(0), 5.0);
      });

      test('loadFromDiskJson handles empty JSON gracefully', () {
        expect(() => cached.loadFromDiskJson('{}'), returnsNormally);
      });

      test('loadFromDiskJson handles invalid JSON gracefully', () {
        expect(() => cached.loadFromDiskJson('not valid json'), returnsNormally);
      });
    });
  });
}
