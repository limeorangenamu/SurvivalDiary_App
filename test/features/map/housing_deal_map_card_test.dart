import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/core/services/housing_rent_api_service.dart';
import 'package:project_survival_diary/features/map/widgets/housing_deal_map_card.dart';

void main() {
  testWidgets('실거래 마커 요약카드를 누르면 상세 동작을 호출한다', (tester) async {
    var tapCount = 0;
    var favoriteTapCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 276,
            height: 146,
            child: HousingDealMapCard(
              deal: _deal,
              isFavorite: false,
              onFavoritePressed: () => favoriteTapCount++,
              onTap: () => tapCount++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('오피스텔 · 월세'), findsOneWidget);
    expect(find.text('강남역 오피스텔'), findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey('housing-deal-favorite-button')));
    expect(favoriteTapCount, 1);
    await tester.tap(find.byKey(const ValueKey('housing-deal-map-card')));
    expect(tapCount, 1);
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
  contractTerm: '',
  contractType: '',
  previousDepositTenThousandWon: null,
  previousMonthlyRentTenThousandWon: null,
  renewalRequestRightUsed: '',
  address: '서울특별시 강남구 역삼동 123-*',
  latitude: 37.5,
  longitude: 127.0,
  locationAccuracy: '지번',
);
