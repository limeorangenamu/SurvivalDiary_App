import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/core/services/housing_rent_api_service.dart';
import 'package:project_survival_diary/core/theme/app_theme.dart';
import 'package:project_survival_diary/features/map/housing_deal_detail_page.dart';

void main() {
  testWidgets('전월세 계약과 위치 상세정보를 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: HousingDealDetailPage(deal: _deal),
      ),
    );

    expect(find.text('강남역 오피스텔'), findsOneWidget);
    expect(find.text('오피스텔 · 월세'), findsOneWidget);
    expect(find.textContaining('보증금 1억원'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('신규'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('신규'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('2026.08~2028.07'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('2026.08~2028.07'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('서울특별시 강남구 역삼동 123-*'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('서울특별시 강남구 역삼동 123-*'), findsOneWidget);
  });
}

final _deal = HousingRentDeal(
  id: 'deal-1',
  propertyType: '오피스텔',
  propertyName: '강남역 오피스텔',
  dealType: '월세',
  depositTenThousandWon: 10000,
  monthlyRentTenThousandWon: 80,
  contractDate: DateTime(2026, 8, 3),
  areaSquareMeters: 29.8,
  floor: 8,
  neighborhood: '역삼동',
  lotNumber: '123-*',
  buildYear: 2020,
  contractTerm: '2026.08~2028.07',
  contractType: '신규',
  previousDepositTenThousandWon: null,
  previousMonthlyRentTenThousandWon: null,
  renewalRequestRightUsed: '',
  address: '서울특별시 강남구 역삼동 123-*',
  latitude: 37.5,
  longitude: 127.0,
  locationAccuracy: '지번',
);
