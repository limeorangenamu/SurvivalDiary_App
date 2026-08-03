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
    final tokens = await _apiClient.socialLogin(
      provider: provider.name,
      providerAccessToken: providerToken,
    );
    await AuthSession.instance.establishSession(
      tokens,
      apiClient: _apiClient,
    );
  }

  Future<String> _loginWithKakao() async {
    try {
      final token = await (await isKakaoTalkInstalled()
          ? UserApi.instance.loginWithKakaoTalk()
          : UserApi.instance.loginWithKakaoAccount());
      return token.accessToken;
    } catch (error) {
      throw const AuthApiException('카카오 로그인을 완료하지 못했어요. 다시 시도해 주세요.');
    }
  }

  Future<String> _loginWithNaver() async {
    try {
      final result = await FlutterNaverLogin.logIn();
      if (result.status != NaverLoginStatus.loggedIn) {
        throw const AuthApiException('네이버 로그인이 취소되었어요.');
      }
      final token = await FlutterNaverLogin.getCurrentAccessToken();
      if (!token.isValid()) {
        throw const AuthApiException('네이버 인증 토큰을 확인하지 못했어요.');
      }
      return token.accessToken;
    } on AuthApiException {
      rethrow;
    } catch (error) {
      throw const AuthApiException('네이버 로그인을 완료하지 못했어요. 다시 시도해 주세요.');
    }
  }
}
