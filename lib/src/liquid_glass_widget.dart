import 'dart:async' show StreamSubscription;
import 'dart:io' show Platform;
import 'dart:math' show atan2, min;
import 'dart:ui' as ui;

import 'package:sensors_plus/sensors_plus.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart' show StandardMessageCodec;
import 'package:flutter/widgets.dart';

import 'device_capabilities.dart';
import 'fluid_simulation.dart';
import 'glass_theme.dart';
import 'liquid_glass_fallback.dart';
import 'liquid_glass_group.dart';
import 'liquid_glass_mode.dart';
import 'liquid_glass_settings.dart';
import 'liquid_glass_shape.dart';
import 'liquid_glass_variant.dart';
import 'tier_resolver.dart';

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
  static const int fluidStrength = 31;
  static const int velocityX = 32;
  static const int velocityY = 33;
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
    with TickerProviderStateMixin {
  ui.FragmentShader? _shader;
  ui.FragmentShader? _fallbackShader;
  AnimationController? _touchController;
  Offset _touchPosition = Offset.zero;
  Offset _pointerVelocity = Offset.zero;

  FluidSimulation? _fluidSim;
  ui.Image? _displacementImage;
  Offset _lastPointerPosition = Offset.zero;
  DateTime _lastPointerTime = DateTime.now();
  AnimationController? _velocityDecayController;

  Ticker? _fluidTicker;

  RenderingTier? _resolvedTier;

  // Static so Impeller capability detection only happens once across all
  // instances. null = not yet determined.
  static bool? _supportsShader;

  // Static flag: emit the FlutterError.reportError fallback warning once only.
  static bool _fallbackErrorReported = false;

  // Static 1x1 neutral displacement image used when fluid simulation is
  // disabled. Prevents SIGSEGV on Mali/OpenGLES drivers that validate all
  // declared samplers regardless of shader branch conditions.
  static ui.Image? _dummyDisplacement;
  static bool _dummyDisplacementLoading = false;

  bool _disposed = false;

  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  double _gyroLightAngle = 0.0;
  double _gyroZFlatness = 2.0;

  @override
  void initState() {
    super.initState();
    _ensureDummyDisplacement();
    _initTierAndShaders();
    _initTouchController();
    _initVelocityDecay();
    if (widget.settings.enableFluid) {
      _initFluidSim();
      _startFluidTicker();
    }
  }

  /// Creates a static 1x1 RGBA image (128,128,0,255) representing zero
  /// displacement. Shared across all LiquidGlass instances.
  static void _ensureDummyDisplacement() {
    if (_dummyDisplacement != null || _dummyDisplacementLoading) return;
    _dummyDisplacementLoading = true;
    // 1x1 pixel: R=128 G=128 (maps to 0.0 displacement), B=0, A=255
    final bytes = Uint8List.fromList([128, 128, 0, 255]);
    ui.decodeImageFromPixels(
      bytes,
      1,
      1,
      ui.PixelFormat.rgba8888,
      (image) {
        _dummyDisplacement = image;
        _dummyDisplacementLoading = false;
      },
    );
  }

  void _initTierAndShaders() async {
    // For explicit non-auto modes, resolve immediately without querying device
    if (widget.mode != LiquidGlassMode.auto) {
      _resolvedTier = TierResolver.resolve(DeviceInfo.unsupported(), widget.mode);
    } else {
      final info = await DeviceCapabilities.query();
      if (_disposed) return;
      _resolvedTier = TierResolver.resolve(info, widget.mode);
    }

    TierResolver.logTier(_resolvedTier!);

    switch (_resolvedTier!) {
      case RenderingTier.tier1Shader:
        _loadShadersForTier1();
        return; // setState will be called when shader loads
      case RenderingTier.tier2Fallback:
        _loadFallbackShader();
        break;
      case RenderingTier.tier0Native:
      case RenderingTier.tier3PureFlutter:
        // No shaders needed
        break;
    }
    if (mounted) setState(() {});
  }

  void _loadShadersForTier1() {
    ui.FragmentProgram.fromAsset('packages/liquid_glass/shaders/liquid_glass.frag')
        .then((program) {
      if (_disposed) return;
      final shader = program.fragmentShader();
      if (_supportsShader == null) {
        try {
          ui.ImageFilter.shader(shader);
          _supportsShader = true;
        } on UnsupportedError {
          _supportsShader = false;
        }
      }
      setState(() { _shader = shader; });
      if (_supportsShader == false) {
        _reportFallbackOnce();
        _loadFallbackShader();
      }
    }).catchError((error) {
      if (kDebugMode) debugPrint('LiquidGlass: shader load failed: $error');
      // Fall back to Tier 2 on shader load failure
      _resolvedTier = RenderingTier.tier2Fallback;
      _loadFallbackShader();
      if (mounted) setState(() {});
    });
  }

  void _initTouchController() {
    _touchController = AnimationController(
      vsync: this,
    )..addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _initVelocityDecay() {
    _velocityDecayController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    )..addListener(() {
      if (mounted) {
        _pointerVelocity = Offset.lerp(_pointerVelocity, Offset.zero, _velocityDecayController!.value)!;
        setState(() {});
      }
    });
  }

  void _initFluidSim() {
    _fluidSim = FluidSimulation();
  }

  void _disposeFluidSim() {
    _fluidSim = null;
    _displacementImage?.dispose();
    _displacementImage = null;
  }

  void _startFluidTicker() {
    _fluidTicker?.stop();
    _fluidTicker?.dispose();
    _fluidTicker = createTicker((elapsed) {
      _fluidSim?.step(1.0 / 60.0);
      _updateDisplacementImage();
    });
    _fluidTicker!.start();
  }

  void _stopFluidTicker() {
    _fluidTicker?.stop();
    _fluidTicker?.dispose();
    _fluidTicker = null;
  }

  void _updateDisplacementImage() {
    if (_fluidSim == null) return;
    final bytes = _fluidSim!.getDisplacementBytes();
    ui.decodeImageFromPixels(
      bytes,
      _fluidSim!.gridSize,
      _fluidSim!.gridSize,
      ui.PixelFormat.rgba8888,
      (image) {
        _displacementImage?.dispose();
        _displacementImage = image;
        if (mounted) setState(() {});
      },
    );
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
          'LiquidGlass: ImageFilter.shader unavailable or unsafe on this '
          'backend (Android OpenGLES: flutter/flutter#164757). '
          'Using Tier 2 blur+specular fallback. '
          'Override with LiquidGlassMode.tier1 to force full shader.',
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
    final wasFluid = oldWidget.settings.enableFluid;
    final isFluid = widget.settings.enableFluid;
    if (wasFluid != isFluid) {
      if (isFluid) {
        _initFluidSim();
        _startFluidTicker();
      } else {
        _stopFluidTicker();
        _disposeFluidSim();
        _pointerVelocity = Offset.zero;
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _stopGyroscope();
    _touchController?.dispose();
    _velocityDecayController?.dispose();
    _stopFluidTicker();
    _disposeFluidSim();
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
        // Dark mode: visible cool blue-white ambient tint
        settings = settings.copyWith(
          tint: const Color(0x30B8C8F0),
        );
      } else {
        // Light mode: subtle warm ambient tint
        settings = settings.copyWith(
          tint: const Color(0x20F0E8D8),
        );
      }
    }

    return settings;
  }

  void _setUniforms(ui.FragmentShader shader, LiquidGlassSettings s,
      double mergeDistanceValue, bool fluidActive) {
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
    shader.setFloat(_Uniforms.fluidStrength, s.enableFluid ? s.fluidStrength : 0.0);

    // When fluid is active: velocity is injected into the fluid sim, so the
    // direct velocity uniforms are zeroed out (fluid handles distortion).
    // When fluid is inactive: velocity goes directly to uniforms.
    if (fluidActive) {
      shader.setFloat(_Uniforms.velocityX, 0.0);
      shader.setFloat(_Uniforms.velocityY, 0.0);
    } else {
      shader.setFloat(_Uniforms.velocityX, _pointerVelocity.dx);
      shader.setFloat(_Uniforms.velocityY, _pointerVelocity.dy);
    }
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

        // Fluid sim: inject force at touch point on pointer down
        if (_fluidSim != null) {
          final nx = event.localPosition.dx / elementSize.width;
          final ny = event.localPosition.dy / elementSize.height;
          _fluidSim!.injectForce(nx, ny, 0.0, 0.0, 0.1);
        }

        _lastPointerPosition = event.localPosition;
        _lastPointerTime = DateTime.now();
      },
      onPointerMove: (event) {
        final now = DateTime.now();
        final dt = now.difference(_lastPointerTime).inMicroseconds / 1e6;
        if (dt > 0) {
          final delta = event.localPosition - _lastPointerPosition;
          final rawVelocity = Offset(
            delta.dx / dt / elementSize.width,
            delta.dy / dt / elementSize.height,
          );
          // Low-pass filter with alpha=0.3
          const alpha = 0.3;
          final filtered = Offset(
            _pointerVelocity.dx * (1 - alpha) + rawVelocity.dx * alpha,
            _pointerVelocity.dy * (1 - alpha) + rawVelocity.dy * alpha,
          );
          // Normalize to unit range
          final magnitude = filtered.distance;
          final normalized = magnitude > 0
              ? Offset(filtered.dx / magnitude, filtered.dy / magnitude)
              : Offset.zero;

          if (_fluidSim != null) {
            // When fluid active: inject velocity as force into fluid sim
            final nx = event.localPosition.dx / elementSize.width;
            final ny = event.localPosition.dy / elementSize.height;
            _fluidSim!.injectForce(nx, ny, normalized.dx, normalized.dy, 0.1);
          } else {
            // When fluid inactive: update _pointerVelocity for direct shader distortion
            _pointerVelocity = normalized;
            setState(() {});
          }
        }
        _lastPointerPosition = event.localPosition;
        _lastPointerTime = now;
      },
      onPointerUp: (_) {
        _touchController?.duration = const Duration(milliseconds: 300);
        _touchController?.reverse();
        // Start velocity decay: animate to zero over 200ms
        _velocityDecayController?.forward(from: 0.0);
      },
      onPointerCancel: (_) {
        _touchController?.duration = const Duration(milliseconds: 300);
        _touchController?.reverse();
        _velocityDecayController?.forward(from: 0.0);
      },
      child: child,
    );
  }

  /// Builds the Tier 2 fallback: BackdropFilter blur + specular overlay.
  ///
  /// When the fallback shader is available, uses [GlassFallbackPainter] for
  /// the specular chrome. When no shaders are loaded at all (Android OpenGLES),
  /// uses a pure-Flutter gradient overlay to approximate specular highlights.
  Widget _buildTier2(BorderRadius borderRadius, LiquidGlassSettings settings) {
    // Cap sigma at 20: above this threshold the blur degrades in quality.
    final clampedSigma = min(settings.blurSigma, 20.0);

    // Specular overlay: shader-based if available, pure-Flutter gradient if not.
    final Widget specularOverlay;
    if (_fallbackShader != null) {
      specularOverlay = CustomPaint(
        painter: GlassFallbackPainter(
          settings: settings,
          shape: widget.shape,
          shader: _fallbackShader,
        ),
      );
    } else {
      // Pure-Flutter specular approximation for devices where shaders crash.
      // Diagonal gradient simulates a directional light source.
      specularOverlay = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0x1AFFFFFF),
              const Color(0x08FFFFFF),
              const Color(0x00FFFFFF),
              const Color(0x05FFFFFF),
            ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
          border: Border.all(
            color: const Color(0x20FFFFFF),
            width: 0.5,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: clampedSigma,
          sigmaY: clampedSigma,
        ),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(child: specularOverlay),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTier1Shader(BorderRadius borderRadius, LiquidGlassSettings effectiveSettings, double mergeDistance, bool fluidActive) {
    _setUniforms(_shader!, effectiveSettings, mergeDistance, fluidActive);

    if (effectiveSettings.enableFluid && _displacementImage != null) {
      _shader!.setImageSampler(1, _displacementImage!);
    } else if (_dummyDisplacement != null) {
      _shader!.setImageSampler(1, _dummyDisplacement!);
    }

    ui.ImageFilter filter;
    try {
      final sigma = min(effectiveSettings.blurSigma, 25.0);
      filter = ui.ImageFilter.compose(
        inner: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        outer: ui.ImageFilter.shader(_shader!),
      );
    } on UnsupportedError {
      _supportsShader = false;
      final clampedSigma = min(effectiveSettings.blurSigma, 20.0);
      filter = ui.ImageFilter.blur(sigmaX: clampedSigma, sigmaY: clampedSigma);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: filter,
        child: widget.child,
      ),
    );
  }

  Widget _buildTier0Native(BorderRadius borderRadius, LiquidGlassSettings settings) {
    if (kIsWeb) return _buildTier2(borderRadius, settings);

    final creationParams = _settingsToNativeParams(settings, widget.shape);

    if (!kIsWeb && Platform.isAndroid) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            AndroidView(
              viewType: 'liquid-glass-native-view',
              creationParams: creationParams,
              creationParamsCodec: const StandardMessageCodec(),
            ),
            widget.child,
          ],
        ),
      );
    }

    // Non-Android Tier 0 not yet implemented, fall back to Tier 2
    return _buildTier2(borderRadius, settings);
  }

  Map<String, dynamic> _settingsToNativeParams(LiquidGlassSettings s, LiquidGlassShape shape) {
    return {
      'blurSigma': s.blurSigma,
      'lightAngle': s.lightAngle,
      'lightIntensity': s.lightIntensity,
      'specularPower': s.specularPower,
      'specularKickPower': s.specularKickPower,
      'specularKickIntensity': s.specularKickIntensity,
      'lightBandOffset': s.lightBandOffset,
      'lightBandWidth': s.lightBandWidth,
      'lightBandStrength': s.lightBandStrength,
      'tintColor': s.tint?.toARGB32(),
      'cornerRadius': _shapeRadius(shape),
      'variant': s.variant == LiquidGlassVariant.clear ? 'clear' : 'regular',
    };
  }

  Widget _buildTier3PureFlutter(BorderRadius borderRadius, LiquidGlassSettings settings) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: const [
                      Color(0x1AFFFFFF),
                      Color(0x08FFFFFF),
                      Color(0x00FFFFFF),
                      Color(0x05FFFFFF),
                    ],
                    stops: const [0.0, 0.3, 0.6, 1.0],
                  ),
                  border: Border.all(color: const Color(0x20FFFFFF), width: 0.5),
                ),
              ),
            ),
          ),
        ],
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
    final fluidActive = effectiveSettings.enableFluid && _fluidSim != null;

    // Determine effective tier
    var effectiveTier = _resolvedTier;
    if (effectiveTier == null) {
      return widget.child; // Tier not yet resolved
    }

    // Theme mode override
    if (effectiveMode == LiquidGlassMode.tier2) {
      effectiveTier = RenderingTier.tier2Fallback;
    } else if (effectiveMode == LiquidGlassMode.native) {
      effectiveTier = RenderingTier.tier0Native;
    }

    Widget glassWidget;
    switch (effectiveTier) {
      case RenderingTier.tier0Native:
        glassWidget = _buildTier0Native(borderRadius, effectiveSettings);
      case RenderingTier.tier1Shader:
        if (_shader == null) return widget.child; // shader still loading
        glassWidget = _buildTier1Shader(borderRadius, effectiveSettings, mergeDistance, fluidActive);
      case RenderingTier.tier2Fallback:
        glassWidget = _buildTier2(borderRadius, effectiveSettings);
      case RenderingTier.tier3PureFlutter:
        glassWidget = _buildTier3PureFlutter(borderRadius, effectiveSettings);
    }
    glassWidget = _buildWithShadow(glassWidget, borderRadius);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return _wrapInteractive(glassWidget, size, isInteractive);
      },
    );
  }
}
