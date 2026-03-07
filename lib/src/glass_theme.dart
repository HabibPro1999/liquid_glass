import 'package:flutter/widgets.dart';

import 'liquid_glass_mode.dart';
import 'liquid_glass_settings.dart';
import 'liquid_glass_variant.dart';

class GlassThemeData {
  const GlassThemeData({
    this.settings = const LiquidGlassSettings(),
    this.mode = LiquidGlassMode.auto,
    this.variant,
  });

  final LiquidGlassSettings settings;
  final LiquidGlassMode mode;

  /// If non-null, overrides the variant in [settings] for all descendants.
  final LiquidGlassVariant? variant;

  /// Light-mode defaults (standard glass appearance).
  const GlassThemeData.light()
      : settings = const LiquidGlassSettings(),
        mode = LiquidGlassMode.auto,
        variant = null;

  /// Dark-mode defaults with subtle white tint lift.
  const GlassThemeData.dark()
      : settings = const LiquidGlassSettings(
          tint: Color(0x0DFFFFFF),
        ),
        mode = LiquidGlassMode.auto,
        variant = null;

  GlassThemeData copyWith({
    LiquidGlassSettings? settings,
    LiquidGlassMode? mode,
    LiquidGlassVariant? variant,
    bool clearVariant = false,
  }) {
    return GlassThemeData(
      settings: settings ?? this.settings,
      mode: mode ?? this.mode,
      variant: clearVariant ? null : (variant ?? this.variant),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GlassThemeData) return false;
    return settings == other.settings &&
        mode == other.mode &&
        variant == other.variant;
  }

  @override
  int get hashCode => Object.hash(settings, mode, variant);
}

class GlassTheme extends InheritedWidget {
  const GlassTheme({
    super.key,
    required this.data,
    required super.child,
  });

  final GlassThemeData data;

  static GlassThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<GlassTheme>();
    return theme?.data ?? const GlassThemeData();
  }

  static GlassThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GlassTheme>()?.data;
  }

  @override
  bool updateShouldNotify(GlassTheme old) => data != old.data;
}
