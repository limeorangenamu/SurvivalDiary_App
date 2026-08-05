import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/router/app_routes.dart';
import 'features/auth/auth_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();

  if (AppConfig.kakaoNativeAppKey.isNotEmpty) {
    KakaoSdk.init(nativeAppKey: AppConfig.kakaoNativeAppKey);
  }

  SystemChrome.setPreferredOrientations(
    const [DeviceOrientation.portraitUp],
  );

  try {
    await FlutterNaverMap()
        .init(
          clientId: 'sm91tb2q5d',
          onAuthFailed: (error) {
            debugPrint('네이버 지도 인증 실패: $error');
          },
        )
        .timeout(const Duration(seconds: 5));
  } on TimeoutException {
    debugPrint('Naver Map initialization timed out; continuing app startup.');
  } catch (error) {
    debugPrint(
        'Naver Map initialization failed; continuing app startup: $error');
  }

  final hasSession = await AuthSession.instance.restore();
  runApp(
    SurvivalDiaryApp(
      initialRoute: hasSession ? AppRoutes.root : AppRoutes.onboarding,
    ),
  );
}
