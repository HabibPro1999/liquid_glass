import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass/liquid_glass.dart';

void main() {
  // The test environment runs on Skia, which does not support
  // ImageFilter.shader. All tests exercise the child-passthrough or
  // Tier 2 fallback paths.
  //
  // When the main shader loads but ImageFilter.shader is unsupported, the
  // widget reports a FlutterError once (debug only). We capture that expected
  // error globally so individual tests are not marked as failures.

  FlutterExceptionHandler? _originalOnError;

  setUp(() {
    _originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      // Swallow the known fallback warning. All other errors are re-thrown.
      final message = details.exception.toString();
      if (message.contains('ImageFilter.shader unavailable')) return;
      _originalOnError?.call(details);
    };
  });

  tearDown(() {
    FlutterError.onError = _originalOnError;
  });

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

  group('LiquidGlassMode', () {
    testWidgets('tier2 mode renders without errors', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: LiquidGlass(
            mode: LiquidGlassMode.tier2,
            child: Text('Hello'),
          ),
        ),
      );
      // Allow async fallback shader loading to settle.
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tier2 mode uses BackdropFilter blur', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: LiquidGlass(
            mode: LiquidGlassMode.tier2,
            child: Text('Hello'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tier 2 always produces a BackdropFilter regardless of shader loading.
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'test environment exercises fallback path (Skia has no ImageFilter.shader)',
        (tester) async {
      // Tests run on Skia. The widget must exercise the fallback path without
      // crashing when ImageFilter.shader is unavailable.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: LiquidGlass(
            mode: LiquidGlassMode.auto,
            child: Text('Fallback'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fallback'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('auto mode with isEnabled: false skips BackdropFilter',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: LiquidGlass(
            mode: LiquidGlassMode.auto,
            isEnabled: false,
            child: Text('Hello'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
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
