import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/features/map/saving_map_page.dart';
import 'package:project_survival_diary/features/map/good_price_store_marker_style.dart';
import 'package:project_survival_diary/features/map/housing_deal_marker_style.dart';
import 'package:project_survival_diary/features/map/widgets/map_canvas.dart';
import 'package:project_survival_diary/core/theme/app_colors.dart';
import 'package:project_survival_diary/shared/widgets/app_card.dart';
import 'package:project_survival_diary/shared/widgets/pill_chip.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('지도는 MY 탭을 선택한 상태로 시작한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SavingMapPage()));

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(scaffold.extendBodyBehindAppBar, isTrue);
    expect(appBar.backgroundColor, Colors.transparent);
    expect(appBar.systemOverlayStyle?.statusBarColor, Colors.transparent);
    expect(find.text('절약 지도'), findsNothing);

    final finder = find.widgetWithText(PillChip, 'MY');
    expect(finder, findsOneWidget);
    expect(tester.widget<PillChip>(finder).selected, isTrue);
    expect(find.widgetWithText(PillChip, '전체'), findsNothing);
    expect(
      find.byKey(const ValueKey('my-favorite-type-__all__')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('my-favorite-type-good-price')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('my-favorite-type-public-facility')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('my-favorite-type-public-parking')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('my-favorite-type-housing')),
      findsNothing,
    );
    expect(find.textContaining('찜한 장소'), findsNothing);
  });

  testWidgets('MY 분류를 선택하면 해당 종류의 찜만 지도에 표시한다', (tester) async {
    FlutterSecureStorage.setMockInitialValues(_allFavoriteTypes());
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

  testWidgets('MY 찜 분류 배너는 흰색 2x2 그리드로 세로 스크롤된다', (tester) async {
    FlutterSecureStorage.setMockInitialValues(_allFavoriteTypes());
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: SavingMapPage()));
    await tester.pump();

    final categoryPanel = find.byKey(const ValueKey('map-category-panel'));
    expect(
      find.descendant(of: categoryPanel, matching: find.byType(GridView)),
      findsOneWidget,
    );
    final grid = tester.widget<GridView>(
      find.descendant(of: categoryPanel, matching: find.byType(GridView)),
    );
    expect(grid.scrollDirection, Axis.vertical);
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);

    final panelRect = tester.getRect(categoryPanel);
    for (final key in const [
      'my-favorite-type-__all__',
      'my-favorite-type-good-price',
      'my-favorite-type-public-facility',
      'my-favorite-type-public-parking',
    ]) {
      final bannerRect = tester.getRect(find.byKey(ValueKey(key)));
      expect(bannerRect.left, greaterThanOrEqualTo(panelRect.left));
      expect(bannerRect.right, lessThanOrEqualTo(panelRect.right));
    }

    final unselectedBanner = find.byKey(
      const ValueKey('my-favorite-type-public-facility'),
    );
    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: unselectedBanner,
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.surface);
    expect(decoration.boxShadow, isNotEmpty);

    final scrollable = find.descendant(
      of: categoryPanel,
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    expect(position.maxScrollExtent, greaterThan(0));
    await tester.drag(
      find.descendant(of: categoryPanel, matching: find.byType(GridView)),
      const Offset(0, -80),
    );
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(0));
    expect(
      find.byKey(const ValueKey('my-favorite-type-housing')),
      findsOneWidget,
    );
  });

  testWidgets('주거지 데이터가 없으면 하단 분류 배너를 숨긴다', (tester) async {
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
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('housing-property-type-오피스텔')),
      findsNothing,
    );
    expect(find.byType(HousingDealMarkerIcon), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('map-category-panel')),
        matching: find.byType(AppCard),
      ),
      findsNothing,
    );
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('착한가격업소 데이터가 없으면 하단 분류 배너를 숨긴다', (tester) async {
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
      findsNothing,
    );
    expect(find.byType(GoodPriceStoreMarkerIcon), findsNothing);
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
    FlutterSecureStorage.setMockInitialValues(_allFavoriteTypes());
    await tester.pumpWidget(const MaterialApp(home: SavingMapPage()));
    await tester.pump();

    final banner = find.byKey(
      const ValueKey('my-favorite-type-public-facility'),
    );
    AnimatedContainer container() => tester.widget<AnimatedContainer>(
          find.descendant(of: banner, matching: find.byType(AnimatedContainer)),
        );

    expect(container().transform?.getTranslation().y, 0);
    final unselectedDecoration = container().decoration! as BoxDecoration;
    expect(unselectedDecoration.color, AppColors.surface);
    expect(unselectedDecoration.boxShadow, isNotEmpty);

    await tester.tap(banner);
    await tester.pump(const Duration(milliseconds: 200));

    final decoration = container().decoration! as BoxDecoration;
    expect(container().transform?.getTranslation().y, -6);
    expect(decoration.color, AppColors.pinPublic);
  });

  testWidgets('공공시설과 공영주차장도 데이터가 없으면 분류 배너를 숨긴다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SavingMapPage()));

    await tester.tap(find.widgetWithText(PillChip, '공공시설'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('public-facility-category-__all__')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('public-facility-category-__free__')),
      findsNothing,
    );

    await tester.tap(find.widgetWithText(PillChip, '공영주차장'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('public-parking-type-__all__')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('public-parking-type-__free__')),
      findsNothing,
    );
    final categoryPanel = find.byKey(const ValueKey('map-category-panel'));
    expect(
      find.descendant(
        of: categoryPanel,
        matching: find.byType(AppCard),
      ),
      findsNothing,
    );
  });
}

Map<String, String> _allFavoriteTypes() {
  return {
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
  };
}
