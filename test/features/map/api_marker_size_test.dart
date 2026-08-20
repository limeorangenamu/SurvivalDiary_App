import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/features/map/good_price_store_marker_style.dart';
import 'package:project_survival_diary/features/map/housing_deal_marker_style.dart';
import 'package:project_survival_diary/features/map/public_facility_marker_style.dart';
import 'package:project_survival_diary/features/map/public_parking_marker_style.dart';

void main() {
  testWidgets('API 지도 마커는 기존 크기의 75%로 표시된다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GoodPriceStoreMarkerIcon(
                style: GoodPriceStoreMarkerStyle.fromCategory('한식'),
              ),
              PublicFacilityMarkerIcon(
                style: PublicFacilityMarkerStyle.fromCategory('공원'),
              ),
              const PublicParkingMarkerIcon(),
              HousingDealMarkerIcon(
                style: HousingDealMarkerStyle.fromPropertyType('오피스텔'),
              ),
            ],
          ),
        ),
      ),
    );

    const expectedSize = Size(33, 39);
    expect(
      tester.getSize(find.byType(GoodPriceStoreMarkerIcon)),
      expectedSize,
    );
    expect(
      tester.getSize(find.byType(PublicFacilityMarkerIcon)),
      expectedSize,
    );
    expect(
      tester.getSize(find.byType(PublicParkingMarkerIcon)),
      expectedSize,
    );
    expect(
      tester.getSize(find.byType(HousingDealMarkerIcon)),
      expectedSize,
    );
  });
}
