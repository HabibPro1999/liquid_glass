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
  ///
  /// Available in Phase 2.
  static LiquidGlassShape roundedRect({double radius = 8.0}) =>
      throw UnimplementedError(
        'LiquidGlassShape.roundedRect is available in Phase 2.',
      );

  /// A perfect circle shape.
  ///
  /// Maps to the [sdCircle] GLSL function.
  ///
  /// Available in Phase 2.
  static LiquidGlassShape circle() =>
      throw UnimplementedError(
        'LiquidGlassShape.circle is available in Phase 2.',
      );

  /// A capsule (full pill / stadium) shape.
  ///
  /// Maps to the [sdCapsule] GLSL function.
  ///
  /// Available in Phase 2.
  static LiquidGlassShape capsule() =>
      throw UnimplementedError(
        'LiquidGlassShape.capsule is available in Phase 2.',
      );

  /// An axis-aligned ellipse shape.
  ///
  /// Maps to the [sdEllipse] GLSL function.
  ///
  /// Available in Phase 2.
  static LiquidGlassShape ellipse() =>
      throw UnimplementedError(
        'LiquidGlassShape.ellipse is available in Phase 2.',
      );

  /// The default shape: a squircle with radius 20.0.
  static const LiquidGlassShape defaultShape = Squircle(radius: 20.0);
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
