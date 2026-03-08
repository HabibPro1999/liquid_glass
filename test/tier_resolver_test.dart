import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass/src/device_capabilities.dart';
import 'package:liquid_glass/src/liquid_glass_mode.dart';
import 'package:liquid_glass/src/tier_resolver.dart';

void main() {
  const DeviceInfo vulkanDevice = DeviceInfo(
    vulkanLevel: 1,
    vulkanVersion: 0x401000,
    apiLevel: 33,
    gpuRenderer: 'Adreno 730',
    supportsVulkan: true,
  );
  const DeviceInfo openGLESDevice = DeviceInfo(
    vulkanLevel: -1,
    vulkanVersion: 0,
    apiLevel: 30,
    gpuRenderer: 'Mali-G51',
    supportsVulkan: false,
  );
  const DeviceInfo legacyDevice = DeviceInfo(
    vulkanLevel: -1,
    vulkanVersion: 0,
    apiLevel: 19,
    gpuRenderer: 'Adreno 306',
    supportsVulkan: false,
  );

  // ---------------------------------------------------------------------------
  // Explicit mode overrides
  // ---------------------------------------------------------------------------
  group('Explicit mode overrides', () {
    test('mode=tier1 with vulkanDevice → tier1Shader', () {
      expect(
        TierResolver.resolve(vulkanDevice, LiquidGlassMode.tier1),
        RenderingTier.tier1Shader,
      );
    });

    test('mode=tier1 with openGLESDevice → tier1Shader', () {
      expect(
        TierResolver.resolve(openGLESDevice, LiquidGlassMode.tier1),
        RenderingTier.tier1Shader,
      );
    });

    test('mode=tier1 with legacyDevice → tier1Shader', () {
      expect(
        TierResolver.resolve(legacyDevice, LiquidGlassMode.tier1),
        RenderingTier.tier1Shader,
      );
    });

    test('mode=tier2 with vulkanDevice → tier2Fallback', () {
      expect(
        TierResolver.resolve(vulkanDevice, LiquidGlassMode.tier2),
        RenderingTier.tier2Fallback,
      );
    });

    test('mode=tier2 with openGLESDevice → tier2Fallback', () {
      expect(
        TierResolver.resolve(openGLESDevice, LiquidGlassMode.tier2),
        RenderingTier.tier2Fallback,
      );
    });

    test('mode=tier2 with legacyDevice → tier2Fallback', () {
      expect(
        TierResolver.resolve(legacyDevice, LiquidGlassMode.tier2),
        RenderingTier.tier2Fallback,
      );
    });

    test('mode=native with vulkanDevice → tier0Native', () {
      expect(
        TierResolver.resolve(vulkanDevice, LiquidGlassMode.native),
        RenderingTier.tier0Native,
      );
    });

    test('mode=native with openGLESDevice → tier0Native', () {
      expect(
        TierResolver.resolve(openGLESDevice, LiquidGlassMode.native),
        RenderingTier.tier0Native,
      );
    });

    test('mode=native with legacyDevice → tier0Native', () {
      expect(
        TierResolver.resolve(legacyDevice, LiquidGlassMode.native),
        RenderingTier.tier0Native,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Auto mode — Android + Vulkan
  // ---------------------------------------------------------------------------
  group('Auto mode: Android with Vulkan support', () {
    test('supportsVulkan=true, platformOverride=android → tier1Shader', () {
      expect(
        TierResolver.resolve(
          vulkanDevice,
          LiquidGlassMode.auto,
          platformOverride: TargetPlatform.android,
        ),
        RenderingTier.tier1Shader,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Auto mode — Android without Vulkan, API >= 21
  // ---------------------------------------------------------------------------
  group('Auto mode: Android without Vulkan, API >= 21', () {
    test(
        'supportsVulkan=false, apiLevel=31, platformOverride=android → tier0Native',
        () {
      const DeviceInfo device = DeviceInfo(
        vulkanLevel: -1,
        vulkanVersion: 0,
        apiLevel: 31,
        gpuRenderer: 'Mali-G51',
        supportsVulkan: false,
      );
      expect(
        TierResolver.resolve(
          device,
          LiquidGlassMode.auto,
          platformOverride: TargetPlatform.android,
        ),
        RenderingTier.tier0Native,
      );
    });

    test(
        'openGLESDevice (apiLevel=30), platformOverride=android → tier0Native',
        () {
      expect(
        TierResolver.resolve(
          openGLESDevice,
          LiquidGlassMode.auto,
          platformOverride: TargetPlatform.android,
        ),
        RenderingTier.tier0Native,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Auto mode — Android without Vulkan, API < 21
  // ---------------------------------------------------------------------------
  group('Auto mode: Android without Vulkan, API < 21', () {
    test(
        'supportsVulkan=false, apiLevel=19, platformOverride=android → tier3PureFlutter',
        () {
      expect(
        TierResolver.resolve(
          legacyDevice,
          LiquidGlassMode.auto,
          platformOverride: TargetPlatform.android,
        ),
        RenderingTier.tier3PureFlutter,
      );
    });

    test('apiLevel=20, platformOverride=android → tier3PureFlutter', () {
      const DeviceInfo device = DeviceInfo(
        vulkanLevel: -1,
        vulkanVersion: 0,
        apiLevel: 20,
        gpuRenderer: 'Adreno 306',
        supportsVulkan: false,
      );
      expect(
        TierResolver.resolve(
          device,
          LiquidGlassMode.auto,
          platformOverride: TargetPlatform.android,
        ),
        RenderingTier.tier3PureFlutter,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Auto mode — iOS
  // ---------------------------------------------------------------------------
  group('Auto mode: iOS', () {
    test('vulkanDevice, platformOverride=iOS → tier1Shader', () {
      expect(
        TierResolver.resolve(
          vulkanDevice,
          LiquidGlassMode.auto,
          platformOverride: TargetPlatform.iOS,
        ),
        RenderingTier.tier1Shader,
      );
    });

    test('DeviceInfo.unsupported(), platformOverride=iOS → tier1Shader', () {
      expect(
        TierResolver.resolve(
          DeviceInfo.unsupported(),
          LiquidGlassMode.auto,
          platformOverride: TargetPlatform.iOS,
        ),
        RenderingTier.tier1Shader,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Auto mode — Desktop
  // ---------------------------------------------------------------------------
  group('Auto mode: desktop', () {
    test('platformOverride=macOS → tier2Fallback', () {
      expect(
        TierResolver.resolve(
          vulkanDevice,
          LiquidGlassMode.auto,
          platformOverride: TargetPlatform.macOS,
        ),
        RenderingTier.tier2Fallback,
      );
    });

    test('platformOverride=linux → tier2Fallback', () {
      expect(
        TierResolver.resolve(
          vulkanDevice,
          LiquidGlassMode.auto,
          platformOverride: TargetPlatform.linux,
        ),
        RenderingTier.tier2Fallback,
      );
    });

    test('platformOverride=windows → tier2Fallback', () {
      expect(
        TierResolver.resolve(
          vulkanDevice,
          LiquidGlassMode.auto,
          platformOverride: TargetPlatform.windows,
        ),
        RenderingTier.tier2Fallback,
      );
    });

    test('no platformOverride (test host is macOS) → tier2Fallback', () {
      // On the macOS CI/test host, Platform.isMacOS is true, so no override
      // is needed — the resolver falls through to the desktop branch.
      expect(
        TierResolver.resolve(vulkanDevice, LiquidGlassMode.auto),
        RenderingTier.tier2Fallback,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Auto mode — DeviceInfo.unsupported() on Android
  // ---------------------------------------------------------------------------
  group('Auto mode: DeviceInfo.unsupported() on Android', () {
    test(
        'unsupported has apiLevel=0, platformOverride=android → tier3PureFlutter',
        () {
      expect(
        TierResolver.resolve(
          DeviceInfo.unsupported(),
          LiquidGlassMode.auto,
          platformOverride: TargetPlatform.android,
        ),
        RenderingTier.tier3PureFlutter,
      );
    });
  });
}
