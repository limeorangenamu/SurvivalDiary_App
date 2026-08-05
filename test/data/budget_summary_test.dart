import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/data/models.dart';

void main() {
  test('예산 미설정 상태를 초과로 판단하지 않는다', () {
    final summary = BudgetSummary.empty(userName: '신규 사용자');

    expect(summary.isOverLimit, isFalse);
    expect(summary.isNearLimit, isFalse);
  });

  test('설정한 예산 이상을 지출하면 초과로 판단한다', () {
    const summary = BudgetSummary(
      userName: '절약이',
      dailyLimit: 35000,
      remainingToday: 0,
      spentToday: 35000,
      savedToday: 0,
      dDay: 0,
      weeklyBudget: 245000,
      weeklySpent: 35000,
      topCategory: ExpenseCategory.food,
    );

    expect(summary.isOverLimit, isTrue);
  });
}
