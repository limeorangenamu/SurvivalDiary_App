import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations(
    const [DeviceOrientation.portraitUp],
  );

  await FlutterNaverMap().init(
    clientId: 'sm91tb2q5d',
    onAuthFailed: (error) {
      debugPrint('네이버 지도 인증 실패: $error');
    },
  );

  runApp(const SurvivalDiaryApp());
}