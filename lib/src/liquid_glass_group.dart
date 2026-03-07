import 'package:flutter/widgets.dart';

class _GroupScope extends InheritedWidget {
  const _GroupScope({
    required super.child,
    required this.spacing,
  });

  final double? spacing;

  static _GroupScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GroupScope>();

  @override
  bool updateShouldNotify(_GroupScope old) => spacing != old.spacing;
}

/// A container that groups [LiquidGlass] elements to enable shared compositing
/// context and optional merging behaviour.
///
/// Place [LiquidGlass] widgets inside a [LiquidGlassGroup] to allow them to
/// share rendering context. When [spacing] is non-null, elements within the
/// group that are close enough to each other will merge their glass surfaces.
///
/// [LiquidGlassGroup] must not be nested inside another [LiquidGlassGroup].
/// Two groups at the same hierarchy level are fine; nested groups produce
/// double-compositing artifacts and trigger a debug assertion.
class LiquidGlassGroup extends StatefulWidget {
  const LiquidGlassGroup({
    super.key,
    required this.child,
    this.spacing,
  });

  /// The widget subtree containing [LiquidGlass] elements.
  final Widget child;

  /// Merge distance in logical pixels.
  /// - null: no merging (elements are visually independent) — default
  /// - 0.0: merge only on physical overlap
  /// - N > 0: elements begin merging when within N logical pixels
  final double? spacing;

  /// Returns the [spacing] value from the nearest enclosing [LiquidGlassGroup],
  /// or null if there is no enclosing group.
  static double? spacingOf(BuildContext context) =>
      _GroupScope.maybeOf(context)?.spacing;

  @override
  State<LiquidGlassGroup> createState() => _LiquidGlassGroupState();
}

class _LiquidGlassGroupState extends State<LiquidGlassGroup> {
  @override
  Widget build(BuildContext context) {
    assert(() {
      final parent = context.getInheritedWidgetOfExactType<_GroupScope>();
      if (parent != null) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: FlutterError(
            'LiquidGlassGroup must not be nested. '
            'Two groups at the same hierarchy level are fine; '
            'nested groups produce double-compositing artifacts.',
          ),
          library: 'liquid_glass',
        ));
      }
      return true;
    }());

    return _GroupScope(
      spacing: widget.spacing,
      child: widget.child,
    );
  }
}
