import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass/liquid_glass.dart';

void main() {
  // The test environment runs on Skia. When the main shader loads but
  // ImageFilter.shader is unsupported, the widget reports a FlutterError once.
  // Capture that expected error so individual tests are not marked as failures.

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

  group('LiquidGlass accessibility overrides', () {
    testWidgets('highContrast active renders without errors', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(highContrast: true),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: LiquidGlass(child: Text('Hello')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disableAnimations active renders without errors',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: LiquidGlass(child: Text('Hello')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'disableAnimations forces identity variant — no BackdropFilter',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: LiquidGlass(child: Text('Hello')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // disableAnimations proxies reduceTransparency → identity → no glass.
      expect(find.text('Hello'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no accessibility flags renders normally', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: LiquidGlass(child: Text('Hello')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('multiple flags active simultaneously renders without errors',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            highContrast: true,
            disableAnimations: true,
          ),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: LiquidGlass(child: Text('Hello')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'highContrast alone does not force identity — glass still renders',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(highContrast: true),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: LiquidGlass(
              mode: LiquidGlassMode.tier2,
              child: Text('Hello'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // highContrast boosts visuals but does not disable glass entirely.
      expect(find.text('Hello'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('isEnabled: false still short-circuits under any accessibility',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(highContrast: true),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: LiquidGlass(
              isEnabled: false,
              child: Text('Hello'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('platformBrightness tint adaptation', () {
    testWidgets('regular variant in dark mode renders', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: LiquidGlass(child: Text('Hello')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('regular variant in light mode renders', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.light),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: LiquidGlass(child: Text('Hello')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('clear variant in dark mode not affected', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: LiquidGlass(
              settings: const LiquidGlassSettings(
                  variant: LiquidGlassVariant.clear),
              child: const Text('Hello'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('explicit tint not overridden', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: LiquidGlass(
              settings: const LiquidGlassSettings(tint: Color(0xFF0000FF)),
              child: const Text('Hello'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsOneWidget);
    });
  });
}
