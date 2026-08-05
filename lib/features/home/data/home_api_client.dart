import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../data/models.dart';

class HomeApiException implements Exception {
  const HomeApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class HomeApiClient {
  HomeApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<BudgetSummary> getSummary({required String accessToken}) async {
    final uri = Uri.parse('$_baseUrl/api/home/summary').replace(
      queryParameters: {
        '_t': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );

    late final http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 10));
    } on http.ClientException catch (error) {
      throw HomeApiException('메인 데이터를 불러오지 못했어요.\n${error.message}');
    } on TimeoutException {
      throw const HomeApiException('메인 데이터 응답이 지연되고 있어요. 잠시 후 다시 시도해 주세요.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HomeApiException(_errorMessage(response));
    }

    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final data = body is Map<String, dynamic> ? body['data'] : null;
      if (data is! Map<String, dynamic>) throw const FormatException();
      return BudgetSummary(
        userName: data['userName'] as String? ?? '',
        dailyLimit: _int(data['dailyLimit']),
        remainingToday: _int(data['remainingToday']),
        spentToday: _int(data['spentToday']),
        savedToday: _int(data['savedToday']),
        dDay: 0,
        weeklyBudget: _int(data['weeklyBudget']),
        weeklySpent: _int(data['weeklySpent']),
        topCategory: _category(data['topCategoryId']),
      );
    } on FormatException {
      throw const HomeApiException('메인 데이터 응답 형식을 확인할 수 없어요.');
    } on TypeError {
      throw const HomeApiException('메인 데이터 응답 형식을 확인할 수 없어요.');
    }
  }

  int _int(Object? value) => (value as num?)?.toInt() ?? 0;

  ExpenseCategory? _category(Object? value) => switch ((value as num?)?.toInt()) {
        1 => ExpenseCategory.food,
        2 => ExpenseCategory.cafe,
        3 => ExpenseCategory.transport,
        4 => ExpenseCategory.shopping,
        5 => ExpenseCategory.etc,
        _ => null,
      };

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic>) {
        final error = body['error'];
        if (error is Map<String, dynamic> && error['message'] is String) {
          return error['message'] as String;
        }
      }
    } on FormatException {
      // Use a generic message for non-JSON responses.
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      return '로그인 세션이 만료됐어요. 다시 로그인해 주세요.';
    }
    return '메인 데이터를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.';
  }
}
