import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/core/services/good_price_api_service.dart';
import 'package:project_survival_diary/core/services/housing_rent_api_service.dart';
import 'package:project_survival_diary/core/services/public_facility_api_service.dart';
import 'package:project_survival_diary/core/services/public_parking_api_service.dart';
import 'package:project_survival_diary/features/map/data/map_favorite_repository.dart';

void main() {
  test('네 가지 지도 찜을 저장하고 다시 불러온다', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final repository = MapFavoriteRepository();
    final store = GoodPriceStore.fromJson({
      'province': '서울특별시',
      'district': '강남구',
      'category': '한식',
      'name': '착한식당',
      'address': '서울 강남구',
      'menu1': '비빔밥',
      'price1': '7000',
      'latitude': 37.5,
      'longitude': 127.0,
    });
    final facility = PublicFacility.fromJson({
      'id': 'facility-1',
      'name': '청년센터',
      'latitude': 37.51,
      'longitude': 127.01,
    });
    final parkingLot = PublicParkingLot.fromJson({
      'id': 'parking-1',
      'name': '공영주차장',
      'latitude': 37.52,
      'longitude': 127.02,
    });
    final housingDeal = HousingRentDeal.fromJson({
      'id': 'housing-1',
      'propertyName': '청년주택',
      'contractDate': '2026-08-01',
      'latitude': 37.53,
      'longitude': 127.03,
    });

    await repository.save(
      MapFavorites(
        goodPriceStores: {store.id: store},
        publicFacilities: {facility.id: facility},
        parkingLots: {parkingLot.id: parkingLot},
        housingDeals: {housingDeal.id: housingDeal},
      ),
    );

    final restored = await repository.load();

    expect(restored.goodPriceStores[store.id]?.menus.single.name, '비빔밥');
    expect(restored.publicFacilities['facility-1']?.name, '청년센터');
    expect(restored.parkingLots['parking-1']?.name, '공영주차장');
    expect(restored.housingDeals['housing-1']?.propertyName, '청년주택');
  });
}
