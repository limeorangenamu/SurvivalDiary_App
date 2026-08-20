import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/data/models.dart';
import 'package:project_survival_diary/features/map/place_expense_summary.dart';

void main() {
  test('카드 자동 결제만 장소명으로 매칭해 누적 사용액을 계산한다', () {
    final summary = summarizeCardExpensesForPlace(
      expenses: [
        _expense(
          id: '1',
          title: '서면 착한식당',
          amount: 7000,
          date: DateTime(2026, 8, 18),
          entryType: ExpenseEntryType.auto,
        ),
        _expense(
          id: '2',
          title: '서면착한식당 카드결제',
          amount: 9000,
          date: DateTime(2026, 8, 20),
          entryType: ExpenseEntryType.auto,
        ),
        _expense(
          id: '3',
          title: '서면착한식당',
          amount: 3000,
          date: DateTime(2026, 8, 19),
          entryType: ExpenseEntryType.manual,
        ),
        _expense(
          id: '4',
          title: '다른 식당',
          amount: 5000,
          date: DateTime(2026, 8, 20),
          entryType: ExpenseEntryType.auto,
        ),
      ],
      placeNames: const ['서면착한식당'],
    );

    expect(summary, isNotNull);
    expect(summary!.totalAmount, 16000);
    expect(summary.paymentCount, 2);
    expect(summary.latestAmount, 9000);
    expect(summary.latestDate, DateTime(2026, 8, 20));
  });

  test('매칭되는 카드 결제가 없으면 사용액을 표시하지 않는다', () {
    final summary = summarizeCardExpensesForPlace(
      expenses: [
        _expense(
          id: '1',
          title: '다른 주차장',
          amount: 2000,
          date: DateTime(2026, 8, 20),
          entryType: ExpenseEntryType.auto,
        ),
        _expense(
          id: '2',
          title: '주차장',
          amount: 3000,
          date: DateTime(2026, 8, 20),
          entryType: ExpenseEntryType.auto,
        ),
      ],
      placeNames: const ['역삼 공영주차장'],
    );

    expect(summary, isNull);
  });
}

Expense _expense({
  required String id,
  required String title,
  required int amount,
  required DateTime date,
  required ExpenseEntryType entryType,
}) {
  return Expense(
    id: id,
    title: title,
    amount: amount,
    date: date,
    category: ExpenseCategory.food,
    entryType: entryType,
  );
}
