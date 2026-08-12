import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_survival_diary/data/models.dart';
import 'package:project_survival_diary/features/policy/data/policy_api_client.dart';
import 'package:project_survival_diary/features/policy/data/policy_models.dart';

void main() {
  test('저장된 기본 조건이 없으면 saved false 응답을 변환한다', () async {
    late http.Request capturedRequest;
    final client = PolicyApiClient(
      baseUrl: 'http://test.example',
      client: MockClient((request) async {
        capturedRequest = request;
        return _successResponse({
          'saved': false,
          'age': 26,
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
      }),
    );

    final preference = await client.getPolicyPreference(
      accessToken: 'access-token',
    );

    expect(capturedRequest.method, 'GET');
    expect(
      capturedRequest.url.path,
      '/api/users/me/policy-preferences',
    );
    expect(preference.saved, isFalse);
    expect(preference.age, 26);
    expect(preference.regionCode, isNull);
  });

  test('기본 조건 저장 시 전체 선택 항목은 요청에서 생략한다', () async {
    late http.Request capturedRequest;
    final client = PolicyApiClient(
      baseUrl: 'http://test.example',
      client: MockClient((request) async {
        capturedRequest = request;
        return _successResponse({
          'saved': true,
          'age': 26,
          'regionCode': '11',
          'districtCode': null,
          'employmentStatus': 'JOB_SEEKING',
          'incomeRange': null,
          'category': null,
          'workStatus': 'UNEMPLOYED',
          'jobSeeking': true,
          'educationStatus': null,
          'interests': ['EMPLOYMENT', 'ASSET_BUILDING'],
        });
      }),
    );

    final preference = await client.savePolicyPreference(
      accessToken: 'access-token',
      condition: _condition,
    );

    expect(capturedRequest.method, 'PUT');
    expect(
      capturedRequest.url.path,
      '/api/users/me/policy-preferences',
    );
    expect(jsonDecode(capturedRequest.body), {
      'age': 27,
      'regionCode': '11',
      'workStatus': 'UNEMPLOYED',
      'jobSeeking': true,
      'interests': ['EMPLOYMENT', 'ASSET_BUILDING'],
    });
    expect(preference.saved, isTrue);
    expect(preference.workStatus, PolicyWorkStatus.unemployed);
    expect(preference.jobSeeking, isTrue);
    expect(
      preference.interests,
      {PolicyInterest.employment, PolicyInterest.assetBuilding},
    );
  });

  test('검색 조건과 액세스 토큰을 백엔드 계약 형식으로 전송한다', () async {
    late http.Request capturedRequest;
    final client = PolicyApiClient(
      baseUrl: 'http://test.example',
      client: MockClient((request) async {
        capturedRequest = request;
        return _successResponse({
          'items': [_summaryJson()],
          'partialResult': true,
          'checkedProviderPages': 1,
          'nextPage': 4,
        });
      }),
    );

    final result = await client.searchPolicies(
      accessToken: 'access-token',
      condition: const PolicyFilterCondition(
        age: 27,
        regionCode: '11',
        region: '서울특별시',
        districtCode: '11680',
        district: '강남구',
        workStatus: PolicyWorkStatus.unemployed,
        jobSeeking: true,
        educationLevel: PolicyEducationLevel.universityFourYear,
        enrollmentStatus: PolicyEnrollmentStatus.graduated,
        category: PolicyCategory.housing,
        interests: {PolicyInterest.housing, PolicyInterest.assetBuilding},
      ),
      keyword: '  월세  ',
      page: 3,
    );

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.path, '/api/policies/search');
    expect(capturedRequest.headers['Authorization'], 'Bearer access-token');
    expect(jsonDecode(capturedRequest.body), {
      'age': 27,
      'regionCode': '11',
      'districtCode': '11680',
      'workStatus': 'UNEMPLOYED',
      'jobSeeking': true,
      'educationLevel': 'UNIVERSITY_4_YEAR',
      'enrollmentStatus': 'GRADUATED',
      'interests': ['HOUSING', 'ASSET_BUILDING'],
      'category': 'HOUSING',
      'keyword': '월세',
      'page': 3,
      'size': 20,
    });
    expect(result.partialResult, isTrue);
    expect(result.checkedProviderPages, 1);
    expect(result.nextPage, 4);
    expect(result.items.single.policyId, 'POLICY-1');
    expect(
      result.items.single.shortSummary,
      '청년의 월세와 주거비를 월 최대 20만원 지원해요',
    );
    expect(
      result.items.single.eligibilityStatus,
      PolicyEligibilityStatus.checkRequired,
    );
    expect(
      result.items.single.recommendationStatus,
      PolicyRecommendationStatus.checkRequired,
    );
    expect(
      result.items.single.matchSignals,
      containsAll([
        PolicyMatchSignal.district,
        PolicyMatchSignal.interestHousing,
      ]),
    );
    expect(result.items.single.supportAmount, 200000);
    expect(
      result.items.single.supportAmountType,
      PolicySupportAmountType.monthlyMaximum,
    );
    expect(
      result.items.single.applicationPeriodType,
      PolicyApplicationPeriodType.fixed,
    );
    expect(
      result.items.single.applicationStartDate,
      DateTime(2026, 8, 1),
    );
  });

  test('맞춤 추천은 저장 조건 대신 탐색 조건만 전송한다', () async {
    late http.Request capturedRequest;
    final client = PolicyApiClient(
      baseUrl: 'http://test.example',
      client: MockClient((request) async {
        capturedRequest = request;
        return _successResponse({
          'items': [_summaryJson()],
          'partialResult': false,
          'checkedProviderPages': 1,
          'nextPage': null,
        });
      }),
    );

    await client.recommendPolicies(
      accessToken: 'access-token',
      category: PolicyCategory.housing,
      keyword: '  월세  ',
      page: 2,
    );

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.path, '/api/policies/recommendations');
    expect(capturedRequest.headers['Authorization'], 'Bearer access-token');
    expect(jsonDecode(capturedRequest.body), {
      'category': 'HOUSING',
      'keyword': '월세',
      'page': 2,
      'size': 20,
    });
  });

  test('정책 ID를 인코딩해 상세를 조회하고 nullable 필드를 변환한다', () async {
    late http.Request capturedRequest;
    final client = PolicyApiClient(
      baseUrl: 'http://test.example',
      client: MockClient((request) async {
        capturedRequest = request;
        return _successResponse({
          'policyId': 'POLICY A/1',
          'category': '기타',
          'categoryType': null,
          'title': '정책 제목',
          'description': '정책 설명',
          'supportAmount': null,
          'supportAmountType': null,
          'supportText': '지원 내용',
          'applicationPeriodText': null,
          'applicationPeriodType': 'UNKNOWN',
          'applicationStartDate': null,
          'target': '지원 대상',
          'agency': '주관 기관',
          'operatingAgency': '운영 기관',
          'applicationMethod': '온라인 신청',
          'documents': <String>[],
          'officialUrl': null,
          'officialLinkType': 'UNAVAILABLE',
          'referenceUrls': <String>[],
        });
      }),
    );

    final detail = await client.getPolicyDetail(
      accessToken: 'access-token',
      policyId: 'POLICY A/1',
    );

    expect(capturedRequest.url.pathSegments.last, 'POLICY A/1');
    expect(detail.categoryType, isNull);
    expect(detail.supportAmount, isNull);
    expect(detail.supportAmountType, isNull);
    expect(detail.applicationPeriodText, isNull);
    expect(
      detail.applicationPeriodType,
      PolicyApplicationPeriodType.unknown,
    );
    expect(detail.officialUrl, isNull);
    expect(detail.officialLinkType, PolicyOfficialLinkType.unavailable);
  });

  test('추천 필드가 없는 구버전 응답은 자격 확인 상태로 호환한다', () async {
    final legacySummary = _summaryJson()
      ..remove('shortSummary')
      ..remove('matchSignals')
      ..remove('recommendationStatus')
      ..remove('recommendationReasons');
    final client = PolicyApiClient(
      baseUrl: 'http://test.example',
      client: MockClient(
        (request) async => _successResponse({
          'items': [legacySummary],
          'partialResult': false,
          'checkedProviderPages': 1,
          'nextPage': null,
        }),
      ),
    );

    final result = await client.searchPolicies(
      accessToken: 'access-token',
      condition: _condition,
    );

    expect(
      result.items.single.recommendationStatus,
      PolicyRecommendationStatus.checkRequired,
    );
    expect(result.items.single.shortSummary, isNull);
    expect(result.items.single.matchSignals, isEmpty);
    expect(
      result.items.single.recommendationReasons,
      ['소득 조건을 확인해 주세요.'],
    );
  });

  test('관심 없음 정책을 계정 목록에서 조회하고 저장하고 복구한다', () async {
    final capturedRequests = <http.Request>[];
    final client = PolicyApiClient(
      baseUrl: 'http://test.example',
      client: MockClient((request) async {
        capturedRequests.add(request);
        if (request.method == 'GET') {
          return _successResponse({
            'content': [
              {
                'policyId': 'POLICY A/1',
                'title': '청년 주거 지원',
                'category': '주거',
                'shortSummary': '월세를 지원해요',
                'hiddenAt': '2026-08-06T12:00:00',
              },
            ],
            'page': 0,
            'size': 100,
            'totalElements': 1,
            'totalPages': 1,
            'hasNext': false,
          });
        }
        if (request.method == 'PUT') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return _successResponse({
            'policyId': 'POLICY A/1',
            ...body,
            'hiddenAt': '2026-08-06T12:00:00',
          });
        }
        return _successResponse(<String, dynamic>{});
      }),
    );
    final policyJson = _summaryJson()..['policyId'] = 'POLICY A/1';
    final policy = PolicySummary.fromJson(policyJson);

    final hidden = await client.getHiddenPolicies(
      accessToken: 'access-token',
    );
    final saved = await client.hidePolicy(
      accessToken: 'access-token',
      policy: policy,
    );
    await client.restoreHiddenPolicy(
      accessToken: 'access-token',
      policyId: policy.policyId,
    );

    expect(hidden.items.single.policyId, 'POLICY A/1');
    expect(hidden.items.single.hiddenAt, DateTime(2026, 8, 6, 12));
    expect(saved.title, policy.title);
    expect(capturedRequests[0].url.queryParameters, {
      'page': '0',
      'size': '100',
    });
    expect(capturedRequests[1].method, 'PUT');
    expect(capturedRequests[1].url.pathSegments.last, 'POLICY A/1');
    expect(capturedRequests[2].method, 'DELETE');
    expect(capturedRequests[2].url.pathSegments.last, 'POLICY A/1');
  });

  test('인증 실패는 로그인 만료 오류로 구분한다', () async {
    final client = PolicyApiClient(
      baseUrl: 'http://test.example',
      client: MockClient((request) async => http.Response('{}', 401)),
    );

    expect(
      () => client.searchPolicies(
        accessToken: 'expired-token',
        condition: _condition,
      ),
      throwsA(
        isA<PolicyApiException>()
            .having(
              (error) => error.type,
              'type',
              PolicyApiErrorType.unauthorized,
            )
            .having(
              (error) => error.message,
              'message',
              '로그인 정보가 만료되었어요. 다시 로그인해 주세요.',
            ),
      ),
    );
  });

  test('응답 계약이 다르면 형식 오류를 반환한다', () async {
    final client = PolicyApiClient(
      baseUrl: 'http://test.example',
      client: MockClient(
        (request) async => _successResponse({'unexpected': true}),
      ),
    );

    expect(
      () => client.searchPolicies(
        accessToken: 'access-token',
        condition: _condition,
      ),
      throwsA(
        isA<PolicyApiException>().having(
          (error) => error.type,
          'type',
          PolicyApiErrorType.invalidResponse,
        ),
      ),
    );
  });
}

const _condition = PolicyFilterCondition(
  age: 27,
  regionCode: '11',
  region: '서울특별시',
  workStatus: PolicyWorkStatus.unemployed,
  jobSeeking: true,
  interests: {PolicyInterest.employment, PolicyInterest.assetBuilding},
);

Map<String, dynamic> _summaryJson() {
  return {
    'policyId': 'POLICY-1',
    'category': '주거',
    'categoryType': 'HOUSING',
    'title': '청년 주거 지원',
    'summary': '정책 설명',
    'shortSummary': '청년의 월세와 주거비를 월 최대 20만원 지원해요',
    'supportAmount': 200000,
    'supportAmountType': 'MONTHLY_MAXIMUM',
    'supportText': '월 최대 20만 원, 최대 12개월 지원',
    'applicationPeriodText': '20260801~20260831',
    'applicationPeriodType': 'FIXED',
    'applicationStartDate': '2026-08-01',
    'applicationEndDate': '2026-08-31',
    'target': '만 19~34세',
    'agency': '주관 기관',
    'eligibilityStatus': 'CHECK_REQUIRED',
    'eligibilityReasons': ['소득 조건을 확인해 주세요.'],
    'recommendationStatus': 'CHECK_REQUIRED',
    'recommendationReasons': [
      '중위소득 조건을 공고문에서 확인해야 합니다.',
      '관심 주제인 주거 분야와 관련된 정책이에요.',
    ],
    'matchSignals': ['DISTRICT', 'INTEREST_HOUSING'],
  };
}

http.Response _successResponse(Object data) {
  return http.Response(
    jsonEncode({'success': true, 'data': data}),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}
