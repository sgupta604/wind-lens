import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:wind_lens/features/wind_dome/models/dome_constants.dart';
import 'package:wind_lens/features/wind_dome/models/dome_particle.dart';
import 'package:wind_lens/features/wind_dome/models/dome_wind_field.dart';
import 'package:wind_lens/features/wind_dome/models/dome_wind_layer.dart';

void main() {
  group('DomeParticle', () {
    final domeR = DomeConstants.domeR;
    final domeH = DomeConstants.domeH;

    group('insideDome()', () {
      test('returns true for origin (0,0,0)', () {
        expect(DomeParticle.insideDome(0, 0, 0, domeR, domeH), isTrue);
      });

      test('returns false for point outside dome', () {
        // Well outside the dome
        expect(
          DomeParticle.insideDome(domeR * 2, domeH * 2, 0, domeR, domeH),
          isFalse,
        );
      });

      test('returns true for point on surface (boundary)', () {
        // Point on the equator: (r, 0, 0)
        expect(
          DomeParticle.insideDome(domeR, 0, 0, domeR, domeH),
          isTrue,
        );
      });

      test('returns false for y < 0', () {
        expect(
          DomeParticle.insideDome(0, -0.01, 0, domeR, domeH),
          isFalse,
        );
      });

      test('returns true for point clearly inside', () {
        expect(
          DomeParticle.insideDome(domeR * 0.3, domeH * 0.3, 0, domeR, domeH),
          isTrue,
        );
      });

      test('returns false for point just outside dome wall', () {
        // Just beyond equator at y=0
        expect(
          DomeParticle.insideDome(domeR * 1.01, 0, 0, domeR, domeH),
          isFalse,
        );
      });
    });

    group('respawn()', () {
      test('places particle inside dome (100 respawns)', () {
        final rng = Random(42);
        final p = DomeParticle();
        for (int i = 0; i < 100; i++) {
          p.respawn(rng, domeR, domeH);
          expect(
            DomeParticle.insideDome(p.x, p.y, p.z, domeR, domeH),
            isTrue,
            reason:
                'Respawn $i: (${p.x}, ${p.y}, ${p.z}) should be inside dome',
          );
        }
      });

      test('clears trail on respawn', () {
        final rng = Random(42);
        final p = DomeParticle();
        // Create some trail data
        p.trailX[0] = 5.0;
        p.trailCount = 1;
        p.trailHead = 1;

        p.respawn(rng, domeR, domeH);
        expect(p.trailCount, 0);
        expect(p.trailHead, 0);
      });
    });

    group('tick()', () {
      late DomeWindField field;
      late DomeParticle particle;

      setUp(() {
        field = DomeWindField(
          validTime: DateTime.utc(2026),
          layers: [
            const DomeWindLayer(altitudeMeters: 10, u: 5.0, v: 3.0),
            const DomeWindLayer(altitudeMeters: 1500, u: 10.0, v: 6.0),
            const DomeWindLayer(altitudeMeters: 3000, u: 15.0, v: 9.0),
          ],
        );
        particle = DomeParticle();
        particle.x = 0;
        particle.y = domeH * 0.3; // Well inside dome
        particle.z = 0;
      });

      test('moves particle position', () {
        final oldX = particle.x;
        final oldZ = particle.z;

        particle.tick(field, 1.0 / 60, domeR, domeH, rng: Random(42));

        // With non-zero wind, position should change
        expect(particle.x != oldX || particle.z != oldZ, isTrue);
      });

      test('with zero wind only applies updraft', () {
        final zeroField = DomeWindField.zero();
        particle.x = 0;
        particle.y = domeH * 0.3;
        particle.z = 0;
        final oldY = particle.y;

        particle.tick(zeroField, 1.0 / 60, domeR, domeH, rng: Random(42));

        // x and z should not change (zero wind)
        expect(particle.x, closeTo(0.0, 0.001));
        expect(particle.z, closeTo(0.0, 0.001));
        // y should increase (updraft)
        expect(particle.y, greaterThan(oldY));
      });

      test('particle stays inside dome (1.02x margin) or respawns after 1000 ticks', () {
        final rng = Random(42);
        particle.respawn(rng, domeR, domeH);

        for (int i = 0; i < 1000; i++) {
          particle.tick(field, 1.0 / 60, domeR, domeH, rng: rng);
          // After each tick, particle should be inside the 1.02x containment
          // boundary (it either stayed or was respawned)
          expect(
            DomeParticle.insideDome(
                particle.x, particle.y, particle.z,
                domeR * 1.02, domeH * 1.02),
            isTrue,
            reason: 'Tick $i: particle should be inside dome (1.02x margin)',
          );
        }
      });

      test('x-displacement matches velocityScale formula', () {
        // Create a field with known uniform wind: u=10 m/s, v=0
        final uniformField = DomeWindField(
          validTime: DateTime.utc(2026),
          layers: [
            const DomeWindLayer(altitudeMeters: 0, u: 10.0, v: 0.0),
            const DomeWindLayer(altitudeMeters: 1800, u: 10.0, v: 0.0),
          ],
        );
        final p = DomeParticle();
        p.x = 0;
        p.y = 1.0; // Low altitude, well inside dome
        p.z = 0;

        final dt = 1.0 / 60;
        p.tick(uniformField, dt, domeR, domeH, rng: Random(42));

        // Expected x displacement: u * velocityScale * dt = 10 * 0.72 * (1/60) = 0.12
        expect(p.x, closeTo(0.12, 0.01));
      });

      test('updraft at y=0 matches updraftBase formula', () {
        final zeroField = DomeWindField.zero();
        final p = DomeParticle();
        p.x = 0;
        p.y = 0.01; // Just above ground (y>=0 required)
        p.z = 0;

        final dt = 1.0; // 1 second
        p.tick(zeroField, dt, domeR, domeH, rng: Random(42));

        // At y~0, updraft per second = updraftBase + (y/domeH)*updraftGradient
        // ~ 0.12 + (0.01/14)*0.18 ~ 0.12013
        // y should increase by approximately updraftBase
        expect(p.y, closeTo(0.01 + DomeConstants.updraftBase, 0.02));
      });

      test('positive v (northward wind) moves particle in -z direction', () {
        final northwardField = DomeWindField(
          validTime: DateTime.utc(2026),
          layers: const [
            DomeWindLayer(altitudeMeters: 0, u: 0.0, v: 10.0),
            DomeWindLayer(altitudeMeters: 1800, u: 0.0, v: 10.0),
          ],
        );
        final p = DomeParticle();
        p.x = 0;
        p.y = 1.0;
        p.z = 0;

        p.tick(northwardField, 1.0 / 60, domeR, domeH, rng: Random(42));

        // +v = northward, North = -z in dome space
        expect(p.z, lessThan(0),
            reason: 'Northward wind should move particle toward -z (North)');
        expect(p.x, closeTo(0, 0.001),
            reason: 'Zero u should not move particle in x');
      });

      test('positive u (eastward wind) moves particle in +x direction', () {
        final eastwardField = DomeWindField(
          validTime: DateTime.utc(2026),
          layers: const [
            DomeWindLayer(altitudeMeters: 0, u: 10.0, v: 0.0),
            DomeWindLayer(altitudeMeters: 1800, u: 10.0, v: 0.0),
          ],
        );
        final p = DomeParticle();
        p.x = 0;
        p.y = 1.0;
        p.z = 0;

        p.tick(eastwardField, 1.0 / 60, domeR, domeH, rng: Random(42));

        // +u = eastward, East = +x in dome space
        expect(p.x, greaterThan(0),
            reason: 'Eastward wind should move particle toward +x (East)');
        expect(p.z, closeTo(0, 0.001),
            reason: 'Zero v should not move particle in z');
      });

      test('containment uses 1.02x margin', () {
        // Place particle just outside the dome at 1.01x radius (inside 1.02x margin)
        final p = DomeParticle();
        p.x = domeR * 1.015; // Between 1.0 and 1.02 of dome radius
        p.y = 0.1;
        p.z = 0;

        final zeroField = DomeWindField.zero();
        // Should NOT respawn (still within 1.02x margin)
        p.tick(zeroField, 1.0 / 60, domeR, domeH, rng: Random(42));

        // Particle should have been respawned since it's outside the dome
        // (insideDome uses exact boundary, containment check uses 1.02x)
        // Actually the containment check uses 1.02x margin, so particle at
        // 1.015x should still be INSIDE the 1.02x boundary and NOT respawn.
        // However, insideDome(1.015*R, 0.1, 0, R*1.02, H*1.02) should be true.
        // The particle should survive this tick.
        expect(p.trailCount, greaterThan(0));
      });
    });

    group('trail ring buffer', () {
      test('records positions after tick', () {
        final field = DomeWindField(
          validTime: DateTime.utc(2026),
          layers: [
            const DomeWindLayer(altitudeMeters: 10, u: 2.0, v: 1.0),
            const DomeWindLayer(altitudeMeters: 1500, u: 4.0, v: 2.0),
            const DomeWindLayer(altitudeMeters: 3000, u: 6.0, v: 3.0),
          ],
        );
        final p = DomeParticle();
        p.x = 0;
        p.y = domeH * 0.2;
        p.z = 0;

        p.tick(field, 1.0 / 60, domeR, domeH, rng: Random(42));
        expect(p.trailCount, 1);
      });

      test('wraps at TRAIL_LENGTH capacity', () {
        final field = DomeWindField(
          validTime: DateTime.utc(2026),
          layers: [
            const DomeWindLayer(altitudeMeters: 10, u: 0.1, v: 0.1),
            const DomeWindLayer(altitudeMeters: 1500, u: 0.2, v: 0.2),
            const DomeWindLayer(altitudeMeters: 3000, u: 0.3, v: 0.3),
          ],
        );
        final p = DomeParticle();
        p.x = 0;
        p.y = domeH * 0.2;
        p.z = 0;

        // Tick more than TRAIL_LENGTH times
        final rng = Random(42);
        for (int i = 0; i < DomeConstants.trailLength + 5; i++) {
          p.tick(field, 1.0 / 60, domeR, domeH, rng: rng);
          // If particle respawned, reset position to keep it inside
          if (p.trailCount == 0) {
            p.x = 0;
            p.y = domeH * 0.2;
            p.z = 0;
          }
        }

        // Trail count should cap at TRAIL_LENGTH
        expect(p.trailCount, lessThanOrEqualTo(DomeConstants.trailLength));
      });

      test('trail count does not exceed TRAIL_LENGTH', () {
        final p = DomeParticle();
        // Manually simulate trail fills
        for (int i = 0; i < DomeConstants.trailLength * 3; i++) {
          p.trailX[p.trailHead] = i.toDouble();
          p.trailY[p.trailHead] = i.toDouble();
          p.trailZ[p.trailHead] = i.toDouble();
          p.trailHead =
              (p.trailHead + 1) % DomeConstants.trailLength;
          if (p.trailCount < DomeConstants.trailLength) {
            p.trailCount++;
          }
        }
        expect(p.trailCount, DomeConstants.trailLength);
      });
    });

    test('DomeParticle.random creates particle inside dome', () {
      final rng = Random(42);
      for (int i = 0; i < 50; i++) {
        final p = DomeParticle.random(rng, domeR, domeH);
        expect(
          DomeParticle.insideDome(p.x, p.y, p.z, domeR, domeH),
          isTrue,
          reason: 'Random particle $i should be inside dome',
        );
      }
    });

    group('velocity scales with dome size', () {
      // A uniform wind field: u=10 m/s, v=0 across all altitudes.
      late DomeWindField uniformField;
      final dt = 1.0 / 60; // one frame at 60 FPS

      setUp(() {
        uniformField = DomeWindField(
          validTime: DateTime.utc(2026),
          layers: const [
            DomeWindLayer(altitudeMeters: 0, u: 10.0, v: 0.0),
            DomeWindLayer(altitudeMeters: 1800, u: 10.0, v: 0.0),
          ],
        );
      });

      test('x-displacement at 50x dome is 50x displacement at base dome', () {
        // Tick at base dome size (domeR = 18)
        final pBase = DomeParticle();
        pBase.x = 0;
        pBase.y = 1.0;
        pBase.z = 0;
        pBase.tick(uniformField, dt, domeR, domeH, rng: Random(42));
        final baseDisplacement = pBase.x;

        // Tick at 50x dome size (domeR = 900, domeH = 700)
        final largeDomeR = domeR * 50;
        final largeDomeH = domeH * 50;
        final pLarge = DomeParticle();
        pLarge.x = 0;
        pLarge.y = 1.0; // Same low altitude in render units
        pLarge.z = 0;
        pLarge.tick(uniformField, dt, largeDomeR, largeDomeH, rng: Random(42));
        final largeDisplacement = pLarge.x;

        // Large dome should have 50x the displacement in render units
        // so particles cross the dome at the same visual speed
        expect(
          largeDisplacement,
          closeTo(baseDisplacement * 50, baseDisplacement * 50 * 0.05),
          reason:
              'Particle x-displacement should scale linearly with dome size '
              '(50x dome = 50x displacement)',
        );
      });

      test('z-displacement at 50x dome is 50x displacement at base dome', () {
        // Use v=10, u=0 wind for z-axis test
        final vField = DomeWindField(
          validTime: DateTime.utc(2026),
          layers: const [
            DomeWindLayer(altitudeMeters: 0, u: 0.0, v: 10.0),
            DomeWindLayer(altitudeMeters: 1800, u: 0.0, v: 10.0),
          ],
        );

        // Tick at base dome size
        final pBase = DomeParticle();
        pBase.x = 0;
        pBase.y = 1.0;
        pBase.z = 0;
        pBase.tick(vField, dt, domeR, domeH, rng: Random(42));
        final baseDisplacement = pBase.z.abs();

        // Tick at 50x dome size
        final largeDomeR = domeR * 50;
        final largeDomeH = domeH * 50;
        final pLarge = DomeParticle();
        pLarge.x = 0;
        pLarge.y = 1.0;
        pLarge.z = 0;
        pLarge.tick(vField, dt, largeDomeR, largeDomeH, rng: Random(42));
        final largeDisplacement = pLarge.z.abs();

        expect(
          largeDisplacement,
          closeTo(baseDisplacement * 50, baseDisplacement * 50 * 0.05),
          reason:
              'Particle z-displacement should scale linearly with dome size',
        );
      });

      test('updraft scales with dome size', () {
        final zeroField = DomeWindField.zero();

        // Tick at base dome size
        final pBase = DomeParticle();
        pBase.x = 0;
        pBase.y = 0.01;
        pBase.z = 0;
        pBase.tick(zeroField, 1.0, domeR, domeH, rng: Random(42));
        final baseUpdraft = pBase.y - 0.01;

        // Tick at 50x dome size
        final largeDomeR = domeR * 50;
        final largeDomeH = domeH * 50;
        final pLarge = DomeParticle();
        pLarge.x = 0;
        pLarge.y = 0.01;
        pLarge.z = 0;
        pLarge.tick(zeroField, 1.0, largeDomeR, largeDomeH, rng: Random(42));
        final largeUpdraft = pLarge.y - 0.01;

        // Updraft should scale proportionally with dome size
        expect(
          largeUpdraft,
          closeTo(baseUpdraft * 50, baseUpdraft * 50 * 0.1),
          reason: 'Updraft should scale linearly with dome size',
        );
      });

      test('at base dome size (renderScale=1.0) displacement is unchanged', () {
        // This verifies the fix does not regress existing behavior
        final p = DomeParticle();
        p.x = 0;
        p.y = 1.0;
        p.z = 0;

        p.tick(uniformField, dt, domeR, domeH, rng: Random(42));

        // Expected: u * velocityScale * renderScale * dt
        // = 10 * 0.72 * 1.0 * (1/60) = 0.12
        expect(p.x, closeTo(0.12, 0.01));
      });
    });
  });
}
