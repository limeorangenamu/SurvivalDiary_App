import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_survival_diary/core/services/public_facility_api_service.dart';

void main() {
  test('지도 경계와 무료 필터를 전달하고 공공시설을 변환한다', () async {
    final service = PublicFacilityApiService(
      baseUrl: 'http://example.com',
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer access-token');
        expect(request.url.queryParameters['southWestLat'], '37.5');
        expect(request.url.queryParameters['northEastLng'], '127.1');
        expect(request.url.queryParameters['freeOnly'], 'true');
        expect(request.url.queryParameters['sort'], 'free');
        return http.Response(
          '''
          {
            "success": true,
            "data": {
              "content": [{
                "id": "facility-id",
                "name": "청년센터 세미나실",
                "locationName": "청년센터",
                "category": "회의실",
                "address": "서울특별시 종로구 세종대로 1",
                "phone": "02-000-0000",
                "latitude": 37.57,
                "longitude": 126.98,
                "distanceMeters": 320,
                "paid": false,
                "fee": "무료",
                "weekdayHours": "09:00~18:00",
                "weekendHours": "10:00~17:00",
                "closedDays": "연중무휴",
                "institution": "서울특별시",
                "department": "청년정책과",
                "homepageUrl": "https://example.com",
                "imageUrl": "",
                "capacity": "20",
                "area": "50",
                "amenities": "와이파이",
                "applicationMethod": "온라인",
                "referenceDate": "2026-08-01"
              }],
              "page": 0,
              "size": 100,
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

    final page = await service.fetchFacilities(
      accessToken: 'access-token',
      southWestLat: 37.5,
      southWestLng: 126.9,
      northEastLat: 37.6,
      northEastLng: 127.1,
      latitude: 37.55,
      longitude: 127.0,
      freeOnly: true,
      sort: 'free',
    );

    expect(page.content.single.name, '청년센터 세미나실');
    expect(page.content.single.isFree, isTrue);
    expect(page.content.single.distanceLabel, '320m');
    expect(page.content.single.hoursLabel, contains('평일 09:00~18:00'));
  });

  test('공통 오류 응답의 메시지를 전달한다', () async {
    final service = PublicFacilityApiService(
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
      () => service.fetchFacilities(
        accessToken: 'access-token',
        southWestLat: 37.5,
        southWestLng: 126.9,
        northEastLat: 37.6,
        northEastLng: 127.1,
        latitude: 37.55,
        longitude: 127.0,
      ),
      throwsA(
        isA<PublicFacilityApiException>().having(
          (error) => error.message,
          'message',
          '조회 실패',
        ),
      ),
    );
  });
}
