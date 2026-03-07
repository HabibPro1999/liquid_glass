enum LiquidGlassMode {
  auto,   // detect Impeller capability at runtime (default)
  tier1,  // force full shader path (crashes on non-Impeller — debug use)
  tier2,  // force fallback path (for performance testing or accessibility)
}
