import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/core/services/good_price_api_service.dart';
import 'package:project_survival_diary/features/map/good_price_store_visibility.dart';

void main() {
  test('착한가격업소 탭은 찜 여부와 관계없이 화면 안의 업소를 모두 표시한다', () {
    final result = goodPriceStoresForMap(
      filter: '착한가격업소',
      visibleStores: [_favoriteStore, _normalStore],
      favoriteStores: [_favoriteStore],
    );

    expect(result, [_favoriteStore, _normalStore]);
  });

  test('전체 탭은 찜한 착한가격업소만 표시한다', () {
    final result = goodPriceStoresForMap(
      filter: '전체',
      visibleStores: [_favoriteStore, _normalStore],
      favoriteStores: [_favoriteStore],
    );

    expect(result, [_favoriteStore]);
  });
}

const _favoriteStore = GoodPriceStore(
  province: '부산광역시',
  district: '부산진구',
  category: '한식',
  name: '찜한 업소',
  phone: '',
  address: '부산광역시 부산진구 중앙대로 1',
  menus: [],
  latitude: 35.1578,
  longitude: 129.0592,
);

const _normalStore = GoodPriceStore(
  province: '부산광역시',
  district: '부산진구',
  category: '세탁업',
  name: '일반 업소',
  phone: '',
  address: '부산광역시 부산진구 중앙대로 2',
  menus: [],
  latitude: 35.1580,
  longitude: 129.0600,
);
