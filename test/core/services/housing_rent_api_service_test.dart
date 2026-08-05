import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_survival_diary/core/services/housing_rent_api_service.dart';

void main() {
  test('두 주택유형의 전월세 실거래 응답을 변환한다', () async {
    late Uri requestedUri;
    late Map<String, String> requestedHeaders;
    final client = MockClient((request) async {
      requestedUri = request.url;
      requestedHeaders = request.headers;
      return http.Response(
        jsonEncode({
          'success': true,
          'data': [
            {
              'id': 'officetel-1',
              'propertyType': '오피스텔',
              'propertyName': '강남역 오피스텔',
              'dealType': '월세',
              'depositTenThousandWon': 10000,
              'monthlyRentTenThousandWon': 80,
              'contractDate': '2026-08-03',
              'areaSquareMeters': 29.8,
              'floor': 8,
              'neighborhood': '역삼동',
              'lotNumber': '123-*',
              'buildYear': 2020,
              'contractTerm': '2026.08~2028.07',
              'contractType': '신규',
              'previousDepositTenThousandWon': null,
              'previousMonthlyRentTenThousandWon': null,
              'renewalRequestRightUsed': '',
              'address': '서울특별시 강남구 역삼동 123-*',
              'latitude': 37.5,
              'longitude': 127.0,
              'locationAccuracy': '지번',
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final service = HousingRentApiService(
      client: client,
      baseUrl: 'http://localhost:8080',
    );

    final deals = await service.fetchDeals(
      accessToken: 'access-token',
      condition: const HousingRentSearchCondition(
        region: '서울특별시 강남구 역삼동',
        lawdCode: '11680',
        neighborhood: '역삼동',
      ),
      endMonth: DateTime(2026, 8),
    );

    expect(requestedUri.path, '/api/map/housing-rent-deals');
    expect(requestedUri.queryParameters['lawdCd'], '11680');
    expect(requestedUri.queryParameters['dealYmd'], '202608');
    expect(requestedUri.queryParameters['months'], '3');
    expect(requestedUri.queryParameters['limit'], '100');
    expect(requestedUri.queryParameters['neighborhood'], '역삼동');
    expect(
      requestedUri.queryParameters['region'],
      '서울특별시 강남구 역삼동',
    );
    expect(requestedHeaders['Authorization'], 'Bearer access-token');
    expect(deals, hasLength(1));
    expect(deals.single.propertyType, '오피스텔');
    expect(deals.single.depositWon, 100000000);
    expect(deals.single.monthlyRentWon, 800000);
    expect(deals.single.hasCoordinates, isTrue);
    expect(deals.single.contractType, '신규');
  });
}
