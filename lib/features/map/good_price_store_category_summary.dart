import '../../core/services/good_price_api_service.dart';

class GoodPriceStoreCategorySummary {
  const GoodPriceStoreCategorySummary({
    required this.key,
    required this.label,
    required this.markerCategory,
    required this.count,
  });

  final String key;
  final String label;
  final String markerCategory;
  final int count;
}

List<GoodPriceStoreCategorySummary> summarizeGoodPriceStoreCategories(
  Iterable<GoodPriceStore> stores,
) {
  final counts = <String, int>{};
  for (final store in stores) {
    final group = _categoryGroup(store.category);
    counts[group] = (counts[group] ?? 0) + 1;
  }

  return [
    GoodPriceStoreCategorySummary(
      key: 'all',
      label: '전체',
      markerCategory: '전체',
      count: stores.length,
    ),
    GoodPriceStoreCategorySummary(
      key: 'food',
      label: '음식점',
      markerCategory: '양식',
      count: counts['food'] ?? 0,
    ),
    GoodPriceStoreCategorySummary(
      key: 'beauty',
      label: '미용업',
      markerCategory: '미용업',
      count: counts['beauty'] ?? 0,
    ),
    GoodPriceStoreCategorySummary(
      key: 'barber',
      label: '이용업',
      markerCategory: '이용업',
      count: counts['barber'] ?? 0,
    ),
    GoodPriceStoreCategorySummary(
      key: 'laundry',
      label: '세탁업',
      markerCategory: '세탁업',
      count: counts['laundry'] ?? 0,
    ),
    GoodPriceStoreCategorySummary(
      key: 'lodging',
      label: '숙박업',
      markerCategory: '숙박업',
      count: counts['lodging'] ?? 0,
    ),
    GoodPriceStoreCategorySummary(
      key: 'bath',
      label: '목욕업',
      markerCategory: '목욕업',
      count: counts['bath'] ?? 0,
    ),
    GoodPriceStoreCategorySummary(
      key: 'other',
      label: '기타',
      markerCategory: '기타비요식업',
      count: counts['other'] ?? 0,
    ),
  ];
}

bool goodPriceStoreMatchesCategory(
  GoodPriceStore store,
  String? categoryKey,
) {
  return categoryKey == null ||
      categoryKey == 'all' ||
      _categoryGroup(store.category) == categoryKey;
}

String _categoryGroup(String category) {
  final normalized = category.trim();
  if (normalized.contains('비요식')) {
    return 'other';
  }
  if (const {'한식', '중식', '일식', '양식', '기타요식업'}.contains(normalized) ||
      normalized.contains('음식') ||
      normalized.contains('요식')) {
    return 'food';
  }
  if (normalized.contains('미용')) {
    return 'beauty';
  }
  if (normalized.contains('이용')) {
    return 'barber';
  }
  if (normalized.contains('세탁')) {
    return 'laundry';
  }
  if (normalized.contains('숙박')) {
    return 'lodging';
  }
  if (normalized.contains('목욕')) {
    return 'bath';
  }
  return 'other';
}
