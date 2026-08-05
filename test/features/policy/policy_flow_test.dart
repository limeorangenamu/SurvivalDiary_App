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
    return MaterialApp(
      theme: AppTheme.light,
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.policyDetail &&
            settings.arguments is PolicyDetailArguments) {
          return MaterialPageRoute<void>(
            builder: (_) => PolicyDetailPage(
              arguments: settings.arguments! as PolicyDetailArguments,
              apiClient: resolvedClient,
              accessTokenProvider: () => 'test-access-token',
            ),
          );
        }
        return AppRouter.onGenerateRoute(settings);
      },
      home: home,
    );
  }

  Widget filterPage({PolicyApiClient? client}) {
    return PolicyFilterPage(
      apiClient: client ?? apiClient,
      accessTokenProvider: () => 'test-access-token',
    );
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
  });

  testWidgets('저장된 조건이 있으면 추천 브리핑을 바로 연다', (tester) async {
    final requestedPaths = <String>[];
    final savedClient = PolicyApiClient(
      baseUrl: 'http://test.example',
      client: MockClient((request) async {
        requestedPaths.add('${request.method} ${request.url.path}');
        if (request.method == 'GET' &&
            request.url.path == '/api/users/me/policy-preferences') {
          return _successResponse(_savedPreferenceJson());
        }
        if (request.method == 'POST' &&
            request.url.path == '/api/policies/recommendations') {
          return _recommendationResponse();
        }
        return http.Response('{}', 404);
      }),
    );

    await tester.pumpWidget(policyApp(filterPage(client: savedClient)));
    await tester.pumpAndSettle();

    expect(requestedPaths, [
      'GET /api/users/me/policy-preferences',
      'POST /api/policies/recommendations',
    ]);
    expect(find.text('놓치면 아쉬운 정책이 1개 있어요'), findsOneWidget);
    expect(find.textContaining('서울특별시 · 종로구 · 만 27세'), findsOneWidget);
    expect(find.text('청년 일자리 지원'), findsOneWidget);
    expect(find.text('내게 추천'), findsOneWidget);
  });

  testWidgets('최초 설정은 지역 누락을 안내하고 한 단계씩 이동한다', (tester) async {
    await tester.pumpWidget(policyApp(filterPage()));
    await tester.pumpAndSettle();

    expect(find.text('어디에 살고 있나요?'), findsOneWidget);
    expect(find.text('정책 분야'), findsNothing);
    expect(find.text('관심 주제'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('policy-setup-next')));
    await tester.pump();

    expect(find.text('시·도를 선택해 주세요.'), findsOneWidget);
    expect(find.text('어디에 살고 있나요?'), findsOneWidget);

    await _selectRegion(tester, '서울특별시');
    await tester.tap(find.byKey(const ValueKey('policy-setup-next')));
    await tester.pumpAndSettle();

    expect(find.text('지금 어떤 상황에 가까운가요?'), findsOneWidget);
    expect(find.text('여러 개를 선택할 수 있고, 잘 모르겠다면 건너뛰어도 괜찮아요.'), findsOneWidget);
  });

  testWidgets('3단계 조건 설정을 저장하고 개인 추천 목록을 연다', (tester) async {
    final capturedBodies = <Map<String, dynamic>>[];
    final client = _policyApiClient(onBody: capturedBodies.add);

    await tester
        .pumpWidget(policyApp(filterPage(client: client), client: client));
    await tester.pumpAndSettle();

    await _selectRegion(tester, '서울특별시');
    await tester.tap(find.byKey(const ValueKey('policy-district-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('종로구').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('policy-setup-next')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('policy-situation-job-seeking')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('policy-setup-next')));
    await tester.pumpAndSettle();

    expect(find.text('추천 준비가 끝났어요'), findsOneWidget);
    expect(find.text('구직 중'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('policy-recommend-button')));
    await tester.pumpAndSettle();

    expect(capturedBodies.first, {
      'regionCode': '11',
      'districtCode': '11110',
      'workStatus': 'UNEMPLOYED',
      'jobSeeking': true,
      'interests': <dynamic>[],
    });
    expect(capturedBodies.last, {'page': 1, 'size': 20});
    expect(find.byKey(const ValueKey('policy-recommended-section')),
        findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('policy-check-section')), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('policy-discover-section')), findsOneWidget);
    expect(find.text('함께 보기'), findsNothing);
  });

  testWidgets('분야 선택과 정책명 검색은 저장 조건을 바꾸지 않는다', (tester) async {
    final requestBodies = <Map<String, dynamic>>[];
    final client = _policyApiClient(onRecommendation: requestBodies.add);

    await tester.pumpWidget(
      policyApp(
        PolicyListPage(
          condition: _defaultCondition,
          apiClient: client,
          accessTokenProvider: () => 'test-access-token',
        ),
        client: client,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('policy-category-housing')),
    );
    await tester.pumpAndSettle();
    expect(requestBodies.last['category'], 'HOUSING');
    expect(requestBodies.last.containsKey('age'), isFalse);
    expect(find.text('청년 월세 지원'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('policy-keyword-field')),
      '월세',
    );
    await tester.tap(
      find.byKey(const ValueKey('policy-keyword-search-button')),
    );
    await tester.pumpAndSettle();

    expect(requestBodies.last['keyword'], '월세');
    expect(find.text('“월세” 검색 결과'), findsOneWidget);
    expect(find.text('월세 검색 정책'), findsOneWidget);
  });

  testWidgets('일반 정책은 추천 배지 없이 표시한다', (tester) async {
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

    expect(find.text('내게 추천'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('조건 확인 필요'), findsOneWidget);
    expect(find.text('함께 보기'), findsNothing);
    expect(find.text('청년 문화 지원'), findsOneWidget);
  });

  testWidgets('관심 없음과 실행취소가 추천 피드에서도 동작한다', (tester) async {
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

    final menu = find.byKey(const ValueKey('policy-menu-policy-employment'));
    await tester.ensureVisible(menu);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('관심 없음'));
    await tester.pumpAndSettle();

    expect(find.text('청년 일자리 지원'), findsNothing);
    await tester.tap(find.text('실행취소'));
    await tester.pumpAndSettle();
    expect(find.text('청년 일자리 지원'), findsOneWidget);
  });

  testWidgets('추천 카드에서 정책 상세로 이동한다', (tester) async {
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

    final card = find.byKey(const ValueKey('policy-card-policy-employment'));
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.text('정책 상세'), findsOneWidget);
    expect(find.text('이 정책을 추천하는 이유'), findsOneWidget);
    expect(find.text('최대 300만 원을 지원해요.'), findsOneWidget);
  });

  testWidgets('로그인 토큰이 없으면 서버 호출 없이 안내한다', (tester) async {
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

Future<void> _selectRegion(WidgetTester tester, String region) async {
  await tester.tap(find.byKey(const ValueKey('policy-region-field')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(region).last);
  await tester.pumpAndSettle();
}

const _defaultCondition = PolicyFilterCondition(
  age: 27,
  regionCode: '11',
  region: '서울특별시',
  districtCode: '11110',
  district: '종로구',
  workStatus: PolicyWorkStatus.unemployed,
  jobSeeking: true,
);

PolicyApiClient _policyApiClient({
  void Function(Map<String, dynamic> body)? onBody,
  void Function(Map<String, dynamic> body)? onRecommendation,
}) {
  return PolicyApiClient(
    baseUrl: 'http://test.example',
    client: MockClient((request) async {
      if (request.method == 'GET' &&
          request.url.path == '/api/users/me/policy-preferences') {
        return _successResponse({
          'saved': false,
          'age': 27,
          'regionCode': null,
          'districtCode': null,
          'employmentStatus': null,
          'incomeRange': null,
          'category': null,
          'workStatus': null,
          'jobSeeking': null,
          'educationStatus': null,
          'interests': const [],
        });
      }

      if (request.method == 'PUT' &&
          request.url.path == '/api/users/me/policy-preferences') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        onBody?.call(body);
        return _successResponse({
          'saved': true,
          'age': 27,
          'regionCode': body['regionCode'],
          'districtCode': body['districtCode'],
          'employmentStatus': null,
          'incomeRange': null,
          'category': null,
          'workStatus': body['workStatus'],
          'jobSeeking': body['jobSeeking'],
          'educationStatus': body['educationStatus'],
          'interests': body['interests'],
        });
      }

      if (request.method == 'POST' &&
          request.url.path == '/api/policies/recommendations') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        onBody?.call(body);
        onRecommendation?.call(body);
        final keyword = body['keyword'] as String?;
        if (keyword != null) {
          return _successResponse({
            'items': [
              _summaryJson(
                policyId: 'policy-search',
                title: '$keyword 검색 정책',
                recommendationStatus: 'DISCOVER',
                recommendationReasons: const [],
              ),
            ],
            'partialResult': false,
            'checkedProviderPages': 1,
            'nextPage': null,
          });
        }
        if (body['category'] == 'HOUSING') {
          return _successResponse({
            'items': [_housingSummary()],
            'partialResult': false,
            'checkedProviderPages': 1,
            'nextPage': null,
          });
        }
        return _recommendationResponse();
      }

      if (request.method == 'GET' &&
          request.url.path.startsWith('/api/policies/')) {
        return _successResponse(_detailJson(request.url.pathSegments.last));
      }
      return http.Response('{}', 404);
    }),
  );
}

http.Response _recommendationResponse() {
  return _successResponse({
    'items': [
      _summaryJson(
        policyId: 'policy-employment',
        category: '일자리·창업',
        categoryType: 'EMPLOYMENT',
        title: '청년 일자리 지원',
        supportAmount: 3000000,
        supportText: '최대 300만 원을 지원해요.',
        recommendationStatus: 'RECOMMENDED',
        recommendationReasons: const ['구직 중인 사용자에게 관련된 일자리 정책이에요.'],
      ),
      _housingSummary(),
      _summaryJson(
        policyId: 'policy-culture',
        category: '복지·문화',
        categoryType: 'WELFARE_CULTURE',
        title: '청년 문화 지원',
        supportAmount: null,
        supportText: '공연과 문화 활동을 지원해요.',
        recommendationStatus: 'DISCOVER',
        recommendationReasons: const [],
      ),
    ],
    'partialResult': false,
    'checkedProviderPages': 1,
    'nextPage': null,
  });
}

Map<String, dynamic> _housingSummary() {
  return _summaryJson(
    policyId: 'policy-housing',
    title: '청년 월세 지원',
    recommendationStatus: 'CHECK_REQUIRED',
    recommendationReasons: const ['소득 조건을 공고문에서 확인해야 합니다.'],
  );
}

Map<String, dynamic> _summaryJson({
  required String policyId,
  String category = '주거',
  String categoryType = 'HOUSING',
  required String title,
  int? supportAmount = 2400000,
  String supportText = '월 최대 20만 원, 최대 12개월',
  required String recommendationStatus,
  required List<String> recommendationReasons,
}) {
  return {
    'policyId': policyId,
    'category': category,
    'categoryType': categoryType,
    'title': title,
    'summary': '청년의 생활비 부담을 줄이는 정책입니다.',
    'supportAmount': supportAmount,
    'supportText': supportText,
    'applicationPeriodText': '2026.08.01~2026.08.31',
    'target': '만 19~34세',
    'agency': '청년정책 담당 기관',
    'eligibilityStatus':
        recommendationStatus == 'CHECK_REQUIRED' ? 'CHECK_REQUIRED' : 'MATCHED',
    'eligibilityReasons': recommendationStatus == 'CHECK_REQUIRED'
        ? ['소득 조건을 공고문에서 확인해야 합니다.']
        : <String>[],
    'recommendationStatus': recommendationStatus,
    'recommendationReasons': recommendationReasons,
  };
}

Map<String, dynamic> _detailJson(String policyId) {
  return {
    'policyId': policyId,
    'category': '일자리·창업',
    'categoryType': 'EMPLOYMENT',
    'title': '청년 일자리 지원',
    'description': '구직 청년의 취업 준비를 지원하는 정책입니다.',
    'supportAmount': 3000000,
    'supportText': '최대 300만 원을 지원해요.',
    'applicationPeriodText': '2026.08.01~2026.08.31',
    'target': '만 19~34세 구직 청년',
    'agency': '청년정책 담당 기관',
    'operatingAgency': '정책 운영 기관',
    'applicationMethod': '공식 사이트에서 온라인 신청',
    'documents': ['신분증'],
    'officialUrl': 'https://example.com/policies/$policyId',
    'referenceUrls': <String>[],
  };
}

Map<String, dynamic> _savedPreferenceJson() {
  return {
    'saved': true,
    'age': 27,
    'regionCode': '11',
    'districtCode': '11110',
    'employmentStatus': 'JOB_SEEKING',
    'incomeRange': null,
    'category': null,
    'workStatus': 'UNEMPLOYED',
    'jobSeeking': true,
    'educationStatus': null,
    'interests': const [],
  };
}

http.Response _successResponse(Object data) {
  return http.Response(
    jsonEncode({'success': true, 'data': data}),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}
