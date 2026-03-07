import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass/liquid_glass.dart';

void main() {
  group('LiquidGlassSettings defaults', () {
    const settings = LiquidGlassSettings();

    test('variant defaults to regular', () {
      expect(settings.variant, LiquidGlassVariant.regular);
    });

    test('tint defaults to null', () {
      expect(settings.tint, isNull);
    });

    test('blurSigma defaults to 12.0', () {
      expect(settings.blurSigma, 12.0);
    });

    test('refractiveIndex defaults to 1.52', () {
      expect(settings.refractiveIndex, 1.52);
    });

    test('refractionStrength defaults to -0.06', () {
      expect(settings.refractionStrength, -0.06);
    });

    test('refractionFalloff defaults to 45.0', () {
      expect(settings.refractionFalloff, 45.0);
    });

    test('refractionFalloffExponent defaults to 4.0', () {
      expect(settings.refractionFalloffExponent, 4.0);
    });

    test('saturation defaults to 1.15', () {
      expect(settings.saturation, 1.15);
    });

    test('chromaticAberration defaults to 0.2', () {
      expect(settings.chromaticAberration, 0.2);
    });

    test('lightAngle defaults to 0.8', () {
      expect(settings.lightAngle, 0.8);
    });

    test('lightIntensity defaults to 1.2', () {
      expect(settings.lightIntensity, 1.2);
    });

    test('specularPower defaults to 14.0', () {
      expect(settings.specularPower, 14.0);
    });

    test('specularKickPower defaults to 20.0', () {
      expect(settings.specularKickPower, 20.0);
    });

    test('specularKickIntensity defaults to 0.4', () {
      expect(settings.specularKickIntensity, 0.4);
    });

    test('lightBandOffset defaults to 10.0', () {
      expect(settings.lightBandOffset, 10.0);
    });

    test('lightBandWidth defaults to 30.0', () {
      expect(settings.lightBandWidth, 30.0);
    });

    test('lightBandStrength defaults to 0.6', () {
      expect(settings.lightBandStrength, 0.6);
    });

    test('grainIntensity defaults to 0.04', () {
      expect(settings.grainIntensity, 0.04);
    });

    test('isInteractive defaults to false', () {
      expect(settings.isInteractive, false);
    });
  });

  group('LiquidGlassSettings copyWith', () {
    const original = LiquidGlassSettings();

    test('copyWith with no arguments preserves all fields', () {
      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('copyWith overrides blurSigma', () {
      final copy = original.copyWith(blurSigma: 20.0);
      expect(copy.blurSigma, 20.0);
      expect(copy.refractiveIndex, original.refractiveIndex);
      expect(copy.variant, original.variant);
    });

    test('copyWith overrides variant', () {
      final copy = original.copyWith(variant: LiquidGlassVariant.clear);
      expect(copy.variant, LiquidGlassVariant.clear);
      expect(copy.blurSigma, original.blurSigma);
    });

    test('copyWith overrides tint', () {
      const color = Color(0x3300AAFF);
      final copy = original.copyWith(tint: color);
      expect(copy.tint, color);
    });

    test('copyWith clearTint sets tint to null', () {
      const withTint = LiquidGlassSettings(tint: Color(0x3300AAFF));
      final cleared = withTint.copyWith(clearTint: true);
      expect(cleared.tint, isNull);
    });

    test('copyWith overrides multiple fields', () {
      final copy = original.copyWith(
        blurSigma: 18.0,
        saturation: 1.3,
        isInteractive: true,
      );
      expect(copy.blurSigma, 18.0);
      expect(copy.saturation, 1.3);
      expect(copy.isInteractive, true);
      expect(copy.refractiveIndex, original.refractiveIndex);
      expect(copy.lightAngle, original.lightAngle);
    });

    test('copyWith returns new instance', () {
      final copy = original.copyWith(blurSigma: 20.0);
      expect(identical(copy, original), isFalse);
    });
  });

  group('LiquidGlassSettings lerp', () {
    const a = LiquidGlassSettings(
      blurSigma: 0.0,
      saturation: 1.0,
      lightIntensity: 0.0,
      specularPower: 4.0,
    );
    const b = LiquidGlassSettings(
      blurSigma: 20.0,
      saturation: 1.4,
      lightIntensity: 2.0,
      specularPower: 200.0,
      variant: LiquidGlassVariant.clear,
      isInteractive: true,
    );

    test('lerp at t=0 returns values equal to a', () {
      final result = LiquidGlassSettings.lerp(a, b, 0.0);
      expect(result.blurSigma, a.blurSigma);
      expect(result.saturation, a.saturation);
      expect(result.lightIntensity, a.lightIntensity);
      expect(result.specularPower, a.specularPower);
    });

    test('lerp at t=1 returns values equal to b', () {
      final result = LiquidGlassSettings.lerp(a, b, 1.0);
      expect(result.blurSigma, b.blurSigma);
      expect(result.saturation, closeTo(b.saturation, 1e-10));
      expect(result.lightIntensity, b.lightIntensity);
      expect(result.specularPower, b.specularPower);
    });

    test('lerp at t=0.5 interpolates numeric fields', () {
      final result = LiquidGlassSettings.lerp(a, b, 0.5);
      expect(result.blurSigma, closeTo(10.0, 1e-10));
      expect(result.saturation, closeTo(1.2, 1e-10));
      expect(result.lightIntensity, closeTo(1.0, 1e-10));
      expect(result.specularPower, closeTo(102.0, 1e-10));
    });

    test('lerp snaps variant at t=0.5 to b', () {
      final result = LiquidGlassSettings.lerp(a, b, 0.5);
      expect(result.variant, b.variant);
    });

    test('lerp snaps variant at t<0.5 to a', () {
      final result = LiquidGlassSettings.lerp(a, b, 0.4);
      expect(result.variant, a.variant);
    });

    test('lerp snaps isInteractive at t=0.5 to b', () {
      final result = LiquidGlassSettings.lerp(a, b, 0.5);
      expect(result.isInteractive, b.isInteractive);
    });

    test('lerp uses Color.lerp for tint', () {
      const settingsA = LiquidGlassSettings(tint: Color(0xFF000000));
      const settingsB = LiquidGlassSettings(tint: Color(0xFFFFFFFF));
      final result = LiquidGlassSettings.lerp(settingsA, settingsB, 0.5);
      expect(result.tint, isNotNull);
    });

    test('lerp with null tints produces null tint', () {
      final result = LiquidGlassSettings.lerp(
        const LiquidGlassSettings(),
        const LiquidGlassSettings(),
        0.5,
      );
      expect(result.tint, isNull);
    });
  });

  group('LiquidGlassSettings equality', () {
    test('identical settings are equal', () {
      const a = LiquidGlassSettings();
      const b = LiquidGlassSettings();
      expect(a, equals(b));
    });

    test('settings with different blurSigma are not equal', () {
      const a = LiquidGlassSettings(blurSigma: 12.0);
      const b = LiquidGlassSettings(blurSigma: 20.0);
      expect(a, isNot(equals(b)));
    });

    test('settings with different variant are not equal', () {
      const a = LiquidGlassSettings(variant: LiquidGlassVariant.regular);
      const b = LiquidGlassSettings(variant: LiquidGlassVariant.clear);
      expect(a, isNot(equals(b)));
    });

    test('settings with different tint are not equal', () {
      const a = LiquidGlassSettings(tint: Color(0xFF0000FF));
      const b = LiquidGlassSettings(tint: Color(0xFFFF0000));
      expect(a, isNot(equals(b)));
    });

    test('settings with null vs non-null tint are not equal', () {
      const a = LiquidGlassSettings();
      const b = LiquidGlassSettings(tint: Color(0xFF0000FF));
      expect(a, isNot(equals(b)));
    });
  });

  group('LiquidGlassSettings hashCode', () {
    test('equal objects have equal hashCodes', () {
      const a = LiquidGlassSettings();
      const b = LiquidGlassSettings();
      expect(a.hashCode, equals(b.hashCode));
    });

    test('objects with same fields have equal hashCodes', () {
      const a = LiquidGlassSettings(blurSigma: 18.0, saturation: 1.2);
      const b = LiquidGlassSettings(blurSigma: 18.0, saturation: 1.2);
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('LiquidGlassVariant', () {
    test('has three values', () {
      expect(LiquidGlassVariant.values.length, 3);
    });

    test('has regular, clear, and identity', () {
      expect(LiquidGlassVariant.values, contains(LiquidGlassVariant.regular));
      expect(LiquidGlassVariant.values, contains(LiquidGlassVariant.clear));
      expect(LiquidGlassVariant.values, contains(LiquidGlassVariant.identity));
    });
  });

  group('LiquidGlassShape', () {
    test('defaultShape is a Squircle with radius 20.0', () {
      final shape = LiquidGlassShape.defaultShape;
      expect(shape, isA<Squircle>());
      expect((shape as Squircle).radius, 20.0);
    });

    test('squircle factory creates Squircle with given radius', () {
      final shape = LiquidGlassShape.squircle(radius: 30.0);
      expect(shape, isA<Squircle>());
      expect((shape as Squircle).radius, 30.0);
    });

    test('squircle factory uses default radius of 20.0', () {
      final shape = LiquidGlassShape.squircle();
      expect((shape as Squircle).radius, 20.0);
    });

    test('roundedRect throws UnimplementedError', () {
      expect(
        () => LiquidGlassShape.roundedRect(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('circle throws UnimplementedError', () {
      expect(
        () => LiquidGlassShape.circle(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('capsule throws UnimplementedError', () {
      expect(
        () => LiquidGlassShape.capsule(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('ellipse throws UnimplementedError', () {
      expect(
        () => LiquidGlassShape.ellipse(),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
