import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_survival_diary/data/models.dart';
import 'package:project_survival_diary/features/diary/data/expense_api_client.dart';

void main() {
  test('지출 조회에서 카드 자동 결제 유형과 출처를 변환한다', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'success': true,
          'data': [
            {
              'expenseId': 1,
              'categoryId': 2,
              'title': '서면착한식당',
              'amount': 7000,
              'spentAt': '2026-08-20T12:30:00',
              'memo': null,
              'entryType': 'AUTO',
              'notificationSource': '신한카드',
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final expenses = await ExpenseApiClient(
      client: client,
      baseUrl: 'https://example.test',
    ).getExpenses(accessToken: 'access-token');

    expect(expenses.single.entryType, ExpenseEntryType.auto);
    expect(expenses.single.notificationSource, '신한카드');
  });

  test('감지한 결제는 AUTO 전용 API 계약으로 저장한다', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({'success': true, 'data': {}}),
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    final apiClient = ExpenseApiClient(
      client: client,
      baseUrl: 'https://example.test',
    );

    await apiClient.createAutoExpense(
      accessToken: 'access-token',
      request: CreateAutoExpenseRequest(
        userId: 1,
        category: ExpenseCategory.cafe,
        title: '스타벅스 강남점',
        amount: 5500,
        spentAt: DateTime(2026, 8, 3, 9, 42),
        detectionKey: 'detection-key',
        notificationSource: '토스',
      ),
    );

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.path, '/api/expenses/auto');
    expect(capturedRequest.headers['Authorization'], 'Bearer access-token');
    expect(jsonDecode(capturedRequest.body), {
      'userId': 1,
      'categoryId': 2,
      'title': '스타벅스 강남점',
      'amount': 5500,
      'spentAt': '2026-08-03T09:42:00',
      'detectionKey': 'detection-key',
      'notificationSource': '토스',
    });
  });
}
