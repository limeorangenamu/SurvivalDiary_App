import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_survival_diary/core/router/app_router.dart';
import 'package:project_survival_diary/core/router/app_routes.dart';
import 'package:project_survival_diary/core/theme/app_theme.dart';
import 'package:project_survival_diary/data/mock_data.dart';
import 'package:project_survival_diary/data/models.dart';
import 'package:project_survival_diary/features/policy/data/policy_api_client.dart';
import 'package:project_survival_diary/features/policy/data/policy_models.dart';
import 'package:project_survival_diary/features/policy/policy_detail_page.dart';
import 'package:project_survival_diary/features/policy/policy_filter_page.dart';
import 'package:project_survival_diary/features/policy/policy_list_page.dart';

void main() {
  late PolicyApiClient apiClient;

  setUp(() {
    apiClient = _policyApiClient();
  });

  Widget policyApp(Widget home, {PolicyApiClient? client}) {
    final resolvedClient = client ?? apiClient;
    Route<dynamic> onGenerateRoute(RouteSettings settings) {
      final page = switch (settings.name) {
        AppRoutes.policyResults
            when settings.arguments is PolicyFilterCondition =>
          PolicyListPage(
            condition: settings.arguments! as PolicyFilterCondition,
            apiClient: resolvedClient,
            accessTokenProvider: () => 'test-access-token',
          ),
        AppRoutes.policyDetail
            when settings.arguments is PolicyDetailArguments =>
          PolicyDetailPage(
            arguments: settings.arguments! as PolicyDetailArguments,
            apiClient: resolvedClient,
            accessTokenProvider: () => 'test-access-token',
          ),
        _ => null,
      };
      if (page != null) {
        return MaterialPageRoute<dynamic>(
          settings: settings,
          builder: (_) => page,
        );
      }
      return AppRouter.onGenerateRoute(settings);
    }

    return MaterialApp(
      theme: AppTheme.light,
      onGenerateRoute: onGenerateRoute,
      home: home,
    );
  }

  Future<void> selectRequiredConditions(
    WidgetTester tester, {
    String age = '27',
    String region = '서울특별시',
    String? district,
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
    if (district != null) {
      await tester.tap(find.byKey(const ValueKey('policy-district-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(district).last);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('policy-employment-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(employment).last);
    await tester.pumpAndSettle();
  }

  test('정책 지역 조건은 전국 17개 시·도와 공식 형식 코드를 제공한다', () {
    expect(MockData.policyRegions, hasLength(17));

    final regionCodes = <String>{};
    final districtCodes = <String>{};
    for (final region in MockData.policyRegions) {
      expect(region.code, matches(RegExp(r'^\d{2}$')));
      expect(regionCodes.add(region.code), isTrue);
      for (final district in region.districts) {
        expect(district.code, matches(RegExp(r'^\d{5}$')));
        expect(district.code.startsWith(region.code), isTrue);
        expect(districtCodes.add(district.code), isTrue);
      }
    }
    expect(districtCodes, hasLength(228));

    final seoul = MockData.policyRegions.singleWhere(
      (region) => region.code == '11',
    );
    expect(seoul.districts, hasLength(25));
    expect(
      seoul.districts.singleWhere((district) => district.code == '11680').name,
      '강남구',
    );

    final sejong = MockData.policyRegions.singleWhere(
      (region) => region.code == '36',
    );
    expect(sejong.districts, isEmpty);
  });

  testWidgets('필수 정책 조건 누락 시 인라인 오류를 표시한다', (tester) async {
    await tester.pumpWidget(policyApp(const PolicyFilterPage()));

    await tester.tap(find.byKey(const ValueKey('policy-search-button')));
    await tester.pump();

    expect(find.text('나이를 입력해 주세요.'), findsOneWidget);
    expect(find.text('시·도를 선택해 주세요.'), findsOneWidget);
    expect(find.text('취업 상태를 선택해 주세요.'), findsOneWidget);
    expect(find.text('맞춤 정책 결과'), findsNothing);
  });

  testWidgets('조건 입력부터 실제 목록·상세 응답과 외부 확인 화면까지 연결된다', (tester) async {
    await tester.pumpWidget(policyApp(const PolicyFilterPage()));
    await selectRequiredConditions(tester, district: '종로구');

    await tester.tap(find.byKey(const ValueKey('policy-search-button')));
    await tester.pumpAndSettle();

    expect(find.text('맞춤 정책 결과'), findsOneWidget);
    expect(find.text('만 27세'), findsOneWidget);
    expect(find.text('서울특별시'), findsOneWidget);
    expect(find.text('종로구'), findsOneWidget);
    expect(find.text('구직 중'), findsOneWidget);
    expect(find.text('청년 월세 지원'), findsOneWidget);
    expect(find.textContaining('제공처 3페이지까지'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('policy-check-required-policy-1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('policy-card-policy-1')));
    await tester.pumpAndSettle();
    expect(find.text('정책 상세'), findsOneWidget);
    expect(find.text('월 최대 20만원, 최대 12개월'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('policy-eligibility-notice')),
      findsOneWidget,
    );
    expect(find.text('중위소득 조건을 공고문에서 확인해야 합니다.'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('policy-application-guide-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('신청 사이트 이동'), findsOneWidget);
    expect(find.text('신청 사이트로 이동할까요?'), findsOneWidget);
    expect(find.text('https://example.com/policies/policy-1'), findsOneWidget);
  });

  testWidgets('서버가 빈 목록을 반환하면 빈 결과를 표시한다', (tester) async {
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
      policyApp(
        PolicyDetailPage(
          arguments: const PolicyDetailArguments(
            policyId: 'missing-policy',
            eligibilityStatus: PolicyEligibilityStatus.matched,
            eligibilityReasons: [],
          ),
          apiClient: apiClient,
          accessTokenProvider: () => 'test-access-token',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('정책 정보를 찾을 수 없어요'), findsOneWidget);
  });

  testWidgets('지원금·신청 기간·공식 URL이 없으면 대체 상태를 표시한다', (tester) async {
    await tester.pumpWidget(
      policyApp(
        PolicyListPage(
          condition: const PolicyFilterCondition(
            age: 20,
            regionCode: '11',
            region: '서울특별시',
            employmentStatus: PolicyEmploymentStatus.student,
            category: PolicyCategory.transport,
          ),
          apiClient: apiClient,
          accessTokenProvider: () => 'test-access-token',
        ),
      ),
    );
    await tester.pumpAndSettle();

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
    expect(find.text('온라인 신청 링크 없음'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('policy-reference-link-0')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const ValueKey('policy-reference-link-0')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('policy-reference-link-0')));
    await tester.pumpAndSettle();

    expect(find.text('참고 링크 이동'), findsOneWidget);
    expect(find.text('정책 안내 페이지로 이동할까요?'), findsOneWidget);
    expect(
      find.text('https://example.com/references/policy-5'),
      findsOneWidget,
    );
  });

  testWidgets('API 실패를 더미 정책으로 숨기지 않고 재시도한다', (tester) async {
    var attempts = 0;
    final retryClient = PolicyApiClient(
      baseUrl: 'http://test.example',
      client: MockClient((request) async {
        attempts += 1;
        if (attempts == 1) {
          return http.Response('{}', 500);
        }
        return _successResponse({
          'items': [_policySummaryJson()],
          'partialResult': false,
          'checkedProviderPages': 1,
        });
      }),
    );
    await tester.pumpWidget(
      policyApp(
        PolicyListPage(
          condition: _defaultCondition,
          apiClient: retryClient,
          accessTokenProvider: () => 'test-access-token',
        ),
        client: retryClient,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('정책 목록을 불러오지 못했어요'), findsOneWidget);
    expect(find.text('청년 월세 지원'), findsNothing);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('청년 월세 지원'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('실제 API 목록에서도 관심 없음과 실행취소가 동작한다', (tester) async {
    await tester.pumpWidget(
      policyApp(
        PolicyListPage(
          condition: _defaultCondition,
          apiClient: apiClient,
          accessTokenProvider: () => 'test-access-token',
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

  testWidgets('로그인 토큰이 없으면 서버 호출 없이 로그인 안내를 표시한다', (tester) async {
    var called = false;
    final client = PolicyApiClient(
      baseUrl: 'http://test.example',
      client: MockClient((request) async {
        called = true;
        return http.Response('{}', 500);
      }),
    );
    await tester.pumpWidget(
      policyApp(
        PolicyListPage(
          condition: _defaultCondition,
          apiClient: client,
          accessTokenProvider: () => null,
        ),
        client: client,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('정책을 조회하려면 먼저 로그인해 주세요.'), findsOneWidget);
    expect(called, isFalse);
  });
}

const _defaultCondition = PolicyFilterCondition(
  age: 27,
  regionCode: '11',
  region: '서울특별시',
  districtCode: '11110',
  district: '종로구',
  employmentStatus: PolicyEmploymentStatus.jobSeeker,
);

PolicyApiClient _policyApiClient() {
  return PolicyApiClient(
    baseUrl: 'http://test.example',
    client: MockClient((request) async {
      if (request.method == 'POST' &&
          request.url.path == '/api/policies/search') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final items = body['age'] == 39
            ? <Map<String, dynamic>>[]
            : body['category'] == 'TRANSPORT'
                ? [_policySummaryJson(policyId: 'policy-5', nullable: true)]
                : [_policySummaryJson()];
        return _successResponse({
          'items': items,
          'partialResult': body['age'] != 39,
          'checkedProviderPages': body['age'] == 39 ? 1 : 3,
        });
      }

      if (request.method == 'GET' &&
          request.url.path == '/api/policies/missing-policy') {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {'code': 'P001', 'message': '정책을 찾을 수 없습니다.'},
          }),
          404,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      if (request.method == 'GET' &&
          request.url.path.startsWith('/api/policies/')) {
        final policyId = request.url.pathSegments.last;
        return _successResponse(
          _policyDetailJson(
            policyId: policyId,
            nullable: policyId == 'policy-5',
            referenceUrls: policyId == 'policy-5'
                ? ['https://example.com/references/policy-5']
                : const [],
          ),
        );
      }
      return http.Response('{}', 404);
    }),
  );
}

Map<String, dynamic> _policySummaryJson({
  String policyId = 'policy-1',
  bool nullable = false,
}) {
  return {
    'policyId': policyId,
    'category': nullable ? '교통' : '주거',
    'categoryType': nullable ? 'TRANSPORT' : 'HOUSING',
    'title': nullable ? '청년 교통비 지원' : '청년 월세 지원',
    'summary': '청년의 생활비 부담을 줄이는 정책입니다.',
    'supportAmount': nullable ? null : 2400000,
    'supportText': nullable ? '지원 내용을 확인해 주세요.' : '월 최대 20만원, 최대 12개월',
    'applicationPeriodText': nullable ? null : '2026.08.01~2026.08.31',
    'target': '만 19~34세',
    'agency': '청년정책 담당 기관',
    'eligibilityStatus': nullable ? 'MATCHED' : 'CHECK_REQUIRED',
    'eligibilityReasons': nullable ? <String>[] : ['중위소득 조건을 공고문에서 확인해야 합니다.'],
  };
}

Map<String, dynamic> _policyDetailJson({
  required String policyId,
  bool nullable = false,
  List<String> referenceUrls = const [],
}) {
  return {
    'policyId': policyId,
    'category': nullable ? '교통' : '주거',
    'categoryType': nullable ? 'TRANSPORT' : 'HOUSING',
    'title': nullable ? '청년 교통비 지원' : '청년 월세 지원',
    'description': '청년의 생활비 부담을 줄이는 정책입니다.',
    'supportAmount': nullable ? null : 2400000,
    'supportText': nullable ? '지원 내용을 확인해 주세요.' : '월 최대 20만원, 최대 12개월',
    'applicationPeriodText': nullable ? null : '2026.08.01~2026.08.31',
    'target': '만 19~34세',
    'agency': '청년정책 담당 기관',
    'operatingAgency': '정책 운영 기관',
    'applicationMethod': '공식 사이트에서 온라인 신청',
    'documents': nullable ? <String>[] : ['신분증', '소득 확인 서류'],
    'officialUrl': nullable ? null : 'https://example.com/policies/$policyId',
    'referenceUrls': referenceUrls,
  };
}

http.Response _successResponse(Object data) {
  return http.Response(
    jsonEncode({'success': true, 'data': data}),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}
