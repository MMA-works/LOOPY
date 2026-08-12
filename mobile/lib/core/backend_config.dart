import 'package:flutter/foundation.dart';

class BackendConfig {
  static String get apiBaseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    
    // Cloud Production URL (Railway)
    return 'https://loopy-production.up.railway.app';
  }

  static String get webSocketUrl =>
      '${apiBaseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://')}/ws';

  static String absoluteUrl(String path) =>
      path.startsWith('http') ? path : '$apiBaseUrl$path';
}
