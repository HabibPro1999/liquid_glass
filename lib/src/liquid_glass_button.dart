import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import 'liquid_glass_settings.dart';
import 'liquid_glass_shape.dart';
import 'liquid_glass_widget.dart';

/// Visual style preset for [LiquidGlassButton].
enum LiquidGlassButtonStyle {
  /// Primary prominent button — higher light intensity, slightly stronger tint.
  primary,

  /// Secondary subtle button — standard glass appearance.
  secondary,
}

/// A liquid-glass styled button with a press-scale spring animation.
///
/// Wraps [LiquidGlass] with gesture handling that animates to [pressedScale]
/// on tap-down and springs back on tap-up, then fires [onPressed].
///
/// When [onPressed] is null the button is disabled and shows no animation.
/// When `MediaQuery.disableAnimations` is active the scale animation is
/// skipped entirely and [onPressed] is called immediately on tap.
class LiquidGlassButton extends StatefulWidget {
  const LiquidGlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style = LiquidGlassButtonStyle.secondary,
    this.settings,
    this.shape,
    this.pressedScale = 0.94,
  });

  /// The widget to display inside the button.
  final Widget child;

  /// Called when the button is tapped. Null disables the button.
  final VoidCallback? onPressed;

  /// Visual style preset controlling light intensity and tint.
  final LiquidGlassButtonStyle style;

  /// Optional settings override applied on top of the [style] defaults.
  final LiquidGlassSettings? settings;

  /// Shape of the glass surface. Defaults to [LiquidGlassShape.capsule].
  final LiquidGlassShape? shape;

  /// Scale factor applied during press. Range: 0.0–1.0. Defaults to 0.94.
  final double pressedScale;

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _shimmerController;
  bool _animationsDisabled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..addListener(() {
      if (mounted) setState(() {});
    });
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationsDisabled = MediaQuery.of(context).disableAnimations;
  }

  @override
  void dispose() {
    _controller.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  double get _scale {
    return 1.0 - (_controller.value * (1.0 - widget.pressedScale));
  }

  void _handleTapDown(TapDownDetails details) {
    if (_animationsDisabled) return;
    _controller.duration = const Duration(milliseconds: 100);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (_animationsDisabled) {
      widget.onPressed?.call();
      return;
    }
    final spring = const SpringDescription(
      mass: 1.0,
      stiffness: 500.0,
      damping: 25.0,
    );
    final simulation = SpringSimulation(
      spring,
      _controller.value,
      0.0,
      -_controller.velocity,
    );
    _controller.animateWith(simulation);
    _shimmerController.forward(from: 0.0);
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (_animationsDisabled) return;
    final spring = const SpringDescription(
      mass: 1.0,
      stiffness: 500.0,
      damping: 25.0,
    );
    final simulation = SpringSimulation(
      spring,
      _controller.value,
      0.0,
      -_controller.velocity,
    );
    _controller.animateWith(simulation);
  }

  LiquidGlassSettings get _effectiveSettings {
    final styleDefaults = switch (widget.style) {
      LiquidGlassButtonStyle.primary => const LiquidGlassSettings(
          lightIntensity: 1.6,
          tint: Color(0x1A007AFF),
        ),
      LiquidGlassButtonStyle.secondary => const LiquidGlassSettings(),
    };

    final userSettings = widget.settings;
    if (userSettings == null) return styleDefaults;

    return styleDefaults.copyWith(
      variant: userSettings.variant,
      tint: userSettings.tint,
      blurSigma: userSettings.blurSigma,
      refractiveIndex: userSettings.refractiveIndex,
      refractionStrength: userSettings.refractionStrength,
      refractionFalloff: userSettings.refractionFalloff,
      refractionFalloffExponent: userSettings.refractionFalloffExponent,
      saturation: userSettings.saturation,
      chromaticAberration: userSettings.chromaticAberration,
      lightAngle: userSettings.lightAngle,
      lightIntensity: userSettings.lightIntensity,
      specularPower: userSettings.specularPower,
      specularKickPower: userSettings.specularKickPower,
      specularKickIntensity: userSettings.specularKickIntensity,
      lightBandOffset: userSettings.lightBandOffset,
      lightBandWidth: userSettings.lightBandWidth,
      lightBandStrength: userSettings.lightBandStrength,
      grainIntensity: userSettings.grainIntensity,
      isInteractive: userSettings.isInteractive,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shimmerPhase =
        _shimmerController.isAnimating ? _shimmerController.value : -1.0;

    return GestureDetector(
      onTapDown: widget.onPressed != null ? _handleTapDown : null,
      onTapUp: widget.onPressed != null ? _handleTapUp : null,
      onTapCancel: widget.onPressed != null ? _handleTapCancel : null,
      child: Transform.scale(
        scale: _scale,
        child: LiquidGlass(
          settings: _effectiveSettings.copyWith(shimmerPhase: shimmerPhase),
          shape: widget.shape ?? LiquidGlassShape.capsule(),
          child: widget.child,
        ),
      ),
    );
  }
}
