import 'dart:ui' show Color;

import 'liquid_glass_variant.dart';

/// Immutable configuration object for the [LiquidGlass] widget.
///
/// All visual parameters are bundled here. Every property has a validated
/// default calibrated to reproduce Apple's `.regular` glass appearance.
/// Use [copyWith] for one-off overrides and [lerp] for animation.
class LiquidGlassSettings {
  const LiquidGlassSettings({
    this.variant = LiquidGlassVariant.regular,
    this.tint,
    this.blurSigma = 12.0,
    this.refractiveIndex = 1.52,
    this.refractionStrength = -0.06,
    this.refractionFalloff = 45.0,
    this.refractionFalloffExponent = 4.0,
    this.saturation = 1.15,
    this.chromaticAberration = 0.2,
    this.lightAngle = 0.8,
    this.lightIntensity = 1.2,
    this.specularPower = 14.0,
    this.specularKickPower = 20.0,
    this.specularKickIntensity = 0.4,
    this.lightBandOffset = 10.0,
    this.lightBandWidth = 30.0,
    this.lightBandStrength = 0.6,
    this.grainIntensity = 0.04,
    this.isInteractive = false,
  });

  /// The visual variant of the glass effect.
  final LiquidGlassVariant variant;

  /// Optional tint color composited over the blurred backdrop.
  ///
  /// When non-null, the tint is composited using additive Plus-Lighter
  /// blending. Alpha drives tint intensity. Null means no tint.
  final Color? tint;

  /// Gaussian blur sigma applied to the backdrop before glass processing.
  ///
  /// GLSL uniform: [u_blur_sigma]. Valid range: 0.0–25.0.
  /// Above 25 risks color-jitter artifacts with animated content.
  final double blurSigma;

  /// Refractive index for Snell's-law UV displacement.
  ///
  /// GLSL uniform: [u_refractive_index]. Valid range: 1.00–1.70.
  /// 1.0 = air, 1.52 = optical glass, 1.7 = dense glass.
  final double refractiveIndex;

  /// Refraction strength (magnitude of lens distortion).
  ///
  /// GLSL uniform: [u_refract_strength]. Valid range: -0.15–0.15.
  /// Negative values produce a concave lens inward bend.
  final double refractionStrength;

  /// Pixels from edge where refraction fades to zero.
  ///
  /// GLSL uniform: [u_distort_falloff]. Valid range: 10.0–80.0.
  /// Higher values widen the distortion ring.
  final double refractionFalloff;

  /// Falloff curve sharpness for the refraction ring.
  ///
  /// GLSL uniform: [u_distort_exponent]. Valid range: 1.0–8.0.
  /// 4.0 gives a physically plausible sharp-edge ring.
  final double refractionFalloffExponent;

  /// Saturation multiplier applied to backdrop pixels.
  ///
  /// GLSL uniform: [u_saturation]. Valid range: 0.80–1.40.
  /// Above 1.4 looks artificial.
  final double saturation;

  /// Per-channel UV offset magnitude for chromatic aberration.
  ///
  /// GLSL uniform: [u_chromatic_aberration]. Valid range: 0.0–0.50.
  /// Above 0.5 breaks visually.
  final double chromaticAberration;

  /// Virtual light source angle in radians.
  ///
  /// GLSL uniform: [u_light_angle]. Valid range: 0.0–6.28 (full circle).
  final double lightAngle;

  /// Specular highlight brightness multiplier.
  ///
  /// GLSL uniform: [u_light_intensity]. Valid range: 0.0–3.0.
  /// Above 3.0 clips to white.
  final double lightIntensity;

  /// Primary Phong shininess exponent for the specular highlight.
  ///
  /// GLSL uniform: [u_spec_power]. Valid range: 4.0–200.0.
  /// 14.0 = broad highlight, calibrated iOS 26 constant.
  final double specularPower;

  /// Back-surface kick light shininess exponent.
  ///
  /// GLSL uniform: [u_spec_kick_power]. Valid range: 4.0–200.0.
  /// 20.0 = iOS 26 calibrated constant.
  final double specularKickPower;

  /// Kick light contribution relative to the primary specular.
  ///
  /// GLSL uniform: [u_spec_kick_intensity]. Valid range: 0.0–1.0.
  /// 0.4 = iOS 26 calibrated constant.
  final double specularKickIntensity;

  /// Pixels from edge where the inner glow band peaks.
  ///
  /// GLSL uniform: [u_lightband_offset]. Valid range: 0.0–40.0.
  final double lightBandOffset;

  /// Width of the inner glow band in pixels.
  ///
  /// GLSL uniform: [u_lightband_width]. Valid range: 5.0–60.0.
  final double lightBandWidth;

  /// Inner glow band brightness.
  ///
  /// GLSL uniform: [u_lightband_strength]. Valid range: 0.0–1.0.
  final double lightBandStrength;

  /// Film grain overlay strength.
  ///
  /// GLSL uniform: [u_grain_intensity]. Valid range: 0.0–0.20.
  final double grainIntensity;

  /// Whether press-scale animation and shimmer feedback are enabled.
  ///
  /// When true, the glass element responds to pointer events with a
  /// spring-back scale animation and a shimmer sweep.
  final bool isInteractive;

  /// Returns a copy of this settings object with the specified fields replaced.
  LiquidGlassSettings copyWith({
    LiquidGlassVariant? variant,
    Color? tint,
    bool clearTint = false,
    double? blurSigma,
    double? refractiveIndex,
    double? refractionStrength,
    double? refractionFalloff,
    double? refractionFalloffExponent,
    double? saturation,
    double? chromaticAberration,
    double? lightAngle,
    double? lightIntensity,
    double? specularPower,
    double? specularKickPower,
    double? specularKickIntensity,
    double? lightBandOffset,
    double? lightBandWidth,
    double? lightBandStrength,
    double? grainIntensity,
    bool? isInteractive,
  }) {
    return LiquidGlassSettings(
      variant: variant ?? this.variant,
      tint: clearTint ? null : (tint ?? this.tint),
      blurSigma: blurSigma ?? this.blurSigma,
      refractiveIndex: refractiveIndex ?? this.refractiveIndex,
      refractionStrength: refractionStrength ?? this.refractionStrength,
      refractionFalloff: refractionFalloff ?? this.refractionFalloff,
      refractionFalloffExponent:
          refractionFalloffExponent ?? this.refractionFalloffExponent,
      saturation: saturation ?? this.saturation,
      chromaticAberration: chromaticAberration ?? this.chromaticAberration,
      lightAngle: lightAngle ?? this.lightAngle,
      lightIntensity: lightIntensity ?? this.lightIntensity,
      specularPower: specularPower ?? this.specularPower,
      specularKickPower: specularKickPower ?? this.specularKickPower,
      specularKickIntensity:
          specularKickIntensity ?? this.specularKickIntensity,
      lightBandOffset: lightBandOffset ?? this.lightBandOffset,
      lightBandWidth: lightBandWidth ?? this.lightBandWidth,
      lightBandStrength: lightBandStrength ?? this.lightBandStrength,
      grainIntensity: grainIntensity ?? this.grainIntensity,
      isInteractive: isInteractive ?? this.isInteractive,
    );
  }

  /// Linearly interpolates between two [LiquidGlassSettings] instances.
  ///
  /// Numeric fields are interpolated. Non-numeric fields ([variant],
  /// [isInteractive]) snap to [b]'s value at [t] >= 0.5. [tint] uses
  /// [Color.lerp].
  static LiquidGlassSettings lerp(
    LiquidGlassSettings a,
    LiquidGlassSettings b,
    double t,
  ) {
    return LiquidGlassSettings(
      variant: t < 0.5 ? a.variant : b.variant,
      tint: Color.lerp(a.tint, b.tint, t),
      blurSigma: _lerpDouble(a.blurSigma, b.blurSigma, t),
      refractiveIndex: _lerpDouble(a.refractiveIndex, b.refractiveIndex, t),
      refractionStrength:
          _lerpDouble(a.refractionStrength, b.refractionStrength, t),
      refractionFalloff:
          _lerpDouble(a.refractionFalloff, b.refractionFalloff, t),
      refractionFalloffExponent:
          _lerpDouble(a.refractionFalloffExponent, b.refractionFalloffExponent, t),
      saturation: _lerpDouble(a.saturation, b.saturation, t),
      chromaticAberration:
          _lerpDouble(a.chromaticAberration, b.chromaticAberration, t),
      lightAngle: _lerpDouble(a.lightAngle, b.lightAngle, t),
      lightIntensity: _lerpDouble(a.lightIntensity, b.lightIntensity, t),
      specularPower: _lerpDouble(a.specularPower, b.specularPower, t),
      specularKickPower: _lerpDouble(a.specularKickPower, b.specularKickPower, t),
      specularKickIntensity:
          _lerpDouble(a.specularKickIntensity, b.specularKickIntensity, t),
      lightBandOffset: _lerpDouble(a.lightBandOffset, b.lightBandOffset, t),
      lightBandWidth: _lerpDouble(a.lightBandWidth, b.lightBandWidth, t),
      lightBandStrength: _lerpDouble(a.lightBandStrength, b.lightBandStrength, t),
      grainIntensity: _lerpDouble(a.grainIntensity, b.grainIntensity, t),
      isInteractive: t < 0.5 ? a.isInteractive : b.isInteractive,
    );
  }

  static double _lerpDouble(double a, double b, double t) =>
      a + (b - a) * t;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LiquidGlassSettings) return false;
    return variant == other.variant &&
        tint == other.tint &&
        blurSigma == other.blurSigma &&
        refractiveIndex == other.refractiveIndex &&
        refractionStrength == other.refractionStrength &&
        refractionFalloff == other.refractionFalloff &&
        refractionFalloffExponent == other.refractionFalloffExponent &&
        saturation == other.saturation &&
        chromaticAberration == other.chromaticAberration &&
        lightAngle == other.lightAngle &&
        lightIntensity == other.lightIntensity &&
        specularPower == other.specularPower &&
        specularKickPower == other.specularKickPower &&
        specularKickIntensity == other.specularKickIntensity &&
        lightBandOffset == other.lightBandOffset &&
        lightBandWidth == other.lightBandWidth &&
        lightBandStrength == other.lightBandStrength &&
        grainIntensity == other.grainIntensity &&
        isInteractive == other.isInteractive;
  }

  @override
  int get hashCode => Object.hash(
        variant,
        tint,
        blurSigma,
        refractiveIndex,
        refractionStrength,
        refractionFalloff,
        refractionFalloffExponent,
        saturation,
        chromaticAberration,
        lightAngle,
        lightIntensity,
        specularPower,
        specularKickPower,
        specularKickIntensity,
        lightBandOffset,
        lightBandWidth,
        lightBandStrength,
        grainIntensity,
        isInteractive,
      );

  @override
  String toString() => 'LiquidGlassSettings('
      'variant: $variant, '
      'tint: $tint, '
      'blurSigma: $blurSigma, '
      'refractiveIndex: $refractiveIndex, '
      'refractionStrength: $refractionStrength, '
      'refractionFalloff: $refractionFalloff, '
      'refractionFalloffExponent: $refractionFalloffExponent, '
      'saturation: $saturation, '
      'chromaticAberration: $chromaticAberration, '
      'lightAngle: $lightAngle, '
      'lightIntensity: $lightIntensity, '
      'specularPower: $specularPower, '
      'specularKickPower: $specularKickPower, '
      'specularKickIntensity: $specularKickIntensity, '
      'lightBandOffset: $lightBandOffset, '
      'lightBandWidth: $lightBandWidth, '
      'lightBandStrength: $lightBandStrength, '
      'grainIntensity: $grainIntensity, '
      'isInteractive: $isInteractive'
      ')';
}
