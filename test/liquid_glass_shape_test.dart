import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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

  group('LiquidGlassShape.fromShapeBorder', () {
    test('RoundedRectangleBorder converts to RoundedRect', () {
      final shape = LiquidGlassShape.fromShapeBorder(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );
      expect(shape, isA<RoundedRect>());
      expect((shape as RoundedRect).radius, 16.0);
    });

    test('CircleBorder converts to Circle', () {
      final shape = LiquidGlassShape.fromShapeBorder(const CircleBorder());
      expect(shape, isA<Circle>());
    });

    test('StadiumBorder converts to Capsule', () {
      final shape = LiquidGlassShape.fromShapeBorder(const StadiumBorder());
      expect(shape, isA<Capsule>());
    });

    test('ContinuousRectangleBorder converts to Squircle with radius 20.0', () {
      final shape = LiquidGlassShape.fromShapeBorder(
        const ContinuousRectangleBorder(),
      );
      expect(shape, isA<Squircle>());
      expect((shape as Squircle).radius, 20.0);
    });

    test('unrecognized ShapeBorder converts to Custom', () {
      final shape = LiquidGlassShape.fromShapeBorder(
        const BeveledRectangleBorder(),
      );
      expect(shape, isA<Custom>());
    });

    test('Custom stores original ShapeBorder by identity', () {
      const border = BeveledRectangleBorder();
      final shape =
          LiquidGlassShape.fromShapeBorder(border) as Custom;
      expect(shape.shapeBorder, same(border));
    });
  });

  group('Custom equality', () {
    test('same instance equals itself', () {
      const border = BeveledRectangleBorder();
      final custom = Custom(shapeBorder: border);
      expect(custom, equals(custom));
    });

    test('two Custom instances with the same border identity are equal', () {
      const border = BeveledRectangleBorder();
      final a = Custom(shapeBorder: border);
      final b = Custom(shapeBorder: border);
      expect(a, equals(b));
    });

    test('two Custom instances with different (non-const) border instances are not equal', () {
      // Use non-const instances to ensure distinct object identities.
      // ignore: prefer_const_constructors
      final borderA = BeveledRectangleBorder();
      // ignore: prefer_const_constructors
      final borderB = BeveledRectangleBorder();
      final a = Custom(shapeBorder: borderA);
      final b = Custom(shapeBorder: borderB);
      expect(a, isNot(equals(b)));
    });

    test('toString is readable', () {
      const border = BeveledRectangleBorder();
      final custom = Custom(shapeBorder: border);
      expect(custom.toString(), startsWith('Custom(shapeBorder:'));
    });
  });

  group('fromShapeBorder widget smoke test', () {
    FlutterExceptionHandler? originalOnError;

    setUp(() {
      originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        final message = details.exception.toString();
        if (message.contains('ImageFilter.shader unavailable')) return;
        originalOnError?.call(details);
      };
    });

    tearDown(() {
      FlutterError.onError = originalOnError;
    });

    testWidgets(
        'LiquidGlass with fromShapeBorder(CircleBorder) renders without errors',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: LiquidGlass(
            shape: LiquidGlassShape.fromShapeBorder(const CircleBorder()),
            child: const Text('Hi'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
