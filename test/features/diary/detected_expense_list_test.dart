import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/core/theme/app_theme.dart';
import 'package:project_survival_diary/features/diary/notification_detection/detected_expense_list.dart';
import 'package:project_survival_diary/features/diary/notification_detection/notification_expense_repository.dart';

void main() {
  const methodChannel = MethodChannel(
    'com.survivaldiary.project_survival_diary/payment_notifications',
  );
  const eventChannel = MethodChannel(
    'com.survivaldiary.project_survival_diary/payment_notification_events',
  );

  setUp(() async {
    await NotificationExpenseRepository.instance.reset();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(methodChannel, (call) async {
      return switch (call.method) {
        'isNotificationAccessGranted' => true,
        'getSmsAccessState' => 'enabled',
        'scanSmsInbox' => 0,
        'getDetectedExpenses' => [
            {
              'id': 'detection-key',
              'merchant': '스타벅스 강남점',
              'amount': 5500,
              'detectedAt': DateTime(2026, 8, 3, 9, 42).millisecondsSinceEpoch,
              'source': '토스',
              'sourcePackage': 'viva.republica.toss',
              'category': 'cafe',
              'confidence': 0.9,
            },
          ],
        _ => null,
      };
    });
    messenger.setMockMethodCallHandler(eventChannel, (call) async => null);
  });

  tearDown(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(methodChannel, null);
    messenger.setMockMethodCallHandler(eventChannel, null);
    await NotificationExpenseRepository.instance.reset();
  });

  testWidgets('기기에 보관된 감지 결제를 자동 등록 목록에 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: DetectedExpenseList(limit: 3, allowExclude: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('결제 알림을 실시간으로 확인 중이에요'), findsNothing);
    expect(find.text('문자함의 결제 내역도 확인 중이에요'), findsNothing);
    expect(find.text('스타벅스 강남점'), findsOneWidget);
    expect(find.text('5,500원'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('edit-detected-detection-key')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('add-detected-detection-key')),
      findsOneWidget,
    );
  });
}
