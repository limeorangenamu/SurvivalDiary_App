import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/core/router/app_router.dart';
import 'package:project_survival_diary/core/theme/app_theme.dart';
import 'package:project_survival_diary/data/models.dart';
import 'package:project_survival_diary/features/policy/policy_detail_page.dart';
import 'package:project_survival_diary/features/policy/policy_filter_page.dart';
import 'package:project_survival_diary/features/policy/policy_list_page.dart';

void main() {
  Widget policyApp(Widget home) {
    return MaterialApp(
      theme: AppTheme.light,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: home,
    );
  }

  Future<void> selectRequiredConditions(
    WidgetTester tester, {
    String age = '27',
    String region = '서울특별시',
    String employment = '구직 중',
  }) async {
    await tester.enterText(
      find.byKey(const ValueKey('policy-age-field')),
      age,
    );
    await tester.tap(find.byKey(const ValueKey('policy-region-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(region).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('policy-employment-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(employment).last);
    await tester.pumpAndSettle();
  }

  testWidgets('필수 정책 조건 누락 시 인라인 오류를 표시한다', (tester) async {
    await tester.pumpWidget(policyApp(const PolicyFilterPage()));

    await tester.tap(find.byKey(const ValueKey('policy-search-button')));
    await tester.pump();

    expect(find.text('나이를 입력해 주세요.'), findsOneWidget);
    expect(find.text('시·도를 선택해 주세요.'), findsOneWidget);
    expect(find.text('취업 상태를 선택해 주세요.'), findsOneWidget);
    expect(find.text('맞춤 정책 결과'), findsNothing);
  });

  testWidgets('조건 입력부터 상세와 외부 이동 확인 화면까지 연결된다', (tester) async {
    await tester.pumpWidget(policyApp(const PolicyFilterPage()));
    await selectRequiredConditions(tester);

    await tester.tap(find.byKey(const ValueKey('policy-search-button')));
    await tester.pumpAndSettle();

    expect(find.text('맞춤 정책 결과'), findsOneWidget);
    expect(find.text('만 27세'), findsOneWidget);
    expect(find.text('서울특별시'), findsOneWidget);
    expect(find.text('구직 중'), findsOneWidget);
    expect(find.text('청년 월세 지원'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('policy-card-policy-1')));
    await tester.pumpAndSettle();
    expect(find.text('정책 상세'), findsOneWidget);
    expect(find.text('월 최대 20만원, 최대 12개월'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('policy-application-guide-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('공식 페이지 이동'), findsOneWidget);
    expect(find.text('외부 공식 사이트로 이동할까요?'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('policy-open-external-button')),
    );
    await tester.pump();
    expect(find.text('외부 브라우저 연결은 다음 단계에서 제공해요.'), findsOneWidget);
  });

  testWidgets('조건과 일치하는 정책이 없으면 빈 결과를 표시한다', (tester) async {
    await tester.pumpWidget(policyApp(const PolicyFilterPage()));
    await selectRequiredConditions(
      tester,
      age: '39',
      employment: '재직 중',
    );

    await tester.tap(find.byKey(const ValueKey('policy-search-button')));
    await tester.pumpAndSettle();

    expect(find.text('조건에 맞는 정책이 없어요'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('policy-edit-condition-button')),
      findsOneWidget,
    );
  });

  testWidgets('없는 정책 ID는 안내 상태를 표시한다', (tester) async {
    await tester.pumpWidget(
      policyApp(const PolicyDetailPage(policyId: 'missing-policy')),
    );

    expect(find.text('정책 정보를 찾을 수 없어요'), findsOneWidget);
  });

  testWidgets('지원금과 마감일이 없으면 대체 문구를 표시한다', (tester) async {
    await tester.pumpWidget(
      policyApp(
        const PolicyListPage(
          condition: PolicyFilterCondition(
            age: 20,
            region: '서울특별시',
            employmentStatus: PolicyEmploymentStatus.student,
            category: PolicyCategory.transport,
          ),
        ),
      ),
    );

    expect(find.text('지원 내용 확인'), findsOneWidget);
    expect(find.text('신청 기간 확인 필요'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('policy-card-policy-5')));
    await tester.pumpAndSettle();
    expect(find.text('지원 내용 확인'), findsOneWidget);
    expect(find.text('신청 기간 확인 필요'), findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('policy-application-guide-button')),
    );
    expect(button.onPressed, isNull);
  });
}
