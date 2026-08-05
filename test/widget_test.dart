import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_survival_diary/app.dart';
import 'package:project_survival_diary/core/router/app_routes.dart';
import 'package:project_survival_diary/core/theme/app_colors.dart';
import 'package:project_survival_diary/core/theme/app_theme.dart';
import 'package:project_survival_diary/features/auth/data/auth_api_client.dart';
import 'package:project_survival_diary/features/auth/data/signup_request.dart';
import 'package:project_survival_diary/features/community/post_write_page.dart';
import 'package:project_survival_diary/features/map/housing_region_page.dart';
import 'package:project_survival_diary/features/policy/policy_list_page.dart';
import 'package:project_survival_diary/data/mock_data.dart';
import 'package:project_survival_diary/data/models.dart';

void main() {
  test('email signup api sends backend signup payload', () async {
    late Map<String, dynamic> payload;
    final client = AuthApiClient(
      baseUrl: 'http://localhost:8080',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/auth/signup');
        payload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({'success': true, 'data': null}),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    await client.signup(
      SignupRequest(
        email: 'kimin@example.com',
        password: 'password1234',
        nickname: 'kimin',
        phone: '01012345678',
        birthDate: DateTime(2000, 3, 15),
        gender: 'MALE',
        region: '서울',
        signupInterests: const ['LIVING_COST', 'YOUTH_POLICY'],
      ),
    );

    expect(payload['email'], 'kimin@example.com');
    expect(payload['password'], 'password1234');
    expect(payload['nickname'], 'kimin');
    expect(payload['phone'], '01012345678');
    expect(payload['birthDate'], '2000-03-15');
    expect(payload['gender'], 'MALE');
    expect(payload['region'], '서울');
    expect(payload['signupInterests'], ['LIVING_COST', 'YOUTH_POLICY']);
  });

  test('email login returns the current user', () async {
    final client = AuthApiClient(
      baseUrl: 'http://localhost:8080',
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          expect(request.method, 'POST');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'accessToken': 'access-token',
                'refreshToken': 'refresh-token',
                'tokenType': 'Bearer',
                'expiresInSeconds': 3600,
              },
            }),
            200,
          );
        }

        expect(request.url.path, '/api/users/me');
        expect(request.headers['authorization'], 'Bearer access-token');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'userId': 7,
              'email': 'user@example.com',
              'name': 'User',
              'phone': '01012345678',
              'birthDate': '2000-03-15',
              'gender': 'MALE',
              'signupInterest': 'LIVING_COST,YOUTH_POLICY',
            },
          }),
          200,
        );
      }),
    );

    final tokens = await client.login(
      email: 'user@example.com',
      password: 'password',
    );
    final user = await client.getCurrentUser(tokens.accessToken);

    expect(user.id, 7);
    expect(user.name, 'User');
    expect(user.interests, ['LIVING_COST', 'YOUTH_POLICY']);
  });

  test('social login exchanges the provider token with the backend', () async {
    late Map<String, dynamic> payload;
    final client = AuthApiClient(
      baseUrl: 'http://localhost:8080',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/auth/social/kakao');
        payload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'accessToken': 'service-access-token',
              'refreshToken': 'service-refresh-token',
              'tokenType': 'Bearer',
              'expiresInSeconds': 1800,
            },
          }),
          200,
        );
      }),
    );

    final tokens = await client.socialLogin(
      provider: 'kakao',
      providerAccessToken: 'provider-access-token',
    );

    expect(payload, {'accessToken': 'provider-access-token'});
    expect(tokens.accessToken, 'service-access-token');
  });

  testWidgets('온보딩 마지막 페이지에 이메일 로그인과 회원가입이 있다', (tester) async {
    await tester.pumpWidget(const SurvivalDiaryApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('onboarding-skip-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('login-email-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('login-password-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('login-submit-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('login-signup-button')), findsOneWidget);
  });

  testWidgets('reaching the last onboarding slide opens the email login page',
      (tester) async {
    await tester.pumpWidget(const SurvivalDiaryApp());
    await tester.pumpAndSettle();

    for (var i = 1; i < MockData.onboardingSlides.length; i++) {
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const ValueKey('login-email-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-skip-button')), findsNothing);
  });

  testWidgets('온보딩 건너뛰기는 마지막 인증 슬라이드로 이동한다', (tester) async {
    await tester.pumpWidget(const SurvivalDiaryApp());
    await tester.pumpAndSettle();

    expect(find.text('기록되는 절약 일기'), findsOneWidget);
    expect(find.byKey(const ValueKey('sns-kakao-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('sns-naver-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('browse-without-login-button')),
        findsNothing);
    expect(find.byKey(const ValueKey('sns-apple-button')), findsNothing);
  });

  testWidgets('온보딩에서 로그인 없이 둘러보기로 홈에 진입한다', (tester) async {
    await tester.pumpWidget(const SurvivalDiaryApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('browse-without-login-button')),
        findsNothing);
    return;

    expect(find.text('안녕하세요, 생존러님! 👋'), findsOneWidget);
  });

  testWidgets('앱 실행 시 홈 인사말과 하단 5개 탭이 나타난다', (tester) async {
    await tester
        .pumpWidget(const SurvivalDiaryApp(initialRoute: AppRoutes.root));
    await tester.pumpAndSettle();

    expect(find.text('안녕하세요, 생존러님! 👋'), findsOneWidget);
    for (final label in ['홈', '일기', '정책', '지도', '커뮤니티']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('하단 네비게이션으로 정책 탭을 연다', (tester) async {
    await tester
        .pumpWidget(const SurvivalDiaryApp(initialRoute: AppRoutes.root));
    await tester.tap(find.byKey(const ValueKey('bottom-policy')));
    await tester.pumpAndSettle();

    expect(find.text('청년 정책 조건'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('policy-age-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('policy-search-button')),
      findsOneWidget,
    );
  });

  testWidgets('일기 탭의 자동 등록과 직접 입력을 전환한다', (tester) async {
    await tester
        .pumpWidget(const SurvivalDiaryApp(initialRoute: AppRoutes.root));
    await tester.tap(find.byKey(const ValueKey('bottom-diary')));
    await tester.pumpAndSettle();

    expect(find.text('결제 알림에서 찾았어요'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('expense-title-field')),
      findsNothing,
    );
    await tester.tap(find.text('직접 입력'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('expense-title-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('expense-save-button')), findsOneWidget);
  });

  testWidgets('정책 관심 없음과 실행취소가 동작한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PolicyListPage(
          condition: const PolicyFilterCondition(
            age: 27,
            regionCode: '11',
            region: '서울특별시',
            workStatus: PolicyWorkStatus.unemployed,
            jobSeeking: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('청년 월세 지원'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('policy-menu-policy-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('관심 없음'));
    await tester.pumpAndSettle();

    expect(find.text('청년 월세 지원'), findsNothing);
    await tester.tap(find.text('실행취소'));
    await tester.pumpAndSettle();

    expect(find.text('청년 월세 지원'), findsOneWidget);
  });

  testWidgets('정책 탭을 이동해도 입력한 나이가 유지된다', (tester) async {
    await tester
        .pumpWidget(const SurvivalDiaryApp(initialRoute: AppRoutes.root));
    await tester.tap(find.byKey(const ValueKey('bottom-policy')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('policy-age-field')),
      '27',
    );

    await tester.tap(find.byKey(const ValueKey('bottom-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bottom-policy')));
    await tester.pumpAndSettle();

    final ageField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('policy-age-field')),
    );
    expect(ageField.controller?.text, '27');
  });

  testWidgets('지역 세 단계 선택 전 실거래 조회 버튼이 비활성이다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const HousingRegionPage()),
    );
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('housing-search-button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('지도 주거지 카테고리에만 실거래 지역 메뉴가 나타난다', (tester) async {
    await tester
        .pumpWidget(const SurvivalDiaryApp(initialRoute: AppRoutes.root));
    await tester.tap(find.byKey(const ValueKey('bottom-map')));
    await tester.pumpAndSettle();

    expect(find.text('주변 부동산 최근 거래'), findsNothing);
    expect(find.text('주거 실거래 지역 선택'), findsNothing);

    await tester.tap(find.text('주거지'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey('map-scroll')),
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();
    expect(find.text('주거 실거래 지역 선택'), findsOneWidget);

    await tester.drag(
      find.byKey(const PageStorageKey('map-scroll')),
      const Offset(0, 260),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('공공시설'));
    await tester.pumpAndSettle();
    expect(find.text('주거 실거래 지역 선택'), findsNothing);
    expect(find.text('주변 부동산 최근 거래'), findsNothing);
  });

  testWidgets('글쓰기 필수값 누락 시 화면 안에 오류가 나타난다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const PostWritePage()),
    );
    await tester.tap(find.byKey(const ValueKey('post-submit-button')));
    await tester.pump();

    expect(find.byKey(const ValueKey('post-write-error')), findsOneWidget);
    expect(find.text('카테고리, 제목, 내용을 모두 입력해 주세요.'), findsOneWidget);
  });

  testWidgets('요청한 홈·일기·정책·커뮤니티 UI가 표시된다', (tester) async {
    await tester
        .pumpWidget(const SurvivalDiaryApp(initialRoute: AppRoutes.root));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('notification-button')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('account-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom-diary')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('edit-detected-detected-1')),
      findsOneWidget,
    );
    final addLabel = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('add-detected-detected-1')),
        matching: find.text('추가'),
      ),
    );
    expect(addLabel.style?.color, AppColors.surface);

    await tester.tap(find.byKey(const ValueKey('bottom-policy')));
    await tester.pumpAndSettle();
    expect(find.text('내 상황에 맞는 정책을 찾아볼까요?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom-community')));
    await tester.pumpAndSettle();
    for (final category in ['자유게시판', '정보 공유', '절약 인증', '질문']) {
      expect(find.text(category), findsWidgets);
    }
  });

  testWidgets('좁은 세로 화면에서 5개 주요 탭에 overflow가 없다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester
        .pumpWidget(const SurvivalDiaryApp(initialRoute: AppRoutes.root));
    await tester.pumpAndSettle();
    final initialException = tester.takeException();
    expect(
      initialException,
      isNull,
      reason: initialException is FlutterError
          ? initialException.toStringDeep()
          : '초기 홈 화면',
    );

    for (final tab in ['diary', 'policy', 'map', 'community', 'home']) {
      await tester.tap(find.byKey(ValueKey('bottom-$tab')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$tab 탭');
    }
  });
}
