import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass/liquid_glass.dart';

void main() {
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

  Widget buildButton({
    required Widget child,
    VoidCallback? onPressed,
    LiquidGlassButtonStyle style = LiquidGlassButtonStyle.secondary,
    LiquidGlassSettings? settings,
    LiquidGlassShape? shape,
    double pressedScale = 0.94,
    bool disableAnimations = false,
  }) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: LiquidGlassButton(
          onPressed: onPressed,
          style: style,
          settings: settings,
          shape: shape,
          pressedScale: pressedScale,
          child: child,
        ),
      ),
    );
  }

  group('LiquidGlassButton', () {
    testWidgets('renders with text child', (tester) async {
      await tester.pumpWidget(
        buildButton(
          onPressed: () {},
          child: const Text('Tap me'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tap me'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('onPressed callback fires on tap', (tester) async {
      var callCount = 0;

      await tester.pumpWidget(
        buildButton(
          onPressed: () => callCount++,
          child: const Text('Button'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(LiquidGlassButton));
      await tester.pumpAndSettle();

      expect(callCount, 1);
    });

    testWidgets('onPressed: null disables interaction', (tester) async {
      var callCount = 0;

      await tester.pumpWidget(
        buildButton(
          onPressed: null,
          child: const Text('Disabled'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(LiquidGlassButton));
      await tester.pumpAndSettle();

      expect(callCount, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disposes without errors', (tester) async {
      await tester.pumpWidget(
        buildButton(
          onPressed: () {},
          child: const Text('Button'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Transform.scale widget appears in tree', (tester) async {
      await tester.pumpWidget(
        buildButton(
          onPressed: () {},
          child: const Text('Button'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('primary style renders without errors', (tester) async {
      await tester.pumpWidget(
        buildButton(
          style: LiquidGlassButtonStyle.primary,
          onPressed: () {},
          child: const Text('Primary'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Primary'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('secondary style renders without errors', (tester) async {
      await tester.pumpWidget(
        buildButton(
          style: LiquidGlassButtonStyle.secondary,
          onPressed: () {},
          child: const Text('Secondary'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Secondary'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('press-scale animation scales down on tap-down', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: LiquidGlassButton(
              onPressed: () {},
              pressedScale: 0.90,
              child: const Text('Button'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate a press-and-hold: pointer down + advance to mid-animation.
      // pump(0) processes the pointer event and fires onTapDown which starts
      // the animation. Then pump(75ms) advances to mid-animation.
      await tester.press(find.byType(LiquidGlassButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));

      // Transform.scale wraps LiquidGlass. Read the X scale from matrix[0]
      // (m00). Transform.scale only sets XY — Z stays 1.0, so getMaxScaleOnAxis
      // always returns 1.0; use matrix[0] to read the actual X scale.
      final transforms = tester.widgetList<Transform>(
        find.ancestor(
          of: find.byType(LiquidGlass),
          matching: find.byType(Transform),
        ),
      ).toList();
      expect(transforms, isNotEmpty);
      final xScale = transforms.first.transform.storage[0];
      expect(xScale, lessThan(1.0));

      await tester.pumpAndSettle();
    });

    testWidgets('press-scale springs back to 1.0 on tap-up', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: LiquidGlassButton(
              onPressed: () {},
              pressedScale: 0.90,
              child: const Text('Button'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(LiquidGlassButton)),
      );
      await tester.pump(const Duration(milliseconds: 150));
      await gesture.up();
      await tester.pumpAndSettle();

      final transforms = tester.widgetList<Transform>(
        find.ancestor(
          of: find.byType(LiquidGlass),
          matching: find.byType(Transform),
        ),
      ).toList();
      expect(transforms, isNotEmpty);
      final xScale = transforms.first.transform.storage[0];
      expect(xScale, closeTo(1.0, 0.01));
    });

    testWidgets('disableAnimations: skips scale and fires onPressed immediately',
        (tester) async {
      var callCount = 0;

      await tester.pumpWidget(
        buildButton(
          onPressed: () => callCount++,
          disableAnimations: true,
          child: const Text('Button'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(LiquidGlassButton));
      await tester.pumpAndSettle();

      expect(callCount, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts custom settings', (tester) async {
      await tester.pumpWidget(
        buildButton(
          onPressed: () {},
          settings: const LiquidGlassSettings(blurSigma: 8.0),
          child: const Text('Button'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Button'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts custom shape', (tester) async {
      await tester.pumpWidget(
        buildButton(
          onPressed: () {},
          shape: LiquidGlassShape.roundedRect(radius: 16.0),
          child: const Text('Button'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Button'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('LiquidGlassButton integration', () {
    testWidgets('LiquidGlassButton inside LiquidGlassGroup renders without errors',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: LiquidGlassGroup(
              child: LiquidGlassButton(
                onPressed: () {},
                child: const Text('Test'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Multiple LiquidGlassButtons in a Row inside LiquidGlassGroup render',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: LiquidGlassGroup(
              spacing: 8.0,
              child: Row(
                children: [
                  LiquidGlassButton(onPressed: () {}, child: const Text('A')),
                  LiquidGlassButton(onPressed: () {}, child: const Text('B')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('LiquidGlassButton with custom settings overrides style defaults',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: LiquidGlassButton(
              onPressed: () {},
              settings: const LiquidGlassSettings(blurSigma: 20.0),
              child: const Text('Custom'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('LiquidGlassButton with custom shape (not default capsule) renders',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: LiquidGlassButton(
              onPressed: () {},
              shape: LiquidGlassShape.roundedRect(radius: 8.0),
              child: const Text('Rect'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rect'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
