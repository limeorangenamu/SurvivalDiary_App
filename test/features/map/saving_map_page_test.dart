import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/features/map/saving_map_page.dart';
import 'package:project_survival_diary/features/map/good_price_store_marker_style.dart';
import 'package:project_survival_diary/features/map/housing_deal_marker_style.dart';
import 'package:project_survival_diary/shared/widgets/app_card.dart';
import 'package:project_survival_diary/shared/widgets/pill_chip.dart';

void main() {
  testWidgets('지도는 MY 탭을 선택한 상태로 시작한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SavingMapPage()));

    final finder = find.widgetWithText(PillChip, 'MY');
    expect(finder, findsOneWidget);
    expect(tester.widget<PillChip>(finder).selected, isTrue);
    expect(find.text('전체'), findsNothing);
  });

  testWidgets('주거지 탭은 지도 안에 분류를 표시한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SavingMapPage()));

    await tester.tap(find.widgetWithText(PillChip, '주거지'));
    await tester.pump();

    final panel = tester.widget<Positioned>(
      find.byKey(const ValueKey('map-category-panel')),
    );
    expect(panel.top, isNull);
    expect(panel.bottom, 16);
    expect(
      find.byKey(const ValueKey('housing-property-type-단독/다가구')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('housing-property-type-오피스텔')),
      findsOneWidget,
    );
    expect(find.byType(HousingDealMarkerIcon), findsNWidgets(2));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('map-category-panel')),
        matching: find.byType(AppCard),
      ),
      findsNothing,
    );
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('착한가격업소 탭은 지도 안에 분류를 표시한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SavingMapPage()));

    await tester.tap(find.widgetWithText(PillChip, '착한가격업소'));
    await tester.pump();

    final panel = tester.widget<Positioned>(
      find.byKey(const ValueKey('map-category-panel')),
    );
    expect(panel.top, isNull);
    expect(panel.bottom, 16);
    expect(
      find.byKey(const ValueKey('good-price-category-all')),
      findsOneWidget,
    );
    expect(find.byType(GoodPriceStoreMarkerIcon), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('map-category-panel')),
        matching: find.byType(AppCard),
      ),
      findsNothing,
    );
    expect(find.byType(BottomSheet), findsNothing);
  });
}
