import 'package:flutter/painting.dart';

/// Describes the shape of a [LiquidGlass] surface.
///
/// Each subtype maps to a GLSL SDF function in the shader library.
/// Use the factory constructors to create shapes.
sealed class LiquidGlassShape {
  const LiquidGlassShape._();

  /// A squircle (iOS-style continuous curvature corner) shape.
  ///
  /// Maps to the [sdSuperellipse] GLSL function. This is the iOS system
  /// default continuous corner profile.
  static LiquidGlassShape squircle({double radius = 20.0}) =>
      Squircle(radius: radius);

  /// A rounded rectangle shape.
  ///
  /// Maps to the [sdRoundedRect] GLSL function.
  static LiquidGlassShape roundedRect({double radius = 12.0}) =>
      RoundedRect(radius: radius);

  /// A perfect circle shape.
  ///
  /// Maps to the [sdCircle] GLSL function.
  static LiquidGlassShape circle() => Circle();

  /// A capsule (full pill / stadium) shape.
  ///
  /// Maps to the [sdCapsule] GLSL function.
  static LiquidGlassShape capsule() => Capsule();

  /// An axis-aligned ellipse shape.
  ///
  /// Maps to the [sdEllipse] GLSL function.
  static LiquidGlassShape ellipse() => Ellipse();

  /// The default shape: a squircle with radius 20.0.
  static const LiquidGlassShape defaultShape = Squircle(radius: 20.0);

  /// Converts a Flutter [ShapeBorder] to the closest [LiquidGlassShape].
  ///
  /// Known types are mapped to their SDF equivalents. Unrecognized types
  /// fall back to [Custom], which uses [ClipPath] with [ShapeBorderClipper]
  /// for visual clipping and a squircle SDF approximation for glass effects.
  static LiquidGlassShape fromShapeBorder(ShapeBorder border) {
    return switch (border) {
      RoundedRectangleBorder(:final borderRadius) =>
        RoundedRect(radius: borderRadius.resolve(TextDirection.ltr).topLeft.x),
      CircleBorder() => const Circle(),
      StadiumBorder() => const Capsule(),
      ContinuousRectangleBorder() => const Squircle(radius: 20.0),
      _ => Custom(shapeBorder: border),
    };
  }
}

/// A squircle (iOS-style continuous curvature corner) shape.
///
/// Produced by [LiquidGlassShape.squircle].
final class Squircle extends LiquidGlassShape {
  const Squircle({required this.radius}) : super._();

  /// The corner radius. Defaults to 20.0, which produces the iOS system
  /// default continuous corner profile.
  final double radius;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Squircle &&
          runtimeType == other.runtimeType &&
          radius == other.radius;

  @override
  int get hashCode => radius.hashCode;

  @override
  String toString() => 'Squircle(radius: $radius)';
}

/// A rounded rectangle shape.
///
/// Produced by [LiquidGlassShape.roundedRect].
final class RoundedRect extends LiquidGlassShape {
  const RoundedRect({required this.radius}) : super._();

  /// The corner radius. Defaults to 12.0.
  final double radius;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoundedRect &&
          runtimeType == other.runtimeType &&
          radius == other.radius;

  @override
  int get hashCode => radius.hashCode;

  @override
  String toString() => 'RoundedRect(radius: $radius)';
}

/// A perfect circle shape.
///
/// Produced by [LiquidGlassShape.circle].
final class Circle extends LiquidGlassShape {
  const Circle() : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Circle;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'Circle()';
}

/// A capsule (full pill / stadium) shape.
///
/// Produced by [LiquidGlassShape.capsule].
final class Capsule extends LiquidGlassShape {
  const Capsule() : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Capsule;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'Capsule()';
}

/// An axis-aligned ellipse shape.
///
/// Produced by [LiquidGlassShape.ellipse].
final class Ellipse extends LiquidGlassShape {
  const Ellipse() : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Ellipse;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'Ellipse()';
}

/// A fallback shape wrapping an arbitrary [ShapeBorder].
///
/// Produced by [LiquidGlassShape.fromShapeBorder] for unrecognized border
/// types. The widget clips using [ClipPath] with [ShapeBorderClipper] and
/// approximates SDF glass effects using a squircle with radius 20.0.
final class Custom extends LiquidGlassShape {
  const Custom({required this.shapeBorder}) : super._();

  /// The Flutter [ShapeBorder] used for visual clipping.
  final ShapeBorder shapeBorder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Custom && identical(shapeBorder, other.shapeBorder);

  @override
  int get hashCode => identityHashCode(shapeBorder);

  @override
  String toString() => 'Custom(shapeBorder: $shapeBorder)';
}
