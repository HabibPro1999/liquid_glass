import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass/liquid_glass.dart';

void main() {
  group('LiquidGlassShape factories', () {
    test('squircle() creates Squircle', () {
      final shape = LiquidGlassShape.squircle();
      expect(shape, isA<Squircle>());
    });

    test('squircle default radius is 20.0', () {
      final shape = LiquidGlassShape.squircle() as Squircle;
      expect(shape.radius, 20.0);
    });

    test('squircle accepts custom radius', () {
      final shape = LiquidGlassShape.squircle(radius: 8.0) as Squircle;
      expect(shape.radius, 8.0);
    });

    test('roundedRect() creates RoundedRect', () {
      final shape = LiquidGlassShape.roundedRect();
      expect(shape, isA<RoundedRect>());
    });

    test('roundedRect default radius is 12.0', () {
      final shape = LiquidGlassShape.roundedRect() as RoundedRect;
      expect(shape.radius, 12.0);
    });

    test('roundedRect accepts custom radius', () {
      final shape = LiquidGlassShape.roundedRect(radius: 4.0) as RoundedRect;
      expect(shape.radius, 4.0);
    });

    test('circle() creates Circle', () {
      final shape = LiquidGlassShape.circle();
      expect(shape, isA<Circle>());
    });

    test('capsule() creates Capsule', () {
      final shape = LiquidGlassShape.capsule();
      expect(shape, isA<Capsule>());
    });

    test('ellipse() creates Ellipse', () {
      final shape = LiquidGlassShape.ellipse();
      expect(shape, isA<Ellipse>());
    });
  });

  group('LiquidGlassShape.defaultShape', () {
    test('is Squircle with radius 20.0', () {
      const shape = LiquidGlassShape.defaultShape;
      expect(shape, isA<Squircle>());
      expect((shape as Squircle).radius, 20.0);
    });

    test('equals Squircle(radius: 20.0)', () {
      expect(
        LiquidGlassShape.defaultShape,
        equals(const Squircle(radius: 20.0)),
      );
    });
  });

  group('Squircle equality', () {
    test('equal when radius matches', () {
      expect(
        const Squircle(radius: 10.0),
        equals(const Squircle(radius: 10.0)),
      );
    });

    test('not equal when radius differs', () {
      expect(
        const Squircle(radius: 10.0),
        isNot(equals(const Squircle(radius: 20.0))),
      );
    });

    test('hashCode matches for equal instances', () {
      expect(
        const Squircle(radius: 15.0).hashCode,
        const Squircle(radius: 15.0).hashCode,
      );
    });

    test('toString is readable', () {
      expect(const Squircle(radius: 20.0).toString(), 'Squircle(radius: 20.0)');
    });
  });

  group('RoundedRect equality', () {
    test('equal when radius matches', () {
      expect(
        const RoundedRect(radius: 8.0),
        equals(const RoundedRect(radius: 8.0)),
      );
    });

    test('not equal when radius differs', () {
      expect(
        const RoundedRect(radius: 8.0),
        isNot(equals(const RoundedRect(radius: 16.0))),
      );
    });

    test('hashCode matches for equal instances', () {
      expect(
        const RoundedRect(radius: 12.0).hashCode,
        const RoundedRect(radius: 12.0).hashCode,
      );
    });

    test('toString is readable', () {
      expect(const RoundedRect(radius: 12.0).toString(), 'RoundedRect(radius: 12.0)');
    });
  });

  group('Circle equality', () {
    test('two Circle instances are equal', () {
      expect(Circle(), equals(Circle()));
    });

    test('hashCode matches for two Circle instances', () {
      expect(Circle().hashCode, Circle().hashCode);
    });

    test('toString is readable', () {
      expect(Circle().toString(), 'Circle()');
    });
  });

  group('Capsule equality', () {
    test('two Capsule instances are equal', () {
      expect(Capsule(), equals(Capsule()));
    });

    test('hashCode matches for two Capsule instances', () {
      expect(Capsule().hashCode, Capsule().hashCode);
    });

    test('toString is readable', () {
      expect(Capsule().toString(), 'Capsule()');
    });
  });

  group('Ellipse equality', () {
    test('two Ellipse instances are equal', () {
      expect(Ellipse(), equals(Ellipse()));
    });

    test('hashCode matches for two Ellipse instances', () {
      expect(Ellipse().hashCode, Ellipse().hashCode);
    });

    test('toString is readable', () {
      expect(Ellipse().toString(), 'Ellipse()');
    });
  });

  group('Cross-type inequality', () {
    test('Circle != Capsule', () {
      expect(Circle(), isNot(equals(Capsule())));
    });

    test('Squircle != RoundedRect with same radius', () {
      expect(
        const Squircle(radius: 12.0),
        isNot(equals(const RoundedRect(radius: 12.0))),
      );
    });

    test('Ellipse != Circle', () {
      expect(Ellipse(), isNot(equals(Circle())));
    });
  });
}
