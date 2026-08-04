import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/core/services/good_price_api_service.dart';
import 'package:project_survival_diary/features/map/good_price_store_distance.dart';

void main() {
  const currentLatitude = 37.5665;
  const currentLongitude = 126.9780;

  test('업소까지의 직선거리를 미터로 계산한다', () {
    final distance = distanceToGoodPriceStore(
      store: _store('1km 업소', latitude: 37.5755, longitude: 126.9780),
      latitude: currentLatitude,
      longitude: currentLongitude,
    );

    expect(distance, isNotNull);
    expect(distance!, inInclusiveRange(990, 1010));
  });

  test('좌표가 없는 업소는 거리를 계산하지 않는다', () {
    final distance = distanceToGoodPriceStore(
      store: _store('좌표 없는 업소'),
      latitude: currentLatitude,
      longitude: currentLongitude,
    );

    expect(distance, isNull);
  });
}

GoodPriceStore _store(
  String name, {
  double? latitude,
  double? longitude,
}) {
  return GoodPriceStore(
    province: '서울특별시',
    district: '중구',
    category: '한식',
    name: name,
    phone: '',
    address: '서울특별시 중구',
    menus: const [],
    latitude: latitude,
    longitude: longitude,
  );
}
