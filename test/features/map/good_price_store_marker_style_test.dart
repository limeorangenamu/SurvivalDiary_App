import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/features/map/good_price_store_marker_style.dart';

void main() {
  const categories = [
    '한식',
    '중식',
    '일식',
    '양식',
    '기타요식업',
    '미용업',
    '이용업',
    '세탁업',
    '숙박업',
    '목욕업',
    '기타비요식업',
  ];

  test('요식업은 같은 색상과 서로 다른 아이콘을 사용한다', () {
    final styles =
        categories.take(5).map(GoodPriceStoreMarkerStyle.fromCategory).toList();

    expect(styles.map((style) => style.color).toSet(), hasLength(1));
    expect(styles.map((style) => style.icon).toSet(), hasLength(5));
  });

  test('개인서비스업은 서로 다른 색상과 아이콘을 사용한다', () {
    final styles =
        categories.skip(5).map(GoodPriceStoreMarkerStyle.fromCategory).toList();

    expect(styles.map((style) => style.color).toSet(), hasLength(6));
    expect(styles.map((style) => style.icon).toSet(), hasLength(6));
  });

  test('알 수 없는 업종에도 기본 마커 스타일을 제공한다', () {
    final style = GoodPriceStoreMarkerStyle.fromCategory('새로운 업종');

    expect(style.color, isNotNull);
    expect(style.icon, isNotNull);
  });
}
