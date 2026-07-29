import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/app.dart';
import 'package:project_survival_diary/core/router/app_routes.dart';
import 'package:project_survival_diary/core/theme/app_colors.dart';
import 'package:project_survival_diary/core/theme/app_theme.dart';
import 'package:project_survival_diary/features/community/post_write_page.dart';
import 'package:project_survival_diary/features/map/housing_region_page.dart';

void main() {
  testWidgets('앱 첫 실행 시 온보딩 슬라이드와 SNS 로그인 버튼이 나타난다', (tester) async {
    await tester.pumpWidget(const SurvivalDiaryApp());
    await tester.pumpAndSettle();

    expect(find.text('기록되는 절약 일기'), findsOneWidget);
    expect(find.text('SNS 계정으로 3초 만에 시작해요!'), findsOneWidget);
    for (final key in ['sns-kakao-button', 'sns-naver-button']) {
      expect(find.byKey(ValueKey(key)), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('sns-apple-button')), findsNothing);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('청년 정책 맞춤 추천'), findsOneWidget);
  });

  testWidgets('온보딩에서 로그인 없이 둘러보기로 홈에 진입한다', (tester) async {
    await tester.pumpWidget(const SurvivalDiaryApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('browse-without-login-button')));
    await tester.pumpAndSettle();

    expect(find.text('안녕하세요, 생존러님! 👋'), findsOneWidget);
  });

  testWidgets('온보딩에서 이메일로 시작하기로 회원가입 화면에 진입한다', (tester) async {
    await tester.pumpWidget(const SurvivalDiaryApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('email-start-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('signup-email-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('signup-next-button')), findsOneWidget);
  });

  testWidgets('회원가입 단계를 차례로 입력하면 확인 화면을 거쳐 홈으로 이동한다', (tester) async {
    await tester.pumpWidget(
      const SurvivalDiaryApp(initialRoute: AppRoutes.signup),
    );
    await tester.pumpAndSettle();

    final next = find.byKey(const ValueKey('signup-next-button'));

    // 1) 이메일 — 유효한 값 전에는 확인 버튼 비활성
    expect(tester.widget<FilledButton>(next).onPressed, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('signup-email-field')),
      'kimin@test.com',
    );
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();

    // 2) 비밀번호 + 확인
    await tester.enterText(
      find.byKey(const ValueKey('signup-password-field')),
      'password1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('signup-password-confirm-field')),
      'password1',
    );
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();

    // 3) 이름 — 이전 답변(이메일)은 아래에 요약으로 남는다
    expect(find.byKey(const ValueKey('signup-summary-email')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('signup-name-field')),
      '김민',
    );
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();

    // 4) 생년월일 (8자리)
    await tester.enterText(
      find.byKey(const ValueKey('signup-birth-field')),
      '19990214',
    );
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();

    // 5) 성별 — 바텀시트에서 선택
    await tester.tap(find.byKey(const ValueKey('signup-gender-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('signup-gender-female')));
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();

    // 6) 지역 — 나중에 입력
    await tester.tap(find.byKey(const ValueKey('signup-skip-button')));
    await tester.pumpAndSettle();

    // 최종 확인 화면에서 입력값을 모두 보여준다
    expect(find.text('정보가 모두 맞나요?'), findsOneWidget);
    expect(find.text('kimin@test.com'), findsOneWidget);
    expect(find.text('여성'), findsOneWidget);
    expect(find.text('1999.02.14'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('signup-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('안녕하세요, 생존러님! 👋'), findsOneWidget);
  });

  testWidgets('회원가입 확인 화면에서 이전 답변을 수정할 수 있다', (tester) async {
    await tester.pumpWidget(
      const SurvivalDiaryApp(initialRoute: AppRoutes.signup),
    );
    await tester.pumpAndSettle();

    final next = find.byKey(const ValueKey('signup-next-button'));
    await tester.enterText(
      find.byKey(const ValueKey('signup-email-field')),
      'kimin@test.com',
    );
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('signup-password-field')),
      'password1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('signup-password-confirm-field')),
      'password1',
    );
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('signup-name-field')),
      '김민',
    );
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();

    // 선택 항목 3개는 모두 나중에 입력
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('signup-skip-button')));
      await tester.pumpAndSettle();
    }
    expect(find.text('정보가 모두 맞나요?'), findsOneWidget);

    // 이름 항목을 눌러 수정 후 다시 확인 화면으로 복귀
    await tester.tap(find.byKey(const ValueKey('signup-summary-name')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('signup-name-field')),
      '생존러',
    );
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();

    expect(find.text('정보가 모두 맞나요?'), findsOneWidget);
    expect(find.text('생존러'), findsOneWidget);
  });

  testWidgets('앱 실행 시 홈 인사말과 하단 5개 탭이 나타난다', (tester) async {
    await tester.pumpWidget(const SurvivalDiaryApp(initialRoute: AppRoutes.root));
    await tester.pumpAndSettle();

    expect(find.text('안녕하세요, 생존러님! 👋'), findsOneWidget);
    for (final label in ['홈', '일기', '정책', '지도', '커뮤니티']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('하단 네비게이션으로 정책 탭을 연다', (tester) async {
    await tester.pumpWidget(const SurvivalDiaryApp(initialRoute: AppRoutes.root));
    await tester.tap(find.byKey(const ValueKey('bottom-policy')));
    await tester.pumpAndSettle();

    expect(find.text('청년 맞춤 정책'), findsOneWidget);
    expect(find.text('청년 월세 지원'), findsOneWidget);
    await tester.drag(
      find.byKey(const PageStorageKey('policy-list-scroll')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('more-policies-button')),
      findsOneWidget,
    );
  });

  testWidgets('일기 탭의 자동 등록과 직접 입력을 전환한다', (tester) async {
    await tester.pumpWidget(const SurvivalDiaryApp(initialRoute: AppRoutes.root));
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
    await tester.pumpWidget(const SurvivalDiaryApp(initialRoute: AppRoutes.root));
    await tester.tap(find.byKey(const ValueKey('bottom-policy')));
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
    await tester.pumpWidget(const SurvivalDiaryApp(initialRoute: AppRoutes.root));
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
    await tester.pumpWidget(const SurvivalDiaryApp(initialRoute: AppRoutes.root));
    await tester.pumpAndSettle();

    final notificationButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('notification-button')),
    );
    expect(notificationButton.style, isNull);

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
    expect(find.text('신청 마감 2026.08.20'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom-community')));
    await tester.pumpAndSettle();
    for (final category in ['자유게시판', '정보 공유', '절약 인증', '질문']) {
      expect(find.text(category), findsWidgets);
    }
  });

  testWidgets('좁은 세로 화면에서 5개 주요 탭에 overflow가 없다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SurvivalDiaryApp(initialRoute: AppRoutes.root));
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
