import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/core/services/good_price_api_service.dart';
import 'package:project_survival_diary/features/map/widgets/good_price_store_map_card.dart';

void main() {
  testWidgets('지도 업소 카드에서 상세 정보와 찜 상태를 표시한다', (tester) async {
    var isFavorite = false;
    var detailTapCount = 0;
    var directionsTapCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 270,
              height: 158,
              child: StatefulBuilder(
                builder: (context, setState) => GoodPriceStoreMapCard(
                  store: _store,
                  isFavorite: isFavorite,
                  onFavoritePressed: () {
                    setState(() => isFavorite = !isFavorite);
                  },
                  onDirectionsPressed: () => directionsTapCount++,
                  onTap: () => detailTapCount++,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('서면착한식당'), findsOneWidget);
    expect(find.text('한식'), findsOneWidget);
    expect(find.text('부산광역시 부산진구 중앙대로 1'), findsOneWidget);
    expect(find.text('된장찌개 · 7,000원'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('good-price-favorite-button')),
    );
    await tester.pump();

    expect(isFavorite, isTrue);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(detailTapCount, 0);

    await tester.tap(
      find.byKey(const ValueKey('good-price-directions-button')),
    );
    await tester.pump();

    expect(directionsTapCount, 1);
    expect(detailTapCount, 0);

    await tester.tap(find.byKey(const ValueKey('good-price-store-card')));
    await tester.pump();

    expect(detailTapCount, 1);
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
