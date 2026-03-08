import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/services.dart'
    show MethodChannel, MissingPluginException, PlatformException;

class DeviceInfo {
  const DeviceInfo({
    required this.vulkanLevel,
    required this.vulkanVersion,
    required this.apiLevel,
    required this.gpuRenderer,
    required this.supportsVulkan,
  });

  final int vulkanLevel;
  final int vulkanVersion;
  final int apiLevel;
  final String gpuRenderer;
  final bool supportsVulkan;

  factory DeviceInfo.unsupported() => const DeviceInfo(
        vulkanLevel: -1,
        vulkanVersion: 0,
        apiLevel: 0,
        gpuRenderer: 'unsupported',
        supportsVulkan: false,
      );

  factory DeviceInfo.fromMap(Map<dynamic, dynamic> map) => DeviceInfo(
        vulkanLevel: (map['vulkanLevel'] as num?)?.toInt() ?? -1,
        vulkanVersion: (map['vulkanVersion'] as num?)?.toInt() ?? 0,
        apiLevel: (map['apiLevel'] as num?)?.toInt() ?? 0,
        gpuRenderer: (map['gpuRenderer'] as String?) ?? 'unsupported',
        supportsVulkan: (map['supportsVulkan'] as bool?) ?? false,
      );
}

class DeviceCapabilities {
  static const MethodChannel _channel = MethodChannel('liquid_glass');

  static DeviceInfo? _cached;

  static Future<DeviceInfo> query() async {
    if (_cached != null) return _cached!;

    if (kIsWeb || !Platform.isAndroid) {
      _cached = DeviceInfo.unsupported();
      return _cached!;
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getDeviceCapabilities',
      );
      _cached = result != null
          ? DeviceInfo.fromMap(result)
          : DeviceInfo.unsupported();
    } on MissingPluginException {
      _cached = DeviceInfo.unsupported();
    } on PlatformException {
      _cached = DeviceInfo.unsupported();
    }

    return _cached!;
  }

  @visibleForTesting
  static void resetForTesting() {
    _cached = null;
  }
}
