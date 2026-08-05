import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../../../core/config/app_config.dart';
import '../auth_session.dart';
import 'auth_api_client.dart';

enum SocialAuthProvider { kakao, naver }

class SocialAuthService {
  SocialAuthService({AuthApiClient? apiClient})
      : _apiClient = apiClient ?? AuthApiClient();

  final AuthApiClient _apiClient;

  // Kakao apps without business verification can reliably provide the
  // nickname scope. Other profile fields remain optional on the backend.
  static const _kakaoProfileScopes = <String>[
    'profile_nickname',
  ];

  Future<void> login(SocialAuthProvider provider) async {
    _validateConfiguration(provider);
    final providerToken = switch (provider) {
      SocialAuthProvider.kakao => await _loginWithKakao(),
      SocialAuthProvider.naver => await _loginWithNaver(),
    };
    if (providerToken.trim().isEmpty) {
      throw AuthApiException(
        '${_providerLabel(provider)} 인증 서버가 빈 액세스 토큰을 반환했습니다.',
      );
    }
    debugPrint(
      '${provider.name} provider access token acquired '
      '(length: ${providerToken.length}); exchanging with backend.',
    );

    late final AuthTokens tokens;
    try {
      tokens = await _apiClient.socialLogin(
        provider: provider.name,
        providerAccessToken: providerToken,
      );
    } on AuthApiException catch (error) {
      throw AuthApiException(
        '${_providerLabel(provider)} 인증은 완료됐지만 '
        '생존일기 서버 로그인에 실패했습니다.\n${error.message}',
      );
    }

    await AuthSession.instance.establishSession(tokens, apiClient: _apiClient);
  }

  void _validateConfiguration(SocialAuthProvider provider) {
    if (provider == SocialAuthProvider.kakao &&
        AppConfig.kakaoNativeAppKey.isEmpty) {
      throw const AuthApiException(
        '카카오 Native App Key가 앱에 전달되지 않았습니다.\n'
        '--dart-define-from-file=config/local.json 옵션으로 다시 빌드해 주세요.',
      );
    }
  }

  Future<String> _loginWithKakao() async {
    try {
      final token = await _loginWithKakaoAccountFallback();
      return token.accessToken;
    } catch (error, stackTrace) {
      debugPrint('Kakao login failed: $error\n$stackTrace');
      throw AuthApiException('카카오 로그인에 실패했습니다.\n원인: $error');
    }
  }

  Future<OAuthToken> _loginWithKakaoAccountFallback() async {
    late final OAuthToken token;
    if (!await isKakaoTalkInstalled()) {
      token = await UserApi.instance.loginWithKakaoAccount();
    } else {
      try {
        token = await UserApi.instance.loginWithKakaoTalk();
      } on PlatformException catch (error) {
        if (error.code != 'NotSupportError' ||
            !(error.message ?? '').contains('not connected to Kakao account')) {
          rethrow;
        }
        token = await UserApi.instance.loginWithKakaoAccount();
      }
    }

    return _requestMissingKakaoScopes(token);
  }

  Future<OAuthToken> _requestMissingKakaoScopes(OAuthToken token) async {
    try {
      final scopeInfo = await UserApi.instance.scopes();
      final agreedScopes = {
        for (final scope in scopeInfo.scopes ?? <Scope>[])
          if (scope.agreed) scope.id,
      };
      final missingScopes = _kakaoProfileScopes
          .where((scope) => !agreedScopes.contains(scope))
          .toList();

      if (missingScopes.isEmpty) return token;

      debugPrint(
        'Requesting Kakao consent scopes: ${missingScopes.join(', ')}',
      );
      return UserApi.instance.loginWithNewScopes(missingScopes);
    } catch (error, stackTrace) {
      // A scope that is not enabled in the Kakao console must not prevent
      // login. The backend will persist every field Kakao actually returns.
      debugPrint(
          'Kakao additional consent request failed: $error\n$stackTrace');
      return token;
    }
  }

  Future<String> _loginWithNaver() async {
    try {
      final result = await FlutterNaverLogin.logIn();
      if (result.status != NaverLoginStatus.loggedIn) {
        throw const AuthApiException('네이버 로그인이 취소되었습니다.');
      }
      final token = await FlutterNaverLogin.getCurrentAccessToken();
      if (!token.isValid()) {
        throw const AuthApiException('네이버 인증 토큰을 확인하지 못했습니다.');
      }
      return token.accessToken;
    } on AuthApiException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Naver login failed: $error\n$stackTrace');
      throw AuthApiException('네이버 로그인에 실패했습니다.\n원인: $error');
    }
  }

  String _providerLabel(SocialAuthProvider provider) => switch (provider) {
        SocialAuthProvider.kakao => '카카오',
        SocialAuthProvider.naver => '네이버',
      };
}
