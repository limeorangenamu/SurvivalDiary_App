import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/data/models.dart';
import 'package:project_survival_diary/features/diary/notification_detection/detected_expense_candidate.dart';

void main() {
  test('플랫폼 감지 값을 지출 후보로 변환한다', () {
    final candidate = DetectedExpenseCandidate.fromPlatformMap({
      'id': 'detection-key',
      'merchant': '스타벅스 강남점',
      'amount': 5500,
      'detectedAt': DateTime(2026, 8, 3, 9, 42).millisecondsSinceEpoch,
      'source': '토스',
      'sourcePackage': 'viva.republica.toss',
      'category': 'cafe',
      'confidence': 0.9,
    });

    expect(candidate.id, 'detection-key');
    expect(candidate.amount, 5500);
    expect(candidate.category, ExpenseCategory.cafe);
    expect(candidate.needsReview, isFalse);
  });

  test('알 수 없는 카테고리는 기타로 처리한다', () {
    final candidate = DetectedExpenseCandidate.fromPlatformMap({
      'id': 'detection-key',
      'merchant': '가맹점',
      'amount': 1000,
      'detectedAt': 0,
      'source': '토스',
      'sourcePackage': 'viva.republica.toss',
      'category': 'unknown',
      'confidence': 0.5,
    });

    expect(candidate.category, ExpenseCategory.etc);
    expect(candidate.needsReview, isTrue);
  });
}
