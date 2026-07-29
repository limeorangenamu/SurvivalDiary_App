import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';

class SurvivalDiaryApp extends StatelessWidget {
  const SurvivalDiaryApp({super.key, this.initialRoute = AppRoutes.onboarding});

  /// 시작 라우트. 로그인 상태 연동(#33) 전까지는 항상 온보딩에서 시작하고,
  /// 테스트·딥링크에서 홈 직행이 필요하면 [AppRoutes.root]를 주입한다.
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '생존일기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final scale = mediaQuery.textScaler.scale(1).clamp(0.9, 1.1);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: TextScaler.linear(scale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
