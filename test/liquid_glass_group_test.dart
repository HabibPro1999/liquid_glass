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
      // Swallow shader unavailability and nested-group warnings under test.
      if (message.contains('ImageFilter.shader unavailable')) return;
      if (message.contains('LiquidGlassGroup must not be nested')) return;
      originalOnError?.call(details);
    };
  });

  tearDown(() {
    FlutterError.onError = originalOnError;
  });

  Widget wrap(Widget child) => Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: child,
        ),
      );

  group('LiquidGlassGroup', () {
    testWidgets('renders with one child LiquidGlass without errors',
        (tester) async {
      await tester.pumpWidget(wrap(
        LiquidGlassGroup(
          child: LiquidGlass(
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LiquidGlassGroup), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with two children without errors', (tester) async {
      await tester.pumpWidget(wrap(
        LiquidGlassGroup(
          child: Column(
            children: [
              LiquidGlass(child: const SizedBox(width: 100, height: 50)),
              LiquidGlass(child: const SizedBox(width: 100, height: 50)),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LiquidGlass), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('spacing: null (default) renders without errors',
        (tester) async {
      await tester.pumpWidget(wrap(
        const LiquidGlassGroup(
          child: SizedBox(width: 100, height: 100),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LiquidGlassGroup), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('spacing: 8.0 renders without errors', (tester) async {
      await tester.pumpWidget(wrap(
        const LiquidGlassGroup(
          spacing: 8.0,
          child: SizedBox(width: 100, height: 100),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LiquidGlassGroup), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('spacing: 0.0 renders without errors', (tester) async {
      await tester.pumpWidget(wrap(
        const LiquidGlassGroup(
          spacing: 0.0,
          child: SizedBox(width: 100, height: 100),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LiquidGlassGroup), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('nested LiquidGlassGroup emits assertion in debug mode',
        (tester) async {
      bool nestedWarningEmitted = false;

      FlutterError.onError = (FlutterErrorDetails details) {
        final message = details.exception.toString();
        if (message.contains('LiquidGlassGroup must not be nested')) {
          nestedWarningEmitted = true;
          return;
        }
        if (message.contains('ImageFilter.shader unavailable')) return;
        originalOnError?.call(details);
      };

      await tester.pumpWidget(wrap(
        LiquidGlassGroup(
          child: LiquidGlassGroup(
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // In debug mode the nested-group assertion must fire.
      if (kDebugMode) {
        expect(nestedWarningEmitted, isTrue);
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('LiquidGlassGroup.spacingOf', () {
    testWidgets('returns null when no group in scope', (tester) async {
      double? captured;
      await tester.pumpWidget(wrap(
        Builder(builder: (context) {
          captured = LiquidGlassGroup.spacingOf(context);
          return const SizedBox.shrink();
        }),
      ));

      expect(captured, isNull);
    });

    testWidgets('returns spacing from enclosing group', (tester) async {
      double? captured;
      await tester.pumpWidget(wrap(
        LiquidGlassGroup(
          spacing: 12.0,
          child: Builder(builder: (context) {
            captured = LiquidGlassGroup.spacingOf(context);
            return const SizedBox.shrink();
          }),
        ),
      ));

      expect(captured, 12.0);
    });

    testWidgets('returns null spacing when group has no spacing', (tester) async {
      double? captured;
      await tester.pumpWidget(wrap(
        LiquidGlassGroup(
          child: Builder(builder: (context) {
            captured = LiquidGlassGroup.spacingOf(context);
            return const SizedBox.shrink();
          }),
        ),
      ));

      expect(captured, isNull);
    });
  });
}
