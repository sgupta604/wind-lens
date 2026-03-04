import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wind_lens/services/wind/wind_api_client.dart';

// ═══════════════════════════════════════════════════════════════
//  Canned API Responses
// ═══════════════════════════════════════════════════════════════

/// Shyft position response: CoverageCollection with separate U/V coverages.
String shyftPositionJson({double u = 3.97, double v = 1.18}) => jsonEncode({
      'type': 'CoverageCollection',
      'coverages': [
        {
          'type': 'Coverage',
          'domain': {
            'axes': {
              't': {
                'values': ['2026-02-25T18:00:00Z']
              },
              'x': {
                'values': [-122.4194]
              },
              'y': {
                'values': [37.7749]
              },
              'z': {
                'values': [850.0]
              },
            },
          },
          'ranges': {
            'u-component-of-wind': {
              'values': [u],
            },
          },
        },
        {
          'type': 'Coverage',
          'domain': {
            'axes': {
              't': {
                'values': ['2026-02-25T18:00:00Z']
              },
              'x': {
                'values': [-122.4194]
              },
              'y': {
                'values': [37.7749]
              },
              'z': {
                'values': [850.0]
              },
            },
          },
          'ranges': {
            'v-component-of-wind': {
              'values': [v],
            },
          },
        },
      ],
    });

/// Folkweather position response: single Coverage with UGRD/VGRD.
String folkPositionJson({double u = 1.65, double v = -3.47}) => jsonEncode({
      'type': 'Coverage',
      'domain': {
        'axes': {
          'x': {
            'values': [237.5806]
          },
          'y': {
            'values': [37.7749]
          },
          'z': {
            'values': [850.0]
          },
        },
      },
      'ranges': {
        'UGRD': {
          'values': [u],
        },
        'VGRD': {
          'values': [v],
        },
      },
    });

/// Shyft area response: MultiPointSeries with composite axis.
String shyftAreaJson() => jsonEncode({
      'type': 'Coverage',
      'domain': {
        'axes': {
          'composite': {
            'values': [
              [-122.75, 37.5, 850.0],
              [-122.5, 37.5, 850.0],
              [-122.75, 37.75, 850.0],
              [-122.5, 37.75, 850.0],
            ],
          },
          't': {
            'values': ['2026-02-25T18:00:00Z']
          },
        },
      },
      'ranges': {
        'u-component-of-wind': {
          'values': [1.0, 2.0, 3.0, 4.0],
        },
        'v-component-of-wind': {
          'values': [5.0, 6.0, 7.0, 8.0],
        },
      },
    });

/// Folkweather area response: standard x/y axes with 0-360 longitude.
String folkAreaJson() => jsonEncode({
      'type': 'Coverage',
      'domain': {
        'axes': {
          'x': {
            'values': [237.25, 237.5]
          },
          'y': {
            'values': [37.5, 37.75]
          },
          'z': {
            'values': [850.0]
          },
        },
      },
      'ranges': {
        'UGRD': {
          'values': [1.0, 2.0, 3.0, 4.0],
        },
        'VGRD': {
          'values': [5.0, 6.0, 7.0, 8.0],
        },
      },
    });

// ═══════════════════════════════════════════════════════════════
//  Tests
// ═══════════════════════════════════════════════════════════════

void main() {
  group('WindApiClient fetchPointWind', () {
    test('Shyft success parses U/V from CoverageCollection', () async {
      final client = WindApiClient(
        client: MockClient((request) async {
          if (request.url.host == 'ogc.shyftwx.com') {
            return http.Response(shyftPositionJson(), 200);
          }
          return http.Response('', 500);
        }),
      );

      final (u, v, source) = await client.fetchPointWind(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 850,
      );

      expect(u, closeTo(3.97, 0.01));
      expect(v, closeTo(1.18, 0.01));
      expect(source, 'shyft');
    });

    test('Shyft surface uses GFS_height-above-ground_10 collection', () async {
      String? capturedUrl;
      final client = WindApiClient(
        client: MockClient((request) async {
          capturedUrl = request.url.toString();
          return http.Response(shyftPositionJson(), 200);
        }),
      );

      await client.fetchPointWind(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 0,
      );

      expect(capturedUrl, contains('GFS_height-above-ground_10'));
      expect(capturedUrl, isNot(contains('z=')));
    });

    test('Shyft isobaric 850 uses GFS_isobaric with z=850', () async {
      String? capturedUrl;
      final client = WindApiClient(
        client: MockClient((request) async {
          capturedUrl = request.url.toString();
          return http.Response(shyftPositionJson(), 200);
        }),
      );

      await client.fetchPointWind(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 850,
      );

      expect(capturedUrl, contains('GFS_isobaric'));
      expect(capturedUrl, contains('z=850'));
    });

    test('Shyft isobaric 300 uses GFS_isobaric with z=300', () async {
      String? capturedUrl;
      final client = WindApiClient(
        client: MockClient((request) async {
          capturedUrl = request.url.toString();
          return http.Response(shyftPositionJson(), 200);
        }),
      );

      await client.fetchPointWind(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 300,
      );

      expect(capturedUrl, contains('GFS_isobaric'));
      expect(capturedUrl, contains('z=300'));
    });

    test('Shyft URL includes datetime parameter', () async {
      String? capturedUrl;
      final client = WindApiClient(
        client: MockClient((request) async {
          capturedUrl = request.url.toString();
          return http.Response(shyftPositionJson(), 200);
        }),
      );

      await client.fetchPointWind(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 850,
      );

      expect(capturedUrl, contains('datetime='));
    });

    test('Shyft fail (500) falls back to Folkweather', () async {
      final client = WindApiClient(
        client: MockClient((request) async {
          if (request.url.host == 'ogc.shyftwx.com') {
            return http.Response('Server error', 500);
          }
          return http.Response(folkPositionJson(), 200);
        }),
      );

      final (u, v, source) = await client.fetchPointWind(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 850,
      );

      expect(u, closeTo(1.65, 0.01));
      expect(v, closeTo(-3.47, 0.01));
      expect(source, 'folkweather');
    });

    test('Folkweather success parses UGRD/VGRD', () async {
      final client = WindApiClient(
        client: MockClient((request) async {
          if (request.url.host == 'ogc.shyftwx.com') {
            return http.Response('Server error', 500);
          }
          return http.Response(folkPositionJson(u: 5.0, v: -2.0), 200);
        }),
      );

      final (u, v, source) = await client.fetchPointWind(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 850,
      );

      expect(u, closeTo(5.0, 0.01));
      expect(v, closeTo(-2.0, 0.01));
      expect(source, 'folkweather');
    });

    test('Folkweather 850 routes to hrrr-isobaric', () async {
      String? capturedUrl;
      final client = WindApiClient(
        client: MockClient((request) async {
          if (request.url.host == 'ogc.shyftwx.com') {
            return http.Response('Server error', 500);
          }
          capturedUrl = request.url.toString();
          return http.Response(folkPositionJson(), 200);
        }),
      );

      await client.fetchPointWind(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 850,
      );

      expect(capturedUrl, contains('hrrr-isobaric'));
    });

    test('Folkweather 300 routes to hrrr-isobaric', () async {
      String? capturedUrl;
      final client = WindApiClient(
        client: MockClient((request) async {
          if (request.url.host == 'ogc.shyftwx.com') {
            return http.Response('Server error', 500);
          }
          capturedUrl = request.url.toString();
          return http.Response(folkPositionJson(), 200);
        }),
      );

      await client.fetchPointWind(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 300,
      );

      expect(capturedUrl, contains('hrrr-isobaric'));
    });

    test('Folkweather surface routes to hrrr-height-agl with z=10', () async {
      String? capturedUrl;
      final client = WindApiClient(
        client: MockClient((request) async {
          if (request.url.host == 'ogc.shyftwx.com') {
            return http.Response('Server error', 500);
          }
          capturedUrl = request.url.toString();
          return http.Response(folkPositionJson(), 200);
        }),
      );

      await client.fetchPointWind(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 0,
      );

      expect(capturedUrl, contains('hrrr-height-agl'));
      expect(capturedUrl, contains('z=10'));
    });

    test('both APIs fail returns (0, 0)', () async {
      final client = WindApiClient(
        client: MockClient((request) async {
          return http.Response('Server error', 500);
        }),
      );

      final (u, v, source) = await client.fetchPointWind(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 850,
      );

      expect(u, 0.0);
      expect(v, 0.0);
      expect(source, 'none');
    });

    test('Shyft malformed JSON (missing coverages key) falls back to Folkweather', () async {
      final client = WindApiClient(
        client: MockClient((request) async {
          if (request.url.host == 'ogc.shyftwx.com') {
            return http.Response(jsonEncode({'type': 'invalid'}), 200);
          }
          return http.Response(folkPositionJson(), 200);
        }),
      );

      final (u, v, source) = await client.fetchPointWind(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 850,
      );

      expect(u, closeTo(1.65, 0.01));
      expect(v, closeTo(-3.47, 0.01));
      expect(source, 'folkweather');
    });

    test('Folkweather malformed JSON (missing UGRD key) returns (0, 0)', () async {
      final client = WindApiClient(
        client: MockClient((request) async {
          if (request.url.host == 'ogc.shyftwx.com') {
            return http.Response('Server error', 500);
          }
          return http.Response(
            jsonEncode({'type': 'Coverage', 'ranges': {}}),
            200,
          );
        }),
      );

      final (u, v, source) = await client.fetchPointWind(
        lat: 37.7749,
        lng: -122.4194,
        pressureLevel: 850,
      );

      expect(u, 0.0);
      expect(v, 0.0);
      expect(source, 'none');
    });
  });

  group('WindApiClient fetchWindGridSeries', () {
    /// Creates a Shyft area time-series response with multiple timesteps.
    ///
    /// Each timestep has a 2x2 grid of points.
    String shyftAreaSeriesJson(int steps) {
      final times = List.generate(
        steps,
        (i) => DateTime.utc(2026, 2, 27, 12 + i).toIso8601String(),
      );
      // 4 composite points x N timesteps = 4*N values
      final uValues = List.generate(4 * steps, (i) => 1.0 + i * 0.1);
      final vValues = List.generate(4 * steps, (i) => 5.0 + i * 0.1);

      return jsonEncode({
        'type': 'Coverage',
        'domain': {
          'axes': {
            'composite': {
              'values': [
                [-122.75, 37.5, 850.0],
                [-122.5, 37.5, 850.0],
                [-122.75, 37.75, 850.0],
                [-122.5, 37.75, 850.0],
              ],
            },
            't': {'values': times},
          },
        },
        'ranges': {
          'u-component-of-wind': {'values': uValues},
          'v-component-of-wind': {'values': vValues},
        },
      });
    }

    /// Creates a Folkweather area time-series response with multiple timesteps.
    String folkAreaSeriesJson(int steps) {
      final times = List.generate(
        steps,
        (i) => DateTime.utc(2026, 2, 27, 12 + i).toIso8601String(),
      );
      // 4 grid points x N timesteps = 4*N values
      final uValues = List.generate(4 * steps, (i) => 2.0 + i * 0.1);
      final vValues = List.generate(4 * steps, (i) => 6.0 + i * 0.1);

      return jsonEncode({
        'type': 'Coverage',
        'domain': {
          'axes': {
            'x': {'values': [237.25, 237.5]},
            'y': {'values': [37.5, 37.75]},
            'z': {'values': [850.0]},
            't': {'values': times},
          },
        },
        'ranges': {
          'UGRD': {'values': uValues},
          'VGRD': {'values': vValues},
        },
      });
    }

    test('Shyft time-series area: parses multiple timesteps into list of (DateTime, WindField)', () async {
      final client = WindApiClient(
        client: MockClient((request) async {
          if (request.url.host == 'ogc.shyftwx.com') {
            return http.Response(shyftAreaSeriesJson(3), 200);
          }
          return http.Response('', 500);
        }),
      );

      final results = await client.fetchWindGridSeries(
        lat: 37.625,
        lng: -122.625,
        radiusKm: 15,
        pressureLevel: 850,
      );

      expect(results.length, 3);
      // Each result should have a time and a grid
      for (final result in results) {
        expect(result.grid.width, 2);
        expect(result.grid.height, 2);
      }
    });

    test('Shyft fails, Folkweather time-series succeeds', () async {
      final client = WindApiClient(
        client: MockClient((request) async {
          if (request.url.host == 'ogc.shyftwx.com') {
            return http.Response('Server error', 500);
          }
          // Folkweather
          return http.Response(folkAreaSeriesJson(3), 200);
        }),
      );

      final results = await client.fetchWindGridSeries(
        lat: 37.625,
        lng: -122.625,
        radiusKm: 15,
        pressureLevel: 850,
      );

      expect(results.length, 3);
      for (final result in results) {
        expect(result.grid.width, 2);
        expect(result.grid.height, 2);
      }
    });

    test('both time-series fail, falls back to single-timestep via fetchWindGrid()', () async {
      final client = WindApiClient(
        client: MockClient((request) async {
          final url = request.url.toString();
          // Time-series area queries fail (they include datetime range)
          if (url.contains('datetime=') && url.contains('/')) {
            // Heuristic: range has '/' separator
            if (url.contains('area')) {
              return http.Response('Server error', 500);
            }
          }
          // Single-timestep area succeeds
          if (url.contains('area')) {
            if (request.url.host == 'ogc.shyftwx.com') {
              return http.Response(shyftAreaJson(), 200);
            }
            return http.Response(folkAreaJson(), 200);
          }
          return http.Response('', 500);
        }),
      );

      final results = await client.fetchWindGridSeries(
        lat: 37.625,
        lng: -122.625,
        radiusKm: 15,
        pressureLevel: 850,
      );

      // Should have exactly 1 result from single-timestep fallback
      expect(results.length, 1);
      expect(results[0].grid.width, 2);
      expect(results[0].grid.height, 2);
    });

    test('both APIs fail entirely: throws', () async {
      final client = WindApiClient(
        client: MockClient((request) async {
          return http.Response('Server error', 500);
        }),
      );

      expect(
        () => client.fetchWindGridSeries(
          lat: 37.625,
          lng: -122.625,
          radiusKm: 15,
          pressureLevel: 850,
        ),
        throwsException,
      );
    });

    test('URL includes datetime range and POLYGON coords', () async {
      final capturedUrls = <String>[];
      final client = WindApiClient(
        client: MockClient((request) async {
          capturedUrls.add(request.url.toString());
          if (request.url.host == 'ogc.shyftwx.com') {
            return http.Response(shyftAreaSeriesJson(3), 200);
          }
          return http.Response('', 500);
        }),
      );

      await client.fetchWindGridSeries(
        lat: 37.625,
        lng: -122.625,
        radiusKm: 15,
        pressureLevel: 850,
      );

      // Should have made at least one request
      expect(capturedUrls, isNotEmpty);
      final url = capturedUrls.first;
      // URL should contain area endpoint
      expect(url, contains('/area'));
      // URL should contain datetime range (ISO format with '/')
      expect(url, contains('datetime='));
      // URL should contain POLYGON coords
      expect(url, contains('POLYGON'));
    });
  });

  group('WindApiClient fetchWindGrid', () {
    test('Shyft parses MultiPointSeries composite into WindField', () async {
      final client = WindApiClient(
        client: MockClient((request) async {
          if (request.url.host == 'ogc.shyftwx.com') {
            return http.Response(shyftAreaJson(), 200);
          }
          return http.Response('', 500);
        }),
      );

      final field = await client.fetchWindGrid(
        lat: 37.625,
        lng: -122.625,
        radiusKm: 40,
        pressureLevel: 850,
      );

      expect(field.width, 2); // [-122.75, -122.5]
      expect(field.height, 2); // [37.5, 37.75]
      expect(field.source, contains('Shyft'));
      // Verify values are placed correctly in row-major order
      // Row 0 (lat=37.5):  col 0 (lng=-122.75): u=1, col 1 (lng=-122.5): u=2
      // Row 1 (lat=37.75): col 0 (lng=-122.75): u=3, col 1 (lng=-122.5): u=4
      expect(field.getAt(0, 0).u, 1.0);
      expect(field.getAt(0, 1).u, 2.0);
      expect(field.getAt(1, 0).u, 3.0);
      expect(field.getAt(1, 1).u, 4.0);
    });

    test('Folkweather parses x/y axes into WindField with longitude normalization', () async {
      final client = WindApiClient(
        client: MockClient((request) async {
          if (request.url.host == 'ogc.shyftwx.com') {
            return http.Response('Server error', 500);
          }
          return http.Response(folkAreaJson(), 200);
        }),
      );

      final field = await client.fetchWindGrid(
        lat: 37.625,
        lng: -122.625,
        radiusKm: 40,
        pressureLevel: 850,
      );

      expect(field.width, 2);
      expect(field.height, 2);
      expect(field.source, contains('Folkweather'));
      // Check longitude normalization: 237.25 -> -122.75, 237.5 -> -122.5
      expect(field.xs[0], closeTo(-122.75, 0.01));
      expect(field.xs[1], closeTo(-122.5, 0.01));
    });
  });
}
