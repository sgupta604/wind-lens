import 'package:flutter_test/flutter_test.dart';

import 'package:wind_lens/features/wind_dome/models/dome_wind_field.dart';
import 'package:wind_lens/features/wind_dome/models/dome_wind_layer.dart';
import 'package:wind_lens/features/wind_dome/models/dome_wind_profile.dart';

void main() {
  group('DomeWindProfile', () {
    late DomeWindProfile profile;
    final baseTime = DateTime.utc(2026, 2, 27, 12);

    DomeWindField _makeField(int hourOffset, double u, double v) {
      return DomeWindField(
        validTime: baseTime.add(Duration(hours: hourOffset)),
        layers: [
          DomeWindLayer(altitudeMeters: 10, u: u, v: v),
          DomeWindLayer(altitudeMeters: 1500, u: u * 2, v: v * 2),
          DomeWindLayer(altitudeMeters: 3000, u: u * 3, v: v * 3),
        ],
      );
    }

    setUp(() {
      // Create a 72-hour profile
      profile = DomeWindProfile(
        hourly: List.generate(72, (i) => _makeField(i, i * 1.0, i * 0.5)),
        fetchedAt: baseTime,
        lat: 37.7749,
        lng: -122.4194,
      );
    });

    test('fieldAt(0) returns first hourly entry', () {
      final field = profile.fieldAt(0);
      expect(field.validTime, baseTime);
      expect(field.layers[0].u, 0.0);
    });

    test('fieldAt(71) returns last hourly entry', () {
      final field = profile.fieldAt(71);
      expect(field.validTime, baseTime.add(const Duration(hours: 71)));
      expect(field.layers[0].u, 71.0);
    });

    test('fieldAt(-1) clamps to 0', () {
      final field = profile.fieldAt(-1);
      expect(field.validTime, baseTime);
      expect(field.layers[0].u, 0.0);
    });

    test('fieldAt(100) clamps to last index', () {
      final field = profile.fieldAt(100);
      expect(field.validTime, baseTime.add(const Duration(hours: 71)));
      expect(field.layers[0].u, 71.0);
    });

    test('fieldAt() on single-entry hourly always returns that entry', () {
      final singleProfile = DomeWindProfile(
        hourly: [_makeField(0, 5.0, 3.0)],
        fetchedAt: baseTime,
        lat: 37.7749,
        lng: -122.4194,
      );
      expect(singleProfile.fieldAt(0).layers[0].u, 5.0);
      expect(singleProfile.fieldAt(10).layers[0].u, 5.0);
      expect(singleProfile.fieldAt(-5).layers[0].u, 5.0);
    });

    test('fieldAt() returns zero-wind field when hourly is empty', () {
      final emptyProfile = DomeWindProfile(
        hourly: [],
        fetchedAt: baseTime,
        lat: 37.7749,
        lng: -122.4194,
      );
      final field = emptyProfile.fieldAt(0);
      expect(field.layers.length, 3);
      expect(field.layers[0].u, 0.0);
    });

    test('fieldAt selects correct intermediate hour', () {
      final field = profile.fieldAt(36);
      expect(field.validTime, baseTime.add(const Duration(hours: 36)));
      expect(field.layers[0].u, 36.0);
      expect(field.layers[0].v, 18.0);
    });
  });
}
