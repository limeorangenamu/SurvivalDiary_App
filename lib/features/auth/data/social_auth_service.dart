import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../auth_session.dart';
import 'auth_api_client.dart';

enum SocialAuthProvider { kakao, naver }

class SocialAuthService {
  SocialAuthService({AuthApiClient? apiClient})
      : _apiClient = apiClient ?? AuthApiClient();

  final AuthApiClient _apiClient;

  Future<void> login(SocialAuthProvider provider) async {
    final providerToken = switch (provider) {
      SocialAuthProvider.kakao => await _loginWithKakao(),
      SocialAuthProvider.naver => await _loginWithNaver(),
    };

    late final AuthTokens tokens;
    try {
      tokens = await _apiClient.socialLogin(
        provider: provider.name,
        providerAccessToken: providerToken,
      );
    } on AuthApiException catch (error) {
      throw AuthApiException(
        '${provider.name} 인증은 완료됐지만 생존일기 서버 로그인에 실패했습니다.\n${error.message}',
      );
    }

    await AuthSession.instance.establishSession(
      tokens,
      apiClient: _apiClient,
    );
  }

  Future<String> _loginWithKakao() async {
    try {
      final token = await _loginWithKakaoAccountFallback();
      return token.accessToken;
    } catch (error, stackTrace) {
      debugPrint('Kakao login failed: $error\n$stackTrace');
      throw AuthApiException(
        '카카오 로그인에 실패했습니다.\n원인: $error',
      );
    }
  }

  Future<OAuthToken> _loginWithKakaoAccountFallback() async {
    if (!await isKakaoTalkInstalled()) {
      return UserApi.instance.loginWithKakaoAccount();
    }

    try {
      return await UserApi.instance.loginWithKakaoTalk();
    } on PlatformException catch (error) {
      if (error.code != 'NotSupportError' ||
          !(error.message ?? '').contains('not connected to Kakao account')) {
        rethrow;
      }
      debugPrint(
        'KakaoTalk is not connected to an account; falling back to Kakao Account login.',
      );
      return UserApi.instance.loginWithKakaoAccount();
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
      throw AuthApiException(
        '네이버 로그인에 실패했습니다.\n원인: $error',
      );
    }
  }
}
