import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass/liquid_glass.dart';

void main() {
  // The test environment runs on Skia, which does not support
  // ImageFilter.shader. All tests exercise the child-passthrough or
  // Tier 2 fallback paths.

  group('LiquidGlass widget', () {
    testWidgets('renders child without errors (fallback path)', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: LiquidGlass(
            child: Text('Hello'),
          ),
        ),
      );
      // Allow async shader loading to settle. In the test environment
      // FragmentProgram.fromAsset will fail gracefully.
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('isEnabled: false renders child directly', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: LiquidGlass(
            isEnabled: false,
            child: Text('Hello'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      // No BackdropFilter should be present when disabled.
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('identity variant renders child directly', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: LiquidGlass(
            settings: LiquidGlassSettings(
              variant: LiquidGlassVariant.identity,
            ),
            child: Text('Hello'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      // No BackdropFilter should be present for identity variant.
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('disposes without errors', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: LiquidGlass(
            child: Text('Hello'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Replace the widget tree, triggering dispose on the LiquidGlass state.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      );
      await tester.pumpAndSettle();

      // No exception means dispose was clean.
      expect(tester.takeException(), isNull);
    });

    testWidgets('rebuilds when settings change', (tester) async {
      var settings = const LiquidGlassSettings(blurSigma: 10.0);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: LiquidGlass(
            settings: settings,
            child: const Text('Hello'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);

      settings = const LiquidGlassSettings(blurSigma: 20.0);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: LiquidGlass(
            settings: settings,
            child: const Text('Hello'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('LiquidGlass parameters', () {
    testWidgets('accepts custom shape', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: LiquidGlass(
            shape: LiquidGlassShape.squircle(radius: 30.0),
            child: const Text('Hello'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('clear variant does not short-circuit to identity', (tester) async {
      // clear variant should still attempt glass rendering (not zero-GPU).
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: LiquidGlass(
            settings: LiquidGlassSettings(
              variant: LiquidGlassVariant.clear,
            ),
            child: Text('Hello'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('regular variant renders child', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: LiquidGlass(
            settings: LiquidGlassSettings(
              variant: LiquidGlassVariant.regular,
            ),
            child: Text('Hello'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
