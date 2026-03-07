import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'liquid_glass_fallback.dart';
import 'liquid_glass_mode.dart';
import 'liquid_glass_settings.dart';
import 'liquid_glass_shape.dart';
import 'liquid_glass_variant.dart';

// Uniform index constants matching the shader's float declaration order.
// See shaders/liquid_glass.frag for the authoritative ordering.
class _Uniforms {
  static const int width = 0;
  static const int height = 1;
  static const int blurSigma = 2;
  static const int refractiveIndex = 3;
  static const int refractStrength = 4;
  static const int distortFalloff = 5;
  static const int distortExponent = 6;
  static const int saturation = 7;
  static const int chromaticAberration = 8;
  static const int lightAngle = 9;
  static const int lightIntensity = 10;
  static const int specPower = 11;
  static const int specKickPower = 12;
  static const int specKickIntensity = 13;
  static const int lightbandOffset = 14;
  static const int lightbandWidth = 15;
  static const int lightbandStrength = 16;
  static const int grainIntensity = 17;
  static const int tintR = 18;
  static const int tintG = 19;
  static const int tintB = 20;
  static const int tintA = 21;
  static const int shapeType = 22;
  static const int shapeRadius = 23;
  static const int variant = 24;
}

// Shape type values matching the evalSDF switch in liquid_glass.frag.
class _ShapeType {
  static const double roundedRect = 0.0;
  static const double squircle = 1.0;
  static const double circle = 2.0;
  static const double capsule = 3.0;
  static const double ellipse = 4.0;
}

// Variant values matching the GLSL comment: 0=regular, 1=clear, 2=identity.
class _VariantValue {
  static const double regular = 0.0;
  static const double clear = 1.0;
  static const double identity = 2.0;
}

/// A widget that applies Apple-style Liquid Glass effect to its child.
///
/// On Impeller-backed platforms (iOS, Android with Vulkan), this renders
/// using a custom GLSL fragment shader via [ImageFilter.shader]. On platforms
/// where [ImageFilter.shader] is not supported (Skia, web), it falls back to
/// a [ImageFilter.blur] + additive specular chrome via [GlassFallbackPainter].
///
/// Set [isEnabled] to false or use [LiquidGlassVariant.identity] to render
/// the child without any glass processing at zero GPU cost.
///
/// Use [mode] to override the automatic backend detection:
/// - [LiquidGlassMode.auto] (default): detect Impeller at runtime.
/// - [LiquidGlassMode.tier1]: force full shader path (debug use only).
/// - [LiquidGlassMode.tier2]: force fallback path (accessibility / perf testing).
class LiquidGlass extends StatefulWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.settings = const LiquidGlassSettings(),
    this.shape = LiquidGlassShape.defaultShape,
    this.isEnabled = true,
    this.mode = LiquidGlassMode.auto,
  });

  final Widget child;
  final LiquidGlassSettings settings;
  final LiquidGlassShape shape;
  final bool isEnabled;
  final LiquidGlassMode mode;

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass> {
  FragmentShader? _shader;
  FragmentShader? _fallbackShader;

  // Static so Impeller capability detection only happens once across all
  // instances. null = not yet determined.
  static bool? _supportsShader;

  // Static flag: emit the FlutterError.reportError fallback warning once only.
  static bool _fallbackErrorReported = false;

  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _loadShaders();
  }

  void _loadShaders() {
    // If mode forces tier2, skip the main shader and only load the fallback.
    if (widget.mode == LiquidGlassMode.tier2) {
      _loadFallbackShader();
      return;
    }

    FragmentProgram.fromAsset('shaders/liquid_glass.frag').then((program) {
      if (_disposed) return;
      final shader = program.fragmentShader();
      // Detect Impeller capability once, by attempting to create an
      // ImageFilter.shader. Skia and web throw UnsupportedError.
      if (_supportsShader == null) {
        try {
          ImageFilter.shader(shader);
          _supportsShader = true;
        } on UnsupportedError {
          _supportsShader = false;
        }
      }
      setState(() {
        _shader = shader;
      });

      // If the backend does not support ImageFilter.shader, also load the
      // lightweight fallback shader for chrome overlay.
      if (_supportsShader == false) {
        _reportFallbackOnce();
        _loadFallbackShader();
      }
    }).catchError((_) {
      // Shader loading failed (e.g., missing asset in test env).
      // Widget gracefully degrades to showing the child.
    });
  }

  void _loadFallbackShader() {
    loadLightweightShader().then((shader) {
      if (_disposed) return;
      setState(() {
        _fallbackShader = shader;
      });
    });
  }

  void _reportFallbackOnce() {
    if (kDebugMode && !_fallbackErrorReported) {
      _fallbackErrorReported = true;
      final details = FlutterErrorDetails(
        exception: UnsupportedError(
          'LiquidGlass: ImageFilter.shader unavailable on this backend. '
          'Using Tier 2 blur+specular fallback.',
        ),
        library: 'liquid_glass',
        context: ErrorDescription('while initializing LiquidGlass rendering'),
      );
      // In test environments (flutter test), FlutterError.reportError propagates
      // through the test binding and fails the test. Use dumpErrorToConsole to
      // ensure the diagnostic is always visible without failing tests.
      // In production debug builds, also call reportError so registered handlers
      // (e.g. Crashlytics) receive the notification.
      FlutterError.dumpErrorToConsole(details, forceReport: true);
      if (!_isTestEnvironment) {
        FlutterError.reportError(details);
      }
    }
  }

  static bool get _isTestEnvironment {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  @override
  void didUpdateWidget(LiquidGlass oldWidget) {
    super.didUpdateWidget(oldWidget);
    // No need to reload the shader; just mark that uniforms need re-setting
    // on the next build. The build method always re-sets all uniforms, so
    // there is nothing explicit to do here.
  }

  @override
  void dispose() {
    _disposed = true;
    _shader?.dispose();
    _shader = null;
    _fallbackShader?.dispose();
    _fallbackShader = null;
    super.dispose();
  }

  void _setUniforms(FragmentShader shader, double width, double height) {
    final s = widget.settings;
    final tint = s.tint;

    shader.setFloat(_Uniforms.width, width);
    shader.setFloat(_Uniforms.height, height);
    shader.setFloat(_Uniforms.blurSigma, s.blurSigma);
    shader.setFloat(_Uniforms.refractiveIndex, s.refractiveIndex);
    shader.setFloat(_Uniforms.refractStrength, s.refractionStrength);
    shader.setFloat(_Uniforms.distortFalloff, s.refractionFalloff);
    shader.setFloat(_Uniforms.distortExponent, s.refractionFalloffExponent);
    shader.setFloat(_Uniforms.saturation, s.saturation);
    shader.setFloat(_Uniforms.chromaticAberration, s.chromaticAberration);
    shader.setFloat(_Uniforms.lightAngle, s.lightAngle);
    shader.setFloat(_Uniforms.lightIntensity, s.lightIntensity);
    shader.setFloat(_Uniforms.specPower, s.specularPower);
    shader.setFloat(_Uniforms.specKickPower, s.specularKickPower);
    shader.setFloat(_Uniforms.specKickIntensity, s.specularKickIntensity);
    shader.setFloat(_Uniforms.lightbandOffset, s.lightBandOffset);
    shader.setFloat(_Uniforms.lightbandWidth, s.lightBandWidth);
    shader.setFloat(_Uniforms.lightbandStrength, s.lightBandStrength);
    shader.setFloat(_Uniforms.grainIntensity, s.grainIntensity);

    // Tint: RGBA components, 0 if null.
    shader.setFloat(_Uniforms.tintR, tint == null ? 0.0 : tint.r);
    shader.setFloat(_Uniforms.tintG, tint == null ? 0.0 : tint.g);
    shader.setFloat(_Uniforms.tintB, tint == null ? 0.0 : tint.b);
    shader.setFloat(_Uniforms.tintA, tint == null ? 0.0 : tint.a);

    // Shape type and radius.
    shader.setFloat(_Uniforms.shapeType, _shapeTypeValue(widget.shape));
    shader.setFloat(_Uniforms.shapeRadius, _shapeRadius(widget.shape));

    // Variant.
    shader.setFloat(_Uniforms.variant, _variantValue(s.variant));
  }

  double _shapeTypeValue(LiquidGlassShape shape) {
    return switch (shape) {
      RoundedRect() => _ShapeType.roundedRect,
      Squircle() => _ShapeType.squircle,
      Circle() => _ShapeType.circle,
      Capsule() => _ShapeType.capsule,
      Ellipse() => _ShapeType.ellipse,
    };
  }

  double _shapeRadius(LiquidGlassShape shape) {
    return switch (shape) {
      RoundedRect(:final radius) => radius,
      Squircle(:final radius) => radius,
      Circle() => 0.0,
      Capsule() => 0.0,
      Ellipse() => 0.0,
    };
  }

  double _variantValue(LiquidGlassVariant v) {
    return switch (v) {
      LiquidGlassVariant.regular => _VariantValue.regular,
      LiquidGlassVariant.clear => _VariantValue.clear,
      LiquidGlassVariant.identity => _VariantValue.identity,
    };
  }

  BorderRadius _shapeBorderRadius(LiquidGlassShape shape) {
    return switch (shape) {
      RoundedRect(:final radius) => BorderRadius.circular(radius),
      Squircle(:final radius) => BorderRadius.circular(radius),
      Circle() => BorderRadius.circular(9999),
      Capsule() => BorderRadius.circular(9999),
      Ellipse() => BorderRadius.circular(9999),
    };
  }

  /// Builds the Tier 2 fallback: BackdropFilter blur + additive chrome overlay.
  Widget _buildTier2(BorderRadius borderRadius) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.settings.blurSigma,
          sigmaY: widget.settings.blurSigma,
        ),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: GlassFallbackPainter(
                    settings: widget.settings,
                    shape: widget.shape,
                    shader: _fallbackShader,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Zero GPU cost paths.
    if (!widget.isEnabled ||
        widget.settings.variant == LiquidGlassVariant.identity) {
      return widget.child;
    }

    final borderRadius = _shapeBorderRadius(widget.shape);

    // mode: tier2 — always use the fallback, skip shader loading entirely.
    if (widget.mode == LiquidGlassMode.tier2) {
      return _buildTier2(borderRadius);
    }

    // Shader not yet loaded — show child without glass until ready.
    if (_shader == null) {
      return widget.child;
    }

    // mode: tier1 — force the shader path regardless of backend capability.
    if (widget.mode == LiquidGlassMode.tier1 || _supportsShader == true) {
      // Tier 1: Impeller path — full shader-based glass effect.
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isInfinite
              ? MediaQuery.sizeOf(context).width
              : constraints.maxWidth;
          final height = constraints.maxHeight.isInfinite
              ? MediaQuery.sizeOf(context).height
              : constraints.maxHeight;

          _setUniforms(_shader!, width, height);

          ImageFilter filter;
          try {
            filter = ImageFilter.shader(_shader!);
          } on UnsupportedError {
            _supportsShader = false;
            filter = ImageFilter.blur(
              sigmaX: widget.settings.blurSigma,
              sigmaY: widget.settings.blurSigma,
            );
          }

          return ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: filter,
              child: widget.child,
            ),
          );
        },
      );
    } else {
      // Tier 2: fallback blur + specular chrome for Skia / web / old Android.
      return _buildTier2(borderRadius);
    }
  }
}
