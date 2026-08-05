import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_survival_diary/core/router/app_routes.dart';
import 'package:project_survival_diary/core/theme/app_theme.dart';
import 'package:project_survival_diary/features/home/widgets/home_policy_briefing.dart';
import 'package:project_survival_diary/features/policy/data/policy_api_client.dart';
import 'package:project_survival_diary/features/policy/data/policy_models.dart';

void main() {
  testWidgets('홈에 맞춤 추천과 30일 이내 마감 정책을 함께 보여준다', (tester) async {
    final client = PolicyApiClient(
      baseUrl: 'http://localhost:8080',
      client: MockClient((request) async {
        if (request.url.path == '/api/users/me/policy-preferences') {
          return _success({
            'saved': true,
            'age': 29,
            'regionCode': '26',
            'districtCode': null,
            'workStatus': 'UNEMPLOYED',
            'jobSeeking': true,
            'educationStatus': null,
            'interests': ['HOUSING'],
          });
        }
        expect(request.url.path, '/api/policies/recommendations');
        expect(request.method, 'POST');
        return _success({
          'items': [
            _policy(
              id: 'recommended',
              title: '부산 청년 월세 지원',
              status: 'RECOMMENDED',
              reason: '관심 주제인 주거 분야와 관련된 정책이에요.',
            ),
            _policy(
              id: 'urgent',
              title: '청년 취업 준비 지원',
              status: 'CHECK_REQUIRED',
              reason: '신청 전에 근로 조건을 확인해 주세요.',
              endDate: '2026-08-10',
            ),
            _policy(
              id: 'discover',
              title: '청년 문화 이용권',
              status: 'DISCOVER',
              reason: null,
            ),
          ],
          'partialResult': false,
          'checkedProviderPages': 1,
          'nextPage': null,
        });
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomePolicyBriefing(
              apiClient: client,
              accessTokenProvider: () => 'access-token',
              nowProvider: () => DateTime(2026, 8, 5),
              onOpenPolicies: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('놓치면 아쉬운 정책'), findsOneWidget);
    expect(find.text('부산 청년 월세 지원'), findsOneWidget);
    expect(find.text('청년 취업 준비 지원'), findsOneWidget);
    expect(find.text('D-5'), findsOneWidget);
    expect(find.text('월 최대 20만원 지원'), findsNWidgets(3));
  });

  testWidgets('저장된 조건이 없으면 홈에서 간단 설정으로 연결한다', (tester) async {
    var opened = false;
    final client = PolicyApiClient(
      baseUrl: 'http://localhost:8080',
      client: MockClient((request) async {
        expect(request.url.path, '/api/users/me/policy-preferences');
        return _success({
          'saved': false,
          'age': 29,
          'regionCode': null,
          'districtCode': null,
          'workStatus': null,
          'jobSeeking': null,
          'educationStatus': null,
          'interests': <String>[],
        });
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HomePolicyBriefing(
            apiClient: client,
            accessTokenProvider: () => 'access-token',
            onOpenPolicies: () => opened = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('한 번만 조건을 알려주세요'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-policy-setup')));
    expect(opened, isTrue);
  });

  testWidgets('상세에서 숨긴 정책은 홈에서도 제거하고 실행취소할 수 있다', (tester) async {
    final client = PolicyApiClient(
      baseUrl: 'http://localhost:8080',
      client: MockClient((request) async {
        if (request.url.path == '/api/users/me/policy-preferences') {
          return _success({
            'saved': true,
            'age': 29,
            'regionCode': '26',
            'districtCode': null,
            'workStatus': null,
            'jobSeeking': null,
            'educationStatus': null,
            'interests': <String>[],
          });
        }
        return _success({
          'items': [
            _policy(
              id: 'hide-target',
              title: '숨길 정책',
              status: 'RECOMMENDED',
              reason: '현재 상황과 관련된 정책이에요.',
            ),
          ],
          'partialResult': false,
          'checkedProviderPages': 1,
          'nextPage': null,
        });
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.policyDetail) {
            return MaterialPageRoute<PolicyDetailAction>(
              builder: (context) => Scaffold(
                body: Center(
                  child: FilledButton(
                    key: const ValueKey('test-hide-policy'),
                    onPressed: () => Navigator.pop(
                      context,
                      PolicyDetailAction.hide,
                    ),
                    child: const Text('숨기기'),
                  ),
                ),
              ),
            );
          }
          return null;
        },
        home: Scaffold(
          body: HomePolicyBriefing(
            apiClient: client,
            accessTokenProvider: () => 'access-token',
            onOpenPolicies: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-policy-hide-target')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('test-hide-policy')));
    await tester.pumpAndSettle();

    expect(find.text('숨길 정책'), findsNothing);
    expect(find.textContaining('정책을 홈에서 숨겼어요.'), findsOneWidget);
    await tester.tap(find.text('실행취소'));
    await tester.pumpAndSettle();
    expect(find.text('숨길 정책'), findsOneWidget);
  });
}

http.Response _success(Map<String, dynamic> data) => http.Response(
      jsonEncode({'success': true, 'data': data}),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> _policy({
  required String id,
  required String title,
  required String status,
  required String? reason,
  String? endDate,
}) =>
    {
      'policyId': id,
      'category': '주거',
      'categoryType': 'HOUSING',
      'title': title,
      'summary': '청년의 생활비 부담을 줄이는 정책이에요.',
      'supportAmount': null,
      'supportText': '월 최대 20만원 지원',
      'applicationPeriodText': endDate == null ? '상시' : '20260801~20260810',
      'applicationEndDate': endDate,
      'target': '만 19~34세',
      'agency': '부산광역시',
      'eligibilityStatus':
          status == 'CHECK_REQUIRED' ? 'CHECK_REQUIRED' : 'MATCHED',
      'eligibilityReasons': reason == null ? <String>[] : [reason],
      'recommendationStatus': status,
      'recommendationReasons': reason == null ? <String>[] : [reason],
    };
