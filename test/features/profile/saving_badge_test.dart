import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/data/models.dart';
import 'package:project_survival_diary/features/auth/data/auth_api_client.dart';
import 'package:project_survival_diary/shared/widgets/saving_badge_chip.dart';

void main() {
  const badgeJson = {
    'code': 'GUKBAP',
    'label': '국밥 한 그릇',
    'emoji': '🍲',
    'thresholdAmount': 10000,
    'savedAmount': 10500,
    'earnedMonth': '2026-08',
    'message': '지난달에는 국밥 한 그릇에 가까운 금액을 절약했어요',
  };

  test('사용자 응답에서 절약 뱃지를 읽는다', () {
    final user = CurrentUser.fromJson({
      'userId': 1,
      'email': 'user@example.com',
      'name': '사용자',
      'savingBadge': badgeJson,
    });

    expect(user.savingBadge?.code, 'GUKBAP');
    expect(user.savingBadge?.savedAmount, 10500);
  });

  testWidgets('커뮤니티용 절약 뱃지에 음식 아이콘과 이름을 표시한다', (tester) async {
    final badge = SavingBadge.fromJson(badgeJson);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavingBadgeChip(badge: badge, compact: true),
        ),
      ),
    );

    expect(find.text('🍲'), findsOneWidget);
    expect(find.text('국밥 한 그릇'), findsOneWidget);
  });

  testWidgets('500원 뱃지는 동전 대신 사탕 아이콘을 표시한다', (tester) async {
    const candy = SavingBadge(
      code: 'CANDY',
      label: '사탕',
      emoji: '🍬',
      thresholdAmount: 500,
      savedAmount: 700,
      earnedMonth: '2026-08',
      message: '지난달에는 사탕 하나에 가까운 금액을 절약했어요',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SavingBadgeChip(badge: candy, compact: true)),
      ),
    );

    expect(find.text('🍬'), findsOneWidget);
    expect(find.text('사탕'), findsOneWidget);
  });
}
