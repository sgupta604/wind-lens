import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:wind_lens/services/wind/wind_api_client.dart';
import 'package:wind_lens/services/wind/wind_api_constants.dart';

void main() {
  group('WindApiClient.fetchPointWindSeries()', () {
    /// Helper to create a Shyft time-series response JSON for a given
    /// number of timesteps.
    String _shyftSeriesJson(int steps) {
      final times = List.generate(
        steps,
        (i) => DateTime.utc(2026, 2, 27, 12 + i).toIso8601String(),
      );
      final uValues = List.generate(steps, (i) => 2.0 + i * 0.5);
      final vValues = List.generate(steps, (i) => 1.0 + i * 0.3);

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

    /// Helper to create a Folkweather time-series response JSON.
    String _folkSeriesJson(int steps) {
      final times = List.generate(
        steps,
        (i) => DateTime.utc(2026, 2, 27, 12 + i).toIso8601String(),
      );
      final uValues = List.generate(steps, (i) => 3.0 + i * 0.4);
      final vValues = List.generate(steps, (i) => 2.0 + i * 0.2);

      return jsonEncode({
        'domain': {
          'axes': {
            't': {'values': times}
          }
        },
        'ranges': {
          WindApiConstants.folkUParam: {'values': uValues},
          WindApiConstants.folkVParam: {'values': vValues},
        }
      });
    }

    test('Shyft time-series response parses correctly (3 timesteps)', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.host, contains('shyft'));
        return http.Response(_shyftSeriesJson(3), 200);
      });

      final client = WindApiClient(client: mockClient);
      final results = await client.fetchPointWindSeries(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 850,
        hours: 72,
      );

      expect(results.length, 3);
      expect(results[0].u, 2.0);
      expect(results[0].v, 1.0);
      expect(results[1].u, 2.5);
      expect(results[2].u, 3.0);
    });

    test('Folkweather time-series response parses correctly (3 timesteps)',
        () async {
      // Shyft fails, Folkweather succeeds
      final mockClient = MockClient((request) async {
        if (request.url.host.contains('shyft')) {
          return http.Response('error', 500);
        }
        return http.Response(_folkSeriesJson(3), 200);
      });

      final client = WindApiClient(client: mockClient);
      final results = await client.fetchPointWindSeries(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 850,
        hours: 72,
      );

      expect(results.length, 3);
      expect(results[0].u, 3.0);
      expect(results[0].v, 2.0);
    });

    test('Shyft failure falls back to Folkweather (time-series)', () async {
      int shyftCalls = 0;
      int folkCalls = 0;

      final mockClient = MockClient((request) async {
        if (request.url.host.contains('shyft')) {
          shyftCalls++;
          return http.Response('error', 500);
        }
        folkCalls++;
        return http.Response(_folkSeriesJson(3), 200);
      });

      final client = WindApiClient(client: mockClient);
      final results = await client.fetchPointWindSeries(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 850,
      );

      expect(shyftCalls, 1);
      expect(folkCalls, 1);
      expect(results.length, 3);
    });

    test('Both APIs fail returns empty list', () async {
      final mockClient = MockClient((request) async {
        return http.Response('error', 500);
      });

      final client = WindApiClient(client: mockClient);
      final results = await client.fetchPointWindSeries(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 850,
      );

      expect(results, isEmpty);
    });

    test('surface collection used when pressureLevel=0', () async {
      String? capturedUrl;
      final mockClient = MockClient((request) async {
        capturedUrl = request.url.toString();
        return http.Response(_shyftSeriesJson(1), 200);
      });

      final client = WindApiClient(client: mockClient);
      await client.fetchPointWindSeries(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 0,
      );

      expect(capturedUrl, contains(WindApiConstants.shyftSurfaceCollection));
      expect(capturedUrl, isNot(contains('z=')));
    });

    test('isobaric collection used when pressureLevel=850', () async {
      String? capturedUrl;
      final mockClient = MockClient((request) async {
        capturedUrl = request.url.toString();
        return http.Response(_shyftSeriesJson(1), 200);
      });

      final client = WindApiClient(client: mockClient);
      await client.fetchPointWindSeries(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 850,
      );

      expect(capturedUrl, contains(WindApiConstants.shyftIsobaricCollection));
      expect(capturedUrl, contains('z=850'));
    });

    test('response with 72 timesteps parses all entries', () async {
      final mockClient = MockClient((request) async {
        return http.Response(_shyftSeriesJson(72), 200);
      });

      final client = WindApiClient(client: mockClient);
      final results = await client.fetchPointWindSeries(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 850,
      );

      expect(results.length, 72);
      // Verify first and last entries
      expect(results.first.u, 2.0);
      expect(results.last.u, closeTo(2.0 + 71 * 0.5, 0.01));
    });

    test('mismatched u/v array lengths handled gracefully', () async {
      // Create response where U has 5 entries but V has 3
      final times = List.generate(
        5,
        (i) => DateTime.utc(2026, 2, 27, 12 + i).toIso8601String(),
      );

      final json = jsonEncode({
        'coverages': [
          {
            'domain': {
              'axes': {
                't': {'values': times}
              }
            },
            'ranges': {
              WindApiConstants.shyftUParam: {
                'values': [1.0, 2.0, 3.0, 4.0, 5.0]
              }
            }
          },
          {
            'domain': {
              'axes': {
                't': {'values': times}
              }
            },
            'ranges': {
              WindApiConstants.shyftVParam: {
                'values': [0.5, 1.5, 2.5]
              }
            }
          },
        ]
      });

      final mockClient = MockClient((request) async {
        return http.Response(json, 200);
      });

      final client = WindApiClient(client: mockClient);
      final results = await client.fetchPointWindSeries(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 850,
      );

      // Should use the shortest length (3)
      expect(results.length, 3);
    });

    test('null values in response replaced with 0.0', () async {
      final times = [
        DateTime.utc(2026, 2, 27, 12).toIso8601String(),
        DateTime.utc(2026, 2, 27, 13).toIso8601String(),
      ];

      final json = jsonEncode({
        'coverages': [
          {
            'domain': {
              'axes': {
                't': {'values': times}
              }
            },
            'ranges': {
              WindApiConstants.shyftUParam: {
                'values': [null, 5.0]
              }
            }
          },
          {
            'domain': {
              'axes': {
                't': {'values': times}
              }
            },
            'ranges': {
              WindApiConstants.shyftVParam: {
                'values': [3.0, null]
              }
            }
          },
        ]
      });

      final mockClient = MockClient((request) async {
        return http.Response(json, 200);
      });

      final client = WindApiClient(client: mockClient);
      final results = await client.fetchPointWindSeries(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 0,
      );

      expect(results.length, 2);
      expect(results[0].u, 0.0); // null replaced with 0.0
      expect(results[0].v, 3.0);
      expect(results[1].u, 5.0);
      expect(results[1].v, 0.0); // null replaced with 0.0
    });

    test('datetime parameter contains ISO 8601 range format', () async {
      String? capturedDatetime;
      final mockClient = MockClient((request) async {
        capturedDatetime = request.url.queryParameters['datetime'];
        return http.Response(_shyftSeriesJson(1), 200);
      });

      final client = WindApiClient(client: mockClient);
      await client.fetchPointWindSeries(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 850,
      );

      expect(capturedDatetime, isNotNull);
      // Should be in format "start/end" with ISO dates
      expect(capturedDatetime, contains('/'));
      final parts = capturedDatetime!.split('/');
      expect(parts.length, 2);
      // Both parts should end with Z
      expect(parts[0], endsWith('Z'));
      expect(parts[1], endsWith('Z'));
    });
  });
}
