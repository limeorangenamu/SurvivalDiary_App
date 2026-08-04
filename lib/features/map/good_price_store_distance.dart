import 'package:geolocator/geolocator.dart';

import '../../core/services/good_price_api_service.dart';

double? distanceToGoodPriceStore({
  required GoodPriceStore store,
  required double latitude,
  required double longitude,
}) {
  if (!store.hasCoordinates) {
    return null;
  }
  return Geolocator.distanceBetween(
    latitude,
    longitude,
    store.latitude!,
    store.longitude!,
  );
}
