import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass/liquid_glass.dart';

void main() {
  group('GlassThemeData defaults', () {
    test('default constructor has standard settings', () {
      const data = GlassThemeData();
      expect(data.settings, const LiquidGlassSettings());
      expect(data.mode, LiquidGlassMode.auto);
      expect(data.variant, isNull);
    });

    test('GlassThemeData.light() has standard settings', () {
      const data = GlassThemeData.light();
      expect(data.settings, const LiquidGlassSettings());
      expect(data.mode, LiquidGlassMode.auto);
      expect(data.variant, isNull);
    });

    test('GlassThemeData.dark() has tint Color(0x0DFFFFFF)', () {
      const data = GlassThemeData.dark();
      expect(data.settings.tint, const Color(0x0DFFFFFF));
      expect(data.mode, LiquidGlassMode.auto);
      expect(data.variant, isNull);
    });
  });

  group('GlassThemeData copyWith', () {
    test('copyWith replaces settings', () {
      const original = GlassThemeData();
      const newSettings = LiquidGlassSettings(blurSigma: 20.0);
      final copy = original.copyWith(settings: newSettings);
      expect(copy.settings, newSettings);
      expect(copy.mode, original.mode);
      expect(copy.variant, original.variant);
    });

    test('copyWith replaces mode', () {
      const original = GlassThemeData();
      final copy = original.copyWith(mode: LiquidGlassMode.tier2);
      expect(copy.mode, LiquidGlassMode.tier2);
      expect(copy.settings, original.settings);
    });

    test('copyWith replaces variant', () {
      const original = GlassThemeData();
      final copy = original.copyWith(variant: LiquidGlassVariant.clear);
      expect(copy.variant, LiquidGlassVariant.clear);
    });

    test('copyWith with no arguments preserves all fields', () {
      const original = GlassThemeData(variant: LiquidGlassVariant.clear);
      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('copyWith clearVariant sets variant to null', () {
      const original = GlassThemeData(variant: LiquidGlassVariant.clear);
      final copy = original.copyWith(clearVariant: true);
      expect(copy.variant, isNull);
    });
  });

  group('GlassThemeData equality and hashCode', () {
    test('two default instances are equal', () {
      const a = GlassThemeData();
      const b = GlassThemeData();
      expect(a, equals(b));
    });

    test('equal objects have equal hashCodes', () {
      const a = GlassThemeData();
      const b = GlassThemeData();
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different settings are not equal', () {
      const a = GlassThemeData();
      const b = GlassThemeData(settings: LiquidGlassSettings(blurSigma: 20.0));
      expect(a, isNot(equals(b)));
    });

    test('different mode values are not equal', () {
      const a = GlassThemeData(mode: LiquidGlassMode.auto);
      const b = GlassThemeData(mode: LiquidGlassMode.tier2);
      expect(a, isNot(equals(b)));
    });

    test('different variant values are not equal', () {
      const a = GlassThemeData();
      const b = GlassThemeData(variant: LiquidGlassVariant.clear);
      expect(a, isNot(equals(b)));
    });

    test('objects with same fields have equal hashCodes', () {
      const a = GlassThemeData(variant: LiquidGlassVariant.clear);
      const b = GlassThemeData(variant: LiquidGlassVariant.clear);
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('GlassTheme InheritedWidget', () {
    testWidgets('GlassTheme.of returns default when no theme in tree',
        (tester) async {
      late GlassThemeData captured;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              captured = GlassTheme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(captured, const GlassThemeData());
    });

    testWidgets('GlassTheme.of returns provided theme data', (tester) async {
      const customData = GlassThemeData(
        mode: LiquidGlassMode.tier2,
        variant: LiquidGlassVariant.clear,
      );
      late GlassThemeData captured;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: GlassTheme(
            data: customData,
            child: Builder(
              builder: (context) {
                captured = GlassTheme.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(captured, customData);
    });

    testWidgets('GlassTheme.maybeOf returns null when no theme in tree',
        (tester) async {
      GlassThemeData? captured = const GlassThemeData(); // non-null sentinel
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              captured = GlassTheme.maybeOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(captured, isNull);
    });

    testWidgets('GlassTheme.maybeOf returns data when theme present',
        (tester) async {
      const customData = GlassThemeData(mode: LiquidGlassMode.tier1);
      GlassThemeData? captured;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: GlassTheme(
            data: customData,
            child: Builder(
              builder: (context) {
                captured = GlassTheme.maybeOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(captured, customData);
    });
  });

  group('LiquidGlassSettings.highPerformance', () {
    const hp = LiquidGlassSettings.highPerformance();

    test('chromaticAberration is 0.0', () {
      expect(hp.chromaticAberration, 0.0);
    });

    test('grainIntensity is 0.0', () {
      expect(hp.grainIntensity, 0.0);
    });

    test('blurSigma is 10.0', () {
      expect(hp.blurSigma, 10.0);
    });

    test('specularKickIntensity is 0.2', () {
      expect(hp.specularKickIntensity, 0.2);
    });

    test('saturation is 1.10', () {
      expect(hp.saturation, 1.10);
    });

    test('variant is regular', () {
      expect(hp.variant, LiquidGlassVariant.regular);
    });

    test('isInteractive is false', () {
      expect(hp.isInteractive, false);
    });

    test('copyWith works on highPerformance instance', () {
      final copy = hp.copyWith(blurSigma: 5.0);
      expect(copy.blurSigma, 5.0);
      expect(copy.chromaticAberration, 0.0);
      expect(copy.grainIntensity, 0.0);
    });

    test('highPerformance is not equal to default settings', () {
      const defaults = LiquidGlassSettings();
      expect(hp, isNot(equals(defaults)));
    });

    test('two highPerformance instances are equal', () {
      const a = LiquidGlassSettings.highPerformance();
      const b = LiquidGlassSettings.highPerformance();
      expect(a, equals(b));
    });
  });
}
