/// Controls which rendering backend [LiquidGlass] uses.
///
/// [auto] is the recommended value for production. [tier1] and [tier2] exist
/// for debugging and accessibility overrides.
enum LiquidGlassMode {
  /// Detect capability at runtime and choose the best tier. Default.
  auto,

  /// Force the full Impeller shader path regardless of backend capability.
  /// On non-Impeller or OpenGLES backends this may crash. Use at your own risk.
  tier1,

  /// Force the blur + specular fallback path.
  tier2,

  /// Force native platform view rendering (Tier 0).
  /// Uses Android RenderEffect/BlurView or iOS UIVisualEffectView.
  native,
}
