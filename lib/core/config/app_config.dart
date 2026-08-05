import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppConfig {
  AppConfig._();

  static const _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _configuredKakaoNativeAppKey = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
  );
  static const _configuredNaverLoginClientId = String.fromEnvironment(
    'NAVER_LOGIN_CLIENT_ID',
  );
  static const _configuredNaverLoginClientSecret = String.fromEnvironment(
    'NAVER_LOGIN_CLIENT_SECRET',
  );

  static const _channel = MethodChannel(
    'com.survivaldiary.project_survival_diary/app_config',
  );
  static String _apiBaseUrl = _configuredApiBaseUrl;
  static String kakaoNativeAppKey = _configuredKakaoNativeAppKey;
  static String naverLoginClientId = _configuredNaverLoginClientId;
  static String naverLoginClientSecret = _configuredNaverLoginClientSecret;
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final native = await _channel.invokeMapMethod<String, String>('get');
        _apiBaseUrl = _preferConfigured(
          _configuredApiBaseUrl,
          native?['apiBaseUrl'],
        );
        kakaoNativeAppKey = _preferConfigured(
          _configuredKakaoNativeAppKey,
          native?['kakaoNativeAppKey'],
        );
        naverLoginClientId = _preferConfigured(
          _configuredNaverLoginClientId,
          native?['naverLoginClientId'],
        );
        naverLoginClientSecret = _preferConfigured(
          _configuredNaverLoginClientSecret,
          native?['naverLoginClientSecret'],
        );
      } on PlatformException catch (error) {
        debugPrint('Native app configuration unavailable: $error');
      }
    }
    _loaded = true;
  }

  static String _preferConfigured(String configured, String? native) =>
      configured.isNotEmpty ? configured : (native ?? '');

  static String get apiBaseUrl {
    if (_apiBaseUrl.isNotEmpty) {
      return _apiBaseUrl;
    }
    return kIsWeb ? 'http://localhost:8080' : 'http://10.100.105.9:8080';
  }
}
