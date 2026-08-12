import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../data/models.dart';
import 'policy_models.dart';

enum PolicyApiErrorType {
  unauthorized,
  notFound,
  network,
  invalidResponse,
  server,
}

class PolicyApiException implements Exception {
  const PolicyApiException(this.message, {required this.type});

  final String message;
  final PolicyApiErrorType type;

  @override
  String toString() => message;
}

class PolicyApiClient {
  PolicyApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<PolicyPreference> getPolicyPreference({
    required String accessToken,
  }) async {
    final response = await _send(
      () => _client.get(
        Uri.parse('$_baseUrl/api/users/me/policy-preferences'),
        headers: _headers(accessToken),
      ),
      fallbackMessage: '저장된 정책 조건을 불러오지 못했어요.',
    );

    try {
      return PolicyPreference.fromJson(_responseData(response));
    } on FormatException {
      throw const PolicyApiException(
        '서버의 정책 조건 응답 형식을 확인하지 못했어요.',
        type: PolicyApiErrorType.invalidResponse,
      );
    } on TypeError {
      throw const PolicyApiException(
        '서버의 정책 조건 응답 형식을 확인하지 못했어요.',
        type: PolicyApiErrorType.invalidResponse,
      );
    }
  }

  Future<PolicyPreference> savePolicyPreference({
    required String accessToken,
    required PolicyFilterCondition condition,
  }) async {
    final response = await _send(
      () => _client.put(
        Uri.parse('$_baseUrl/api/users/me/policy-preferences'),
        headers: _headers(accessToken, hasBody: true),
        body: jsonEncode(_preferenceBody(condition)),
      ),
      fallbackMessage: '정책 기본 조건을 저장하지 못했어요.',
    );

    try {
      return PolicyPreference.fromJson(_responseData(response));
    } on FormatException {
      throw const PolicyApiException(
        '서버의 정책 조건 응답 형식을 확인하지 못했어요.',
        type: PolicyApiErrorType.invalidResponse,
      );
    } on TypeError {
      throw const PolicyApiException(
        '서버의 정책 조건 응답 형식을 확인하지 못했어요.',
        type: PolicyApiErrorType.invalidResponse,
      );
    }
  }

  Future<PolicySearchResult> searchPolicies({
    required String accessToken,
    required PolicyFilterCondition condition,
    PolicyCategory? category,
    String? keyword,
    int page = 1,
    int size = 20,
  }) async {
    final response = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl/api/policies/search'),
        headers: _headers(accessToken, hasBody: true),
        body: jsonEncode(
          _searchBody(
            condition,
            category: category,
            keyword: keyword,
            page: page,
            size: size,
          ),
        ),
      ),
      fallbackMessage: '정책 목록을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
      retryTransient: true,
    );

    try {
      return PolicySearchResult.fromJson(_responseData(response));
    } on FormatException {
      throw const PolicyApiException(
        '서버의 정책 목록 응답 형식을 확인하지 못했어요.',
        type: PolicyApiErrorType.invalidResponse,
      );
    } on TypeError {
      throw const PolicyApiException(
        '서버의 정책 목록 응답 형식을 확인하지 못했어요.',
        type: PolicyApiErrorType.invalidResponse,
      );
    }
  }

  Future<PolicySearchResult> recommendPolicies({
    required String accessToken,
    PolicyCategory? category,
    String? keyword,
    int page = 1,
    int size = 20,
  }) async {
    final response = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl/api/policies/recommendations'),
        headers: _headers(accessToken, hasBody: true),
        body: jsonEncode(
          _recommendationBody(
            category: category,
            keyword: keyword,
            page: page,
            size: size,
          ),
        ),
      ),
      fallbackMessage: '맞춤 정책을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
      retryTransient: true,
    );

    try {
      return PolicySearchResult.fromJson(_responseData(response));
    } on FormatException {
      throw const PolicyApiException(
        '서버의 맞춤 정책 응답 형식을 확인하지 못했어요.',
        type: PolicyApiErrorType.invalidResponse,
      );
    } on TypeError {
      throw const PolicyApiException(
        '서버의 맞춤 정책 응답 형식을 확인하지 못했어요.',
        type: PolicyApiErrorType.invalidResponse,
      );
    }
  }

  Future<HiddenPolicyResult> getHiddenPolicies({
    required String accessToken,
    int page = 0,
    int size = 100,
  }) async {
    final response = await _send(
      () => _client.get(
        Uri.parse(
          '$_baseUrl/api/users/me/hidden-policies?page=$page&size=$size',
        ),
        headers: _headers(accessToken),
      ),
      fallbackMessage: '관심 없음 정책을 불러오지 못했어요.',
    );

    try {
      return HiddenPolicyResult.fromJson(_responseData(response));
    } on FormatException {
      throw const PolicyApiException(
        '서버의 관심 없음 정책 응답 형식을 확인하지 못했어요.',
        type: PolicyApiErrorType.invalidResponse,
      );
    } on TypeError {
      throw const PolicyApiException(
        '서버의 관심 없음 정책 응답 형식을 확인하지 못했어요.',
        type: PolicyApiErrorType.invalidResponse,
      );
    }
  }

  Future<HiddenPolicySummary> hidePolicy({
    required String accessToken,
    required PolicySummary policy,
  }) async {
    final policyId = Uri.encodeComponent(policy.policyId);
    final response = await _send(
      () => _client.put(
        Uri.parse('$_baseUrl/api/users/me/hidden-policies/$policyId'),
        headers: _headers(accessToken, hasBody: true),
        body: jsonEncode({
          'title': _limitedText(policy.title, 200),
          'category': _limitedText(policy.category, 100),
          'shortSummary': _limitedText(
            policy.shortSummary ?? policy.summary,
            500,
          ),
        }),
      ),
      fallbackMessage: '정책을 관심 없음으로 설정하지 못했어요.',
    );

    try {
      return HiddenPolicySummary.fromJson(_responseData(response));
    } on FormatException {
      throw const PolicyApiException(
        '서버의 관심 없음 저장 응답 형식을 확인하지 못했어요.',
        type: PolicyApiErrorType.invalidResponse,
      );
    } on TypeError {
      throw const PolicyApiException(
        '서버의 관심 없음 저장 응답 형식을 확인하지 못했어요.',
        type: PolicyApiErrorType.invalidResponse,
      );
    }
  }

  Future<void> restoreHiddenPolicy({
    required String accessToken,
    required String policyId,
  }) async {
    await _send(
      () => _client.delete(
        Uri.parse(
          '$_baseUrl/api/users/me/hidden-policies/${Uri.encodeComponent(policyId)}',
        ),
        headers: _headers(accessToken),
      ),
      fallbackMessage: '관심 없음 정책을 복구하지 못했어요.',
    );
  }

  Future<PolicyDetail> getPolicyDetail({
    required String accessToken,
    required String policyId,
  }) async {
    final response = await _send(
      () => _client.get(
        Uri.parse('$_baseUrl/api/policies/${Uri.encodeComponent(policyId)}'),
        headers: _headers(accessToken),
      ),
      fallbackMessage: '정책 상세를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
    );

    try {
      return PolicyDetail.fromJson(_responseData(response));
    } on FormatException {
      throw const PolicyApiException(
        '서버의 정책 상세 응답 형식을 확인하지 못했어요.',
        type: PolicyApiErrorType.invalidResponse,
      );
    } on TypeError {
      throw const PolicyApiException(
        '서버의 정책 상세 응답 형식을 확인하지 못했어요.',
        type: PolicyApiErrorType.invalidResponse,
      );
    }
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    required String fallbackMessage,
    bool retryTransient = false,
  }) async {
    final maxAttempts = retryTransient ? 2 : 1;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await request().timeout(const Duration(seconds: 15));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        if (attempt < maxAttempts && _isTransientStatus(response.statusCode)) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          continue;
        }

        final type = switch (response.statusCode) {
          401 || 403 => PolicyApiErrorType.unauthorized,
          404 => PolicyApiErrorType.notFound,
          _ => PolicyApiErrorType.server,
        };
        throw PolicyApiException(
          _errorMessage(response, type: type, fallbackMessage: fallbackMessage),
          type: type,
        );
      } on TimeoutException {
        if (attempt < maxAttempts) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          continue;
        }
        throw const PolicyApiException(
          '서버 응답이 늦어지고 있어요. 잠시 후 다시 시도해 주세요.',
          type: PolicyApiErrorType.network,
        );
      } on http.ClientException {
        if (attempt < maxAttempts) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          continue;
        }
        throw const PolicyApiException(
          '서버에 연결하지 못했어요. 네트워크를 확인한 뒤 다시 시도해 주세요.',
          type: PolicyApiErrorType.network,
        );
      }
    }
    throw PolicyApiException(
      fallbackMessage,
      type: PolicyApiErrorType.server,
    );
  }

  bool _isTransientStatus(int statusCode) {
    return statusCode == 429 ||
        statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  Map<String, dynamic> _responseData(http.Response response) {
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map<String, dynamic> ||
        body['success'] != true ||
        body['data'] is! Map<String, dynamic>) {
      throw const FormatException();
    }
    return body['data'] as Map<String, dynamic>;
  }

  Map<String, String> _headers(String accessToken, {bool hasBody = false}) {
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'Cache-Control': 'no-cache',
      if (hasBody) 'Content-Type': 'application/json',
    };
  }

  Map<String, dynamic> _searchBody(
    PolicyFilterCondition condition, {
    PolicyCategory? category,
    String? keyword,
    required int page,
    required int size,
  }) {
    final resolvedCategory = category ?? condition.category;
    final normalizedKeyword = keyword?.trim();
    return {
      'age': condition.age,
      'regionCode': condition.regionCode,
      if (condition.districtCode != null)
        'districtCode': condition.districtCode,
      if (condition.workStatus != null)
        'workStatus': _workStatusCode(condition.workStatus!),
      if (condition.jobSeeking != null) 'jobSeeking': condition.jobSeeking,
      if (condition.educationLevel != null)
        'educationLevel': _educationLevelCode(condition.educationLevel!),
      if (condition.enrollmentStatus != null)
        'enrollmentStatus': _enrollmentStatusCode(condition.enrollmentStatus!),
      'interests': condition.interests.map(_interestCode).toList(),
      if (resolvedCategory != null)
        'category': switch (resolvedCategory) {
          PolicyCategory.employment => 'EMPLOYMENT',
          PolicyCategory.housing => 'HOUSING',
          PolicyCategory.education => 'EDUCATION',
          PolicyCategory.welfareCulture => 'WELFARE_CULTURE',
          PolicyCategory.participationRights => 'PARTICIPATION_RIGHTS',
        },
      if (normalizedKeyword != null && normalizedKeyword.isNotEmpty)
        'keyword': normalizedKeyword,
      'page': page,
      'size': size,
    };
  }

  Map<String, dynamic> _recommendationBody({
    PolicyCategory? category,
    String? keyword,
    required int page,
    required int size,
  }) {
    final normalizedKeyword = keyword?.trim();
    return {
      if (category != null)
        'category': switch (category) {
          PolicyCategory.employment => 'EMPLOYMENT',
          PolicyCategory.housing => 'HOUSING',
          PolicyCategory.education => 'EDUCATION',
          PolicyCategory.welfareCulture => 'WELFARE_CULTURE',
          PolicyCategory.participationRights => 'PARTICIPATION_RIGHTS',
        },
      if (normalizedKeyword != null && normalizedKeyword.isNotEmpty)
        'keyword': normalizedKeyword,
      'page': page,
      'size': size,
    };
  }

  Map<String, dynamic> _preferenceBody(PolicyFilterCondition condition) {
    return {
      'age': condition.age,
      'regionCode': condition.regionCode,
      if (condition.districtCode != null)
        'districtCode': condition.districtCode,
      if (condition.workStatus != null)
        'workStatus': _workStatusCode(condition.workStatus!),
      if (condition.jobSeeking != null) 'jobSeeking': condition.jobSeeking,
      if (condition.educationLevel != null)
        'educationLevel': _educationLevelCode(condition.educationLevel!),
      if (condition.enrollmentStatus != null)
        'enrollmentStatus': _enrollmentStatusCode(condition.enrollmentStatus!),
      'interests': condition.interests.map(_interestCode).toList(),
    };
  }

  String _workStatusCode(PolicyWorkStatus status) => switch (status) {
        PolicyWorkStatus.employed => 'EMPLOYED',
        PolicyWorkStatus.selfEmployed => 'SELF_EMPLOYED',
        PolicyWorkStatus.unemployed => 'UNEMPLOYED',
        PolicyWorkStatus.freelancer => 'FREELANCER',
        PolicyWorkStatus.dailyWorker => 'DAILY_WORKER',
        PolicyWorkStatus.prospectiveFounder => 'PROSPECTIVE_FOUNDER',
        PolicyWorkStatus.shortTermWorker => 'SHORT_TERM_WORKER',
        PolicyWorkStatus.farmer => 'FARMER',
        PolicyWorkStatus.other => 'OTHER',
      };

  String _educationLevelCode(PolicyEducationLevel level) => switch (level) {
        PolicyEducationLevel.middleSchoolOrLess => 'MIDDLE_SCHOOL_OR_LESS',
        PolicyEducationLevel.highSchool => 'HIGH_SCHOOL',
        PolicyEducationLevel.collegeTwoThreeYear => 'COLLEGE_2_3_YEAR',
        PolicyEducationLevel.universityFourYear => 'UNIVERSITY_4_YEAR',
        PolicyEducationLevel.graduateSchool => 'GRADUATE_SCHOOL',
        PolicyEducationLevel.other => 'OTHER',
      };

  String _enrollmentStatusCode(PolicyEnrollmentStatus status) =>
      switch (status) {
        PolicyEnrollmentStatus.enrolled => 'ENROLLED',
        PolicyEnrollmentStatus.onLeave => 'ON_LEAVE',
        PolicyEnrollmentStatus.expectedGraduation => 'EXPECTED_GRADUATION',
        PolicyEnrollmentStatus.graduated => 'GRADUATED',
        PolicyEnrollmentStatus.droppedOut => 'DROPPED_OUT',
        PolicyEnrollmentStatus.notApplicable => 'NOT_APPLICABLE',
      };

  String _interestCode(PolicyInterest interest) => switch (interest) {
        PolicyInterest.employment => 'EMPLOYMENT',
        PolicyInterest.housing => 'HOUSING',
        PolicyInterest.education => 'EDUCATION',
        PolicyInterest.welfareCulture => 'WELFARE_CULTURE',
        PolicyInterest.participationRights => 'PARTICIPATION_RIGHTS',
        PolicyInterest.assetBuilding => 'ASSET_BUILDING',
        PolicyInterest.transport => 'TRANSPORT',
      };

  String _limitedText(String value, int maxLength) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return normalized.substring(0, maxLength);
  }

  String _errorMessage(
    http.Response response, {
    required PolicyApiErrorType type,
    required String fallbackMessage,
  }) {
    if (type == PolicyApiErrorType.unauthorized) {
      return '로그인 정보가 만료되었어요. 다시 로그인해 주세요.';
    }
    if (type == PolicyApiErrorType.notFound) {
      return '정책 정보를 찾을 수 없어요.';
    }

    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic>) {
        final error = body['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }
        final message = body['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } on FormatException {
      // JSON이 아닌 오류 응답은 화면용 기본 문구로 처리한다.
    }
    return fallbackMessage;
  }
}
