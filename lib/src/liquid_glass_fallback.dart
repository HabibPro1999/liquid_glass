import 'dart:ui';

import 'package:flutter/rendering.dart';

import 'liquid_glass_settings.dart';
import 'liquid_glass_shape.dart';

/// Internal CustomPainter that renders additive specular and rim chrome via
/// [shaders/lightweight_glass.frag] using [Paint.shader] + [BlendMode.plus].
///
/// This painter does NOT sample the backdrop — it only overlays chrome (key
/// specular, kick specular, rim, light band) on top of the blurred background
/// produced by the surrounding [BackdropFilter].
///
/// If the lightweight shader fails to load (e.g., test environments), the
/// painter does nothing; the blur underneath remains visible.
class GlassFallbackPainter extends CustomPainter {
  GlassFallbackPainter({
    required this.settings,
    required this.shape,
    required this.shader,
  });

  final LiquidGlassSettings settings;
  final LiquidGlassShape shape;

  /// May be null when the shader failed to load.
  final FragmentShader? shader;

  double _shapeRadius(LiquidGlassShape s) {
    return switch (s) {
      RoundedRect(:final radius) => radius,
      Squircle(:final radius) => radius,
      Circle() => 0.0,
      Capsule() => 0.0,
      Ellipse() => 0.0,
      Custom() => 20.0,
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final FragmentShader? fs = shader;
    if (fs == null) return;

    // Set uniforms in the order declared in lightweight_glass.frag.
    fs.setFloat(0, size.width);
    fs.setFloat(1, size.height);
    fs.setFloat(2, settings.lightAngle);
    fs.setFloat(3, settings.lightIntensity);
    fs.setFloat(4, settings.specularPower);
    fs.setFloat(5, settings.specularKickPower);
    fs.setFloat(6, settings.specularKickIntensity);
    // Rim opacity — matches kRimBaseOpacity from liquid_glass_widgets §4.2.
    fs.setFloat(7, 0.4);
    fs.setFloat(8, _shapeRadius(shape));

    final paint = Paint()
      ..shader = fs
      ..blendMode = BlendMode.plus;

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(GlassFallbackPainter oldDelegate) {
    return oldDelegate.settings != settings ||
        oldDelegate.shape != shape ||
        oldDelegate.shader != shader;
  }
}

/// Loads [shaders/lightweight_glass.frag] asynchronously and provides the
/// resulting [FragmentShader] to the caller.
///
/// Returns null if loading fails (e.g., missing asset in test environments).
Future<FragmentShader?> loadLightweightShader() async {
  try {
    final program =
        await FragmentProgram.fromAsset('shaders/lightweight_glass.frag');
    return program.fragmentShader();
  } catch (_) {
    return null;
  }
}
