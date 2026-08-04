import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_survival_diary/core/services/good_price_api_service.dart';

void main() {
  test('착한가격업소 페이지 응답과 메뉴 가격을 변환한다', () async {
    final service = GoodPriceApiService(
      baseUrl: 'http://example.com',
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer access-token');
        expect(request.url.queryParameters['province'], '서울특별시');
        expect(request.url.queryParameters['district'], '종로구');
        expect(request.url.queryParameters['sort'], 'price');
        return http.Response(
          '''
          {
            "success": true,
            "data": {
              "content": [
                {
                  "province": "서울특별시",
                  "district": "종로구",
                  "category": "양식",
                  "name": "돈까스보라",
                  "phone": "02-741-3455",
                  "address": "서울특별시 종로구 대학로5길 5",
                  "menu1": "수제 돈까스",
                  "price1": "7,000원",
                  "menu2": "",
                  "price2": "",
                  "menu3": "",
                  "price3": "",
                  "menu4": "",
                  "price4": "",
                  "latitude": 37.5796,
                  "longitude": 126.9990
                }
              ],
              "page": 0,
              "size": 20,
              "totalElements": 1,
              "totalPages": 1,
              "hasNext": false
            }
          }
          ''',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final page = await service.fetchStores(
      accessToken: 'access-token',
      province: '서울특별시',
      district: '종로구',
      sort: 'price',
    );

    expect(page.content.single.name, '돈까스보라');
    expect(page.content.single.lowestPrice, 7000);
    expect(page.content.single.hasCoordinates, isTrue);
    expect(page.hasNext, isFalse);
  });

  test('공통 오류 응답의 메시지를 전달한다', () async {
    final service = GoodPriceApiService(
      baseUrl: 'http://example.com',
      client: MockClient(
        (_) async => http.Response(
          '{"success":false,"error":{"code":"L001","message":"조회 실패"}}',
          503,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );

    expect(
      () => service.fetchStores(accessToken: 'access-token'),
      throwsA(
        isA<GoodPriceApiException>().having(
          (error) => error.message,
          'message',
          '조회 실패',
        ),
      ),
    );
  });

  test('지도 화면 중심 조회는 시도와 시군구를 전달한다', () async {
    final service = GoodPriceApiService(
      baseUrl: 'http://example.com',
      client: MockClient((request) async {
        expect(request.url.queryParameters['province'], '부산광역시');
        expect(request.url.queryParameters['district'], '부산진구');
        return http.Response(
          '''
          {
            "success": true,
            "data": {
              "content": [],
              "page": 0,
              "size": 20,
              "totalElements": 0,
              "totalPages": 0,
              "hasNext": false
            }
          }
          ''',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    await service.fetchStores(
      accessToken: 'access-token',
      province: '부산광역시',
      district: '부산진구',
    );
  });
}
