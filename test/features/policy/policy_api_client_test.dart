import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_survival_diary/data/models.dart';
import 'package:project_survival_diary/features/policy/data/policy_api_client.dart';
import 'package:project_survival_diary/features/policy/data/policy_models.dart';

void main() {
  test('검색 조건과 액세스 토큰을 백엔드 계약 형식으로 전송한다', () async {
    late http.Request capturedRequest;
    final client = PolicyApiClient(
      baseUrl: 'http://test.example',
      client: MockClient((request) async {
        capturedRequest = request;
        return _successResponse({
          'items': [_summaryJson()],
          'partialResult': true,
          'checkedProviderPages': 3,
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
        employmentStatus: PolicyEmploymentStatus.jobSeeker,
        incomeRange: PolicyIncomeRange.below100,
        category: PolicyCategory.housing,
      ),
    );

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.path, '/api/policies/search');
    expect(capturedRequest.headers['Authorization'], 'Bearer access-token');
    expect(jsonDecode(capturedRequest.body), {
      'age': 27,
      'regionCode': '11',
      'districtCode': '11680',
      'employmentStatus': 'JOB_SEEKING',
      'incomeRange': 'BELOW_100',
      'category': 'HOUSING',
      'size': 20,
    });
    expect(result.partialResult, isTrue);
    expect(result.checkedProviderPages, 3);
    expect(result.items.single.policyId, 'POLICY-1');
    expect(
      result.items.single.eligibilityStatus,
      PolicyEligibilityStatus.checkRequired,
    );
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
          'supportText': '지원 내용',
          'applicationPeriodText': null,
          'target': '지원 대상',
          'agency': '주관 기관',
          'operatingAgency': '운영 기관',
          'applicationMethod': '온라인 신청',
          'documents': <String>[],
          'officialUrl': null,
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
    expect(detail.applicationPeriodText, isNull);
    expect(detail.officialUrl, isNull);
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
  employmentStatus: PolicyEmploymentStatus.jobSeeker,
);

Map<String, dynamic> _summaryJson() {
  return {
    'policyId': 'POLICY-1',
    'category': '주거',
    'categoryType': 'HOUSING',
    'title': '청년 주거 지원',
    'summary': '정책 설명',
    'supportAmount': null,
    'supportText': '지원 내용',
    'applicationPeriodText': '20260801~20260831',
    'target': '만 19~34세',
    'agency': '주관 기관',
    'eligibilityStatus': 'CHECK_REQUIRED',
    'eligibilityReasons': ['소득 조건을 확인해 주세요.'],
  };
}

http.Response _successResponse(Object data) {
  return http.Response(
    jsonEncode({'success': true, 'data': data}),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}
