import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class BudgetApiException implements Exception {
  const BudgetApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BudgetApiClient {
  BudgetApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<int> getToday({required String accessToken}) async {
    final response = await _request(
      method: 'GET',
      period: 'today',
      accessToken: accessToken,
    );
    return _amount(response);
  }

  Future<int> saveToday({
    required String accessToken,
    required int amount,
  }) async {
    final response = await _request(
      method: 'PUT',
      period: 'today',
      accessToken: accessToken,
      amount: amount,
    );
    return _amount(response);
  }

  Future<int> getMonth({required String accessToken}) async {
    final response = await _request(
        method: 'GET', period: 'month', accessToken: accessToken);
    return _amount(response);
  }

  Future<int> saveMonth(
      {required String accessToken, required int amount}) async {
    final response = await _request(
      method: 'PUT',
      period: 'month',
      accessToken: accessToken,
      amount: amount,
    );
    return _amount(response);
  }

  Future<http.Response> _request({
    required String method,
    required String period,
    required String accessToken,
    int? amount,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/budgets/$period');
    try {
      final response = switch (method) {
        'GET' => await _client
            .get(uri, headers: _headers(accessToken))
            .timeout(const Duration(seconds: 10)),
        'PUT' => await _client
            .put(
              uri,
              headers: _headers(accessToken, json: true),
              body: jsonEncode({'amount': amount}),
            )
            .timeout(const Duration(seconds: 10)),
        _ => throw StateError('지원하지 않는 요청 방식입니다.'),
      };
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      throw BudgetApiException(_errorMessage(response));
    } on http.ClientException catch (error) {
      throw BudgetApiException(
        '예산 서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.\n${error.message}',
      );
    } on TimeoutException {
      throw const BudgetApiException('예산 서버 응답이 늦어지고 있어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  Map<String, String> _headers(String accessToken, {bool json = false}) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Cache-Control': 'no-cache',
        if (json) 'Content-Type': 'application/json',
      };

  int _amount(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final data = body is Map<String, dynamic> ? body['data'] : null;
      if (data is! Map<String, dynamic>) {
        throw const FormatException();
      }
      return (data['amount'] as num?)?.toInt() ?? 0;
    } on FormatException {
      throw const BudgetApiException('서버의 예산 응답 형식을 확인하지 못했어요.');
    } on TypeError {
      throw const BudgetApiException('서버의 예산 응답 형식을 확인하지 못했어요.');
    }
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final error = body is Map<String, dynamic> ? body['error'] : null;
      final message = error is Map<String, dynamic> ? error['message'] : null;
      if (message is String && message.isNotEmpty) {
        return message;
      }
    } on FormatException {
      // 상태 코드에 맞는 기본 안내 문구를 사용한다.
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      return '로그인 정보가 만료되었어요. 다시 로그인해 주세요.';
    }
    return '예산을 처리하지 못했어요. 잠시 후 다시 시도해 주세요.';
  }
}
