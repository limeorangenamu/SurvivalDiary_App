import '../../core/services/good_price_api_service.dart';

List<GoodPriceStore> goodPriceStoresForMap({
  required String filter,
  required List<GoodPriceStore> visibleStores,
  required Iterable<GoodPriceStore> favoriteStores,
}) {
  if (filter == '착한가격업소') {
    return visibleStores;
  }
  if (filter == '전체') {
    return favoriteStores.toList(growable: false);
  }
  return const [];
}
