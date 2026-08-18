import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/features/map/saving_map_page.dart';
import 'package:project_survival_diary/features/map/good_price_store_marker_style.dart';
import 'package:project_survival_diary/features/map/housing_deal_marker_style.dart';
import 'package:project_survival_diary/features/map/widgets/map_canvas.dart';
import 'package:project_survival_diary/shared/widgets/app_card.dart';
import 'package:project_survival_diary/shared/widgets/pill_chip.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('지도는 MY 탭을 선택한 상태로 시작한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SavingMapPage()));

    final finder = find.widgetWithText(PillChip, 'MY');
    expect(finder, findsOneWidget);
    expect(tester.widget<PillChip>(finder).selected, isTrue);
    expect(find.widgetWithText(PillChip, '전체'), findsNothing);
    expect(
      find.byKey(const ValueKey('my-favorite-type-__all__')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('my-favorite-type-good-price')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('my-favorite-type-public-facility')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('my-favorite-type-public-parking')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('my-favorite-type-housing')),
      findsOneWidget,
    );
    expect(find.textContaining('찜한 장소'), findsNothing);
  });

  testWidgets('MY 분류를 선택하면 해당 종류의 찜만 지도에 표시한다', (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      'map.favorites.v1': jsonEncode({
        'goodPriceStores': {
          'good-1': {
            'province': '서울',
            'district': '중구',
            'category': '한식',
            'name': '착한식당',
            'address': '서울 중구',
            'latitude': 37.56,
            'longitude': 126.98,
          },
        },
        'publicFacilities': {
          'facility-1': {
            'id': 'facility-1',
            'name': '청년센터',
            'category': '문화시설',
            'latitude': 37.57,
            'longitude': 126.99,
          },
        },
        'parkingLots': {
          'parking-1': {
            'id': 'parking-1',
            'name': '공영주차장',
            'parkingType': '노외',
            'latitude': 37.58,
            'longitude': 127.0,
          },
        },
        'housingDeals': {
          'housing-1': {
            'id': 'housing-1',
            'propertyType': '오피스텔',
            'contractDate': '2026-08-18T00:00:00.000',
            'latitude': 37.59,
            'longitude': 127.01,
          },
        },
      }),
    });
    await tester.pumpWidget(const MaterialApp(home: SavingMapPage()));
    await tester.pump();

    SavingMapCanvas canvas() =>
        tester.widget<SavingMapCanvas>(find.byType(SavingMapCanvas));
    expect(canvas().goodPriceStores, hasLength(1));
    expect(canvas().publicFacilities, hasLength(1));
    expect(canvas().parkingLots, hasLength(1));
    expect(canvas().housingDeals, hasLength(1));
    expect(find.text('찜 4개'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('my-favorite-type-public-facility')),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(canvas().goodPriceStores, isEmpty);
    expect(canvas().publicFacilities, hasLength(1));
    expect(canvas().parkingLots, isEmpty);
    expect(canvas().housingDeals, isEmpty);
  });

  testWidgets('MY 찜 분류 배너는 공간이 충분하면 가운데 정렬된다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: SavingMapPage()));

    final categoryPanel = find.byKey(const ValueKey('map-category-panel'));
    final firstBanner = find.byKey(
      const ValueKey('my-favorite-type-__all__'),
    );
    final lastBanner = find.byKey(
      const ValueKey('my-favorite-type-housing'),
    );
    final bannersCenter = (tester.getTopLeft(firstBanner).dx +
            tester.getTopRight(lastBanner).dx) /
        2;

    expect(
      bannersCenter,
      moreOrLessEquals(tester.getCenter(categoryPanel).dx, epsilon: 1),
    );
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

  testWidgets('분류 배너를 선택하면 색상이 바뀌고 위로 올라간다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SavingMapPage()));

    await tester.tap(find.widgetWithText(PillChip, '주거지'));
    await tester.pump();

    final banner = find.byKey(
      const ValueKey('housing-property-type-단독/다가구'),
    );
    AnimatedContainer container() => tester.widget<AnimatedContainer>(
          find.descendant(of: banner, matching: find.byType(AnimatedContainer)),
        );

    expect(container().transform?.getTranslation().y, 0);

    await tester.tap(banner);
    await tester.pump(const Duration(milliseconds: 200));

    final style = HousingDealMarkerStyle.fromPropertyType('단독/다가구');
    final decoration = container().decoration! as BoxDecoration;
    expect(container().transform?.getTranslation().y, -6);
    expect(decoration.color, style.color);
  });

  testWidgets('공공시설과 공영주차장도 동일한 하단 분류 배너를 사용한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SavingMapPage()));

    await tester.tap(find.widgetWithText(PillChip, '공공시설'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('public-facility-category-__all__')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('public-facility-category-__free__')),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(PillChip, '공영주차장'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('public-parking-type-__all__')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('public-parking-type-__free__')),
      findsOneWidget,
    );
    final categoryPanel = find.byKey(const ValueKey('map-category-panel'));
    final allBanner = find.byKey(
      const ValueKey('public-parking-type-__all__'),
    );
    final freeBanner = find.byKey(
      const ValueKey('public-parking-type-__free__'),
    );
    final bannersCenter =
        (tester.getTopLeft(allBanner).dx + tester.getTopRight(freeBanner).dx) /
            2;
    expect(
      bannersCenter,
      moreOrLessEquals(tester.getCenter(categoryPanel).dx, epsilon: 1),
    );
    expect(
      find.descendant(
        of: categoryPanel,
        matching: find.byType(AppCard),
      ),
      findsNothing,
    );
  });
}
