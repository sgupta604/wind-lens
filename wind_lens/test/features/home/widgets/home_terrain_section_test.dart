import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/core/models/horizon_profile.dart';
import 'package:wind_lens/features/home/widgets/home_terrain_section.dart';

void main() {
  group('HomeTerrainPainter', () {
    final timestamp = DateTime(2026, 3, 4, 12, 0, 0);

    test('shouldRepaint returns true when profile changes', () {
      final profileA = HorizonProfile(
        latitude: 47.6,
        longitude: -122.3,
        elevationAngles: {0.0: 5.0, 90.0: 10.0},
        fetchedAt: timestamp,
      );
      final profileB = HorizonProfile(
        latitude: 47.6,
        longitude: -122.3,
        elevationAngles: {0.0: 8.0, 90.0: 12.0},
        fetchedAt: timestamp,
      );

      final painterA = HomeTerrainPainter(profile: profileA);
      final painterB = HomeTerrainPainter(profile: profileB);

      // painterA.shouldRepaint(painterB) checks if painterA needs to
      // repaint given that the old delegate was painterB.
      expect(painterA.shouldRepaint(painterB), isTrue);
    });

    test('shouldRepaint returns false when profile is same reference', () {
      final profile = HorizonProfile(
        latitude: 47.6,
        longitude: -122.3,
        elevationAngles: {0.0: 5.0, 90.0: 10.0},
        fetchedAt: timestamp,
      );

      final painterA = HomeTerrainPainter(profile: profile);
      final painterB = HomeTerrainPainter(profile: profile);

      // Same profile reference -- no need to repaint.
      expect(painterA.shouldRepaint(painterB), isFalse);
    });

    test('shouldRepaint returns true when null vs non-null', () {
      final profile = HorizonProfile(
        latitude: 47.6,
        longitude: -122.3,
        elevationAngles: {0.0: 5.0},
        fetchedAt: timestamp,
      );

      final painterWithProfile = HomeTerrainPainter(profile: profile);
      final painterWithoutProfile = HomeTerrainPainter();

      // null -> non-null: should repaint.
      expect(painterWithProfile.shouldRepaint(painterWithoutProfile), isTrue);

      // non-null -> null: should repaint.
      expect(painterWithoutProfile.shouldRepaint(painterWithProfile), isTrue);
    });
  });
}
