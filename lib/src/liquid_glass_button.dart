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

  final Widget child;
  final VoidCallback? onPressed;
  final LiquidGlassButtonStyle style;
  final LiquidGlassSettings? settings;
  final LiquidGlassShape? shape;
  final double pressedScale;

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _animationsDisabled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationsDisabled = MediaQuery.of(context).disableAnimations;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _scale {
    return 1.0 - (_scaleAnimation.value * (1.0 - widget.pressedScale));
  }

  void _handleTapDown(TapDownDetails details) {
    if (_animationsDisabled) return;
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (_animationsDisabled) {
      widget.onPressed?.call();
      return;
    }
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (_animationsDisabled) return;
    _controller.reverse();
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
    return GestureDetector(
      onTapDown: widget.onPressed != null ? _handleTapDown : null,
      onTapUp: widget.onPressed != null ? _handleTapUp : null,
      onTapCancel: widget.onPressed != null ? _handleTapCancel : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scale,
          child: child,
        ),
        child: LiquidGlass(
          settings: _effectiveSettings,
          shape: widget.shape ?? LiquidGlassShape.capsule(),
          child: widget.child,
        ),
      ),
    );
  }
}
