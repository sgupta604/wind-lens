import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:wind_lens/features/wind_dome/models/dome_constants.dart';
import 'package:wind_lens/services/wind/dome_wind_fetcher.dart';
import 'package:wind_lens/services/wind/wind_api_client.dart';
import 'package:wind_lens/services/wind/wind_api_constants.dart';

void main() {
  group('DomeWindFetcher', () {
    setUp(() {
      // Clear cache before each test
      DomeWindFetcher.clearCache();
    });

    /// Creates a Shyft time-series response with the given number of steps.
    String _shyftSeriesJson(int steps, {double uBase = 2.0, double vBase = 1.0}) {
      final times = List.generate(
        steps,
        (i) => DateTime.utc(2026, 2, 27, 12 + i).toIso8601String(),
      );
      final uValues = List.generate(steps, (i) => uBase + i * 0.1);
      final vValues = List.generate(steps, (i) => vBase + i * 0.05);

      return jsonEncode({
        'coverages': [
          {
            'domain': {
              'axes': {
                't': {'values': times}
              }
            },
            'ranges': {
              WindApiConstants.shyftUParam: {'values': uValues}
            }
          },
          {
            'domain': {
              'axes': {
                't': {'values': times}
              }
            },
            'ranges': {
              WindApiConstants.shyftVParam: {'values': vValues}
            }
          },
        ]
      });
    }

    test('fetch() returns DomeWindProfile with 3 layers per field', () async {
      final mockClient = MockClient((request) async {
        return http.Response(_shyftSeriesJson(3), 200);
      });

      final apiClient = WindApiClient(client: mockClient);
      final fetcher = DomeWindFetcher(apiClient: apiClient);
      final profile = await fetcher.fetch(37.77, -122.42);

      expect(profile.hourly.length, 3);
      for (final field in profile.hourly) {
        expect(field.layers.length, 3);
      }
    });

    test('fetch() returns 72 hourly fields', () async {
      final mockClient = MockClient((request) async {
        return http.Response(_shyftSeriesJson(72), 200);
      });

      final apiClient = WindApiClient(client: mockClient);
      final fetcher = DomeWindFetcher(apiClient: apiClient);
      final profile = await fetcher.fetch(37.77, -122.42);

      expect(profile.hourly.length, 72);
    });

    test('cache hit returns same profile (no re-fetch)', () async {
      int fetchCount = 0;
      final mockClient = MockClient((request) async {
        fetchCount++;
        return http.Response(_shyftSeriesJson(3), 200);
      });

      final apiClient = WindApiClient(client: mockClient);
      final fetcher = DomeWindFetcher(apiClient: apiClient);

      final profile1 = await fetcher.fetch(37.77, -122.42);
      final profile2 = await fetcher.fetch(37.77, -122.42);

      // 3 API calls for 3 pressure levels, only on first fetch
      expect(fetchCount, 3);
      expect(identical(profile1, profile2), isTrue);
    });

    test('cache miss after TTL expiry triggers re-fetch', () async {
      int fetchCount = 0;
      final mockClient = MockClient((request) async {
        fetchCount++;
        return http.Response(_shyftSeriesJson(3), 200);
      });

      final apiClient = WindApiClient(client: mockClient);
      final fetcher = DomeWindFetcher(apiClient: apiClient);

      await fetcher.fetch(37.77, -122.42);
      expect(fetchCount, 3); // 3 pressure levels

      // Manually expire the cache
      DomeWindFetcher.clearCache();

      await fetcher.fetch(37.77, -122.42);
      expect(fetchCount, 6); // 3 more pressure levels
    });

    test('cache key rounds lat/lng to 2 decimal places', () async {
      int fetchCount = 0;
      final mockClient = MockClient((request) async {
        fetchCount++;
        return http.Response(_shyftSeriesJson(3), 200);
      });

      final apiClient = WindApiClient(client: mockClient);
      final fetcher = DomeWindFetcher(apiClient: apiClient);

      // These all round to (37.77, -122.42) at 2 decimal places
      await fetcher.fetch(37.7701, -122.4201);
      await fetcher.fetch(37.7749, -122.4249);
      await fetcher.fetch(37.7700, -122.4200);

      // Only 3 API calls (one set of 3 pressure levels)
      expect(fetchCount, 3);
    });

    test('API failure returns zero-wind profile (graceful degradation)',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response('error', 500);
      });

      final apiClient = WindApiClient(client: mockClient);
      final fetcher = DomeWindFetcher(apiClient: apiClient);
      final profile = await fetcher.fetch(37.77, -122.42);

      // Should return a valid profile with zero-wind fields
      expect(profile.hourly.length, 72);
      for (final field in profile.hourly) {
        expect(field.layers.length, 3);
        final wind = field.sample(0, 0, 0);
        expect(wind.u, 0.0);
        expect(wind.v, 0.0);
      }
    });

    test('3 pressure levels fetched in parallel', () async {
      final requestedLevels = <int>[];
      final mockClient = MockClient((request) async {
        final url = request.url.toString();
        if (url.contains('z=850')) {
          requestedLevels.add(850);
        } else if (url.contains('z=700')) {
          requestedLevels.add(700);
        } else {
          requestedLevels.add(0); // surface
        }
        return http.Response(_shyftSeriesJson(3), 200);
      });

      final apiClient = WindApiClient(client: mockClient);
      final fetcher = DomeWindFetcher(apiClient: apiClient);
      await fetcher.fetch(37.77, -122.42);

      // All 3 levels should be requested
      expect(requestedLevels.length, 3);
      expect(requestedLevels, containsAll([0, 850, 700]));
    });

    test('altitude mapping correct (0->surface, 850->1500m, 700->3000m)',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(_shyftSeriesJson(1), 200);
      });

      final apiClient = WindApiClient(client: mockClient);
      final fetcher = DomeWindFetcher(apiClient: apiClient);
      final profile = await fetcher.fetch(37.77, -122.42);

      final layers = profile.hourly.first.layers;
      // Sorted by altitude ascending
      expect(layers[0].altitudeMeters, 10.0);
      expect(layers[1].altitudeMeters, 1500.0);
      expect(layers[2].altitudeMeters, 3000.0);
    });

    test('layers sorted by altitude ascending', () async {
      final mockClient = MockClient((request) async {
        return http.Response(_shyftSeriesJson(5), 200);
      });

      final apiClient = WindApiClient(client: mockClient);
      final fetcher = DomeWindFetcher(apiClient: apiClient);
      final profile = await fetcher.fetch(37.77, -122.42);

      for (final field in profile.hourly) {
        for (int i = 1; i < field.layers.length; i++) {
          expect(
            field.layers[i].altitudeMeters,
            greaterThanOrEqualTo(field.layers[i - 1].altitudeMeters),
          );
        }
      }
    });

    test('fetch() with radiusMeters == gridFetchThresholdMeters uses point fetch (not grid)',
        () async {
      final requestedUrls = <String>[];
      final mockClient = MockClient((request) async {
        requestedUrls.add(request.url.toString());
        return http.Response(_shyftSeriesJson(3), 200);
      });

      final apiClient = WindApiClient(client: mockClient);
      final fetcher = DomeWindFetcher(apiClient: apiClient);

      // Fetch with radiusMeters exactly equal to the threshold
      final profile = await fetcher.fetch(
        37.77,
        -122.42,
        radiusMeters: DomeConstants.gridFetchThresholdMeters, // 25000.0
      );

      // Should use point fetch: no /area URLs should appear
      for (final url in requestedUrls) {
        expect(url, isNot(contains('/area')),
            reason: 'radiusMeters == threshold should use point fetch, '
                'not grid fetch (no /area queries)');
      }

      // Layers should have null grids (point fetch doesn't produce grids)
      for (final field in profile.hourly) {
        for (final layer in field.layers) {
          expect(layer.grid, isNull,
              reason: 'Point fetch layers should not have grid data');
        }
      }

      // Should still return a valid profile
      expect(profile.hourly.length, 3);
    });

    test('grid fetch uses DomeConstants.metersPerRenderUnit (not radiusMeters/domeR)',
        () async {
      // Create a Shyft area (MultiPointSeries) response with a 2x2 grid
      String shyftAreaJson(int steps) {
        final time = DateTime.utc(2026, 2, 27, 12).toIso8601String();
        final times = List.generate(steps, (i) =>
            DateTime.utc(2026, 2, 27, 12 + i).toIso8601String());

        // 2x2 grid of composite points: [lng, lat, pressure]
        // Centered around (37.77N, -122.42E)
        final composites = [
          [-122.5, 37.7, 0],
          [-122.3, 37.7, 0],
          [-122.5, 37.9, 0],
          [-122.3, 37.9, 0],
        ];

        final numPoints = composites.length;
        // All u=5.0, v=3.0 for simplicity
        final uValues = List.generate(
            numPoints * steps, (_) => 5.0);
        final vValues = List.generate(
            numPoints * steps, (_) => 3.0);

        return jsonEncode({
          'domain': {
            'axes': {
              'composite': {'values': composites},
              't': {'values': times},
            },
          },
          'ranges': {
            WindApiConstants.shyftUParam: {'values': uValues},
            WindApiConstants.shyftVParam: {'values': vValues},
          },
        });
      }

      final mockClient = MockClient((request) async {
        final url = request.url.toString();
        // Return area response for area queries, point response for fallbacks
        if (url.contains('/area')) {
          return http.Response(shyftAreaJson(3), 200);
        }
        return http.Response(_shyftSeriesJson(3), 200);
      });

      final apiClient = WindApiClient(client: mockClient);
      final fetcher = DomeWindFetcher(apiClient: apiClient);

      // Fetch with radiusMeters = 50000 (50km) -- triggers grid path
      final profile = await fetcher.fetch(
        37.77,
        -122.42,
        radiusMeters: 50000.0,
      );

      // The DomeWindField.metersPerRenderUnit must match the base rate
      // that the screen uses (55.56), NOT radiusMeters/domeR (2777.78).
      for (final field in profile.hourly) {
        expect(
          field.metersPerRenderUnit,
          closeTo(DomeConstants.metersPerRenderUnit, 0.01),
          reason:
              'Grid fetch should use DomeConstants.metersPerRenderUnit '
              '(${DomeConstants.metersPerRenderUnit.toStringAsFixed(2)}), '
              'not radiusMeters/domeR '
              '(${(50000.0 / DomeConstants.domeR).toStringAsFixed(2)})',
        );
      }
    });
  });
}
