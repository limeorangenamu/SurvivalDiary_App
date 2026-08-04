import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const kakaoNativeAppKey = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
  );

  static String get apiBaseUrl {
    if (_configuredApiBaseUrl.isNotEmpty) {
      return _configuredApiBaseUrl;
    }
    return kIsWeb ? 'http://localhost:8080' : 'http://10.100.105.9:8080';
  }
}
