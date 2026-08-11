import 'package:flutter/foundation.dart';

class BackendConfig {
  static String get apiBaseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) return 'http://127.0.0.1:8081';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8081'
        : 'http://127.0.0.1:8081';
  }

  static String get webSocketUrl =>
      '${apiBaseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://')}/ws';

  static String absoluteUrl(String path) =>
      path.startsWith('http') ? path : '$apiBaseUrl$path';
}
