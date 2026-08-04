import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/core/services/good_price_api_service.dart';
import 'package:project_survival_diary/features/map/good_price_store_category_summary.dart';

void main() {
  test('현재 화면의 착한가격업소를 표시 카테고리별로 집계한다', () {
    final summaries = summarizeGoodPriceStoreCategories([
      _store('한식'),
      _store('중식'),
      _store('미용업'),
      _store('이용업'),
      _store('세탁업'),
      _store('숙박업'),
      _store('목욕업'),
      _store('기타비요식업'),
    ]);

    expect(_countOf(summaries, '전체'), 8);
    expect(_countOf(summaries, '음식점'), 2);
    expect(_countOf(summaries, '미용업'), 1);
    expect(_countOf(summaries, '이용업'), 1);
    expect(_countOf(summaries, '세탁업'), 1);
    expect(_countOf(summaries, '숙박업'), 1);
    expect(_countOf(summaries, '목욕업'), 1);
    expect(_countOf(summaries, '기타'), 1);
  });

  test('선택한 표시 카테고리에 해당하는 업소만 반환한다', () {
    final stores = [_store('한식'), _store('미용업'), _store('세탁업')];

    expect(
      stores
          .where((store) => goodPriceStoreMatchesCategory(store, 'food'))
          .map((store) => store.category),
      ['한식'],
    );
    expect(
      stores.where((store) => goodPriceStoreMatchesCategory(store, null)),
      stores,
    );
  });
}

int _countOf(List<GoodPriceStoreCategorySummary> summaries, String label) {
  return summaries.singleWhere((summary) => summary.label == label).count;
}

GoodPriceStore _store(String category) {
  return GoodPriceStore(
    province: '부산광역시',
    district: '부산진구',
    category: category,
    name: '$category 업소',
    phone: '',
    address: '부산광역시 부산진구 중앙대로',
    menus: const [],
    latitude: 35.1578,
    longitude: 129.0592,
  );
}
