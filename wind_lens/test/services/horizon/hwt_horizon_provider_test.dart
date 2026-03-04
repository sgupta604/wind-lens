import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:wind_lens/services/horizon/hwt_horizon_provider.dart';

void main() {
  group('HwtHorizonProvider', () {
    /// Builds a mock result.json body with [count] limits entries.
    ///
    /// Each entry has [lat, lon, elevation_angle] where the elevation angle
    /// increments by 0.1 degrees from [baseElevation].
    String buildResultJson({
      String id = 'TEST1234',
      int count = 360,
      double baseElevation = 5.0,
      int declination = 15,
    }) {
      final limits = <List<double>>[];
      for (int i = 0; i < count; i++) {
        limits.add([47.0 + i * 0.001, -122.0 + i * 0.001, baseElevation + i * 0.1]);
      }
      return jsonEncode({
        'id': id,
        'lat': 47.6062,
        'lon': -122.3321,
        'declination': declination,
        'limits': limits,
      });
    }

    /// Creates a [MockClient] that handles submit, poll, and result requests.
    ///
    /// [submitBody]: Response body for the submit request.
    /// [pollResponses]: List of bodies returned for successive poll requests.
    /// [resultBody]: Response body for the result.json request.
    /// [submitStatus]: HTTP status for the submit request (default 200).
    /// [resultStatus]: HTTP status for the result.json request (default 200).
    /// [pollStatus]: HTTP status for poll requests (default 200).
    MockClient buildMockClient({
      String submitBody = 'RDJCX2LU queued 47.6062 -122.3321 - 2 1772595803 0 0 0 0 wt windlens',
      List<String>? pollResponses,
      String? resultBody,
      int submitStatus = 200,
      int resultStatus = 200,
      int pollStatus = 200,
    }) {
      final effectivePollResponses = pollResponses ?? ['ok 47.6062 -122.3321 62 2'];
      final effectiveResultBody = resultBody ?? buildResultJson();
      int pollIndex = 0;

      return MockClient((request) async {
        final path = request.url.path;

        if (path.contains('query.cgi')) {
          return http.Response(submitBody, submitStatus);
        }

        if (path.contains('/results/') && path.endsWith('/data')) {
          final response = effectivePollResponses[
              pollIndex.clamp(0, effectivePollResponses.length - 1)];
          pollIndex++;
          return http.Response(response, pollStatus);
        }

        if (path.contains('result.json')) {
          return http.Response(effectiveResultBody, resultStatus);
        }

        return http.Response('Not found', 404);
      });
    }

    test('submit parses panorama ID from first token', () async {
      final client = buildMockClient(
        submitBody: 'RDJCX2LU queued 47.6062 -122.3321 - 2 1772595803 0 0 0 0 wt windlens',
      );

      final provider = HwtHorizonProvider(
        client: client,
        pollInterval: Duration.zero,
      );

      final profile = await provider.getHorizon(
        latitude: 47.6062,
        longitude: -122.3321,
      );

      // If the ID was parsed correctly from the first token, the result.json
      // request should succeed and produce a valid profile with 360 entries.
      expect(profile.elevationAngles.length, 360);
    });

    test('polls until response starts with ok', () async {
      int pollCount = 0;
      final client = MockClient((request) async {
        final path = request.url.path;

        if (path.contains('query.cgi')) {
          return http.Response('TEST1234 queued 47.6 -122.3', 200);
        }

        if (path.contains('/results/') && path.endsWith('/data')) {
          pollCount++;
          if (pollCount < 3) {
            return http.Response('running 46.85 -113.99 984 2', 200);
          }
          return http.Response('ok 47.60 -122.33 62 2', 200);
        }

        if (path.contains('result.json')) {
          return http.Response(buildResultJson(), 200);
        }

        return http.Response('Not found', 404);
      });

      final provider = HwtHorizonProvider(
        client: client,
        pollInterval: Duration.zero,
      );

      final profile = await provider.getHorizon(
        latitude: 47.6062,
        longitude: -122.3321,
      );

      expect(pollCount, 3);
      expect(profile.elevationAngles.length, 360);
    });

    test('times out after max duration and returns flat', () async {
      // Poll always returns "running" so it never completes.
      final client = buildMockClient(
        pollResponses: List.filled(100, 'running 46.85 -113.99 984 2'),
      );

      final provider = HwtHorizonProvider(
        client: client,
        pollInterval: Duration.zero,
        timeout: const Duration(milliseconds: 100),
      );

      final profile = await provider.getHorizon(
        latitude: 47.6062,
        longitude: -122.3321,
      );

      // Should return flat profile (all zeros) after timeout.
      expect(profile.elevationAngles.values.every((e) => e == 0.0), isTrue);
      expect(profile.latitude, 47.6062);
      expect(profile.longitude, -122.3321);
    });

    test('parses 360 limits entries correctly', () async {
      final client = buildMockClient();

      final provider = HwtHorizonProvider(
        client: client,
        pollInterval: Duration.zero,
      );

      final profile = await provider.getHorizon(
        latitude: 47.6062,
        longitude: -122.3321,
      );

      expect(profile.elevationAngles.length, 360);
      // First entry should have elevation = baseElevation (5.0)
      expect(profile.elevationAngles[0.0], 5.0);
      // Entry at bearing 1 should be 5.1
      expect(profile.elevationAngles[1.0], closeTo(5.1, 0.001));
    });

    test('extracts declination from result JSON', () async {
      final client = buildMockClient(
        resultBody: buildResultJson(declination: 15),
      );

      final provider = HwtHorizonProvider(
        client: client,
        pollInterval: Duration.zero,
      );

      final profile = await provider.getHorizon(
        latitude: 47.6062,
        longitude: -122.3321,
      );

      expect(profile.declination, 15.0);
    });

    test('extracts panoramaId from result JSON', () async {
      final client = buildMockClient(
        submitBody: 'ABCD5678 queued 47.6 -122.3',
      );

      final provider = HwtHorizonProvider(
        client: client,
        pollInterval: Duration.zero,
      );

      final profile = await provider.getHorizon(
        latitude: 47.6062,
        longitude: -122.3321,
      );

      expect(profile.panoramaId, 'ABCD5678');
    });

    test('returns flat on HTTP error (submit 500)', () async {
      final client = buildMockClient(submitStatus: 500);

      final provider = HwtHorizonProvider(
        client: client,
        pollInterval: Duration.zero,
      );

      final profile = await provider.getHorizon(
        latitude: 47.6062,
        longitude: -122.3321,
      );

      // Should return flat profile, all zeros.
      expect(profile.elevationAngles.values.every((e) => e == 0.0), isTrue);
      expect(profile.latitude, 47.6062);
    });

    test('returns flat on HTTP error (result fetch 500)', () async {
      final client = buildMockClient(resultStatus: 500);

      final provider = HwtHorizonProvider(
        client: client,
        pollInterval: Duration.zero,
      );

      final profile = await provider.getHorizon(
        latitude: 47.6062,
        longitude: -122.3321,
      );

      // Should return flat profile.
      expect(profile.elevationAngles.values.every((e) => e == 0.0), isTrue);
    });

    test('returns flat on network exception', () async {
      final client = MockClient((request) async {
        throw const SocketException('No internet');
      });

      final provider = HwtHorizonProvider(
        client: client,
        pollInterval: Duration.zero,
      );

      final profile = await provider.getHorizon(
        latitude: 47.6062,
        longitude: -122.3321,
      );

      // Should return flat profile, not throw.
      expect(profile.elevationAngles.values.every((e) => e == 0.0), isTrue);
      expect(profile.latitude, 47.6062);
    });

    test('returns flat on empty result body (invalid panorama ID)', () async {
      final client = buildMockClient(resultBody: '');

      final provider = HwtHorizonProvider(
        client: client,
        pollInterval: Duration.zero,
      );

      final profile = await provider.getHorizon(
        latitude: 47.6062,
        longitude: -122.3321,
      );

      // Empty body should trigger flat fallback.
      expect(profile.elevationAngles.values.every((e) => e == 0.0), isTrue);
    });

    test('returns flat on poll 404 (invalid panorama ID)', () async {
      final client = buildMockClient(pollStatus: 404);

      final provider = HwtHorizonProvider(
        client: client,
        pollInterval: Duration.zero,
      );

      final profile = await provider.getHorizon(
        latitude: 47.6062,
        longitude: -122.3321,
      );

      // 404 on poll should trigger flat fallback.
      expect(profile.elevationAngles.values.every((e) => e == 0.0), isTrue);
    });
  });
}
