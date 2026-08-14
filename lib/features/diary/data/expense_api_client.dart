import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../data/models.dart';

class CreateExpenseRequest {
  const CreateExpenseRequest({
    required this.userId,
    required this.category,
    required this.title,
    required this.amount,
    required this.spentAt,
    this.memo,
  });

  final int userId;
  final ExpenseCategory category;
  final String title;
  final int amount;
  final DateTime spentAt;
  final String? memo;

  Map<String, dynamic> toJson() {
    final trimmedMemo = memo?.trim();
    return {
      'userId': userId,
      'categoryId': category.databaseId,
      'title': title.trim(),
      'amount': amount,
      'spentAt': _formatRequestDateTime(spentAt),
      if (trimmedMemo != null && trimmedMemo.isNotEmpty) 'memo': trimmedMemo,
      'entryType': 'MANUAL',
    };
  }

}

class CreateAutoExpenseRequest {
  const CreateAutoExpenseRequest({
    required this.userId,
    required this.category,
    required this.title,
    required this.amount,
    required this.spentAt,
    required this.detectionKey,
    required this.notificationSource,
    this.memo,
  });

  final int userId;
  final ExpenseCategory category;
  final String title;
  final int amount;
  final DateTime spentAt;
  final String detectionKey;
  final String notificationSource;
  final String? memo;

  Map<String, dynamic> toJson() {
    final trimmedMemo = memo?.trim();
    return {
      'userId': userId,
      'categoryId': category.databaseId,
      'title': title.trim(),
      'amount': amount,
      'spentAt': _formatRequestDateTime(spentAt),
      if (trimmedMemo != null && trimmedMemo.isNotEmpty) 'memo': trimmedMemo,
      'detectionKey': detectionKey,
      'notificationSource': notificationSource.trim(),
    };
  }
}

extension on ExpenseCategory {
  int get databaseId => switch (this) {
        ExpenseCategory.food => 1,
        ExpenseCategory.cafe => 2,
        ExpenseCategory.transport => 3,
        ExpenseCategory.shopping => 4,
        ExpenseCategory.leisure => 6,
        ExpenseCategory.etc => 5,
      };
}

class ExpenseApiException implements Exception {
  const ExpenseApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ExpenseApiClient {
  ExpenseApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<List<Expense>> getExpenses({required String accessToken}) async {
    final uri = Uri.parse('$_baseUrl/api/expenses').replace(
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
      );
    } on http.ClientException catch (error) {
      throw ExpenseApiException(
        '서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.\n${error.message}',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ExpenseApiException(
        _errorMessage(
          response,
          fallbackMessage: '지출 내역을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
        ),
      );
    }

    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic> || body['data'] is! List) {
        throw const FormatException();
      }
      return (body['data'] as List).map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException();
        }
        return Expense(
          id: (item['expenseId'] as num).toInt().toString(),
          title: item['title'] as String,
          amount: (item['amount'] as num).toInt(),
          date: DateTime.parse(item['spentAt'] as String),
          category: _categoryFromDatabaseId(
            (item['categoryId'] as num).toInt(),
          ),
          memo: item['memo'] as String?,
        );
      }).toList();
    } on FormatException {
      throw const ExpenseApiException('서버의 지출 내역 응답 형식을 확인하지 못했어요.');
    } on TypeError {
      throw const ExpenseApiException('서버의 지출 내역 응답 형식을 확인하지 못했어요.');
    }
  }

  Future<void> deleteExpense({
    required String accessToken,
    required String expenseId,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/api/expenses/${Uri.encodeComponent(expenseId)}',
    );
    late final http.Response response;

    try {
      response = await _client.delete(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
    } on http.ClientException catch (error) {
      throw ExpenseApiException(
        '서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.\n${error.message}',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw ExpenseApiException(
      _errorMessage(
        response,
        fallbackMessage: '지출을 삭제하지 못했어요. 잠시 후 다시 시도해 주세요.',
      ),
    );
  }

  Future<void> createExpense({
    required String accessToken,
    required CreateExpenseRequest request,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/expenses');
    late final http.Response response;

    try {
      response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(request.toJson()),
      );
    } on http.ClientException catch (error) {
      throw ExpenseApiException(
        '서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.\n${error.message}',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw ExpenseApiException(
      _errorMessage(
        response,
        fallbackMessage: '지출을 저장하지 못했어요. 잠시 후 다시 시도해 주세요.',
      ),
    );
  }

  Future<void> createAutoExpense({
    required String accessToken,
    required CreateAutoExpenseRequest request,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/expenses/auto');
    late final http.Response response;

    try {
      response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(request.toJson()),
      );
    } on http.ClientException catch (error) {
      throw ExpenseApiException(
        '서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.\n${error.message}',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw ExpenseApiException(
      _errorMessage(
        response,
        fallbackMessage: '감지한 지출을 저장하지 못했어요. 잠시 후 다시 시도해 주세요.',
      ),
    );
  }

  String _errorMessage(
    http.Response response, {
    required String fallbackMessage,
  }) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic>) {
        final error = body['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.isNotEmpty) {
            return message;
          }
        }

        final message = body['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    } on FormatException {
      // Fall back to a status-based message for non-JSON responses.
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      return '로그인 정보가 만료되었어요. 다시 로그인해 주세요.';
    }
    if (response.statusCode == 400) {
      return '입력한 지출 정보를 다시 확인해 주세요.';
    }
    return fallbackMessage;
  }
}

ExpenseCategory _categoryFromDatabaseId(int categoryId) => switch (categoryId) {
      1 => ExpenseCategory.food,
      2 => ExpenseCategory.cafe,
      3 => ExpenseCategory.transport,
      4 => ExpenseCategory.shopping,
      5 => ExpenseCategory.etc,
      6 => ExpenseCategory.leisure,
      _ => throw const FormatException(),
    };

String _formatRequestDateTime(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)}'
      'T${twoDigits(value.hour)}:${twoDigits(value.minute)}:'
      '${twoDigits(value.second)}';
}
