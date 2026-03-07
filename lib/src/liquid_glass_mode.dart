/// Controls which rendering backend [LiquidGlass] uses.
///
/// [auto] is the recommended value for production. [tier1] and [tier2] exist
/// for debugging and accessibility overrides.
enum LiquidGlassMode {
  /// Detect Impeller capability at runtime and choose the best tier. Default.
  auto,

  /// Force the full Impeller shader path regardless of backend capability.
  ///
  /// Only use this during development. On non-Impeller backends this will
  /// throw an [UnsupportedError] from [ImageFilter.shader].
  tier1,

  /// Force the blur + specular fallback path.
  ///
  /// Useful for performance testing, screenshot testing, or when you want to
  /// explicitly opt in to the accessibility-friendly Tier 2 appearance.
  tier2,
}
