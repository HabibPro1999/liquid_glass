import 'dart:async' show StreamSubscription;
import 'dart:io' show Platform;
import 'dart:math' show atan2, min;
import 'dart:ui';

import 'package:sensors_plus/sensors_plus.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'glass_theme.dart';
import 'liquid_glass_fallback.dart';
import 'liquid_glass_group.dart';
import 'liquid_glass_mode.dart';
import 'liquid_glass_settings.dart';
import 'liquid_glass_shape.dart';
import 'liquid_glass_variant.dart';

// Uniform index constants matching the shader's float declaration order.
// See shaders/liquid_glass.frag for the authoritative ordering.
// Indices 0 and 1 (u_width, u_height) are auto-set by the engine when used
// via ImageFilter.shader — do NOT call setFloat for them from Dart.
class _Uniforms {
  // 0: u_width  — auto-set by engine
  // 1: u_height — auto-set by engine
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
  static const int mergeDistance = 25;
  static const int zFlatness = 26;
  static const int touchX = 27;
  static const int touchY = 28;
  static const int touchIntensity = 29;
  static const int shimmerPhase = 30;
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
    this.showShadow = true,
  });

  /// The widget to render inside the glass surface.
  final Widget child;

  /// Visual parameters for the glass effect.
  final LiquidGlassSettings settings;

  /// The SDF shape that defines the glass surface boundary.
  final LiquidGlassShape shape;

  /// Whether the glass effect is applied.
  ///
  /// When false the [child] is returned directly at zero GPU cost.
  final bool isEnabled;

  /// Rendering backend selection.
  ///
  /// Defaults to [LiquidGlassMode.auto], which detects Impeller support at
  /// runtime. Override with [LiquidGlassMode.tier2] to force the fallback path.
  final LiquidGlassMode mode;

  /// Whether to render a drop shadow beneath the glass surface.
  /// Adds perceived depth/elevation. Defaults to true.
  final bool showShadow;

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass>
    with SingleTickerProviderStateMixin {
  FragmentShader? _shader;
  FragmentShader? _fallbackShader;
  AnimationController? _touchController;
  Offset _touchPosition = Offset.zero;

  // Static so Impeller capability detection only happens once across all
  // instances. null = not yet determined.
  static bool? _supportsShader;

  // Static flag: emit the FlutterError.reportError fallback warning once only.
  static bool _fallbackErrorReported = false;

  bool _disposed = false;

  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  double _gyroLightAngle = 0.0;
  double _gyroZFlatness = 2.0;

  @override
  void initState() {
    super.initState();
    _loadShaders();
    _initTouchController();
  }

  void _initTouchController() {
    _touchController = AnimationController(
      vsync: this,
    )..addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _startGyroscope(LiquidGlassSettings settings) {
    _accelSubscription?.cancel();
    try {
      _accelSubscription = accelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen((event) {
        if (!mounted) return;
        final rawAngle = atan2(event.x, event.y) * settings.gyroscopeSensitivity;
        _gyroLightAngle = _gyroLightAngle * 0.85 + rawAngle * 0.15;
        final rawZ = (event.z / 9.81).clamp(-1.0, 1.0);
        _gyroZFlatness = _gyroZFlatness * 0.85 + (2.0 + rawZ * 1.5) * 0.15;
        setState(() {});
      });
    } catch (_) {
      // Platform doesn't support accelerometer — silently ignore
    }
  }

  void _stopGyroscope() {
    _accelSubscription?.cancel();
    _accelSubscription = null;
  }

  void _loadShaders() {
    // If mode forces tier2, skip the main shader and only load the fallback.
    if (widget.mode == LiquidGlassMode.tier2) {
      _loadFallbackShader();
      return;
    }

    FragmentProgram.fromAsset('packages/liquid_glass/shaders/liquid_glass.frag')
        .then((program) {
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
    }).catchError((error) {
      // Shader loading failed — widget degrades to showing the child.
      if (kDebugMode) {
        debugPrint('LiquidGlass: shader load failed: $error');
      }
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
    _stopGyroscope();
    _touchController?.dispose();
    _shader?.dispose();
    _shader = null;
    _fallbackShader?.dispose();
    _fallbackShader = null;
    super.dispose();
  }

  LiquidGlassSettings _effectiveSettings(BuildContext context) {
    final mq = MediaQuery.of(context);
    final themeData = GlassTheme.maybeOf(context);

    // Start from theme settings if widget uses defaults, otherwise widget settings.
    var settings = widget.settings;
    if (themeData != null) {
      if (settings == const LiquidGlassSettings()) {
        settings = themeData.settings;
      }
      // Apply variant override from theme if present.
      if (themeData.variant != null &&
          settings.variant == LiquidGlassVariant.regular) {
        settings = settings.copyWith(variant: themeData.variant);
      }
    }

    // reduceTransparency proxy: disableAnimations is the closest available
    // Flutter API. When active, force identity variant so glass is skipped.
    if (mq.disableAnimations) {
      settings = settings.copyWith(variant: LiquidGlassVariant.identity);
    }

    // highContrast: boost saturation and lightIntensity for legibility.
    if (mq.highContrast) {
      settings = settings.copyWith(saturation: 1.35, lightIntensity: 1.8);
    }

    // disableAnimations: disable interactive physics and shimmer.
    if (mq.disableAnimations) {
      settings = settings.copyWith(isInteractive: false);
    }

    // platformBrightness tint adaptation for regular variant
    if (settings.variant == LiquidGlassVariant.regular &&
        settings.tint == null) {
      final brightness = MediaQuery.platformBrightnessOf(context);
      if (brightness == Brightness.dark) {
        // Dark mode: apply subtle neutral warm tint lift
        settings = settings.copyWith(
          tint: const Color(0x0DFFFFFF), // very subtle white lift
        );
      }
      // Light mode: no automatic tint (transparent/clear is correct)
    }

    return settings;
  }

  void _setUniforms(FragmentShader shader, LiquidGlassSettings s,
      double mergeDistanceValue) {
    final tint = s.tint;

    // Indices 0, 1 (u_width, u_height) are auto-set by the engine via
    // ImageFilter.shader — do not set them from Dart.
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

    // Merge distance from group scope (0.0 if no group or no spacing).
    shader.setFloat(_Uniforms.mergeDistance, mergeDistanceValue);

    shader.setFloat(_Uniforms.zFlatness, s.zFlatness);

    shader.setFloat(_Uniforms.touchX, _touchPosition.dx);
    shader.setFloat(_Uniforms.touchY, _touchPosition.dy);
    shader.setFloat(_Uniforms.touchIntensity, _touchController?.value ?? 0.0);
    shader.setFloat(_Uniforms.shimmerPhase, s.shimmerPhase);
  }

  double _shapeTypeValue(LiquidGlassShape shape) {
    return switch (shape) {
      RoundedRect() => _ShapeType.roundedRect,
      Squircle() => _ShapeType.squircle,
      Circle() => _ShapeType.circle,
      Capsule() => _ShapeType.capsule,
      Ellipse() => _ShapeType.ellipse,
      Custom() => _ShapeType.squircle,
    };
  }

  double _shapeRadius(LiquidGlassShape shape) {
    return switch (shape) {
      RoundedRect(:final radius) => radius,
      Squircle(:final radius) => radius,
      Circle() => 0.0,
      Capsule() => 0.0,
      Ellipse() => 0.0,
      Custom() => 20.0,
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
      Custom() => BorderRadius.circular(20.0),
    };
  }

  Widget _buildWithShadow(Widget glassWidget, BorderRadius borderRadius) {
    if (!widget.showShadow) return glassWidget;
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: glassWidget,
    );
  }

  Widget _wrapInteractive(Widget child, Size elementSize, bool isInteractive) {
    if (!isInteractive) return child;
    return Listener(
      onPointerDown: (event) {
        _touchPosition = Offset(
          event.localPosition.dx / elementSize.width,
          event.localPosition.dy / elementSize.height,
        );
        _touchController?.duration = const Duration(milliseconds: 150);
        _touchController?.forward(from: 0.0);
      },
      onPointerUp: (_) {
        _touchController?.duration = const Duration(milliseconds: 300);
        _touchController?.reverse();
      },
      onPointerCancel: (_) {
        _touchController?.duration = const Duration(milliseconds: 300);
        _touchController?.reverse();
      },
      child: child,
    );
  }

  /// Builds the Tier 2 fallback: BackdropFilter blur + additive chrome overlay.
  ///
  /// Half-sigma blur at full resolution approximates full-sigma at half
  /// resolution, avoiding artifacts above sigma 25 (docs/05 §5.2).
  Widget _buildTier2(BorderRadius borderRadius, LiquidGlassSettings settings) {
    // Cap sigma at 20: above this threshold the blur degrades in quality.
    final clampedSigma = min(settings.blurSigma, 20.0);
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: clampedSigma,
          sigmaY: clampedSigma,
        ),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: GlassFallbackPainter(
                    settings: settings,
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
    // Step 1: User-explicit disabled check — zero GPU cost.
    if (!widget.isEnabled) {
      return widget.child;
    }

    // Step 2: User-explicit identity variant — zero GPU cost.
    if (widget.settings.variant == LiquidGlassVariant.identity) {
      return widget.child;
    }

    // Step 3: Apply accessibility overrides to get effective settings.
    var effectiveSettings = _effectiveSettings(context);

    // Step 3b: Read group merge distance for shader uniform (u_merge_distance).
    final mergeDistance = LiquidGlassGroup.spacingOf(context) ?? 0.0;

    // Step 3c: Compute effective mode — theme can override auto.
    final themeData = GlassTheme.maybeOf(context);
    final effectiveMode = widget.mode != LiquidGlassMode.auto
        ? widget.mode
        : (themeData?.mode ?? LiquidGlassMode.auto);

    // Step 4: Accessibility may have forced identity variant (e.g. reduceTransparency proxy).
    if (effectiveSettings.variant == LiquidGlassVariant.identity) {
      _stopGyroscope();
      return widget.child;
    }

    // Step 4b: Apply gyroscope light overrides when enabled and motion is allowed.
    final mq = MediaQuery.of(context);
    if (effectiveSettings.enableGyroscope && !mq.disableAnimations) {
      if (_accelSubscription == null) {
        _startGyroscope(effectiveSettings);
      }
      effectiveSettings = effectiveSettings.copyWith(
        lightAngle: _gyroLightAngle,
        zFlatness: _gyroZFlatness,
      );
    } else {
      _stopGyroscope();
    }

    // Step 5: Use effective settings for all rendering.
    final borderRadius = _shapeBorderRadius(widget.shape);
    final isInteractive = effectiveSettings.isInteractive;

    Widget glassWidget;

    // mode: tier2 — always use the fallback, skip shader loading entirely.
    if (effectiveMode == LiquidGlassMode.tier2) {
      glassWidget = _buildWithShadow(_buildTier2(borderRadius, effectiveSettings), borderRadius);
    } else if (_shader == null) {
      // Shader not yet loaded — show child without glass until ready.
      return widget.child;
    } else if (effectiveMode == LiquidGlassMode.tier1 || _supportsShader == true) {
      // Tier 1: Impeller path — full shader-based glass effect.
      _setUniforms(_shader!, effectiveSettings, mergeDistance);

      ImageFilter filter;
      try {
        final sigma = min(effectiveSettings.blurSigma, 25.0);
        filter = ImageFilter.compose(
          inner: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          outer: ImageFilter.shader(_shader!),
        );
      } on UnsupportedError {
        _supportsShader = false;
        final clampedSigma = min(effectiveSettings.blurSigma, 20.0);
        filter = ImageFilter.blur(
          sigmaX: clampedSigma,
          sigmaY: clampedSigma,
        );
      }

      glassWidget = _buildWithShadow(
        ClipRRect(
          borderRadius: borderRadius,
          child: BackdropFilter(
            filter: filter,
            child: widget.child,
          ),
        ),
        borderRadius,
      );
    } else {
      // Tier 2: fallback blur + specular chrome for Skia / web / old Android.
      glassWidget = _buildWithShadow(_buildTier2(borderRadius, effectiveSettings), borderRadius);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return _wrapInteractive(glassWidget, size, isInteractive);
      },
    );
  }
}
