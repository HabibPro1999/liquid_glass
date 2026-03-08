import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint, TargetPlatform;
import 'device_capabilities.dart';
import 'liquid_glass_mode.dart';

/// The resolved rendering tier for a LiquidGlass instance.
enum RenderingTier {
  /// Tier 0: Native platform view (Android RenderEffect/BlurView, iOS UIVisualEffectView)
  tier0Native,
  /// Tier 1: Full Impeller GLSL shader (Metal on iOS, Vulkan on Android)
  tier1Shader,
  /// Tier 2: Impeller blur + lightweight specular shader (Skia, web)
  tier2Fallback,
  /// Tier 3: Pure Flutter widgets (universal safety net, no shaders at all)
  tier3PureFlutter,
}

class TierResolver {
  static bool _logged = false;

  static RenderingTier resolve(
    DeviceInfo info,
    LiquidGlassMode mode, {
    TargetPlatform? platformOverride,
  }) {
    switch (mode) {
      case LiquidGlassMode.tier1:
        return RenderingTier.tier1Shader;
      case LiquidGlassMode.tier2:
        return RenderingTier.tier2Fallback;
      case LiquidGlassMode.native:
        return RenderingTier.tier0Native;
      case LiquidGlassMode.auto:
        break;
    }

    // Auto mode routing
    if (platformOverride == null && kIsWeb) {
      return RenderingTier.tier2Fallback;
    }

    final bool isIOS = platformOverride == TargetPlatform.iOS ||
        (platformOverride == null && !kIsWeb && Platform.isIOS);
    final bool isAndroid = platformOverride == TargetPlatform.android ||
        (platformOverride == null && !kIsWeb && Platform.isAndroid);
    final bool isDesktop = platformOverride == TargetPlatform.macOS ||
        platformOverride == TargetPlatform.linux ||
        platformOverride == TargetPlatform.windows ||
        (platformOverride == null &&
            !kIsWeb &&
            (Platform.isMacOS || Platform.isLinux || Platform.isWindows));

    if (isIOS) {
      return RenderingTier.tier1Shader;
    }

    if (isAndroid) {
      if (info.supportsVulkan) {
        return RenderingTier.tier1Shader;
      }
      if (info.apiLevel >= 21) {
        return RenderingTier.tier0Native;
      }
      return RenderingTier.tier3PureFlutter;
    }

    if (isDesktop) {
      return RenderingTier.tier2Fallback;
    }

    return RenderingTier.tier2Fallback;
  }

  static void logTier(RenderingTier tier) {
    if (!kDebugMode || _logged) return;
    _logged = true;
    switch (tier) {
      case RenderingTier.tier0Native:
        debugPrint('LiquidGlass: using Tier 0 (native platform glass view)');
      case RenderingTier.tier1Shader:
        debugPrint('LiquidGlass: using Tier 1 (Impeller shader)');
      case RenderingTier.tier2Fallback:
        debugPrint('LiquidGlass: using Tier 2 (blur + specular fallback)');
      case RenderingTier.tier3PureFlutter:
        debugPrint('LiquidGlass: using Tier 3 (pure Flutter)');
    }
  }
}
