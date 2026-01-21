import 'dart:math';

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
    });
  });
}
