import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/core/services/good_price_api_service.dart';
import 'package:project_survival_diary/features/map/good_price_store_detail_page.dart';
import 'package:project_survival_diary/features/map/place_expense_summary.dart';

void main() {
  testWidgets('착한가격업소 상세 화면에 API 정보를 표시한다', (tester) async {
    final spendingSummary = PlaceExpenseSummary(
      totalAmount: 16000,
      paymentCount: 2,
      latestAmount: 9000,
      latestDate: DateTime(2026, 8, 20),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GoodPriceStoreDetailPage(
          store: _store,
          spendingSummary: spendingSummary,
        ),
      ),
    );

    expect(find.text('착한가격업소 상세'), findsOneWidget);
    expect(find.text('서면착한식당'), findsOneWidget);
    expect(find.text('부산광역시 부산진구'), findsOneWidget);
    expect(find.text('부산광역시 부산진구 중앙대로 1'), findsOneWidget);
    expect(find.text('051-123-4567'), findsOneWidget);
    expect(find.text('된장찌개'), findsOneWidget);
    expect(find.text('7,000원'), findsOneWidget);
    expect(find.text('내 카드 사용'), findsOneWidget);
    expect(find.text('16,000원'), findsOneWidget);
    expect(find.text('총 2회 · 최근 8/20 9,000원'), findsOneWidget);
  });
}

const _store = GoodPriceStore(
  province: '부산광역시',
  district: '부산진구',
  category: '한식',
  name: '서면착한식당',
  phone: '051-123-4567',
  address: '부산광역시 부산진구 중앙대로 1',
  menus: [GoodPriceMenu(name: '된장찌개', price: '7,000원')],
  latitude: 35.1578,
  longitude: 129.0592,
);
