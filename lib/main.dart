import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations(
    const [DeviceOrientation.portraitUp],
  );

  try {
    await FlutterNaverMap().init(
      clientId: 'sm91tb2q5d',
      onAuthFailed: (error) {
      debugPrint('네이버 지도 인증 실패: $error');
      },
    ).timeout(const Duration(seconds: 5));
  } on TimeoutException {
    debugPrint('Naver Map initialization timed out; continuing app startup.');
  } catch (error) {
    debugPrint('Naver Map initialization failed; continuing app startup: $error');
  }

  runApp(const SurvivalDiaryApp());
}
