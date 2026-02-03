import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/models/particle.dart';

void main() {
  group('Particle', () {
    group('constructor', () {
      test('creates with default values', () {
        final particle = Particle();

        expect(particle.x, 0);
        expect(particle.y, 0);
        expect(particle.age, 0);
        expect(particle.trailLength, 10);
      });

      test('creates with custom values', () {
        final particle = Particle(
          x: 0.5,
          y: 0.7,
          age: 0.3,
          trailLength: 15,
        );

        expect(particle.x, 0.5);
        expect(particle.y, 0.7);
        expect(particle.age, 0.3);
        expect(particle.trailLength, 15);
      });
    });

    group('reset()', () {
      test('randomizes x and y positions', () {
        final particle = Particle(x: 0.5, y: 0.5, age: 0.8);
        final random = Random(42); // Seeded for reproducibility

        // Record the initial positions
        final initialX = particle.x;
        final initialY = particle.y;

        particle.reset(random);

        // After reset, positions should be different (with high probability)
        // With a seeded random, we can verify specific behavior
        expect(particle.x, isNot(equals(initialX)));
        expect(particle.y, isNot(equals(initialY)));
      });

      test('resets age to 0.0', () {
        final particle = Particle(age: 0.8);
        final random = Random(42);

        particle.reset(random);

        expect(particle.age, 0.0);
      });

      test('positions stay in 0-1 range after reset', () {
        final particle = Particle();
        final random = Random();

        // Reset multiple times and verify range
        for (int i = 0; i < 100; i++) {
          particle.reset(random);

          expect(particle.x, greaterThanOrEqualTo(0.0));
          expect(particle.x, lessThan(1.0));
          expect(particle.y, greaterThanOrEqualTo(0.0));
          expect(particle.y, lessThan(1.0));
        }
      });

      test('does not change trailLength', () {
        final particle = Particle(trailLength: 20);
        final random = Random(42);

        particle.reset(random);

        expect(particle.trailLength, 20);
      });
    });

    group('isExpired', () {
      test('returns true when age >= 1.0', () {
        final particle1 = Particle(age: 1.0);
        final particle2 = Particle(age: 1.5);

        expect(particle1.isExpired, true);
        expect(particle2.isExpired, true);
      });

      test('returns false when age < 1.0', () {
        final particle1 = Particle(age: 0.0);
        final particle2 = Particle(age: 0.5);
        final particle3 = Particle(age: 0.99);

        expect(particle1.isExpired, false);
        expect(particle2.isExpired, false);
        expect(particle3.isExpired, false);
      });
    });

    group('mutable fields', () {
      test('x can be updated in-place', () {
        final particle = Particle();
        particle.x = 0.75;

        expect(particle.x, 0.75);
      });

      test('y can be updated in-place', () {
        final particle = Particle();
        particle.y = 0.25;

        expect(particle.y, 0.25);
      });

      test('age can be updated in-place', () {
        final particle = Particle();
        particle.age = 0.6;

        expect(particle.age, 0.6);
      });

      test('trailLength can be updated in-place', () {
        final particle = Particle();
        particle.trailLength = 25;

        expect(particle.trailLength, 25);
      });

      test('speed can be updated in-place', () {
        final particle = Particle();
        particle.speed = 15.5;

        expect(particle.speed, 15.5);
      });
    });

    group('trail storage', () {
      test('trailX is a Float32List', () {
        final particle = Particle();
        expect(particle.trailX, isA<Float32List>());
      });

      test('trailY is a Float32List', () {
        final particle = Particle();
        expect(particle.trailY, isA<Float32List>());
      });

      test('trail arrays have capacity for maxTrailPoints (30)', () {
        final particle = Particle();
        expect(particle.trailX.length, Particle.maxTrailPoints);
        expect(particle.trailY.length, Particle.maxTrailPoints);
        expect(Particle.maxTrailPoints, 30);
      });

      test('trailHead starts at 0', () {
        final particle = Particle();
        expect(particle.trailHead, 0);
      });

      test('trailCount starts at 0', () {
        final particle = Particle();
        expect(particle.trailCount, 0);
      });

      test('speed defaults to 0.0', () {
        final particle = Particle();
        expect(particle.speed, 0.0);
      });
    });

    group('recordTrailPoint()', () {
      test('adds point to buffer', () {
        final particle = Particle(x: 0.5, y: 0.7);
        particle.recordTrailPoint();

        // Float32List has reduced precision, use closeTo matcher
        expect(particle.trailX[0], closeTo(0.5, 0.001));
        expect(particle.trailY[0], closeTo(0.7, 0.001));
      });

      test('increments trailHead after recording', () {
        final particle = Particle(x: 0.5, y: 0.7);
        expect(particle.trailHead, 0);

        particle.recordTrailPoint();
        expect(particle.trailHead, 1);

        particle.x = 0.6;
        particle.y = 0.8;
        particle.recordTrailPoint();
        expect(particle.trailHead, 2);
      });

      test('increments trailCount up to maxTrailPoints', () {
        final particle = Particle();
        expect(particle.trailCount, 0);

        particle.recordTrailPoint();
        expect(particle.trailCount, 1);

        particle.recordTrailPoint();
        expect(particle.trailCount, 2);
      });

      test('caps trailCount at maxTrailPoints', () {
        final particle = Particle();

        // Fill buffer beyond capacity
        for (int i = 0; i < Particle.maxTrailPoints + 10; i++) {
          particle.x = i.toDouble() / 100;
          particle.y = i.toDouble() / 100;
          particle.recordTrailPoint();
        }

        expect(particle.trailCount, Particle.maxTrailPoints);
      });

      test('trailHead wraps around circularly', () {
        final particle = Particle();

        // Fill buffer exactly
        for (int i = 0; i < Particle.maxTrailPoints; i++) {
          particle.x = i.toDouble() / 100;
          particle.y = i.toDouble() / 100;
          particle.recordTrailPoint();
        }

        expect(particle.trailHead, 0); // Wrapped back to start

        // One more record
        particle.x = 0.99;
        particle.y = 0.99;
        particle.recordTrailPoint();

        expect(particle.trailHead, 1);
        // Float32List has reduced precision, use closeTo matcher
        expect(particle.trailX[0], closeTo(0.99, 0.001));
        expect(particle.trailY[0], closeTo(0.99, 0.001));
      });

      test('stores multiple points correctly', () {
        final particle = Particle();

        particle.x = 0.1;
        particle.y = 0.2;
        particle.recordTrailPoint();

        particle.x = 0.3;
        particle.y = 0.4;
        particle.recordTrailPoint();

        particle.x = 0.5;
        particle.y = 0.6;
        particle.recordTrailPoint();

        // Float32List has reduced precision, use closeTo matcher
        expect(particle.trailX[0], closeTo(0.1, 0.001));
        expect(particle.trailY[0], closeTo(0.2, 0.001));
        expect(particle.trailX[1], closeTo(0.3, 0.001));
        expect(particle.trailY[1], closeTo(0.4, 0.001));
        expect(particle.trailX[2], closeTo(0.5, 0.001));
        expect(particle.trailY[2], closeTo(0.6, 0.001));
        expect(particle.trailCount, 3);
      });
    });

    group('resetTrail()', () {
      test('resets trailHead to 0', () {
        final particle = Particle();
        particle.recordTrailPoint();
        particle.recordTrailPoint();
        expect(particle.trailHead, 2);

        particle.resetTrail();
        expect(particle.trailHead, 0);
      });

      test('resets trailCount to 0', () {
        final particle = Particle();
        particle.recordTrailPoint();
        particle.recordTrailPoint();
        expect(particle.trailCount, 2);

        particle.resetTrail();
        expect(particle.trailCount, 0);
      });

      test('can record new points after reset', () {
        final particle = Particle(x: 0.1, y: 0.2);
        particle.recordTrailPoint();
        particle.recordTrailPoint();
        particle.resetTrail();

        particle.x = 0.9;
        particle.y = 0.8;
        particle.recordTrailPoint();

        expect(particle.trailHead, 1);
        expect(particle.trailCount, 1);
        // Float32List has reduced precision, use closeTo matcher
        expect(particle.trailX[0], closeTo(0.9, 0.001));
        expect(particle.trailY[0], closeTo(0.8, 0.001));
      });
    });

    group('reset() with trail', () {
      test('reset() calls resetTrail()', () {
        final particle = Particle();
        final random = Random(42);

        // Record some trail points
        particle.recordTrailPoint();
        particle.recordTrailPoint();
        particle.recordTrailPoint();
        expect(particle.trailCount, 3);
        expect(particle.trailHead, 3);

        // Reset particle
        particle.reset(random);

        // Trail should be cleared
        expect(particle.trailHead, 0);
        expect(particle.trailCount, 0);
      });

      test('reset() clears trail history on particle recycle', () {
        final particle = Particle(x: 0.5, y: 0.5);
        final random = Random(42);

        // Simulate particle lifecycle with trail
        for (int i = 0; i < 15; i++) {
          particle.x = i.toDouble() / 20;
          particle.y = i.toDouble() / 20;
          particle.recordTrailPoint();
        }
        expect(particle.trailCount, 15);

        // Particle expires and resets
        particle.reset(random);

        // New particle should have empty trail
        expect(particle.trailCount, 0);
        expect(particle.trailHead, 0);
      });
    });
  });
}
