/// The visual variant of the glass effect, mapping directly to Apple's
/// three [Glass] static properties.
enum LiquidGlassVariant {
  /// Adaptive opacity with ambient tint extraction. Adjusts automatically
  /// based on the surrounding content and system brightness. Equivalent to
  /// Apple's [Glass.regular].
  regular,

  /// Static high transparency with no ambient tint extraction. The glass
  /// surface is always fully transparent with no color adaptation. Equivalent
  /// to Apple's [Glass.clear].
  clear,

  /// No glass effect; zero GPU cost. Renders the child without any glass
  /// processing. Equivalent to Apple's [Glass.identity] / [isEnabled: false].
  identity,
}
