import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/services/good_price_api_service.dart';
import '../../../core/services/housing_rent_api_service.dart';
import '../../../core/services/public_facility_api_service.dart';
import '../../../core/services/public_parking_api_service.dart';

class MapFavorites {
  const MapFavorites({
    this.goodPriceStores = const {},
    this.publicFacilities = const {},
    this.parkingLots = const {},
    this.housingDeals = const {},
  });

  final Map<String, GoodPriceStore> goodPriceStores;
  final Map<String, PublicFacility> publicFacilities;
  final Map<String, PublicParkingLot> parkingLots;
  final Map<String, HousingRentDeal> housingDeals;

  bool get isEmpty =>
      goodPriceStores.isEmpty &&
      publicFacilities.isEmpty &&
      parkingLots.isEmpty &&
      housingDeals.isEmpty;
}

class MapFavoriteRepository {
  MapFavoriteRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _storageKey = 'map.favorites.v1';
  final FlutterSecureStorage _storage;

  Future<MapFavorites> load() async {
    final encoded = await _storage.read(key: _storageKey);
    if (encoded == null || encoded.isEmpty) return const MapFavorites();

    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) return const MapFavorites();
    return MapFavorites(
      goodPriceStores:
          _decodeMap(decoded['goodPriceStores'], GoodPriceStore.fromJson),
      publicFacilities:
          _decodeMap(decoded['publicFacilities'], PublicFacility.fromJson),
      parkingLots:
          _decodeMap(decoded['parkingLots'], PublicParkingLot.fromJson),
      housingDeals:
          _decodeMap(decoded['housingDeals'], HousingRentDeal.fromJson),
    );
  }

  Future<void> save(MapFavorites favorites) async {
    final data = <String, dynamic>{
      'goodPriceStores': favorites.goodPriceStores.map(
        (id, store) => MapEntry(id, _goodPriceStoreToJson(store)),
      ),
      'publicFacilities': favorites.publicFacilities.map(
        (id, facility) => MapEntry(id, _publicFacilityToJson(facility)),
      ),
      'parkingLots': favorites.parkingLots.map(
        (id, lot) => MapEntry(id, _parkingLotToJson(lot)),
      ),
      'housingDeals': favorites.housingDeals.map(
        (id, deal) => MapEntry(id, _housingDealToJson(deal)),
      ),
    };
    await _storage.write(key: _storageKey, value: jsonEncode(data));
  }

  Map<String, T> _decodeMap<T>(
    Object? value,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (value is! Map<String, dynamic>) return {};
    return value.map((id, item) {
      if (item is! Map<String, dynamic>) throw const FormatException();
      return MapEntry(id, fromJson(item));
    });
  }

  Map<String, dynamic> _goodPriceStoreToJson(GoodPriceStore store) {
    final data = <String, dynamic>{
      'province': store.province,
      'district': store.district,
      'category': store.category,
      'name': store.name,
      'phone': store.phone,
      'address': store.address,
      'latitude': store.latitude,
      'longitude': store.longitude,
    };
    for (var index = 0; index < store.menus.length && index < 4; index++) {
      data['menu${index + 1}'] = store.menus[index].name;
      data['price${index + 1}'] = store.menus[index].price;
    }
    return data;
  }

  Map<String, dynamic> _publicFacilityToJson(PublicFacility facility) => {
        'id': facility.id,
        'name': facility.name,
        'locationName': facility.locationName,
        'category': facility.category,
        'address': facility.address,
        'phone': facility.phone,
        'latitude': facility.latitude,
        'longitude': facility.longitude,
        'distanceMeters': facility.distanceMeters,
        'paid': facility.paid,
        'fee': facility.fee,
        'weekdayHours': facility.weekdayHours,
        'weekendHours': facility.weekendHours,
        'closedDays': facility.closedDays,
        'institution': facility.institution,
        'department': facility.department,
        'homepageUrl': facility.homepageUrl,
        'imageUrl': facility.imageUrl,
        'capacity': facility.capacity,
        'area': facility.area,
        'amenities': facility.amenities,
        'applicationMethod': facility.applicationMethod,
        'referenceDate': facility.referenceDate,
      };

  Map<String, dynamic> _parkingLotToJson(PublicParkingLot lot) => {
        'id': lot.id,
        'name': lot.name,
        'parkingType': lot.parkingType,
        'address': lot.address,
        'phone': lot.phone,
        'latitude': lot.latitude,
        'longitude': lot.longitude,
        'distanceMeters': lot.distanceMeters,
        'free': lot.free,
        'capacity': lot.capacity,
        'operationDays': lot.operationDays,
        'weekdayHours': lot.weekdayHours,
        'saturdayHours': lot.saturdayHours,
        'holidayHours': lot.holidayHours,
        'basicMinutes': lot.basicMinutes,
        'basicFee': lot.basicFee,
        'additionalMinutes': lot.additionalMinutes,
        'additionalFee': lot.additionalFee,
        'dailyFee': lot.dailyFee,
        'monthlyFee': lot.monthlyFee,
        'paymentMethods': lot.paymentMethods,
        'notes': lot.notes,
        'institution': lot.institution,
        'accessibleParking': lot.accessibleParking,
        'referenceDate': lot.referenceDate,
      };

  Map<String, dynamic> _housingDealToJson(HousingRentDeal deal) => {
        'id': deal.id,
        'propertyType': deal.propertyType,
        'propertyName': deal.propertyName,
        'dealType': deal.dealType,
        'depositTenThousandWon': deal.depositTenThousandWon,
        'monthlyRentTenThousandWon': deal.monthlyRentTenThousandWon,
        'contractDate': deal.contractDate.toIso8601String(),
        'areaSquareMeters': deal.areaSquareMeters,
        'floor': deal.floor,
        'neighborhood': deal.neighborhood,
        'lotNumber': deal.lotNumber,
        'buildYear': deal.buildYear,
        'contractTerm': deal.contractTerm,
        'contractType': deal.contractType,
        'previousDepositTenThousandWon': deal.previousDepositTenThousandWon,
        'previousMonthlyRentTenThousandWon':
            deal.previousMonthlyRentTenThousandWon,
        'renewalRequestRightUsed': deal.renewalRequestRightUsed,
        'address': deal.address,
        'latitude': deal.latitude,
        'longitude': deal.longitude,
        'locationAccuracy': deal.locationAccuracy,
      };
}
